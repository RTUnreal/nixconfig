{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.forgejo;
  DOMAIN = config.networking.fqdn;
  HTTP_PORT = 3002;
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
      default.APP_NAME = "${DOMAIN}: My Dumbest Gitea instance";
      server = {
        inherit DOMAIN HTTP_PORT;
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
    };
  };
  services.anubis = {
    defaultOptions.settings = {
      USER_DEFINED_DEFAULT = true;
    };
    instances = {
      "anubis".settings = {
        TARGET = "http://localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}";
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
    forceSSL = true;
    enableACME = true;
  };
  environment.systemPackages = [ cfg.package ];
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
