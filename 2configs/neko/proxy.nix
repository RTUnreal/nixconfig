{ selflib, ... }:
{
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p udp -d 49.12.205.30 --dport 52000:52100 -j DNAT --to-destination ${selflib.homevpn.hosts.spinner.ip}:52000-52100
  '';
  services.nginx.virtualHosts."neko.rtinf.net" = {
    locations."/" = {
      proxyPass = "http://${selflib.homevpn.hosts.spinner.ip}:3023";
      proxyWebsockets = true;
    };
    forceSSL = true;
    enableACME = true;
  };

  rtinf = {
    stream2 = {
      enable = true;
      domain = "stream.rtinf.net";
      hls = { };
      openFirewall = true;
    };
    stream.auth = {
      authDir = "/var/lib/rtmp-auth";
      allowedCIDRS = [ "${selflib.homevpn.hosts.spinner.ip}/32" ];
    };
  };

  networking.firewall.interfaces."veth3".allowedTCPPorts = [ 8888 ];
}
