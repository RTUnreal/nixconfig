{ config, ... }:
{
  services.hedgedoc = {
    enable = true;
    configureNginx = true;
    settings = {
      protocolUseSSL = true;
      domain = "pad.rtinf.net";

      email = true;
      allowEmailRegister = false;

      allowAnonymous = false;
      allowAnonymousEdits = true;
    };
  };
  services.nginx.virtualHosts.${config.services.hedgedoc.settings.domain} = {
    enableACME = true;
  };
}
