{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.vscode;

  extFromPkgs = with pkgs.vscode-extensions; [
    ms-toolsai.jupyter
    ms-toolsai.jupyter-renderers
    ms-ceintl.vscode-language-pack-de
  ];
  extFilter = map (e: e.vscodeExtUniqueId) extFromPkgs;
  extFromFile =
    map
      (
        extension:
        pkgs.vscode-utils.buildVscodeMarketplaceExtension {
          mktplcRef = {
            inherit (extension)
              name
              publisher
              version
              hash
              ;
          };
        }
      )
      (
        lib.filter (e: !lib.elem "${e.publisher}.${e.name}" extFilter) (import ./extensions.nix).extensions
      );
in
{
  options.rtinf.vscode = {
    enable = mkEnableOption "vscode";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = extFromFile ++ extFromPkgs;
      })
    ];
  };
}
