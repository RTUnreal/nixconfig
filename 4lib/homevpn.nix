{
  meta = {
    listenPort = 51820;
    ingressHost = "network.user-sites.de";
    ingress = "safe";
    egress = "spinner";
    base = "10.69.0.0/24";
  };
  hosts = {
    safe = {
      publicKey = "SWA0lWwRroZBEudH1lcASIKMv/0ayL8S/KtmUXFdomI=";
      ip = "10.69.0.1";
    };
    spinner = {
      publicKey = "a9DSEaO+mkpBTaaOrwiZIyduDBXBYe73e0FwbfGim18=";
      ip = "10.69.0.2";
    };
    worker = {
      publicKey = "VOHbmF+DU/vYjDF1gDXNpmkBGgxRnCKWnSOrlJXMtwk=";
      ip = "10.69.0.3";
    };
    phone = {
      publicKey = "nAD9372w6USjUbkZ/Cl1urLaeA1C/zKMBZ18wq2j0A4=";
      ip = "10.69.0.4";
    };
  };
}
