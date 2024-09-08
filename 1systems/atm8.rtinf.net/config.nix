# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];
  rtinf.base.systemType = "server";

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "atm8";
    domain = "rtinf.net";
  };
  users = {
    users = {
      mc.isSystemUser = true;
      mc.group = "mc";
    };
    groups.mc = {};
  };

  services.modded-minecraft-servers = {
    eula = true;
    instances = {
      "eclipsed" = {
        enable = true;
        jvmPackage = pkgs.jre_headless;
        serverConfig = {
          motd = "Fantasy Medieval";
          extra-options = {
            simulation-distance = 10;
            allow-flight = true;
          };
        };
      };
    };
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
