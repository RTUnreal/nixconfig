_:
{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
  };
  settings.formatter.alejandra.excludes = [ "2configs/vscode/extensions.nix" ];
}
