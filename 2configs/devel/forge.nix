{ config, pkgs, lib, ... }:
let
  cfg = config.services.gitea;
  domain = config.networking.fqdn;
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

  services.gitea = {
    enable = true;
    package = pkgs.forgejo;
    user = "git";
    appName = "${domain}: My Dumbest Gitea instance";
    database.user = "git";
    settings = {
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
      proxyPass = "http://unix:/run/gitea/gitea.sock";
      proxyWebsockets = true;
    };
    forceSSL = true;
    enableACME = true;
  };
  environment.systemPackages = [ cfg.package ];
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
