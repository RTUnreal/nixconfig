{ ... }:
{
  imports = [
    # Include the results of the hardware scan.
  ];

  boot.loader.systemd-boot.enable = true;
  rtinf.base.systemType = "server";
  networking = {
    hostName = "ttt"; # Define your hostname.
    domain = "rtinf.net";
  };

  services.garrys-mod = {
    enable = true;
    openFirewall = true;
    gamemode = "terrortown";
    #map = "ttt_mc_skyislands";
    workshopCollection = 864555069;
  };
  boot.kernel.sysctl."dev.tty.legacy_tiocsti" = 0;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  #system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
