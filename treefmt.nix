_: {
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    deadnix.enable = true;
  };
  settings.formatter.nixfmt.excludes = [ "3modules/vscode/extensions.nix" ];
}
