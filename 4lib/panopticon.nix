{
  network = {
    meta = {
      listenPort = 51821;
      ingressHost = "network.user-sites.de";
      ingress = "safe";
      egress = "";
      isLocal = true;
      base = "10.70.0.0/24";
    };
    hosts = {
      safe = {
        publicKey = "VuR6HUxyeAMCQuIpy/ovGrZOysTXH1ZbY0mVFmRASUI=";
        ip = "10.70.0.1";
      };
      spinner = {
        publicKey = "NT/jgwccCfcJ9p+1Xmxg11QCU5I8P0Vcpdtos65fExs=";
        ip = "10.70.0.2";
      };
      devel = {
        publicKey = "a3W0khjijjXyjXwe6sfQ0TawQzDMLafCPve2topUFA0=";
        ip = "10.70.0.3";
      };
    };
  };
  scrapeConfigs =
    let
      single = job_name: target: {
        inherit job_name;
        static_configs = [ { targets = [ target ]; } ];
      };
    in
    [
      (single "node_safe" "10.70.0.1:9100")
      (single "node_devel" "10.70.0.3:9100")
      (single "forgejo" "10.70.0.3:3002")
      (single "pinger" "10.70.0.1:9199")
    ];
}
