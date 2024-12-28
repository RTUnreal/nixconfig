{ config, pkgs, ... }:
{
  imports = [
    ./../../2configs/safe
    ./../../2configs/news.nix
    ./../../2configs/mango.nix
    ./../../2configs/ffsync.nix
  ];
  rtinf.base.systemType = "server";

  boot.loader.grub.devices = [ "/dev/sda" ];

  networking = {
    hostName = "safe";
    domain = "user-sites.de";

    firewall = {
      allowedUDPPorts = [ 51820 ];
    };
    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.69.0.1/32" ];
          listenPort = 51820;

          privateKeyFile = "/var/lib/wireguard/private";
          generatePrivateKeyFile = true;

          # TODO: figure out how to use tables instead
          fwMark = "123";
          table = "wg0";
          preSetup = ''
            set -x
            #ip route add 10.69.0.1/32 dev wg0 table wg0
            ip rule add not fwmark 123 table wg0 priority 456 || true
            ip rule add table main suppress_prefixlength 0 || true
          '';

          postShutdown = ''
            set -x
            ip rule del table main suppress_prefixlength 0 || true
            ip rule del table wg0 || true
            #ip route del 10.69.0.1/32 dev wg0 table wg0
          '';

          peers = [
            # home server
            {
              publicKey = "a9DSEaO+mkpBTaaOrwiZIyduDBXBYe73e0FwbfGim18=";
              # TODO: change to 0.0.0.0/0 when table = 123 works
              allowedIPs = [
                "10.69.0.2/32"
                "192.168.0.0/24"
              ];
            }
            {
              publicKey = "VOHbmF+DU/vYjDF1gDXNpmkBGgxRnCKWnSOrlJXMtwk=";
              allowedIPs = [ "10.69.0.3/32" ];
            }
            {
              publicKey = "nAD9372w6USjUbkZ/Cl1urLaeA1C/zKMBZ18wq2j0A4=";
              allowedIPs = [ "10.69.0.4/32" ];
            }
          ];
        };
      };
    };
    iproute2 = {
      enable = true;
      rttablesExtraConfig = ''
        123 wg0
      '';
    };
  };
  systemd.services.wireguard-wg0 = {
    after = [
      "systemd-networkd.service"
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "upgrade-pg-cluster" ''
      set -eux
      # XXX it's perhaps advisable to stop all services that depend on postgresql
      systemctl stop postgresql

      # XXX replace `<new version>` with the psqlSchema here
      export NEWDATA="/var/lib/postgresql/14"

      # XXX specify the postgresql package you'd like to upgrade to
      export NEWBIN="${pkgs.postgresql_14}/bin"

      export OLDDATA="${config.services.postgresql.dataDir}"
      export OLDBIN="${config.services.postgresql.package}/bin"

      install -d -m 0700 -o postgres -g postgres "$NEWDATA"
      cd "$NEWDATA"
      sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

      sudo -u postgres $NEWBIN/pg_upgrade \
        --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
        --old-bindir $OLDBIN --new-bindir $NEWBIN \
        "$@"
    '')
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
