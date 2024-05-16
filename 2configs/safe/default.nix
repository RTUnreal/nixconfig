{pkgs, ...}: {
  security.acme = {
    defaults.email = "alex@user-sites.de";
    acceptTerms = true;
  };
  services = {
    nginx.virtualHosts."safe.user-sites.de" = {
      enableACME = true;
      forceSSL = true;
    };
    nextcloud = let
      version = 29;
    in {
      enable = true;
      https = true;
      hostName = "safe.user-sites.de";
      package = pkgs."nextcloud${builtins.toString version}";
      datadir = "/data/nextcloud";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
        dbname = "nextcloud";
        adminuser = "root";
        adminpassFile = "/data/nextcloud/config/adminpw";
      };
      extraApps = let
        mapListToNCApps = list:
          builtins.listToAttrs (map (value: {
              inherit (value) name;
              value = pkgs.fetchNextcloudApp (builtins.removeAttrs value ["name" "version" "description"]);
            })
            list);
      in
        mapListToNCApps (builtins.fromJSON (builtins.readFile ./apps.json));
    };
    postgresql = {
      enable = true;
      ensureDatabases = ["nextcloud"];
      ensureUsers = [
        {
          name = "nextcloud";
          #ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
          ensureDBOwnership = true;
        }
      ];
    };
    fail2ban = {
      enable = true;
      ignoreIP = [
        "95.88.0.0/14" # Kabel Deutschland (Alex)
      ];
    };
  };
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };
}
