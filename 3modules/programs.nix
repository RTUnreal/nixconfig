{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkMerge mkIf mkEnableOption;
in {
  options.rtinf.programs = {
    mpv = mkEnableOption "mpv";
  };
  config = mkMerge [
    (mkIf false {
      nixpkgs.overlays = [
        (final: prev: {
          mpv = prev.mpv.override {
            scripts = [final.mpvScripts.mpris];
          };
        })
      ];

      environment.systemPackages = with pkgs; [mpv];
    })
  ];
}
