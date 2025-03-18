{
  config,
  lib,
  selfpkgs,
  ...
}:
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
    hls = mkOption {
      type = types.nullOr (
        types.submodule {
          options.port = mkOption {
            type = types.port;
            default = 8888;
            description = lib.mdDoc "port of the auth service";
          };
        }
      );
      default = null;
      description = lib.mdDoc "set hls specific configs. `null` to disable.";
    };

    api = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            port = mkOption {
              type = types.port;
              default = 9997;
              description = lib.mdDoc "port of the api service";
            };
            chaosctrl = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    extraEnvFile = mkOption {
                      example = "/run/secrets/chaosctrl";
                      type = types.str;
                      description = lib.mdDoc "A file with Envvars loaded before start";
                    };
                  };
                }
              );
              default = null;
              description = lib.mdDoc "chaosctrl specific settings. `null` to disable.";
            };
          };
        }
      );
      default = { };
      description = lib.mdDoc "set api specific configs. `null` to disable.";
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
          writeQueueSize = 2048;

          api = cfg.api != null;

          rtsp = true;
          protocols = [ "tcp" ]; # "udp"];
          rtspAddress = ":554";

          rtmp = true;
          rtmpAddress = ":1935";

          hls = cfg.hls != null;

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
        (mkIf (cfg.api != null) {
          apiAddress = ":${toString cfg.api.port}";
        })
        (mkIf (cfg.hls != null) {
          hlsVariant = "mpegts";
          hlsAlwaysRemux = true;
          hlsAddress = ":${toString cfg.hls.port}";
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
              proxyPass = "http://127.0.0.1:${toString cfg.hls.port}";
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
    systemd.services.chaosctrl = mkIf (cfg.api != null && cfg.api.chaosctrl != null) {
      wantedBy = [
        "multi-user.target"
        "mediamtx.service"
      ];
      path = [ selfpkgs.chaosctrl ];
      environment = {
        STREAM_API_BASE_URL = "http://127.0.0.1:${toString cfg.api.port}";
      };

      script = ''
        set -a
        . $CREDENTIALS_DIRECTORY/EXTRA_ENV_FILE
        set +a

        exec chaosctrl
      '';

      serviceConfig = {
        LoadCredential = [
          "EXTRA_ENV_FILE:${cfg.api.chaosctrl.extraEnvFile}"
        ];
        # Hardening
        DynamicUser = true;
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "full";
        RemoveIPC = true;
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
      };

    };
  };
}
