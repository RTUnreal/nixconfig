{ config, pkgs, lib, ... }:
let
  domain = "buildbot.rtinf.net";
  client-id = "";
  client-secret = "";

in
{
  services = {
    buildbot-master = {
      enable = true;
      buildbotUrl = "https://${domain}/";
      extraConfig = ''
        from buildbot_gitea.auth import GiteaAuth
        c['www']['auth'] = GiteaAuth(
            endpoint="https://devel.rtinf.net",
            client_id='${client-id}',
            client_secret='${client-secret}')
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
  };
}
