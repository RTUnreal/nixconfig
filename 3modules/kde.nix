{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.kde;
in {
  options.rtinf.kde.enable = mkEnableOption "set kde configuration";
  config = mkIf cfg.enable {
    # Enable the Plasma 5 Desktop Environment.
    services = {
      displayManager.sddm.enable = true;
      xserver = {
        desktopManager.plasma5 = {
          enable = true;
          kdeglobals = {
            KDE = {
              SingleClick = false;
            };
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      kate
      kcalc
      okular
      gwenview
      ark
      spectacle
      okteta
      filelight
      kalendar
      qpwgraph
      xwaylandvideobridge
    ];
  };
}
