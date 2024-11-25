{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    ;
  cfg = config.rtinf.stream2;

  enableTLS = cfg.domain != null;
in
{
  options.rtinf.stream2 = {
    enable = mkEnableOption "enable stream";
    domain = mkOption {
      type = types.nullOr types.str;
      default = config.networking.fqdn;
      description = lib.mdDoc "domain of the server";
    };
    directory = mkOption {
      type = types.str;
      default = "/var/lib/rtmp";
      description = lib.mdDoc "domain of the server";
    };
    hls = mkOption {
      type = types.nullOr (types.submodule { });
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
          logDestinations = [ "syslog" ];

          api = true;

          rtsp = true;
          protocols = [ "tcp" ]; # "udp"];
          rtspAddress = ":554";

          rtmp = true;
          rtmpAddress = ":1935";

          hls = cfg.hls != null;
          hlsVariant = "mpegts";
          hlsAlwaysRemux = true;

          webrtc = false;
          srt = false;

          # reroute to rtsp
          paths = {
            "~^live/(\\w+)$" = { };
          };
        }
        (mkIf (config.rtinf.stream.auth != null) {
          authMethod = "http";
          authHTTPAddress = "http://localhost:${toString config.rtinf.stream.auth.port}/mediamtx";
        })
        (mkIf enableTLS {
          encryption = "optional";
          rtspsAddress = ":322";
          rtmpEncryption = "optional";
          rtmpsAddress = ":1936";
          hlsTrustedProxies = [ "127.0.0.1" ];
        })
      ];
    };

    services.nginx = mkIf enableTLS {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;

        locations = mkMerge [
          (mkIf (cfg.hls != null) {
            "/live" = {
              proxyPass = "http://127.0.0.1:8888";
            };
          })
        ];
      };
    };

    networking.firewall = mkIf cfg.openFirewall (mkMerge [
      {
        /*
          allowedUDPPorts = [
            # RTSP/RTP
            8000
            # RTSP/RTCP
            8001
          ];
        */
        allowedTCPPorts = [
          # RTSP
          554
          # RTMP
          1935
        ];
      }
      (mkIf enableTLS {
        allowedTCPPorts = [
          80
          443
          # RTSPS
          322
          # RTMPS
          1936
        ];
      })
    ]);
    systemd.services.mediamtx = mkMerge [
      {
        serviceConfig = {
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        };
      }
      (mkIf enableTLS {
        wants = [ "acme-finished-${cfg.domain}.target" ];
        after = [ "acme-finished-${cfg.domain}.target" ];
        environment = {
          MTX_SERVERKEY = "%d/key.pem";
          MTX_SERVERCERT = "%d/fullchain.pem";
          MTX_RTMPSERVERKEY = "%d/key.pem";
          MTX_RTMPSERVERCERT = "%d/fullchain.pem";
        };
        serviceConfig = {
          LoadCredential = [
            "fullchain.pem:/var/lib/acme/${cfg.domain}/fullchain.pem"
            "key.pem:/var/lib/acme/${cfg.domain}/key.pem"
          ];
        };
      })
    ];
    systemd.services.mediamtx-config-reload = mkIf enableTLS {
      wantedBy = [
        "acme-finished-${cfg.domain}.target"
        "multi-user.target"
      ];
      # Before the finished targets, after the renew services.
      before = [ "acme-finished-${cfg.domain}.target" ];
      after = [ "acme-${cfg.domain}.service" ];
      # Block reloading if not all certs exist yet.
      unitConfig.ConditionPathExists = [
        "${config.security.acme.certs.${cfg.domain}.directory}/fullchain.pem"
      ];
      serviceConfig = {
        Type = "oneshot";
        TimeoutSec = 60;
        ExecCondition = "/run/current-system/systemd/bin/systemctl -q is-active mediamtx.service";
        ExecStart = "/run/current-system/systemd/bin/systemctl --no-block restart mediamtx.service";
      };
    };
  };
}
