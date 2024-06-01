{config, ...}: let
  host = "mango.user-sites.de";
  cfg = config.services.kavita;
  ipAdress = "127.0.0.1";
in {
  services.kavita = {
    enable = true;
    tokenKeyFile = "/var/lib/kavita/TOKEN";
    settings.IpAddresses = "${ipAdress}";
  };
  users.users.kavita.extraGroups = ["nextcloud"];
  services.nginx = {
    enable = true;
    virtualHosts."${host}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyWebsockets = true;
        proxyPass = "http://${ipAdress}:${toString cfg.settings.Port}";
      };
    };
  };
}
