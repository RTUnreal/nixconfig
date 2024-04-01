{
  nixpkgs,
  self,
  system,
}: {
  nix.registry.n.flake = nixpkgs;
  _module.args = {
    selfpkgs = self.packages.${system};
    selfnixosModules = self.nixosModules;
  };
  imports = [
    ./base.nix
    ./virtualisation.nix

    self.nixosModules.nixvim
    ./nixvim.nix
  ];
}
