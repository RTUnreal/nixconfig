{ config, ... }: {
  services.hledger-web = {
    enable = true;
    baseUrl = "https://travel-ledger.rtinf.net";
    allow = "edit";
    journalFiles = [ "travel-ledger.journal" ];
  };
  services.nginx.virtualHosts."travel-ledger.rtinf.net" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.services.hledger-web.port}";
  };
}
