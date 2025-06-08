{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.flake-parts.follows = "flake-parts";
    };
    nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
    disko.url = "github:nix-community/disko";
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    search = {
      url = "github:NuschtOS/search";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-router.url = "github:chayleaf/nixos-router";
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
          inputs.home-manager.flakeModules.home-manager
          inputs.treefmt-nix.flakeModule
          inputs.clan-core.flakeModules.default
        ];

        perSystem =
          {
            pkgs,
            inputs',
            self',
            config,
            ...
          }:
          {
            treefmt = import ./treefmt.nix;

            apps = {
              search = {
                type = "app";
                program = "${pkgs.lib.getExe (
                  pkgs.writeShellApplication {
                    name = "rtinf-search";

                    runtimeInputs = [
                      pkgs.http-server
                    ];

                    text = # sh
                      ''
                        http-server "${self'.packages.rtinf-search}" -p0 -o/ &
                      '';
                  }
                )}";
              };
            };

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

                rtinf-search = inputs'.search.packages.mkMultiSearch {
                  title = "RTUnreal's Search";
                  scopes = [
                    {
                      optionsJSON =
                        (import "${inputs.nixpkgs}/nixos/release.nix" { }).options + "/share/doc/nixos/options.json";
                      name = "NixOS";
                      urlPrefix = "https://github.com/NixOS/nixpkgs/tree/${inputs.nixpkgs.rev}/";
                    }
                    {
                      optionsJSON = inputs'.nixos-router.packages.optionsJSON + "/share/doc/nixos/options.json";
                      urlPrefix = "https://github.com/chayleaf/nixos-router/blob/${inputs.nixos-router.rev}/";
                    }
                  ];
                };
              };
            devShells.default = pkgs.mkShell { packages = [ inputs'.clan-core.packages.clan-cli ]; };
          };
        clan = {
          meta.name = "net_rtinf";
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
                      inherit inputs;
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
                  clan.core.deployment.requireExplicitUpdate = true;
                  imports = [
                    inputs.home-manager.nixosModules.home-manager
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.backupFileExtension = "hm-bak";
                      # TODO: I don't like it being here
                      home-manager.users.trr = self.homeConfigurations.default;
                    }
                  ];
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
                    (common system { })
                    inputs.srvos.nixosModules.server
                    ./1systems/devel.rtinf.net/config.nix
                    (remote { targetHost = "trr@devel.rtinf.net"; })
                  ];
                };
              konstream =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system { })
                    inputs.srvos.nixosModules.server
                    inputs.srvos.nixosModules.hardware-hetzner-cloud
                    inputs.disko.nixosModules.default
                    ./1systems/konstream.rtinf.net/config.nix
                    (remote { targetHost = "trr@konstream.rtinf.net"; })
                    {
                      disko.devices = {
                        disk = {
                          main = {
                            device = "/dev/sda";
                            type = "disk";
                            content = {
                              type = "gpt";
                              partitions = {
                                ESP = {
                                  type = "EF02";
                                  size = "1M";
                                };
                                root = {
                                  size = "100%";
                                  content = {
                                    type = "filesystem";
                                    format = "ext4";
                                    mountpoint = "/";
                                  };
                                };
                              };
                            };
                          };
                        };
                      };
                    }
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

          homeModules = { };
          homeConfigurations = {
            default = ./6home/default.nix;
          };

          lib = import ./4lib;
        };
      }
    );
}
