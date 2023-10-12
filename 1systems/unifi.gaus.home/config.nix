{ ... }:
{
  imports = [
    ./../../2configs/base.nix
    ./../../2configs/base-server.nix
  ];

  boot.loader.raspberryPi = {
    enable = true;
    version = 3;
  };
  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "unifi";
    domain = "gaus.home";

    useDHCP = false;
    interfaces.enp1s0.useDHCP = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
