{ pkgs, ... }:
let
  storageMountPoint = "/mnt/storagebox";
in
{
  security.acme = {
    defaults.email = "alex@user-sites.de";
    acceptTerms = true;
  };
  fileSystems.${storageMountPoint} = {
    device = "//u408927.your-storagebox.de/backup";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"

      "iocharset=utf8"
      "rw"
      "credentials=/root/storagebox-secrets"
      "uid=nextcloud"
      "gid=nextcloud"
      "file_mode=0660"
      "dir_mode=0770"
      "cache=none"
      "seal"
      "mfsymlinks" # nextcloud-setup wants to create symlinks on cifs
    ];
  };
  services = {
    nginx.virtualHosts."safe.user-sites.de" = {
      enableACME = true;
      forceSSL = true;
    };
    nextcloud =
      let
        version = 30;
      in
      {
        enable = true;
        https = true;
        hostName = "safe.user-sites.de";
        package = pkgs."nextcloud${builtins.toString version}";
        datadir = "/${storageMountPoint}/nextcloud";
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
          dbname = "nextcloud";
          adminuser = "root";
          adminpassFile = "/var/lib/nextcloud/adminpw";
        };
        extraApps = with pkgs."nextcloud${toString version}Packages".apps; {
          inherit
            calendar
            contacts
            mail
            music
            notes
            tasks
            ;
        };
      };
    postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        {
          name = "nextcloud";
          #ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
          ensureDBOwnership = true;
        }
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  systemd.services."nextcloud-setup" = {
    requires = [
      "mnt-storagebox.mount"
      "postgresql.service"
    ];
    wants = [
      "mnt-storagebox.mount"
      "postgresql.service"
    ];
    after = [
      "mnt-storagebox.mount"
      "postgresql.service"
    ];
  };
}
