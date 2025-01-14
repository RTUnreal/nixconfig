{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./retiolum-cfg.nix
    ../../2configs/nvidia-prime.nix
    ../../2configs/alexandria.nix
    ../../2configs/wanze.nix
    ../../2configs/grafana-json-api.nix
  ];
  rtinf = {
    base = {
      systemType = "server";
      laptopServer = {
        buildinDisplayName = "intel_backlight";
      };
    };
    virtualisation.enable = true;
    hyprland.enable = true;
    magnet = {
      enable = true;
      openFirewall = true;
    };
    stream.auth = {
      authDir = "/var/lib/rtmp-auth";
    };
    stream2 = {
      enable = true;
      domain = null;
      hls = { };
      openFirewall = true;
    };
    misc = {
      bluetooth = true;
      docker = true;
      wacom = true;
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
      };
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        #hide_version = true;
      };
    };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        3000
        8888
        9997
      ];
      allowedUDPPorts = [ 51820 ];
    };
    nat = {
      enable = true;
      #enableIPv6 = true;
      externalInterface = "enp2s0f1";
      internalInterfaces = [ "wg0" ];
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.69.0.2/32" ];
          listenPort = 51820;

          privateKeyFile = "/var/lib/wireguard/private";
          generatePrivateKeyFile = true;

          postSetup = ''
            ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.69.0.1/24 -o enp2s0f1 -j MASQUERADE
          '';

          preShutdown = ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.69.0.1/24 -o enp2s0f1 -j MASQUERADE
          '';

          peers = [
            {
              publicKey = "SWA0lWwRroZBEudH1lcASIKMv/0ayL8S/KtmUXFdomI=";
              allowedIPs = [ "10.69.0.0/24" ];
              endpoint = "network.user-sites.de:51820";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  users.users.${config.services.jellyfin.user}.extraGroups = [ config.rtinf.magnet.group ];

  hardware.enableRedistributableFirmware = true;
  hardware.nvidia.open = false;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "spinner";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
