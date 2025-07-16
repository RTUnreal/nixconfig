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
                monado =
                  (pkgs.monado.overrideAttrs (prevAttrs: {
                    pname = "monado-solarxr"; # optional but helps distinguishing between packages

                    src = pkgs.fetchFromGitLab {
                      domain = "gitlab.freedesktop.org";
                      owner = "rcelyte";
                      repo = "monado";
                      rev = "af2f39fbe0f8e3f9b2d207ac430f1bb54ce95391";
                      hash = "sha256-OupR3eKeDBQ3qApIDl4L2fVNE8hoXWdaqbAmwadPndI=";
                    };
                    patches = builtins.filter (
                      patch: patch.name != "2a6932d46dad9aa957205e8a47ec2baa33041076.patch"
                    ) prevAttrs.patches or [ ];
                  })).override
                    { inherit (self'.packages) libsurvive; };
                libsurvive = pkgs.callPackage ./5pkgs/libsurvive.nix { };
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
          inventory.machines = {
            "devel" = {
              tags = [ "server" ];
              deploy.targetHost = "trr@devel.rtinf.net";
            };
            "spinner" = {
              tags = [ "server" ];
              deploy.targetHost = "trr@192.168.0.101";
            };
            "safe" = {
              tags = [ "server" ];
              deploy.targetHost = "trr@safe.user-sites.de";
            };
            "konstream" = {
              tags = [ "server" ];
              deploy.targetHost = "trr@konstream.rtinf.net";
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
                          inputs.nixpkgs-xr.overlays.default
                        ];
                      };
                      inherit inputs;
                    };
                    imports = [
                      inputs.nix-gaming.nixosModules.platformOptimizations
                      inputs.home-manager.nixosModules.home-manager
                      ./3modules/modules.nix
                    ];
                  }
                );
              local =
                { }:
                {
                  clan.core.deployment.requireExplicitUpdate = true;
                  imports = [
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
                { }:
                {
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
                    (remote { })
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
                    (remote { })
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
                    (remote { })
                  ];
                };
              konstream =
                let
                  system = "x86_64-linux";
                in
                {
                  imports = [
                    (common system { allowedUnfree = [ "factorio-headless" ]; })
                    inputs.srvos.nixosModules.server
                    inputs.srvos.nixosModules.hardware-hetzner-cloud
                    inputs.disko.nixosModules.default
                    ./1systems/konstream.rtinf.net/config.nix
                    (remote { })
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
