{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    neovim-flake.url = "github:notashelf/neovim-flake";
    hyprland.url = "github:hyprwm/Hyprland";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    colmena.url = "github:zhaofengli/colmena";
    mms.url = "github:Triton171/nixos-modded-minecraft-servers/8f00cdc8477a306d7f2e1036fcad03506ae9ce12";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    neovim-flake,
    retiolum,
    treefmt-nix,
    systems,
    nixos-hardware,
    nixvim,
    colmena,
    mms,
    ...
  }: let
    # Small tool to iterate over each systems
    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (system:
        f (import nixpkgs {
          inherit system;
        }));

    treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
  in {
    colmena = let
      pinned-nixpkgs = {
        nix.registry.nixpkgs.flake = nixpkgs;
      };
      unfreePkgs = system: {allowedUnfree ? []}: {
        _module.args.nixpkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs-unstable.legacyPackages."${system}".lib.getName pkg) allowedUnfree;
        };
      };
      selfpkgs = system: {
        _module.args.selfpkgs = self.packages.${system};
      };
    in {
      meta = {
        nixpkgs = import nixpkgs {system = "x86_64-linux";};
      };

      runner = let
        system = "x86_64-linux";
      in {
        nixpkgs.system = system;
        deployment.allowLocalDeployment = true;
        imports = [
          (unfreePkgs system {
            allowedUnfree = [
              "steam"
              "steam-original"
              "steam-run"

              "zoom"
              "anydesk"

              "vscode-extension-ms-vscode-cpptools"
            ];
          })
          (selfpkgs system)
          pinned-nixpkgs
          retiolum.nixosModules.retiolum
          ./1systems/runner/config.nix
        ];
      };
      spinner = let
        system = "x86_64-linux";
      in {
        nixpkgs.system = system;
        imports = [
          (unfreePkgs system {
            allowedUnfree = [
              "steam"
              "steam-original"
              "steam-run"

              "zoom"
              "anydesk"

              "nvidia-x11"
              "nvidia-settings"

              "vscode-extension-ms-vscode-cpptools"
            ];
          })
          (selfpkgs system)
          pinned-nixpkgs
          retiolum.nixosModules.retiolum
          self.nixosModules.virtualization
          ./1systems/spinner/config.nix
        ];
      };
      worker = let
        system = "x86_64-linux";
      in {
        nixpkgs.system = system;
        deployment.allowLocalDeployment = true;
        imports = [
          (unfreePkgs system {
            allowedUnfree = [
              "zoom"
              "anydesk"

              "vscode-extension-ms-vscode-cpptools"
            ];
          })
          (selfpkgs system)
          pinned-nixpkgs
          retiolum.nixosModules.retiolum
          nixos-hardware.nixosModules.framework-13-7040-amd
          self.nixosModules.virtualization
          ./1systems/worker/config.nix
        ];
      };
      safe = let
        system = "x86_64-linux";
      in {
        deployment = {
          targetHost = "safe.user-sites.de";
          tags = ["remote" "servers"];
        };
        nixpkgs.system = system;
        imports = [
          ./1systems/safe.user-sites.de/config.nix
          ({pkgs, ...}: {
            environment.systemPackages = [pkgs.wireguard-tools];
            networking = {
              wireguard.interfaces = {
                wg0 = {
                  privateKey = "wBxjEgRPmPelxISVv54zjAgGhv3ZaOeK7uv1VKuhf14=";
                  ips = ["10.82.0.1/24"];
                  listenPort = 51820;
                };
              };
            };
          })
        ];
      };
      devel = let
        system = "x86_64-linux";
      in {
        nixpkgs.system = system;
        deployment = {
          targetHost = "devel.rtinf.net";
          tags = ["remote" "servers"];
        };
        imports = [
          (unfreePkgs system {})
          ./1systems/devel.rtinf.net/config.nix
        ];
      };
      atm9 = let
        system = "x86_64-linux";
      in {
        nixpkgs.system = system;
        deployment = {
          targetHost = "atm9.rtinf.net";
          tags = ["remote" "servers"];
        };
        imports = [
          (unfreePkgs system {})
          mms.module
          ./1systems/atm8.rtinf.net/config.nix
        ];
      };
      /*
      konfactory = let
        system = "x86_64-linux";
      in {

        deployment = {
          targetHost = "konfactory.rtinf.net";
          tags = ["remote" "servers"];
        };

        imports = [
          #{_modules.args.nixUnstPath = "${nixpkgs-unstable}";}
          #(unfreePkgs system {
          #  allowedUnfree = [
          #    "factorio-headless"
          #  ];
          #})
          #./1systems/konfactory.rtinf.net/config.nix
        ];
      };
      comms = let
        system = "x86_64-linux";
      in {
        imports = [
          (unfreePkgs system {})
          ./1systems/comms.rtinf.net/config.nix
        ];
      };
      */
    };
    nixosModules = {
      base = import ./2configs/base.nix;
      base-pc = import ./2configs/base-pc.nix;
      base-server = import ./2configs/base-server.nix;
      bluetooth = import ./2configs/bluetooth.nix;
      docker = import ./2configs/docker.nix;
      mpv = import ./2configs/mpv.nix;
      nvidia-prime = import ./2configs/nvidia-prime.nix;
      steam = import ./2configs/steam.nix;
      virtualization = import ./3modules/virtualisation.nix;
      wacom = import ./2configs/wacom.nix;

      devel-forge = import ./2configs/devel/forge.nix;
      devel-ci = import ./2configs/devel/ci.nix;
      inherit (nixvim.nixosModules) nixvim;
    };

    nixosConfigurations = (colmena.lib.makeHive self.colmena).nodes;

    packages = eachSystem (
      pkgs: let
        mkNixVim = opt:
          nixvim.legacyPackages.${pkgs.system}.makeNixvim (import ./5pkgs/nixvim-config.nix {
              inherit (nixpkgs) lib;
              inherit pkgs;
            }
            opt);
      in {
        inherit
          (neovim-flake.lib.neovimConfiguration {
            modules = [./5pkgs/neovim-flake-config.nix];
            pkgs = nixpkgs-unstable.legacyPackages.${pkgs.system};
          })
          neovim
          ;
        nixvim = mkNixVim {};
        nixvimDesktop = mkNixVim {enableDesktop = true;};
        nixvimIDE = mkNixVim {enableIDEFeatures = true;};
        nixvimTheFullPackage = mkNixVim {
          enableIDEFeatures = true;
          enableStupidFeatures = true;
        };

        slimevr = pkgs.callPackage ./5pkgs/slimevr/default.nix {};
        slimevr-appimage = pkgs.callPackage ./5pkgs/slimevr/appimage.nix {};
        mango-bin = pkgs.callPackage ./5pkgs/mango.nix {};
        md-dl = nixpkgs-unstable.legacyPackages.${pkgs.system}.callPackage ./5pkgs/md-dl.nix {};
      }
    );
    devShells =
      eachSystem
      (pkgs: {
        default =
          pkgs.mkShell
          {
            packages = with pkgs; [
              nixpkgs-fmt
              nil
              sumneko-lua-language-server

              # Use `nixos-rebuild build-vm .#${name}` instead
              #(pkgs.writeShellScriptBin "vm-build" ''
              #  export NIXOS_EXTRA_MODULE_PATH=${./.}/5pkgs/vm-config.nix
              #  nixos-rebuild -I "nixos-config=$1" build-vm
              #'')
              (pkgs.writeShellScriptBin "vm-run" ''
                export QEMU_NET_OPTS=net=192.168.76.0/24,dhcpstart=192.168.76.5,hostfwd=tcp::80-:80,hostfwd=tcp::443-:443,hostfwd=tcp::8025-:8025
                ./result/bin/run-*
              '')
            ];
          };
      });

    formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
    checks = eachSystem (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
    });
  };
}
