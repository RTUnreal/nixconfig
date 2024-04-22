{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.forgejo;
  domain = config.networking.fqdn;
in {
  users.users.git = {
    description = "Gitea Service";
    home = cfg.stateDir;
    useDefaultShell = true;
    group = "git";
    isSystemUser = true;
  };
  users.groups.git = {};

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    user = "git";
    database.type = "sqlite3";
    settings = {
      default.APP_NAME = "${domain}: My Dumbest Gitea instance";
      server = {
        PROTOCOL = "http+unix";
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
      };
      service = {
        DISABLE_REGISTRATION = lib.mkForce true;
      };
      security = {
        IMPORT_LOCAL_PATHS = "true";
      };
      log.LEVEL = "Error";
      webhook.ALLOWED_HOST_LIST = "*.devel.rtinf.net";
    };
  };
  services.nginx.virtualHosts."${domain}" = {
    locations."/" = {
      proxyPass = "http://unix:/run/forgejo/forgejo.sock";
      proxyWebsockets = true;
    };
    forceSSL = true;
    enableACME = true;
  };
  environment.systemPackages = [cfg.package];
  networking.firewall.allowedTCPPorts = [80 443];
}
