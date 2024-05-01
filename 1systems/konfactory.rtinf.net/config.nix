# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  config,
  lib,
  pkgs,
  nixUnstPath,
  nixpkgs-unstable ?
    import <nixosUnstable> {
      config =
        config.nixpkgs.config
        // {
          allowUnfreePredicate = pkg:
            builtins.elem (lib.getName pkg) [
              "factorio-headless"
            ];
        };
    },
  ...
}: {
  disabledModules = [
    "services/games/factorio.nix"
  ];

  imports = [
    ./hardware-configuration.nix
    "${nixUnstPath}/nixos/modules/services/games/factorio.nix"
  ];
  rtinf.base.systemType = "server";

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "konfactory";
    domain = "rtinf.net";
  };

  services.factorio = {
    enable = true;
    openFirewall = true;
    extraSettingsFile = "/var/lib/factorio/settings.json";
    package = nixpkgs-unstable.factorio-headless;
    saveName = "factorissimo";
    mods = let
      modDrv = pkgs.factorio-utils.modDrv {
        allRecommendedMods = true;
        allOptionalMods = true;
      };

      mods = rec {
        Factorissimo2-Playthrough = modDrv {
          src = pkgs.requireFile {
            name = "Factorissimo2-Playthrough_1.2.1.zip";
            url = "https://mods.factorio.com/download/Factorissimo2-Playthrough/64ce38aa59d3cfa58acd391a?username={username}&token={token}";
            sha256 = "1dgrnzczh0vypayiv976hrpdzg9ixafmra90dbnar2lm8kzaxva7";
          };
          deps = [Factorissimo2];
        };
        Factorissimo2 = modDrv {
          src = pkgs.requireFile {
            name = "Factorissimo2_2.5.3.zip";
            url = "https://mods.factorio.com/download/Factorissimo2/616ea82bda84c78d82cde184?username={username}&token={token}";
            sha256 = "0knsghvsj02ziymml8p97w0y4vi8i7d926imny6lwr43myjw57ck";
          };
        };
      };
    in [
      mods.Factorissimo2-Playthrough
    ];
  };

  time.timeZone = "Europe/Berlin";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
