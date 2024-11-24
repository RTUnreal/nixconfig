{config, ...}: let
  imgPath = "/var/lib/koncert-imgs";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  rtinf = {
    base.systemType = "server";
    stream = {
      #enable = true;
      hls = {};
      auth = {
        authDir = "/var/lib/rtmp-auth";
      };
      openFirewall = true;
    };
    stream2 = {
      enable = true;
      hls = {};
      openFirewall = true;
    };
    mofongo = {
      enable = true;
      appendConfigWithFile = "${config.rtinf.mofongo.stateDir}/additional-settings.txt";
      settings = {
        prefix = "m!";
      };
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "konstream";
  networking.domain = "rtinf.net";

  services.nginx.virtualHosts."konstream.rtinf.net".locations."/imgs".root = imgPath;
  systemd.services.nginx.serviceConfig.ReadOnlyPaths = [imgPath];

  systemd.tmpfiles.rules = [
    "d ${imgPath} 0755 trr users -"
  ];

  users.users.trr.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzDeh+d/nSEnYIhAOtuwW5/rJNwXeS7wgWXgp588TOY"
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "unreal@rtinf.net";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
