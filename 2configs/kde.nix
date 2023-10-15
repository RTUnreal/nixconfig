{pkgs, ...}: {
  services.xserver = {
    # Enable the Plasma 5 Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma5 = {
      enable = true;
      kdeglobals = {
        KDE = {
          SingleClick = false;
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    kate
    kcalc
    okular
    gwenview
    ark
    spectacle
    okteta
    filelight
    kalendar
    qpwgraph
  ];
}
