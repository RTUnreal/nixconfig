{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    ../../2configs/rocm.nix
  ];
  rtinf = {
    base = {
      systemType = "desktop";
      additionalPrograms = true;
    };
    virtualisation.enable = true;
    neovim.type = "ide";
    gpu.type = "amd";
    kde.enable = true;
    steam.enable = true;
    vscode.enable = true;
    hyprland.enable = true;
    misc = {
      bluetooth = true;
      #docker = true;
      wacom = true;
    };
  };

  hardware.enableRedistributableFirmware = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_6_17;
  };

  environment.systemPackages = [
    pkgs.perf
    pkgs.distrobox
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  boot.binfmt = {
    emulatedSystems = [ "riscv64-linux" ];
    addEmulatedSystemsToNixSandbox = true;
  };

  services.fwupd.enable = true;

  networking.hostName = "worker";
  networking.firewall.checkReversePath = "loose";

  time.timeZone = "Europe/Berlin";

  # The state version is required and should stay at the version you
  # originally installed.
  home-manager.users.trr.home.stateVersion = "25.05";
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
