{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.kde;
in
{
  options.rtinf.kde.enable = mkEnableOption "set kde configuration";
  config = mkIf cfg.enable {
    # Enable the Plasma 5 Desktop Environment.
    services = {
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
      xserver = {
        desktopManager.plasma5 = {
          kdeglobals = {
            KDE = {
              SingleClick = false;
            };
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      kcalc
      okteta
      filelight
      qpwgraph
      xwaylandvideobridge
    ];
  };
}
