# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
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
    neovim.type = "full";
    gpu.type = "amd";
    kde.enable = true;
    steam.enable = true;
    vscode.enable = true;
    misc = {
      docker = true;
      mpv = true;
      virtualization = true;
      wacom = true;
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    kernelModules = [ "rtw88_8822bu" ];
    kernelPackages = pkgs.linuxKernel.packages.linux_6_11;
  };

  networking.hostName = "runner";

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  networking.firewall.checkReversePath = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    prismlauncher
    obs-studio

    inkscape
    blender-hip
    krita
    gimp
    musescore

    paprefs
  ];

  programs = {
    bash.undistractMe = {
      enable = true;
      timeout = 30;
      playSound = true;
    };
    kdeconnect.enable = true;
    dconf.enable = true;
  };
  services.flatpak.enable = true;

  system.stateVersion = "21.11"; # Did you read the comment?
}
