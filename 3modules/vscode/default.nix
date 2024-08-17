{
  config,
  lib,
  nixpkgs-unstable,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.vscode;

  extFromPkgs = with nixpkgs-unstable.vscode-extensions; [
    ms-vscode.cpptools
    ms-toolsai.jupyter
    ms-toolsai.jupyter-renderers
    elmtooling.elm-ls-vscode
    rust-lang.rust-analyzer
    ms-ceintl.vscode-language-pack-de
  ];
  extFilter = map (e: e.vscodeExtUniqueId) extFromPkgs;
  extFromFile =
    map
    (extension:
      nixpkgs-unstable.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          inherit (extension) name publisher version sha256;
        };
      })
    (lib.filter (e: !lib.elem "${e.publisher}.${e.name}" extFilter) (import ./extensions.nix).extensions);
in {
  options.rtinf.vscode = {
    enable = mkEnableOption "vscode";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      (nixpkgs-unstable.vscode-with-extensions.override {
        vscode = nixpkgs-unstable.vscodium;
        vscodeExtensions =
          extFromFile
          ++ extFromPkgs;
      })
    ];
  };
}
