{...}: {
  imports = [
    ../../2configs/base.nix
    ../../2configs/base-server.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    enable = true;
    devices = ["/dev/sda"];
  };

  networking = {
    hostName = "comms";
    domain = "rtinf.net";

    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    firewall.allowedTCPPorts = [22 80 443];
  };

  services = {
    /*
    mastodon = {
      enable = true;
      localDomain = "social.rtinf.net";
      configureNginx = true;
      smtp = {
        createLocally = false;
        port = 1025;
        fromAddress = "social@rtinf.net";
      };
      extraConfig = {
        SINGLE_USER_MODE = "true";
      };
    };
    opensearch.enable = true;
    matrix-synapse = {
    enable = true;
    settings = {
      server_name = "matrix.rtinf.net";
      listeners = [
        {
          port = 8008
        }
      ];
    };
    };
    */
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "letsencrypt@rtinf.net";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
