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
    };
  };
  scrapeConfigs = [
    {
      job_name = "node";
      static_configs = [
        {
          targets = [
            "10.70.0.1:9100"
          ];
        }
      ];
    }
  ];
}
