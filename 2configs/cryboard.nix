{ config, ... }:
{
  services.whitebophir = {
    enable = true;
  };
  services.nginx.virtualHosts."cryboard.rtinf.net" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:5001";
  };
}
