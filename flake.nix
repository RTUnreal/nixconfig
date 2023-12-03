{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    neovim-flake.url = "github:notashelf/neovim-flake";
    nix-gaming.url = "github:fufexan/nix-gaming";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = {
    self,
    nix-gaming,
    hyprland,
    nixpkgs,
    nixinate,
    nixpkgs-unstable,
    neovim-flake,
    retiolum,
    treefmt-nix,
    systems,
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
    };

    nixosConfigurations = let
      pinned-nixpkgs = {
        nix.registry.nixpkgs.flake = nixpkgs;
      };
      unfreePkgs = {
        system,
        allowedUnfree,
      }:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs-unstable.legacyPackages."${system}".lib.getName pkg) allowedUnfree;
        };
    in
      {
        runner =
          nixpkgs.lib.nixosSystem
          rec {
            system = "x86_64-linux";
            specialArgs = {
              nixpkgs-unstable = unfreePkgs {
                inherit system;
                allowedUnfree = [
                  "steam"
                  "steam-original"
                  "steam-run"

                  "zoom"
                  "anydesk"

                  "vscode-extension-ms-vscode-cpptools"
                ];
              };
              selfpkgs = self.packages.${system};
            };
            modules = [
              pinned-nixpkgs
              retiolum.nixosModules.retiolum
              ./1systems/runner/config.nix
            ];
          };
        spinner = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit hyprland;
            nixpkgs-unstable = unfreePkgs {
              inherit system;
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
            };
            selfpkgs = self.packages.${system};
          };
          modules = [
            pinned-nixpkgs
            retiolum.nixosModules.retiolum
            self.nixosModules.virtualization
            ./1systems/spinner/config.nix
          ];
        };
        devel = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            nixpkgs-unstable = nixpkgs-unstable.legacyPackages."${system}";
          };
          modules = [
            ./1systems/devel.rtinf.net/config.nix
            {
              _module.args.nixinate = {
                host = "devel.rtinf.net";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = true;
              };
            }
          ];
        };
        safe = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              _module.args.nixinate = {
                host = "safe.user-sites.de";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = true;
              };
            }
            ./1systems/safe.user-sites.de/config.nix
          ];
        };
        konfactory = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            nixUnstPath = nixpkgs-unstable;
            nixpkgs-unstable = unfreePkgs {
              inherit system;
              allowedUnfree = [
                "factorio-headless"
              ];
            };
          };
          modules = [
            /*
              {
              _module.args.nixinate = {
                host = "konfactory.rtinf.net";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = true;
              };
            }
            */
            ./1systems/konfactory.rtinf.net/config.nix
          ];
        };

        /*
        comms = nixpkgs.lib.nixosSystem rec {
          #system = "aarch64-linux";
          system = "x86_64-linux";
          specialArgs = {
            nixpkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };
          modules = [
            ./1systems/comms.rtinf.net/config.nix
          ];
        };
        */
      }
      // (
        let
          makeTestVM = x: {
            name = "testVM-" + x;
            value = self.nixosConfigurations.${x}.extendModules {modules = [./5pkgs/vm-config.nix];};
          };
        in
          builtins.listToAttrs (builtins.map makeTestVM ["safe" "devel"])
      );
    # adapted from: https://github.com/kmein/niveum
    apps = eachSystem (pkgs: let
      nixinate' = (nixinate.nixinate.${pkgs.system} self).nixinate;
    in
      (builtins.listToAttrs (builtins.map
        (name: {
          name = "nixinate-${name}";
          value = nixinate'.${name};
        })
        (builtins.attrNames nixinate')))
      // {
        deploy = {
          type = "app";
          program = toString (pkgs.writers.writeDash "deploy" ''
            if [ $# -eq 0 ]
            then
              systems='${toString (builtins.filter (x: !(pkgs.lib.hasPrefix "testVM-" x)) (builtins.attrNames self.nixosConfigurations))}'
            else
              systems=$*
            fi
            ${pkgs.parallel}/bin/parallel --line-buffer --tagstring '{}' 'nix run .\?submodules=1\#nixinate-{}' ::: $systems
          '');
        };
      });
    packages = eachSystem (pkgs:
      {
        inherit
          (neovim-flake.lib.neovimConfiguration {
            modules = [./5pkgs/neovim-flake-config.nix];
            pkgs = nixpkgs-unstable.legacyPackages.${pkgs.system};
          })
          neovim
          ;

        mango-bin = pkgs.callPackage ./5pkgs/mango.nix {};
        md-dl = nixpkgs-unstable.legacyPackages.${pkgs.system}.callPackage ./5pkgs/md-dl.nix {};
      }
      // pkgs.lib.optionalAttrs (pkgs.system == "x86_64-linux") {
        inherit (nix-gaming.packages.${pkgs.system}) proton-ge;
      });
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
    hydraJobs.nixosConfigurations."x86_64-linux" = let
      mapNameToConfigs = y:
        builtins.listToAttrs (builtins.map
          (x: {
            name = x;
            value = self.nixosConfigurations.${x}.config.system.build.toplevel;
          })
          y);
    in
      mapNameToConfigs ["safe" "devel"];

    formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
    checks = eachSystem (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
    });
  };
}
