{pkgs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      mpv = prev.mpv.override {
        scripts = [final.mpvScripts.mpris];
      };
    })
  ];

  environment.systemPackages = with pkgs; [mpv];
}
