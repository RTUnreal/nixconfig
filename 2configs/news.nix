{...}: {
  services = {
    miniflux = {
      enable = true;
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
