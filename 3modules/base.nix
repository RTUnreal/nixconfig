{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkMerge mkIf;
  cfg = config.rtinf.base;
in {
  options.rtinf.base = {
    systemType = mkOption {
      type = types.nullOr (types.enum ["desktop" "server"]);
    };
    additionalPrograms = mkEnableOption "add additional Programs";
  };

  config = mkMerge [
    (mkIf (cfg.systemType != null) {
      users.users.trr = {
        isNormalUser = true;
        description = "Alexander Gaus";
        extraGroups = ["wheel"];
        uid = 1000;
      };

      # Select internationalisation properties.
      i18n.defaultLocale = "de_DE.UTF-8";
      console = {
        font = "Lat2-Terminus16";
        keyMap = "de";
      };
      environment.systemPackages = with pkgs; [
        # shell utils
        wget
        file
        findutils
        tree
        lsof
        xxd
        jq
        qrencode
        bat

        # net utils
        bind
        whois
        iperf
        nmap

        # system utils
        htop
        inxi
        pciutils
        usbutils
      ];

      programs = {
        bash.shellAliases = {
          gs = "git status";
          gap = "git add -p";
        };
        git = {
          enable = true;
          lfs.enable = true;
        };
        htop.enable = true;
        less.enable = true;
        iftop.enable = true;
      };

      rtinf.neovim.enable = true;

      #system.copySystemConfiguration = true;

      nix.settings.experimental-features = ["nix-command" "flakes"];
    })
    (mkIf (cfg.systemType == "desktop") {
      rtinf.neovim.type = lib.mkDefault "desktop";
      services = {
        # Enable the X11 windowing system.
        xserver = {
          enable = true;

          # Configure keymap in X11
          layout = "de,us";
          xkbOptions = "eurosign:e,caps:escape_shifted_capslock,grp:win_space_toggle";
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

      boot.plymouth = {
        enable = true;
        theme = "breeze";
      };

      fonts.packages = with pkgs; [
        (nerdfonts.override {fonts = ["SourceCodePro"];})
      ];

      networking.networkmanager.enable = true;

      users.users.trr.extraGroups = ["networkmanager"];

      environment.systemPackages = with pkgs; [
        lazygit
      ];

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
                IdentityFile ${args.identity_file or "~/.ssh/id_rsa"}
                User ${args.user or "trr"}
                ${args.extraConfig or ""}
              '');
          in
            builtins.concatStringsSep "\n" (mapHosts [
              {
                name = "safetest";
                host = "safe.user-sites.de";
              }
            ]);
        };
        partition-manager.enable = true;
      };
    })
    (mkIf (cfg.systemType == "server") {
      users.users.trr.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOQJOT6cBwg5xXHR+zpS7+VMcx4F73Qm+X4cWaFqRp+g5ru0M/xb+T2icX189j0qWe3BwpftupzaHy7h4sZRTIcRGwlu8LRGFY1WpL8ftgvWCG45ZD3Lp1nX3XpOfBTZD+XYoNOWVM4kuL/+wWYGQYKzo4Ui3kKFEPo0hrShN7GEMim76Xm3m7sldGW0vBzSk8DpLykDLt+RxrLeY2xGI112fjAVvaWn82KE+kflaQIF5XZNVPFqNTMvhRL+ZHTal1SeN3i2TdcbxV9DMLQ/s5bcSLatae/SMlYqNipTpX+lodBqc0d7e0LfwYJERkAHB0NX3TfQPB5tB8EReGMoOm2m0TPdIRGhaEAM5abB5cQr3KV/r2BAVTrcA6ij2f2GszVNNllhHQHvpv5RZUw8+htvFbaTv0Ww+3X1CY/B+hQQ9st4DIfC0o2or38BE1cn90mqfqvl1s/uplkX3ToYo8PU8j0SqVtBWNq/E7lHecTIZqUL5NX32xUnXvjmhZgtU= trr@runner"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAWBFNy2N6Exx7tHlbUDXERJjT7PhIs+vZIWPmhh3qLieeC1tAOf9XcbgVGL3bAryyaCEr1s2bZ6rs2L1JgFFJEGE9TCbfl2dfJIslCPP4OmKxwciIo+T4eXbanGDV0hzW+/vvMyQeWcVT27BrANYR7R28nURmXa1aQ9nWdnHy1Evuv4fI/e+6o3AKEji6Spl5FHs3T9+5vrEwsdq7Mewbfel6gAb3xmp9DIR0Kz0QnitwwErcZYgA2o64C6DLNgsG2l1PrZxE3/MaB6FyzCyOfU8C0FovWlvmmOXkwFPZz1HN1KkKZKV50H4ffiN0cVSLBt6NW6s0v7TWhJyrbIEr trr@spinner"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjWrChmpKdOSmzKghxh5c4UURnetbUsxwLS2l8TLfJW trr@worker"
      ];
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };
    })
    (mkIf cfg.additionalPrograms {
      environment.systemPackages = with pkgs; [
        thunderbird
        keepassxc
        mumble
        neochat
        element-desktop
        xournalpp
        texlive.combined.scheme-full
        texstudio
        hexchat
        vlc
        nixpkgs-unstable.nextcloud-client
        tdesktop
        blender
        libreoffice-fresh
        ghidra

        discord
        nixpkgs-unstable.zoom-us
        nixpkgs-unstable.anydesk
      ];
    })
  ];
}
