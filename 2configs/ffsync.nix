{ pkgs, lib, ... }:
{
  services.firefox-syncserver = {
    enable = true;
    singleNode = {
      enable = true;
      hostname = "ffsync.user-sites.de";
      enableNginx = true;
      enableTLS = true;
      capacity = 1;
    };
    settings.port = 8008;
    secrets = "/root/ffsync-secrets";
    database.createLocally = true;
  };
  services.mysql.package = lib.mkDefault pkgs.mariadb;
}
