{
  config,
  selfpkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.rtinf.neovim;
in
{
  options.rtinf.neovim = {
    enable = mkEnableOption "the neovim config";
    type = mkOption {
      type = types.enum [
        "barebones"
        "desktop"
        "ide"
        "full"
      ];
      default = "barebones";
    };
  };
  config = mkIf cfg.enable (
    let
      pkg =
        if cfg.type == "full" then
          selfpkgs.nixvimTheFullPackage
        else if cfg.type == "ide" then
          selfpkgs.nixvimIDE
        else if cfg.type == "desktop" then
          selfpkgs.nixvimDesktop
        else
          selfpkgs.nixvim;
    in
    {
      environment.systemPackages = [ pkg ];
      environment.variables.EDITOR = "nvim";
    }
  );
}
