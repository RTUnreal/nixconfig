{
  config,
  pkgs,
  lib,
  #hyprland,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.hyprland;
in {
  options.rtinf.hyprland.enable = mkEnableOption "enable hyprland";
  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      #package = hyprland.packages.${pkgs.system}.hyprland;
    };
  };
}
