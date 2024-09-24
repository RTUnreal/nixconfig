{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  selflib,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkMerge mkIf;
  cfg = config.rtinf.base;
in {
  options.rtinf.base = {
    systemType = mkOption {
      type = types.nullOr (types.enum ["desktop" "server"]);
    };
    laptopServer = mkOption {
      type = types.nullOr (types.submodule {
        options.buildinDisplayName = mkOption {
          type = types.str;
          example = "intel_backlight";
          description = lib.mdDoc "`/sys/acpi/backlight` display name";
        };
      });
      default = null;
      description = lib.mdDoc "set laptop server specific configs. `null` to disable.";
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
      console.font = "Lat2-Terminus16";
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
        colmena

        # net utils
        bind
        whois
        iperf
        nmap

        # system utils
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

      console.keyMap = "de";
      services = {
        # Enable the X11 windowing system.
        xserver = {
          enable = true;

          # Configure keymap in X11
          xkb = {
            layout = "de,us";
            options = "eurosign:e,caps:escape,grp:win_space_toggle";
          };
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

      environment.systemPackages = with pkgs; [
        lazygit
      ];

      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };
      sound.enable = true;
      programs = {
        firefox = {
          enable = true;
          preferences = {
            "identity.sync.tokenserver.uri" = "https://ffsync.user-sites.de/token/1.0/sync/1.5";
          };
        };
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };
        ssh = {
          extraConfig = lib.pipe selflib.hosts [
            (builtins.mapAttrs (
              name: args: ''
                Host ${name}
                Hostname ${builtins.head args.hostNames}
                User ${args.user or "trr"}
                ${args.extraSSHConfig or ""}
              ''
            ))
            builtins.attrValues
            (builtins.concatStringsSep "\n")
          ];

          knownHostsFiles = [
            (pkgs.writeText "known_hosts" (
              lib.pipe selflib.hosts [
                builtins.attrValues
                (builtins.concatMap (h: (builtins.map (k: (builtins.concatStringsSep "," h.hostNames) + " " + k) h.sshHostKeys)))
                (builtins.concatStringsSep "\n")
                (t: t + "\n")
              ]
            ))
          ];
        };
        appimage = {
          enable = true;
          binfmt = true;
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
      nix = {
        settings.trusted-users = ["root" "@wheel"];
        gc = {
          automatic = true;
          persistent = true;
        };
      };
      security.sudo.wheelNeedsPassword = false;
      services = {
        openssh = {
          enable = true;
          #settings.PermitRootLogin = "yes";
        };
        fail2ban = {
          # also adds ssh filters
          enable = cfg.laptopServer == null;
          ignoreIP = [
            "95.88.0.0/14" # Kabel Deutschland (Alex)
          ];
        };
      };
    })
    (mkIf (cfg.laptopServer != null) {
      services.logind.lidSwitch = "ignore";
      services.acpid = {
        enable = true;
        logEvents = true;
        lidEventCommands = ''
          vals=($1)
          echo "lid event '$1'"
          case ''${vals[3]} in
            open)
              echo 100 > /sys/class/acpi/backlight/${cfg.laptopServer.buildinDisplayName}/brightness
              ;;
            close)
              echo 0 > /sys/class/acpi/backlight/${cfg.laptopServer.buildinDisplayName}/brightness
              ;;
            *)
              echo unknown lid state ''${vals[3]}
              ;;
          esac
        '';
        # TODO: make this emit a warning when unplugged
        # acEventCommand = "";
      };
    })
    (mkIf cfg.additionalPrograms {
      environment.systemPackages = with pkgs; [
        thunderbird
        keepassxc
        mumble
        element-desktop
        xournalpp
        #texlive.combined.scheme-full
        #texstudio
        hexchat
        vlc
        nextcloud-client
        tdesktop
        libreoffice-fresh
        ghidra

        discord
        nixpkgs-unstable.anydesk
      ];
    })
  ];
}
