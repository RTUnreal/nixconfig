# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  config,
  lib,
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
  imports = [
    ./hardware-configuration.nix
    ../../2configs/base.nix
    ../../2configs/base-server.nix
    ../../3modules/factorio.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "konfactory";
    domain = "rtinf.net";
  };

  users.users.root.openssh.authorizedKeys.keys = config.users.users.trr.openssh.authorizedKeys.keys;

  rtinf.factorio = {
    enable = true;
    openFirewall = true;
    gamePasswordFile = "/var/lib/factorio/game-password";
    package = nixpkgs-unstable.factorio-headless;
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
