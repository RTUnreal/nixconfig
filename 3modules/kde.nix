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
      desktopManager.plasma6 = {
        enable = true;
        enableQt5Integration = true;
      };
    };

    environment.systemPackages = lib.attrValues {
      inherit (pkgs.kdePackages) kcalc filelight;
      inherit (pkgs) qpwgraph imhex;
    };
  };
}
