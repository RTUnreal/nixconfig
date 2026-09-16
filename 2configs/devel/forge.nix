{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.forgejo;
  DOMAIN = config.networking.fqdn;
in
{
  users.users.git = {
    description = "Gitea Service";
    home = cfg.stateDir;
    useDefaultShell = true;
    group = "git";
    isSystemUser = true;
  };
  users.groups.git = { };

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    user = "git";
    database.type = "sqlite3";
    settings = {
      default.APP_NAME = "${DOMAIN}: My Gayest Forgejo instance";
      server = {
        inherit DOMAIN;
        HTTP_PORT = 3002;
        ROOT_URL = "https://${DOMAIN}/";
      };
      service = {
        DISABLE_REGISTRATION = lib.mkForce true;
      };
      security = {
        IMPORT_LOCAL_PATHS = "true";
      };
      repository = {
        DISABLE_DOWNLOAD_SOURCE_ARCHIVES = true;
        ENABLE_ARCHIVE = false;
      };
      log.LEVEL = "Error";
      webhook.ALLOWED_HOST_LIST = "*.devel.rtinf.net";
      metrics.ENABLED = true;
    };
  };
  services.anubis = {
    defaultOptions.settings = {
      USER_DEFINED_DEFAULT = true;
    };
    instances = {
      "anubis".settings = {
        TARGET = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}";
        BIND = "/run/anubis/anubis-anubis/anubis.sock";
        METRICS_BIND = "/run/anubis/anubis-anubis/anubis-metrics.sock";
        DIFFICULTY = 4;
        USER_DEFINED_INSTANCE = true;
        OG_PASSTHROUGH = true;
        SERVE_ROBOTS_TXT = true;
      };
    };
  };
  users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];
  services.nginx.virtualHosts."${DOMAIN}" = {
    locations."/" = {
      proxyPass = "http://unix:${config.services.anubis.instances."anubis".settings.BIND}";
      proxyWebsockets = true;
    };
    locations."/metrics" = {
      return = "302 https://${DOMAIN}/404";
    };
    forceSSL = true;
    enableACME = true;
  };
  environment.systemPackages = [ cfg.package ];
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
