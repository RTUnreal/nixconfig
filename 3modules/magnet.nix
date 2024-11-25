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
    mkPackageOption
    mkIf
    optionalAttrs
    types
    ;
  cfg = config.rtinf.magnet;
in
{
  options.rtinf.magnet = {
    enable = mkEnableOption "enable magnet";
    package = mkPackageOption pkgs "qbittorrent-nox" { };
    user = mkOption {
      type = types.str;
      default = "magnet";
      description = lib.mdDoc "User account under which magnet runs.";
    };
    group = mkOption {
      type = types.str;
      default = "magnet";
      description = lib.mdDoc "Group account under which magnet runs.";
    };
    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/magnet";
      description = "magnet data directory.";
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "port number";
    };
    openFirewall = mkEnableOption "open the magnet port on the firewall";
  };
  config = mkIf (cfg.enable) {
    users = {
      users = optionalAttrs (cfg.user == "magnet") {
        magnet = {
          group = cfg.group;
          isSystemUser = true;
          home = cfg.stateDir;
        };
      };
      groups = optionalAttrs (cfg.group == "magnet") { magnet = { }; };
    };

    systemd = {
      tmpfiles.rules = [ "d '${cfg.stateDir}' 750 ${cfg.user} ${cfg.group}" ];
      services.magnet = {
        description = "Magnet web service";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network.target"
          "local-fs.target"
          "network-online.target"
          "nss-lookup.target"
        ];
        path = [ cfg.package ];
        serviceConfig = {
          Type = "exec";
          DynamicUser = false;
          User = cfg.user;
          Group = cfg.group;
          PrivateTmp = false;
          TimeoutStopSec = 1800;
          ExecStart = "${cfg.package}/bin/qbittorrent-nox --webui-port=${toString cfg.port}";
          UMask = "0002";
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    environment.systemPackages = [ cfg.package ];
  };
}
