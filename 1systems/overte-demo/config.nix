{
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  rtinf = {
    base = {
      systemType = "desktop";
    };
    virtualisation.enable = true;
    gpu.type = "amd";
    kde.enable = true;
    steam = {
      enable = true;
      enableMonado = true;
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
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

  # The state version is required and should stay at the version you
  # originally installed.
  home-manager.users.trr.home.stateVersion = "25.05";
  system.stateVersion = "21.11"; # Did you read the comment?
}
