{
  config,
  pkgs,
  selflib,
  ...
}:
{
  imports = [
    ./../../2configs/safe
    ./../../2configs/news.nix
    ./../../2configs/mango.nix
    ./../../2configs/ffsync.nix
    ./../../2configs/cryboard.nix
    ./../../2configs/pinger.nix
    ./../../2configs/pad.nix
  ];
  rtinf = {
    base.systemType = "server";
    dirtickvpn.interfaces = {
      wg0 = {
        meta = selflib.homevpn;
        privateKeyFile = "/var/lib/wireguard/private";
      };
      wg1 = {
        meta = selflib.wbnet;
        privateKeyFile = "/var/lib/wireguard/wbnet-pk";
      };
      panopticon = {
        privateKeyFile = "/var/lib/wireguard/panopticon-pk";
        connectOutside = {
          forwardedTcpPorts = [
            9100
            9199
          ];
        };
      };
    };
    panopticon = {
      meta = selflib.panopticon;
    };
  };

  boot.loader.grub.devices = [ "/dev/sda" ];

  networking = {
    hostName = "safe";
    domain = "user-sites.de";

    wireguard.interfaces.wg0.generatePrivateKeyFile = true;
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
