{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    retiolum.url = "github:Mic92/retiolum";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    hyprland.url = "github:hyprwm/Hyprland";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    srvos.url = "github:nix-community/srvos";
    colmena.url = "github:zhaofengli/colmena";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
    disko.url = "github:nix-community/disko";
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      treefmt-nix,
      systems,
      nixvim,
      nix-gaming,
      nixpkgs-xr,
      disko,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { inputs, ... }:
      {
        systems = [ "x86_64-linux" ];

        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.clan-core.flakeModules.default
        ];

        perSystem =
          {
            pkgs,
            inputs',
            config,
            ...
          }:
          {
            treefmt = import ./treefmt.nix;

            packages =
              let
                mkNixVim =
                  opt:
                  inputs'.nixvim.legacyPackages.makeNixvim (
                    import ./5pkgs/nixvim-config.nix {
                      inherit (nixpkgs-unstable) lib;
                      pkgs = inputs'.nixpkgs-unstable.legacyPackages;
                    } opt
                  );
              in
              {
                nixvim = mkNixVim { };
                nixvimDesktop = mkNixVim { enableDesktop = true; };
                nixvimIDE = mkNixVim { enableIDEFeatures = true; };
                nixvimTheFullPackage = mkNixVim {
                  enableIDEFeatures = true;
                  enableSillyFeatures = true;
                };

                slimevr = pkgs.callPackage ./5pkgs/slimevr/default.nix { };

                jmusicbot = pkgs.callPackage ./5pkgs/jmusicbot.nix { };

                chaosctrl = pkgs.callPackage ./5pkgs/chaosctrl { };
              };
            devShells.default = pkgs.mkShell { packages = [ inputs'.clan-core.packages.clan-cli ]; };
          };
        clan = {
          meta.name = "net.rtinf";
          specialArgs = {
            self = {
              inherit (self) inputs nixosModules packages;
            };
            selflib = self.lib;
          };
          inventory = {
            tags = {
              "servers" = [
                "spinner"
                "safe"
                "devel"
              ];
              "remote" = [
                "safe"
                "devel"
              ];
            };
          };
          inherit self;
          machines =
            let
              common =
                system:
                {
                  allowedUnfree ? [ ],
                }:
                (
                  { lib, ... }:
                  {
                    nix.registry.n.flake = nixpkgs;
                    nixpkgs = {
                      hostPlatform = system;
                      config.allowUnfreePredicate = lib.mkIf (allowedUnfree != [ ]) (
                        pkg: builtins.elem (lib.getName pkg) allowedUnfree
                      );
                    };
                    _module.args = {
                      selfpkgs = self.packages.${system};
                      nixpkgs-unstable = import nixpkgs-unstable {
                        inherit system;
                        config.allowUnfreePredicate =
                          pkg: builtins.elem (nixpkgs-unstable.legacyPackages."${system}".lib.getName pkg) allowedUnfree;
                        overlays = [
                          nixpkgs-xr.overlays.default
                        ];
                      };
                    };
                    imports = [
                      nix-gaming.nixosModules.platformOptimizations
                      ./3modules/modules.nix
                    ];
                  }
                );
              local =
                { }:
                {
                  clan.deployment.requireExplicitUpdate = true;
                };
              remote =
                { targetHost }:
                {
                  clan.core.networking = {
                    inherit targetHost;
                  };
                };
            in
            {
              runner =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system {
                      allowedUnfree = [
                        "steam"
                        "steam-unwrapped"
                        "steam-original"
                        "steam-run"

                        "discord"
                        "anydesk"

                        "vscode-extension-ms-vscode-cpptools"
                      ];
                    })
                    ./1systems/runner/config.nix
                    inputs.retiolum.nixosModules.retiolum
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
                    (local { })
                  ];
                };
              worker =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system {
                      allowedUnfree = [
                        "steam"
                        "steam-unwrapped"
                        "steam-original"
                        "steam-run"

                        "discord"
                        "anydesk"

                        "vscode-extension-ms-vscode-cpptools"
                      ];
                    })
                    inputs.retiolum.nixosModules.retiolum
                    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
                    ./1systems/worker/config.nix
                    (local { })
                  ];
                };
              spinner =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system {
                      allowedUnfree = [
                        "nvidia-x11"
                        "nvidia-settings"
                      ];
                    })
                    inputs.retiolum.nixosModules.retiolum
                    ./1systems/spinner/config.nix
                    (remote { targetHost = "trr@192.168.0.101"; })
                  ];
                };
              safe =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system { })
                    inputs.srvos.nixosModules.server
                    inputs.srvos.nixosModules.hardware-hetzner-cloud
                    ./1systems/safe.user-sites.de/config.nix
                    (remote { targetHost = "trr@safe.user-sites.de"; })
                  ];
                };
              devel =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system { allowedUnfree = [ "factorio-headless" ]; })
                    inputs.srvos.nixosModules.server
                    ./1systems/devel.rtinf.net/config.nix
                    (remote { targetHost = "trr@devel.rtinf.net"; })
                  ];
                };
            };
        };
        flake = {
          nixosModules = {
            nvidia-prime = import ./2configs/nvidia-prime.nix;

            devel-forge = import ./2configs/devel/forge.nix;
            devel-ci = import ./2configs/devel/ci.nix;
          };

          # nixosConfigurations = (colmena.lib.makeHive self.colmena).nodes;

          lib = import ./4lib;
        };
      }
    );
}
