{ selflib, ... }:
{
  virtualisation.oci-containers.containers = {
    neko = {
      image = "m1k1o/neko:firefox";
      autoStart = true;
      extraOptions = [
        "--pull=newer"
        "-l=homepage.group=Services"
        "-l=homepage.name=Neko"
        "-l=homepage.icon=neko.svg"
        "-l=homepage.href=http://neko.rtinf.net:3023"
        "-l=homepage.description=Remote browser service with Firefox"
      ];
      ports = [
        "3023:8080"
        "52000-52100:52000-52100/udp"
      ];
      environment = {
        NEKO_SCREEN = "1280x720@30";
        NEKO_EPR = "52000-52100";
        NEKO_ICELITE = "0";
        NEKO_SERVER_PROXY = "true";
        NEKO_NAT1TO1 = "192.168.0.101";
        NEKO_CAPTURE_BROADCAST_URL = "rtmp://${selflib.homevpn.hosts.safe.ip}/live/neko";
      };
      environmentFiles = [ "/var/lib/neko/.env" ];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [ 3023 ];
    allowedUDPPortRanges = [
      {
        from = 52000;
        to = 52100;
      }
    ];
  };
}
