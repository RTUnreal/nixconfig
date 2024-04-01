{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../2configs/devel/forge.nix
    # TODO: Remove when buildbot is standing
    #./../../2configs/devel/ci.nix
    ./../../2configs/devel/buildbot.nix
  ];
  rtinf.base.systemType = "server";
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "devel"; # Define your hostname.
    domain = "rtinf.net";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # List services that you want to enable:
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "unreal@rtinf.net";

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
