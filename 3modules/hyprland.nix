{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.hyprland;
in
{
  options.rtinf.hyprland.enable = mkEnableOption "enable hyprland";
  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      waybar.enable = true;
    };

    environment.systemPackages = [
      # ... other packages
      pkgs.kitty # required for the default Hyprland config
    ];
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
