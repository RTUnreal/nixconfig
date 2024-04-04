# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
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
    ./../../2configs/kde.nix
    ./../../2configs/virtualization.nix
    ./../../2configs/docker.nix
    ./../../2configs/wacom.nix
    ./../../2configs/mpv.nix
    ./../../2configs/steam.nix
    (import ./../../2configs/vscode {inherit nixosUnstable;})
    ./retiolum-cfg.nix
  ];
  rtinf.base.systemType = "desktop";

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    extraModulePackages = with config.boot.kernelPackages; [
      /*
      rtl88x2bu
      */
      v4l2loopback
    ];
    kernelModules = ["rtw88_8822bu"];
    kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
  };

  networking.hostName = "runner";

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  rtinf.neovim.type = "full";

  networking.firewall.checkReversePath = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    lm_sensors
    wireguard-tools
    glxinfo
    xorg.xdpyinfo

    nixosUnstable.rustup
    nixosUnstable.rust-analyzer
    nixosUnstable.cargo-outdated

    thunderbird
    prismlauncher
    mumble
    hexchat
    element-desktop
    nixosUnstable.nextcloud-client
    obs-studio

    keepassxc
    neochat
    tdesktop
    xournalpp
    inkscape
    # TODO: Revert when fixed in nixpkgs
    #nixosUnstable.blender-hip
    krita
    nixosUnstable.texstudio
    texlive.combined.scheme-full
    libreoffice
    gimp
    musescore
    ghidra-bin
    soundux

    vlc
    paprefs

    discord
    nixosUnstable.zoom-us
    nixosUnstable.anydesk
  ];
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"

      "discord"
      "zoom"
      "unityhub"
      "anydesk"

      "vscode-extension-ms-vscode-cpptools"
    ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs = {
    bash.undistractMe = {
      enable = true;
      timeout = 30;
      playSound = true;
    };
    kdeconnect.enable = true;
    dconf.enable = true;
    partition-manager.enable = true;
  };

  system.stateVersion = "21.11"; # Did you read the comment?
}
