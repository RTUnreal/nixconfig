{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      retiolum,
      treefmt-nix,
      systems,
      nixos-hardware,
      nixvim,
      srvos,
      nix-gaming,
      colmena,
      ...
    }:
    let
      # Small tool to iterate over each systems
      eachSystem =
        f: nixpkgs.lib.genAttrs (import systems) (system: f (import nixpkgs { inherit system; }));

      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      colmena =
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
                  inherit system;
                };
                _module.args = {
                  selfpkgs = self.packages.${system};
                  selflib = self.lib;
                  nixpkgs-unstable = import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfreePredicate =
                      pkg: builtins.elem (nixpkgs-unstable.legacyPackages."${system}".lib.getName pkg) allowedUnfree;
                  };
                };
                imports = [
                  nix-gaming.nixosModules.platformOptimizations
                  ./3modules/modules.nix
                ];
              }
              // lib.optionalAttrs (allowedUnfree != [ ]) {
                nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowedUnfree;
              }
            );
        in
        {
          meta = {
            nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          };

          runner =
            let
              system = "x86_64-linux";
            in
            {
              deployment.allowLocalDeployment = true;
              imports = [
                (common system {
                  allowedUnfree = [
                    "steam"
                    "steam-original"
                    "steam-run"

                    "discord"
                    "anydesk"

                    "vscode-extension-ms-vscode-cpptools"
                  ];
                })
                ./1systems/runner/config.nix
                retiolum.nixosModules.retiolum
                nixos-hardware.nixosModules.common-gpu-amd
                nixos-hardware.nixosModules.common-cpu-amd
                nixos-hardware.nixosModules.common-cpu-amd-pstate
              ];
            };
          spinner =
            let
              system = "x86_64-linux";
            in
            {
              deployment = {
                targetUser = "trr";
                targetHost = "192.168.0.101";
                tags = [
                  "servers"
                  "personal"
                ];
              };
              imports = [
                (common system {
                  allowedUnfree = [
                    "steam"
                    "steam-original"
                    "steam-run"

                    "discord"
                    "anydesk"

                    "nvidia-x11"
                    "nvidia-settings"

                    "vscode-extension-ms-vscode-cpptools"
                  ];
                })
                ./1systems/spinner/config.nix
                retiolum.nixosModules.retiolum
              ];
            };
          worker =
            let
              system = "x86_64-linux";
            in
            {
              deployment.allowLocalDeployment = true;
              imports = [
                (common system {
                  allowedUnfree = [
                    "steam"
                    "steam-original"
                    "steam-run"

                    "discord"
                    "anydesk"

                    "vscode-extension-ms-vscode-cpptools"
                  ];
                })
                retiolum.nixosModules.retiolum
                nixos-hardware.nixosModules.framework-13-7040-amd
                ./1systems/worker/config.nix
              ];
            };
          safe =
            let
              system = "x86_64-linux";
            in
            {
              deployment = {
                targetUser = "trr";
                targetHost = "safe.user-sites.de";
                tags = [
                  "remote"
                  "servers"
                  "personal"
                ];
              };
              imports = [
                (common system { })
                srvos.nixosModules.server
                srvos.nixosModules.hardware-hetzner-cloud
                ./1systems/safe.user-sites.de/config.nix
              ];
            };
          devel =
            let
              system = "x86_64-linux";
            in
            {
              deployment = {
                targetUser = "trr";
                targetHost = "devel.rtinf.net";
                tags = [
                  "remote"
                  "servers"
                ];
              };
              imports = [
                (common system { allowedUnfree = [ "factorio-headless" ]; })
                srvos.nixosModules.server
                ./1systems/devel.rtinf.net/config.nix
              ];
            };
          konstream =
            let
              system = "aarch64-linux";
            in
            {
              deployment = {
                targetUser = "trr";
                buildOnTarget = true;
                targetHost = "konstream.rtinf.net";
                tags = [
                  "remote"
                  "servers"
                  "koncert"
                ];
              };
              imports = [
                (common system { })
                srvos.nixosModules.server
                ./1systems/konstream.rtinf.net/config.nix
              ];
            };
        };
      nixosModules = {
        nvidia-prime = import ./2configs/nvidia-prime.nix;

        devel-forge = import ./2configs/devel/forge.nix;
        devel-ci = import ./2configs/devel/ci.nix;
      };

      nixosConfigurations = (colmena.lib.makeHive self.colmena).nodes;

      packages = eachSystem (
        pkgs:
        let
          mkNixVim =
            opt:
            nixvim.legacyPackages.${pkgs.system}.makeNixvim (
              import ./5pkgs/nixvim-config.nix {
                inherit (nixpkgs-unstable) lib;
                pkgs = nixpkgs-unstable.legacyPackages.${pkgs.system};
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
          slimevr-appimage = pkgs.callPackage ./5pkgs/slimevr/appimage.nix { };

          proton-ge-rtsp-bin = pkgs.proton-ge-bin.overrideAttrs (
            prevAttrs: rec {
              pname = "proton-ge-rtsp-bin";
              version = "GE-Proton9-20-rtsp15";
              src =  pkgs.fetchzip {
                #url = assert with builtins; trace "blah" true;"https://github.com/SpookySkeletons/proton-ge-rtsp/releases/download/${version}/${version}.tar.gz";
                # this version has a broken link
                url = assert with builtins; trace "blah" true;"https://github.com/SpookySkeletons/proton-ge-rtsp/releases/download/${version}-1/${version}.tar.gz";
                hash = "sha256-dj5qO1AmV0KinrfgUcv+bWzLN9aaAAKf/GxX5o9b6Dc=";
              };
            }
          );

          jmusicbot = pkgs.callPackage (
            { fetchurl }:
            let
              version = "0.4.3";
            in
            fetchurl {
              url = "https://github.com/jagrosh/MusicBot/releases/download/${version}/JMusicBot-${version}.jar";
              sha256 = "sha256-7CHFc94Fe6ip7RY+XJR9gWpZPKM5JY7utHp8C3paU9s=";
            }
          ) { };
        }
      );

      lib = import ./4lib;

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
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
      checks = eachSystem (
        pkgs:
        let
          system = pkgs.system;
          lib = pkgs.lib;
        in
        {
          formatting = treefmtEval.${pkgs.system}.config.build.check self;
        }
        //
          # Nixvim derivations
          (builtins.listToAttrs (
            builtins.map
              (
                { name, value }:
                {
                  inherit name;
                  value = nixvim.lib.${system}.check.mkTestDerivationFromNvim {
                    inherit name;
                    nvim = value;
                  };
                }
              )
              (
                builtins.filter ({ name, ... }: builtins.match "^nixvim" name != null) (
                  lib.mapAttrsToList lib.nameValuePair self.packages.${system}
                )
              )
          ))
      );
    };
}
