{ nixosUnstable ? import <nixosUnstable> { } }:
{ pkgs, lib, ... }:
let
  extFromPkgs = with nixosUnstable.vscode-extensions; [
    ms-vscode.cpptools
    ms-toolsai.jupyter
    ms-toolsai.jupyter-renderers
    elmtooling.elm-ls-vscode
    rust-lang.rust-analyzer
    ms-ceintl.vscode-language-pack-de
  ];
  extFilter = map (e: e.vscodeExtUniqueId) extFromPkgs;
  extFromFile = map
    (extension: nixosUnstable.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        inherit (extension) name publisher version sha256;
      };
    })
    (lib.filter (e: !lib.elem "${e.publisher}.${e.name}" extFilter) (import ./extensions.nix).extensions);
in
{
  environment.systemPackages = with pkgs; [
    (nixosUnstable.vscode-with-extensions.override {
      vscode = nixosUnstable.vscodium;
      vscodeExtensions = extFromFile
        ++ extFromPkgs;
    })
  ];
}
