{ ... }:
{
  services = {
    miniflux = {
      enable = true;
      adminCredentialsFile = "/root/test";
      config = {
        BASE_URL = "https://news.user-sites.de/";
      };
    };

    nginx.virtualHosts."news.user-sites.de" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
      forceSSL = true;
      enableACME = true;
    };
  };
}
