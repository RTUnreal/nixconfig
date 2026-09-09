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
      publicKey = "WOK45dyiWOqROeLUdUA5zpqTkXxDnwTiXMMDvx0cCGc=";
      ip = "10.69.0.3";
    };
    phone = {
      publicKey = "nAD9372w6USjUbkZ/Cl1urLaeA1C/zKMBZ18wq2j0A4=";
      ip = "10.69.0.4";
    };
    runner = {
      publicKey = "yp42nJUsrCyzYMa5X1nOQrVKLB+qjoQIFk6xV7nS+lg=";
      ip = "10.69.0.5";
    };
  };
}
