{ ... }:
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
  virtualisation.docker.enable = true;
  services.gitlab-runner = {
    enable = true;
    settings = {
      concurrent = 10;
    };
    services = {
      default = {
        authenticationTokenConfigFile = "/var/lib/gitlab-runner/runner_auth_env";
        limit = 10;
        dockerImage = "debian:stable";
        dockerPrivileged = true;
        dockerVolumes = [ "/cache" ];
      };
    };
  };
}
