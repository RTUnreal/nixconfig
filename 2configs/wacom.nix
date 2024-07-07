{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
in {
  config = mkMerge [
    {
      services.xserver.wacom.enable = true;
    }
    (mkIf (!config.services.desktopManager.plasma6.enable) {
      environment.systemPackages = [pkgs.wacomtablet];
    })
  ];
}
