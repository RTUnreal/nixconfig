{
  options,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    mkMerge
    mkEnableOption
    ;
  cfg = config.rtinf.panopticon;

  netiface = cfg.networkInterfaceName;
in
{
  options.rtinf.panopticon = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          meta = mkOption {
            type = types.submodule {
              options = {
                network = mkOption {
                  type = types.anything;
                };
                scrapeConfigs = options.services.prometheus.scrapeConfigs;
              };
            };
            default = null;
            description = lib.mdDoc "Set the vpn meta to follow. `null` to disable.";
          };
          networkInterfaceName = mkOption {
            type = types.str;
            default = "panopticon";
          };
          scrapper = {
            enable = mkEnableOption "panopticon scrapper";
          };
        };
      }
    );
    default = null;
  };

  config = lib.mkIf (cfg != null) (mkMerge [
    {
      rtinf.dirtickvpn.interfaces."${netiface}" = {
        meta = cfg.meta.network;
      };
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
      systemd.services.prometheus-node-exporter = {
        after = [ "wireguard-${netiface}.service" ];
        serviceConfig.NetworkNamespacePath = mkIf (!cfg.scrapper.enable) "/run/netns/${netiface}";
      };
      networking.firewall.interfaces."${netiface}".allowedTCPPorts = [
        config.services.prometheus.exporters.node.port
      ];
    }
    (mkIf cfg.scrapper.enable {
      services.prometheus = {
        enable = true;
        globalConfig.scrape_interval = "1m";
        scrapeConfigs = [
          {
            job_name = "this_node";
            static_configs = [
              {
                targets = [
                  "localhost:${toString config.services.prometheus.exporters.node.port}"
                ];
              }
            ];
          }
        ]
        ++ cfg.meta.scrapeConfigs;
      };
    })
  ]);
}
