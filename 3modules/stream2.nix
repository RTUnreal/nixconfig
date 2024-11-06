{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf mkMerge optional optionalString;
  cfg = config.rtinf.stream2;

  enableTLS = cfg.domain != null;
in {
  options.rtinf.stream2 = {
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

    openFirewall = mkEnableOption "open firewall to all services";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.rtinf.stream.enable;
        message = "stream conflicts with stream2";
      }
    ];

    services.mediamtx = {
      enable = true;
      # https://github.com/bluenviron/mediamtx/blob/main/mediamtx.yml
      settings = mkMerge [
        {
          logDestinations = ["syslog"];

          api = true;

          rtsp = true;
          protocols = ["tcp"]; # "udp"];
          rtspAddress = ":554";

          rtmp = true;

          # reroute to rtsp
          paths = {
            "~^live/(\\w+)$" = {
              runOnReady = "${lib.getExe pkgs.ffmpeg-headless} -i rtmp://localhost:1935/live/$G1 -c copy -f rtsp rtsp://localhost:$RTSP_PORT/stream/$G1" + (optionalString (cfg.hls != null) " -f hls -hls_flags delete_segments /var/lib/mediamtx${cfg.hls.storagePath}/$G1.m3u8");
              runOnReadyRestart = true;
            };
            "~^stream/(\\w+)$" = {};
          };
        }
        (mkIf (config.rtinf.stream.auth != null) {
          authMethod = "http";
          authHTTPAddress = "http://localhost:${toString config.rtinf.stream.auth.port}/mediamtx";
        })
        (mkIf enableTLS {
          encryption = "optional";
          rtspsAddress = ":322";
          serverKey = "key.pem";
          serverCert = "fullchain.pem";
          rtmpEncryption = "optional";
          rtmpServerKey = "key.pem";
          rtmpServerCert = "fullchain.pem";
        })
      ];
    };

    services.nginx = mkIf enableTLS {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;

        locations = mkMerge [
          (mkIf (cfg.hls != null) {
            ${cfg.hls.storagePath} = {
              root = "/var/lib/mediamtx";
              extraConfig = ''
                types {
                  application/vnd.apple.mpegurl m3u8;
                  video/mp2t ts;
                }
                add_header Cache-Control no-cache;
              '';
            };
          })
        ];
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      /*
      allowedUDPPorts = [
        # RTSP/RTP
        8000
        # RTSP/RTCP
        8001
      ];
      */
      allowedTCPPorts = [
        80
        443
        # RTSP
        554
        # RTSPS
        322
        # RTMPS
        1936
      ];
    };
    systemd.tmpfiles.rules =
      [
        "d /var/lib/mediamtx - mediamtx mediamtx -"
      ]
      ++ (optional (cfg.hls != null) "d /var/lib/mediamtx${cfg.hls.storagePath} 0666 mediamtx mediamtx 2min"); # Fallback cleanup on crash
    systemd.services.nginx.serviceConfig.ReadOnlyPaths = ["/var/lib/mediamtx"];
    systemd.services.mediamtx = mkIf enableTLS {
      wants = ["acme-finished-${cfg.domain}.target"];
      after = ["acme-finished-${cfg.domain}.target"];
      environment = {
        MTX_SERVERKEY = "%d/key.pem";
        MTX_SERVERCERT = "%d/fullchain.pem";
        MTX_RTMPSERVERKEY = "%d/key.pem";
        MTX_RTMPSERVERCERT = "%d/fullchain.pem";
      };
      serviceConfig = {
        ReadWritePaths = ["/var/lib/mediamtx"];
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
        LoadCredential = [
          "fullchain.pem:/var/lib/acme/${cfg.domain}/fullchain.pem"
          "key.pem:/var/lib/acme/${cfg.domain}/key.pem"
        ];
      };
    };
    systemd.services.mediamtx-config-reload = mkIf enableTLS {
      wantedBy = ["acme-finished-${cfg.domain}.target" "multi-user.target"];
      # Before the finished targets, after the renew services.
      before = ["acme-finished-${cfg.domain}.target"];
      after = ["acme-${cfg.domain}.service"];
      # Block reloading if not all certs exist yet.
      unitConfig.ConditionPathExists = ["${config.security.acme.certs.${cfg.domain}.directory}/fullchain.pem"];
      serviceConfig = {
        Type = "oneshot";
        TimeoutSec = 60;
        ExecCondition = "/run/current-system/systemd/bin/systemctl -q is-active mediamtx.service";
        ExecStart = "/run/current-system/systemd/bin/systemctl --no-block restart mediamtx.service";
      };
    };
  };
}
