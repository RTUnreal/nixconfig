{pkgs, ...}: let
  domain = "ci.devel.rtinf.net";
in {
  nixpkgs.overlays = [
    (_final: prev: {
      hydra_unstable = prev.hydra_unstable.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            (prev.fetchpatch {
              url = "https://github.com/NixOS/hydra/pull/1227.patch";
              sha256 = "sha256-A4dN/4zLMKLYaD38lu87lzAWH/3EUM7G5njx7Q4W47w=";
            })
            (prev.fetchpatch {
              url = "https://github.com/NixOS/hydra/pull/1232.patch";
              sha256 = "sha256-R5Pakyhf5Tw9Tc4iGmZ/xiVEHiCT0ITfYNGFEf2y3OE=";
            })
          ];
        doChecks = false;
      });
    })
  ];
  # FIXME: make range much smaller
  nix.extraOptions = ''
    allowed-uris = https://git.thalheim.io/Mic92/retiolum
  '';
  services.hydra = {
    enable = true;
    hydraURL = "https://${domain}";
    notificationSender = "hydra@${domain}";
    buildMachinesFiles = [];
    useSubstitutes = true;
    # FIXME: file might not be always available
    extraConfig = ''
      Include /var/lib/hydra/hydra-secrets.conf
    '';
  };
  services.nginx = {
    commonHttpConfig = ''
      geo $local {
        default "Authentication required";
        127.0.0.1 "off";
        ::1 "off";
      }
    '';
    virtualHosts."${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:3000";
        extraConfig = ''
          auth_basic $local;
          auth_basic_user_file ${pkgs.writeText "${domain}.htpasswd" ''
            hydra:{PLAIN}LfqvQwsdifsNyKbhyPcp5-yJVUj9Jmn-9fS
          ''};
        '';
      };
    };
  };
  networking.hosts = {
    "127.0.0.1" = ["${domain}"];
    "::1" = ["${domain}"];
  };
  programs.git.config = {
    credential."https://devel.rtinf.net" = {
      username = "hydra";
      helper = pkgs.writeShellScript "lmao-askpass" ''
        echo "password=cejU-qUoJ5MgWxY2gTVd4QNtngsU747VrxQ"
      '';
    };
  };
}
