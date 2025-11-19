{
  meta = {
    listenPort = 51823;
    ingressHost = "network.user-sites.de";
    ingress = "safe";
    egress = "egress";
    base = "10.3.246.0/24";
  };
  hosts = {
    safe = {
      publicKey = "siQtQhkl8kMnZNermRIZimq94b8eb9R43JzPD9bYvDI=";
      ip = "10.3.246.2";
    };
    egress = {
      publicKey = "jV4njLpf7amNfusT4ISodjdP0AG2vJwEeRkRchoz/wk=";
      ip = "10.3.246.1";
    };
    worker = {
      publicKey = "0UK71yn7ksnC5HgnxpBlYNWfhoLD0ayaVCzipyPfKk4=";
      ip = "10.3.246.3";
    };
  };
}
