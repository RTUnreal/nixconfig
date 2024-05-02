{
  config,
  nixpkgs-unstable ?
    import <nixosUnstable> {
      config = config.nixpkgs.config;
    },
  ...
}: let
  nixosUnstable = nixpkgs-unstable;
in {
  imports = [
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    ../../2configs/bluetooth.nix
    ../../2configs/docker.nix
    ../../2configs/nvidia-prime.nix
    ../../2configs/wacom.nix
    ../../2configs/steam.nix
    (import ../../2configs/vscode {inherit nixosUnstable;})
  ];
  rtinf = {
    base = {
      systemType = "server";
      laptopServer = {
        buildinDisplayName = "intel_backlight";
      };
      additionalPrograms = true;
    };
    virtualisation.enable = true;
    hyprland.enable = true;
  };

  services.github-runners."enowars" = {
    enable = true;
    url = "https://github.com/enowars";
    tokenFile = "/var/lib/enowars/token";
    ephemeral = true;
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/enowars 0755 root root -"
  ];

  hardware.enableRedistributableFirmware = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.supportedFilesystems = ["ntfs"];

  networking.hostName = "spinner";

  time.timeZone = "Europe/Berlin";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
