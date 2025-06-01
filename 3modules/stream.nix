{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    optionalString
    ;
  cfg = config.rtinf.stream;

  certdir =
    if cfg.certDir == null then config.security.acme.certs.${cfg.domain}.directory else cfg.certDir;

  writeGo =
    name:
    {
      go ? pkgs.go,
      makeWrapperArgs ? [ ],
      goBuildArgs ? [ ],
      strip ? true,
    }:
    pkgs.writers.makeBinWriter {
      compileScript = ''
        export GO111MODULE=off
        export GOTOOLCHAIN=local
        export GOCACHE="$(pwd)/go-build"

        echo "package main" > main.go
        cat "$contentPath" >> main.go
        ${lib.getExe go} build ${lib.escapeShellArgs goBuildArgs} main.go
        mv main $out
      '';
      inherit makeWrapperArgs strip;
    } name;

  writeGoBin = name: writeGo "/bin/${name}";

  rtmp-auth =
    writeGoBin "rtmp-auth" { goBuildArgs = [ "-tags=nethttpomithttp2" ]; }
      # go
      ''
        import (
          "log"
          "path"
          "encoding/json"
          "net"
          "net/http"
          "net/url"
          "os"
          "os/exec"
          "regexp"
          "strings"
        )

        func main() {
          auth_dir, exists := os.LookupEnv("AUTH_DIR")
          if !exists {
            log.Fatal("AUTH_DIR not set")
            os.Exit(1)
          }
          listen_addr, exists := os.LookupEnv("LISTEN_ADDR")
          if !exists {
            log.Fatal("LISTEN_ADDR not set")
            os.Exit(1)
          }

          http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            var matched bool
            var err error
            var cmd *exec.Cmd
            var auth_path string
            var stderr strings.Builder
            r.ParseForm()
            name := r.Form.Get("name")
            username := r.Form.Get("username")
            password := r.Form.Get("password")

            if name == "" || username == "" || password == "" { goto DENY }

            if matched, _ = regexp.Match(`^\w*$`, []byte(name)); !matched { goto DENY }

            auth_path = path.Join(auth_dir, name)

            cmd = exec.Command("htpasswd", "-bv", auth_path, username, password)
            cmd.Stderr = &stderr
            if err = cmd.Run(); err != nil {
              log.Printf("htpasswd failed: %v\n%q", err, stderr.String())
              goto DENY
            }

            log.Printf("Successful Login for '%s' by '%s'", name, username)
            return
            DENY:
            log.Printf("Failed Login for '%s' by '%s'", name, username)
            w.WriteHeader(http.StatusForbidden)
          })

          http.HandleFunc("/mediamtx", func(w http.ResponseWriter, r *http.Request) {
            var err error
            var ip net.IP
            var matched bool
            var username, password, stream_name, auth_path string
            var query url.Values
            var cmd *exec.Cmd
            var stderr strings.Builder

            // {
            //   "user": "user",
            //   "password": "password",
            //   "ip": "ip",
            //   "action": "publish|read|playback|api|metrics|pprof",
            //   "path": "path",
            //   "protocol": "rtsp|rtmp|hls|webrtc|srt",
            //   "id": "id",
            //   "query": "query"
            // }
            type MediaMTXReq struct {
              User string `json:"user"`
              Password string `json:"password"`
              Ip string `json:"ip"`
              Action string `json:"action"`
              Path string `json:"path"`
              protocol string `json:"protocol"`
              Id string `json:"id"`
              Query string `json:"query"`
            }
            var req MediaMTXReq


            jsonDecoder := json.NewDecoder(r.Body)
            err = jsonDecoder.Decode(&req)
            if err != nil {
              log.Printf("json error: %v", err)
              goto ERR
            }

            if req.Action == "read" { goto SUCCESS }

            if ip = net.ParseIP(req.Ip); ip != nil && ip.IsLoopback() { goto SUCCESS }

            if matched, _ = regexp.Match(`^live/`, []byte(req.Path)); !matched { goto DENY }

            stream_name = req.Path[len("live/"):]

            if matched, _ = regexp.Match(`^\w*$`, []byte(stream_name)); !matched { goto DENY }

            if query, err = url.ParseQuery(req.Query); err != nil {
              log.Printf("query params invalid: %v", err)
              goto DENY
            }

            if !(query.Has("username") && query.Has("password")) {
              log.Print("Not all params exist")
            }

            auth_path, username, password = path.Join(auth_dir, stream_name), query.Get("username"), query.Get("password")

            cmd = exec.Command("htpasswd", "-bv", auth_path, username, password)
            cmd.Stderr = &stderr
            if err = cmd.Run(); err != nil {
              log.Printf("htpasswd failed: %v\n%q", err, stderr.String())
              goto DENY
            }

            log.Printf("Successful Login for '%s' by '%s' from '%s'", req.Path, username, req.Ip)
            SUCCESS:
            return
            DENY:
            log.Printf("Failed Login for '%s' by '%s' from '%s'", req.Path, username, req.Ip)
            w.WriteHeader(http.StatusForbidden)
            return
            ERR:
            w.WriteHeader(http.StatusInternalServerError)
          })

          log.Fatal(http.ListenAndServe(listen_addr, nil))
        }
      '';
in
{
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
      type = types.nullOr (
        types.submodule {
          options.storagePath = mkOption {
            type = types.str;
            default = "/hls";
            description = lib.mdDoc "path where the HLS stream will be available";
          };
        }
      );
      default = null;
      description = lib.mdDoc "set hls specific configs. `null` to disable.";
    };
    dash = mkOption {
      type = types.nullOr (
        types.submodule {
          options.storagePath = mkOption {
            type = types.str;
            default = "/dash";
            description = lib.mdDoc "path where the dash stream will be available";
          };
        }
      );
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
      type = types.nullOr (
        types.submodule {
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
        }
      );
      default = null;
      description = lib.mdDoc "set auth specific configs. `null` to disable.";
    };

    openFirewall = mkEnableOption "open firewall to all services";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      services.nginx = {
        enable = true;
        additionalModules = [ pkgs.nginxModules.rtmp ];
        virtualHosts =
          mkIf
            (builtins.any (x: x != null) [
              cfg.hls
              cfg.dash
            ])
            {
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
                ${
                  optionalString (cfg.auth != null) ''

                    on_publish http://127.0.0.1:${toString cfg.auth.port}/;
                    notify_method get;
                  ''
                }${
                  optionalString (cfg.hls != null) ''

                    hls on;
                    hls_path ${cfg.directory}${cfg.hls.storagePath};
                    hls_playlist_length ${cfg.playlistLength};
                    hls_fragment ${cfg.fragmentLength};
                  ''
                }${
                  optionalString (cfg.dash != null) ''

                    dash on;
                    dash_path ${cfg.directory}${cfg.dash.storagePath};
                    dash_playlist_length ${cfg.playlistLength};
                    dash_fragment ${cfg.fragmentLength};
                  ''
                }
              }
            }
          }
        '';
      };
      systemd.services.nginx.serviceConfig.ReadWritePaths = [ cfg.directory ];
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        80
        443
        1935
        1936
      ];

      systemd.tmpfiles.rules = [
        "d ${cfg.directory} 0744 ${config.services.nginx.user} ${config.services.nginx.group} -"
      ];
    })
    (mkIf (cfg.auth != null) {
      users.users.rtmp-auth = {
        isSystemUser = true;
        group = "rtmp-auth";
      };
      users.groups.rtmp-auth = { };
      systemd.services.rtmp-auth = {
        description = "rtmp-auth service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        path = [ pkgs.apacheHttpd ];

        environment = {
          AUTH_DIR = cfg.auth.authDir;
          LISTEN_ADDR = ":${toString cfg.auth.port}";
        };

        serviceConfig = {
          ExecStart = lib.getExe rtmp-auth;
          User = "rtmp-auth";
          Group = "rtmp-auth";
          ReadWritePaths = [ cfg.auth.authDir ];

          # Hardening
          CapabilityBoundingSet = [ "" ];
          DeviceAllow = [ "" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateUsers = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };
      environment.systemPackages = [ pkgs.apacheHttpd ];
      systemd.tmpfiles.rules = [ "d ${cfg.auth.authDir} 0744 rtmp-auth rtmp-auth -" ];
    })
  ];
}
