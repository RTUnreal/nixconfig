# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  nixpkgs-unstable ?
    import <nixosUnstable> {
      config = config.nixpkgs.config;
    },
  ...
}: let
  nixosUnstable = nixpkgs-unstable;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../2configs/virtualization.nix
    ./../../2configs/docker.nix
    ./../../2configs/wacom.nix
    ./../../2configs/steam.nix
    (import ./../../2configs/vscode {inherit nixosUnstable;})
    ./retiolum-cfg.nix
  ];
  rtinf = {
    base = {
      systemType = "desktop";
      additionalPrograms = true;
    };
    virtualisation.enable = true;
    neovim.type = "full";
    kde.enable = true;
    misc = {
      mpv = true;
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];
    kernelModules = ["rtw88_8822bu"];
    kernelPackages = pkgs.linuxKernel.packages.linux_6_9;
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
    nixosUnstable.blender-hip
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

  system.stateVersion = "21.11"; # Did you read the comment?
}
