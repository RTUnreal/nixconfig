_:
{
  projectRootFile = "flake.nix";
  programs = {
    nixpkgs-fmt.enable = true;
    deadnix.enable = true;
  };
  settings.formatter.nixpkgs-fmt.excludes = [ "2configs/vscode/extensions.nix" ];
}
