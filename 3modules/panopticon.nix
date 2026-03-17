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
  wgConf = config.rtinf.dirtickvpn.interfaces.${netiface};

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
      rtinf.dirtickvpn.interfaces.${netiface} = {
        meta = cfg.meta.network;
      };
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
    }
    (mkIf (wgConf.hostName == wgConf.meta.meta.ingress) {
      networking.firewall.interfaces.${wgConf.connectOutside.vethOutside}.allowedTCPPorts = [
        config.services.prometheus.exporters.node.port
      ];
    })
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
