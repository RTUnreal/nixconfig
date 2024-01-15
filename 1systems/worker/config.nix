{
  selfpkgs,
  config,
  lib,
  pkgs,
  nixpkgs-unstable ?
    import <nixosUnstable> {
      inherit (config.nixpkgs) config;
    },
  ...
}: let
  nixosUnstable = nixpkgs-unstable;
in {
  imports = [
    ./hardware-configuration.nix
    #./retiolum-cfg.nix
    ../../2configs/base.nix
    ../../2configs/base-pc.nix
    ../../2configs/bluetooth.nix
    ../../2configs/docker.nix
    ../../2configs/kde.nix
    ../../2configs/wacom.nix
    #../../2configs/hyprland.nix
    (import ../../2configs/vscode {inherit nixosUnstable;})
  ];

  hardware.enableRedistributableFirmware = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_6_7;
  };

  services.fwupd.enable = true;

  networking.hostName = "worker";

  time.timeZone = "Europe/Berlin";

  rtinf = {
    virtualisation = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    kate
    kcalc
    ark

    thunderbird
    keepassxc
    mumble
    neochat
    element-desktop
    xournalpp
    texlive.combined.scheme-full
    texstudio
    hexchat
    vlc
    nixosUnstable.nextcloud-client
    tdesktop
    blender
    libreoffice-fresh
    selfpkgs.neovim
    ghidra

    discord
    zoom-us
    anydesk
  ];
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"

      "discord"
      "zoom"
      "anydesk"

      "vscode-extension-ms-vscode-cpptools"
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
