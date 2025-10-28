{
  config,
  nixpkgs-unstable,
  pkgs,
  ...
}:
let
  domain = "buildbot.rtinf.net";
  cfg = config.services.buildbot-master;
  secretDir = "/home/buildbot/master/secrets";
in
{
  services = {
    buildbot-nix.packages = {
      buildbot = nixpkgs-unstable.buildbot;
      buildbot-worker = nixpkgs-unstable.buildbot-worker;
      buildbot-plugins = nixpkgs-unstable.buildbot-plugins;
    };
    buildbot-nix.master = {
      enable = true;
      inherit domain;
      useHTTPS = true;

      workersFile = "${secretDir}/workers.json";
      admins = [ "unreal" ];

      authBackend = "gitea";
      gitea = {
        enable = true;
        instanceUrl = "https://devel.rtinf.net";
        oauthId = "4d4cdcae-a7a1-4580-95d7-e791492f13ba";
        oauthSecretFile = "${secretDir}/client_secret";
        webhookSecretFile = "${secretDir}/webhook_secret";
        tokenFile = "${secretDir}/token";
        topic = "buildbot-nix";
      };
    };
    buildbot-nix.worker = {
      enable = true;
      workerPasswordFile = "/home/bbworker/worker/secret/password";
    };
  };

  systemd.services.buildbot-master.environment.SSL_CERT_DIR =
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
  };
}
