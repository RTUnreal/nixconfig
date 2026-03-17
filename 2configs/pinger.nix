{ pkgs, nixpkgs-unstable, ... }:
let
  port = 3030;
  metricsPort = 9199;
  domain = "pinger.rtinf.net";

  templates = {
    grafana = # yaml
      ''
        title: |
          {{- if eq .status "firing" }}
          🚨 {{ .title | default "Alert firing" }}
          {{- else if eq .status "resolved" }}
          ✅ {{ .title | default "Alert resolved" }}
          {{- else }}
          ⚠️ Unknown alert: {{ .title | default "Alert" }}
          {{- end }}
        message: |
          {{ .message | trunc 2000 }}
      '';
  };
  template-dir = pkgs.symlinkJoin {
    name = "ntfy-template-dir";
    paths =
      builtins.attrValues (builtins.mapAttrs (key: val: pkgs.writeTextDir "${key}.yml" val) templates)
      ++ [ ];
  };
in
{
  services.ntfy-sh = {
    enable = true;
    # TODO: remove when 2.14.* hits stable
    package = nixpkgs-unstable.ntfy-sh;
    settings = {
      listen-http = ":${toString port}";
      base-url = "https://${domain}";
      behind-proxy = true;
      auth-default-access = "deny-all";
      inherit template-dir;
      metrics-listen-http = ":${toString metricsPort}";
    };
  };

  networking.firewall.interfaces."veth1".allowedTCPPorts = [ metricsPort ];
  services.nginx = {
    enable = true;
    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
      };
    };
  };
}
