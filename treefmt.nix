_: {
  projectRootFile = "flake.nix";
  programs = {
    nixfmt-rfc-style.enable = true;
    deadnix.enable = true;
  };
  settings.formatter.nixfmt-rfc-style.excludes = [ "3modules/vscode/extensions.nix" ];
}
