{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    #../../2configs/hyprland.nix
  ];
  rtinf = {
    base = {
      systemType = "desktop";
      additionalPrograms = true;
    };
    virtualisation.enable = true;
    neovim.type = "ide";
    kde.enable = true;
    steam.enable = true;
    vscode.enable = true;
    misc = {
      bluetooth = true;
      docker = true;
      wacom = true;
    };
  };

  hardware.enableRedistributableFirmware = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_latest;
  };

  services.fwupd.enable = true;

  networking.hostName = "worker";

  time.timeZone = "Europe/Berlin";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
