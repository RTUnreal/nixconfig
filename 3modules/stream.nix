{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf mkMerge optionalString;
  cfg = config.rtinf.stream;

  certdir =
    if cfg.certDir == null
    then config.security.acme.certs.${cfg.domain}.directory
    else cfg.certDir;
in {
  options.rtinf.stream = {
    enable = mkEnableOption "enable stream";
    domain = mkOption {
      type = types.str;
      default = config.networking.fqdn;
      description = lib.mdDoc "domain of the server";
    };
    directory = mkOption {
      type = types.str;
      default = "/var/lib/rtmp";
      description = lib.mdDoc "domain of the server";
    };
    certDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc "domain of the server";
    };

    hls = mkOption {
      type = types.nullOr (types.submodule {
        options.storagePath = mkOption {
          type = types.str;
          default = "/hls";
          description = lib.mdDoc "path where the HLS stream will be available";
        };
      });
      default = null;
      description = lib.mdDoc "set hls specific configs. `null` to disable.";
    };
    dash = mkOption {
      type = types.nullOr (types.submodule {
        options.storagePath = mkOption {
          type = types.str;
          default = "/dash";
          description = lib.mdDoc "path where the dash stream will be available";
        };
      });
      default = null;
      description = lib.mdDoc "set DASH specific configs. `null` to disable.";
    };
    playlistLength = mkOption {
      type = types.str;
      default = "4s";
      description = lib.mdDoc "playlist length of the stream";
    };
    fragmentLength = mkOption {
      type = types.str;
      default = "1s";
      description = lib.mdDoc "fragment length of the stream";
    };

    auth = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          authDir = mkOption {
            type = types.str;
            description = lib.mdDoc "path to a directory of htpasswd files";
          };
          port = mkOption {
            type = types.port;
            default = 9001;
            description = lib.mdDoc "port of the auth service";
          };
        };
      });
      default = null;
      description = lib.mdDoc "set auth specific configs. `null` to disable.";
    };

    openFirewall = mkEnableOption "open firewall to all services";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      services.nginx = {
        enable = true;
        additionalModules = [pkgs.nginxModules.rtmp];
        virtualHosts = mkIf (builtins.any (x: x != null) [cfg.hls cfg.dash]) {
          ${cfg.domain} = {
            enableACME = cfg.certDir == null;
            forceSSL = true;
            sslCertificate = mkIf (cfg.certDir != null) "${certdir}/fullchain.pem";
            sslCertificateKey = mkIf (cfg.certDir != null) "${certdir}/key.pem";
            locations = mkMerge [
              (mkIf (cfg.hls != null) {
                ${cfg.hls.storagePath} = {
                  root = cfg.directory;
                  extraConfig = ''
                    types {
                      application/vnd.apple.mpegurl m3u8;
                      video/mp2t ts;
                    }
                    add_header Cache-Control no-cache;
                  '';
                };
              })
              (mkIf (cfg.dash != null) {
                ${cfg.dash.storagePath} = {
                  root = cfg.directory;
                  extraConfig = ''
                    add_header Cache-Control no-cache;
                    add_header Access-Control-Allow-Origin *;
                  '';
                };
              })
            ];
          };
        };
        streamConfig = ''
          server {
            listen 1936 ssl;
            ssl_certificate ${certdir}/fullchain.pem;
            ssl_certificate_key ${certdir}/key.pem;
            proxy_pass 127.0.0.1:1935;
          }
        '';
        appendConfig = ''
          rtmp {
            server {
              listen 1935;
              chunk_size 4096;
              allow publish all;

              application live {
                live on;
                record off;
                ${optionalString (cfg.auth != null) ''

            on_publish http://127.0.0.1:${toString cfg.auth.port}/;
            notify_method get;
          ''}${optionalString (cfg.hls != null) ''

            hls on;
            hls_path ${cfg.directory}${cfg.hls.storagePath};
            hls_playlist_length ${cfg.playlistLength};
            hls_fragment ${cfg.fragmentLength};
          ''}${optionalString (cfg.dash != null) ''

            dash on;
            dash_path ${cfg.directory}${cfg.dash.storagePath};
            dash_playlist_length ${cfg.playlistLength};
            dash_fragment ${cfg.fragmentLength};
          ''}
              }
            }
          }
        '';
      };
      systemd.services.nginx.serviceConfig.ReadWritePaths = cfg.directory;
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [80 443 1935 1936];

      systemd.tmpfiles.rules = [
        "d ${cfg.directory} 0744 ${config.services.nginx.user} ${config.services.nginx.group} -"
      ];
    })
    (mkIf (cfg.auth != null) {
      services.uwsgi = {
        enable = true;
        plugins = ["python3"];
        instance = {
          type = "emperor";
          vassals.rtmp-auth = {
            type = "normal";
            master = true;
            workers = 2;
            http = ":${toString cfg.auth.port}";
            module = "auth_app:app";
            env = ["AUTH_DIR=${cfg.auth.authDir}"];
            chdir =
              pkgs.writeTextDir "auth_app.py"
              /*
              py
              */
              ''
                from flask import Flask, request, abort
                from subprocess import run
                import os
                import re

                app = Flask(__name__)
                NAME_RE = re.compile(r"^\w+$")

                auth_dir = os.environ['AUTH_DIR'] + '/'


                @app.route("/", methods=["GET"])
                def hello_world():
                    args = request.args
                    name = args.get("name")
                    username = args.get("username")
                    password = args.get("password")

                    auth_file = auth_dir + name

                    print(auth_file, username, password)

                    if None in (name, username, password) or not NAME_RE.match(name) or run(["${pkgs.apacheHttpd}/bin/htpasswd", "-bv", auth_file, username, password], capture_output=True).returncode != 0:  # noqa: E501
                        print(f"Failed Login for '{name}': '{username}'")
                        abort(403)

                    print(f"{username} started a stream on {name}")
                    return ""
              '';
            pythonPackages = self: [self.flask];
          };
        };
      };
      environment.systemPackages = [pkgs.apacheHttpd];
      systemd.tmpfiles.rules = [
        "d ${cfg.auth.authDir} 0744 ${config.services.uwsgi.user} ${config.services.uwsgi.group} -"
      ];
    })
  ];
}
