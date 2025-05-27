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
        version = 31;
      in
      {
        enable = true;
        https = true;
        hostName = "safe.user-sites.de";
        package = pkgs."nextcloud${toString version}";
        datadir = "${storageMountPoint}/nextcloud";
        config = {
          dbtype = "pgsql";
          adminpassFile = "/var/lib/nextcloud/adminpw";
        };
        database.createLocally = true;
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
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  systemd.services."nextcloud-setup" = {
    requires = [
      "mnt-storagebox.mount"
    ];
    wants = [
      "mnt-storagebox.mount"
    ];
    after = [
      "mnt-storagebox.mount"
    ];
  };
}
