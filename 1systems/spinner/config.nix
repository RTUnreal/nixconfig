{config, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    ../../2configs/nvidia-prime.nix
    ../../2configs/alexandria.nix
    ../../2configs/wanze.nix
  ];
  rtinf = {
    base = {
      systemType = "server";
      laptopServer = {
        buildinDisplayName = "intel_backlight";
      };
    };
    virtualisation.enable = true;
    hyprland.enable = true;
    magnet = {
      enable = true;
      openFirewall = true;
    };
    misc = {
      bluetooth = true;
      docker = true;
      wacom = true;
    };
  };

  users.users.${config.services.jellyfin.user}.extraGroups = [config.rtinf.magnet.group];

  hardware.enableRedistributableFirmware = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.supportedFilesystems = ["ntfs"];

  networking.hostName = "spinner";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
