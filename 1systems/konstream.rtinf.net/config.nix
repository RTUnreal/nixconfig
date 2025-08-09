{
  nixpkgs-unstable,
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

  services.factorio = {
    enable = true;
    openFirewall = true;
    package = nixpkgs-unstable.factorio-headless;
    extraSettingsFile = "/var/lib/factorio/extraSettings.json";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
