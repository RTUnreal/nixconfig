{ pkgs, ... }: {
  services.nginx = {
    virtualHosts = {
      "rtinf.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          root = pkgs.writeTextFile {
            name = "rtinf-root";
            text = ''
              <h1>Stuff is being build here</h1>
              <p>RTInf is comming</p>
              <p>Eine Seite von Alexander Gaus</p>
            '';
            destination = "/index.html";
          };
        };
      };
    };
  };
}
