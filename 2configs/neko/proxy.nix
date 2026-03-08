{
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p udp -d 49.12.205.30 --dport 52000:52100 -j DNAT --to-destination 10.69.0.2:52000-52100
  '';
  services.nginx.virtualHosts."neko.rtinf.net" = {
    locations."/" = {
      proxyPass = "http://10.69.0.2:3023";
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
      # TODO: make smaller
      allowedCIDRS = [ "10.69.0.0/24" ];
    };
  };

  networking.firewall.interfaces."veth3".allowedTCPPorts = [ 8888 ];
}
