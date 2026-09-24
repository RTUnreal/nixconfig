# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  selflib,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    ../../2configs/rocm.nix
    ../../2configs/llama-cpp.nix
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
    steam = {
      enable = true;
      enableMonado = true;
    };
    vscode.enable = true;
    misc = {
      docker = true;
      mpv = true;
      virtualization = true;
      wacom = true;
    };
    dirtickvpn = {
      interfaces = {
        "wg0" = {
          meta = selflib.homevpn;
          privateKeyFile = "/var/lib/wireguard/private";
        };
      };
    };
  };

  services.openssh = {
    enable = true;
    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 22;
      }
    ];
  };
  users.users.trr.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOQJOT6cBwg5xXHR+zpS7+VMcx4F73Qm+X4cWaFqRp+g5ru0M/xb+T2icX189j0qWe3BwpftupzaHy7h4sZRTIcRGwlu8LRGFY1WpL8ftgvWCG45ZD3Lp1nX3XpOfBTZD+XYoNOWVM4kuL/+wWYGQYKzo4Ui3kKFEPo0hrShN7GEMim76Xm3m7sldGW0vBzSk8DpLykDLt+RxrLeY2xGI112fjAVvaWn82KE+kflaQIF5XZNVPFqNTMvhRL+ZHTal1SeN3i2TdcbxV9DMLQ/s5bcSLatae/SMlYqNipTpX+lodBqc0d7e0LfwYJERkAHB0NX3TfQPB5tB8EReGMoOm2m0TPdIRGhaEAM5abB5cQr3KV/r2BAVTrcA6ij2f2GszVNNllhHQHvpv5RZUw8+htvFbaTv0Ww+3X1CY/B+hQQ9st4DIfC0o2or38BE1cn90mqfqvl1s/uplkX3ToYo8PU8j0SqVtBWNq/E7lHecTIZqUL5NX32xUnXvjmhZgtU= trr@runner"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAWBFNy2N6Exx7tHlbUDXERJjT7PhIs+vZIWPmhh3qLieeC1tAOf9XcbgVGL3bAryyaCEr1s2bZ6rs2L1JgFFJEGE9TCbfl2dfJIslCPP4OmKxwciIo+T4eXbanGDV0hzW+/vvMyQeWcVT27BrANYR7R28nURmXa1aQ9nWdnHy1Evuv4fI/e+6o3AKEji6Spl5FHs3T9+5vrEwsdq7Mewbfel6gAb3xmp9DIR0Kz0QnitwwErcZYgA2o64C6DLNgsG2l1PrZxE3/MaB6FyzCyOfU8C0FovWlvmmOXkwFPZz1HN1KkKZKV50H4ffiN0cVSLBt6NW6s0v7TWhJyrbIEr trr@spinner"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjWrChmpKdOSmzKghxh5c4UURnetbUsxwLS2l8TLfJW trr@worker"
  ];

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    #extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    kernelModules = [ "rtw88_8822bu" ];
    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;
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
    (blender.override { rocmSupport = true; })
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

  boot.binfmt = {
    emulatedSystems = [ "riscv64-linux" ];
    addEmulatedSystemsToNixSandbox = true;
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home-manager.users.trr.home.stateVersion = "25.05";
  system.stateVersion = "21.11"; # Did you read the comment?
}
