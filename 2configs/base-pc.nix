{pkgs, ...}: {
  services = {
    # Enable the X11 windowing system.
    xserver = {
      enable = true;

      # Configure keymap in X11
      layout = "de,us";
      xkbOptions = "eurosign:e,caps:escape_shifted_capslock";
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["SourceCodePro"];})
  ];

  networking.networkmanager.enable = true;

  users.users.trr.extraGroups = ["networkmanager"];

  # Enable sound.
  sound.enable = true;
  programs = {
    firefox = {
      enable = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    ssh = {
      #startAgent = true;
      # TODO: generate from system
      knownHosts = {
        safetest = {
          hostNames = ["safe.user-sites.de"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAd9bT8/AMtPQheRlPWK4sJwEci3fHsZE1+eIGXkdBY/";
        };
      };
      extraConfig = let
        mapHosts = map ({
            name,
            host,
            ...
          } @ args: ''
            Host ${name}
            Hostname ${host}
            IdentityFile ${
              if args ? identity_file
              then args.identity_file
              else "~/.ssh/id_rsa"
            }
            User ${
              if args ? user
              then args.user
              else "trr"
            }
            ${
              if args ? extraConfig
              then args.extraConfig
              else ""
            }
          '');
      in
        builtins.concatStringsSep "\n" (mapHosts [
          {
            name = "safetest";
            host = "safe.user-sites.de";
          }
        ]);
    };
  };
}
