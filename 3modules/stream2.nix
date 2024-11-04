{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf mkMerge;
  cfg = config.rtinf.stream2;
in {
  options.rtinf.stream2 = {
    enable = mkEnableOption "enable stream";
    domain = mkOption {
      type = types.str;
      default = config.networking.fqdn;
      description = lib.mdDoc "domain of the server";
    };
  };

  config = mkIf cfg.enable {
    /*
    assertions = [
      {
        assertion = !config.rtinf.stream.enable;
        message = "stream conflicts with stream2";
      }
    ];
    */

    services.mediamtx = {
      enable = true;
      # https://github.com/bluenviron/mediamtx/blob/main/mediamtx.yml
      settings = mkMerge [
        {
          api = true;

          rtsp = true;
          protocols = ["tcp"];
          encryption = "no";
          rtspAddress = ":8554";

          rtmp = true;
          rtmpAddress = ":8585"; # change back, when ready

          # reroute to rtsp
          paths = {
            "live/radio" = {
              runOnReady = "${lib.getExe pkgs.ffmpeg-headless} -i rtmp://localhost:8585/$MTX_PATH -c copy -f rtsp rtsp://localhost:$RTSP_PORT/stream/$MTX_PATH";
            };
            "stream/live/radio" = {};
          };
        }
        (mkIf (config.rtinf.stream.auth != null) {
          authMethod = "http";
          authHTTPAddress = "http://localhost:${toString config.rtinf.stream.auth.port}/mediamtx";
        })
      ];
    };
    networking.firewall.allowedTCPPorts = [8554 8585 8888];

    /*
    systemd.services.mediamtx = {
      wants = ["acme-finished-${cfg.domain}.target"];
      after = ["acme-finished-${cfg.domain}.target"];
    };
    systemd.services.mediamtx-config-reload = {
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
    */
  };
}
