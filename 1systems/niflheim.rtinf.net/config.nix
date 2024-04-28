# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];
  rtinf.base.systemType = "server";

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "niflheim";
    domain = "rtinf.net";
  };
  users = {
    users = {
      vhalheim = {
        isSystemUser = true;
        group = "vhalheim";
      };

      root.openssh.authorizedKeys.keys = config.users.users.trr.openssh.authorizedKeys.keys;
    };
    groups.vhalheim = {};
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.vhalheim = {
      image = "ghcr.io/lloesche/valheim-server";
      ports = ["2456-2457:2456-2457/udp"];
      volumes = [
        "/var/lib/vhalheim/config:/config:Z"
        "/var/lib/vhalheim/data:/opt/vhalheim:Z"
      ];
      environment = {
        SERVER_NAME = "Niflheim";
        SERVER_PORT = "2456";
        WORLD_NAME = "Dedicated";
        SERVER_PASS = "milfheim";
        SERVER_ARGS = "-modifier resources muchmore";
      };
      extraOptions = ["--cap-add=sys_nice"]; # "--stop-timeout 120"];
    };
  };
  networking.firewall.allowedUDPPorts = [2456];
  systemd.tmpfiles.rules = [
    "d /var/lib/vhalheim/config 0755 vhalheim vhalheim -"
    "d /var/lib/vhalheim/data 0755 vhalheim vhalheim -"
  ];

  time.timeZone = "Europe/Berlin";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
