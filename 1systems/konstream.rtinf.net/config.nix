{
  config,
  pkgs,
  selflib,
  ...
}:
{
  imports = [
  ];
  rtinf = {
    base.systemType = "server";
    stream2 = {
      enable = true;
      hls = { };
      api = { };
      openFirewall = true;
    };
    stream.auth = {
      authDir = "/var/lib/rtmp-auth";
    };
  };

  #boot.loader.grub.devices = [ "/dev/sda" ];

  networking = {
    hostName = "konstream";
    domain = "rtinf.net";
  };
  security.acme = {
    defaults.email = "unreal@rtinf.net";
    acceptTerms = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
