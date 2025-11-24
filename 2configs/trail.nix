{
  services.paperless = {
    enable = true;
    database.createLocally = true;
    settings = {
      PAPERLESS_AUTO_LOGIN_USERNAME = "admin";
    };
    address = "0.0.0.0";
    port = 28981;
  };
  networking.firewall.allowedTCPPorts = [ 28981 ];
}
