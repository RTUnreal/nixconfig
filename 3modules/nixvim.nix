{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf filterAttrs;
  cfg = config.rtinf.neovim;
in {
  options.rtinf.neovim = {
    enable = mkEnableOption "the neovim config";
    enableIDEFeatures = mkEnableOption "the IDE features";
    enableSillyFeatures = mkEnableOption "the silly features";
    enableDesktop = mkEnableOption "the desktop features";
  };
  config = mkIf cfg.enable {
    programs.nixvim =
      {
        enable = true;
      }
      // (import ../5pkgs/nixvim-config.nix (filterAttrs (x: !builtins.elem x ["enable"]) cfg));
  };
}
