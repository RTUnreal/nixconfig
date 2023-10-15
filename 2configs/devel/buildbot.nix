{
  config,
  pkgs,
  ...
}: let
  domain = "buildbot.rtinf.net";
  cfg = config.services.buildbot-master;
in {
  services = {
    buildbot-master = {
      enable = true;
      buildbotUrl = "https://${domain}/";
      # TODO: Rewrite when new config structure is added
      extraConfig = ''
        from buildbot_gitea.auth import GiteaAuth

        with open('${cfg.buildbotDir}/secrets/client_id', 'r') as f:
          oauth_client_id = f.read().strip()

        with open('${cfg.buildbotDir}/secrets/client_secret', 'r') as f:
          oauth_client_secret = f.read().strip()

        c['www']['auth'] = GiteaAuth(
            endpoint="https://devel.rtinf.net",
            client_id=oauth_client_id,
            client_secret=oauth_client_secret)

      '';
      packages = with pkgs; [
        cacert
      ];
      pythonPackages = pp: [
        (pp.buildPythonPackage rec {
          pname = "buildbot-gitea";
          version = "1.7.2";
          format = "setuptools";

          src = pp.fetchPypi {
            inherit pname version format;

            sha256 = "sha256-zfHq7xmvKKVl+OuEXvsQg2T23gJGbGl3rKeTkc/oFG0=";
          };

          nativeBuildInputs = with pp; [
            setuptools
            pkgs.buildbot
          ];

          doCheck = false;
        })
        pp.requests
      ];
    };
    buildbot-worker = {
      enable = true;
    };
  };

  systemd.services.buildbot-master.environment.SSL_CERT_DIR = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  services.nginx.virtualHosts."${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.buildbot-master.port}";
      proxyWebsockets = true;
    };
    forceSSL = true;
    enableACME = true;
  };
}
