{
  selfpkgs,
  config,
  lib,
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
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    ../../2configs/bluetooth.nix
    ../../2configs/docker.nix
    ../../2configs/kde.nix
    ../../2configs/nvidia-prime.nix
    ../../2configs/wacom.nix
    ../../2configs/steam.nix
    #../../2configs/hyprland.nix
    (import ../../2configs/vscode {inherit nixosUnstable;})
  ];
  rtinf.base.systemType = "desktop";

  hardware.enableRedistributableFirmware = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.supportedFilesystems = ["ntfs"];

  networking.hostName = "spinner";

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
      "anydesk"

      "nvidia-x11"
      "nvidia-settings"

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
