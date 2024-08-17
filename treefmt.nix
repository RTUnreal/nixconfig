_: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
  };
  settings.formatter.alejandra.excludes = ["3modules/vscode/extensions.nix"];
}
