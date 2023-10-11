{ config, lib, ... }:
{
  users.users = lib.mkIf (!config.boot.isContainer) {
    trr.password = "";
  };
  services.getty.autologinUser = lib.mkIf (!config.boot.isContainer) "trr";
  security.acme.defaults.server = "https://127.0.0.1";
  security.sudo.wheelNeedsPassword = false;
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    diskSize = 2048;
  };

  services.mailhog.enable = true;
  networking.firewall.allowedTCPPorts = [ config.services.mailhog.uiPort ];
}
