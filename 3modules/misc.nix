{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkMerge mkIf mkEnableOption;

  cfg = config.rtinf.misc;
in {
  options.rtinf.misc = {
    mpv = mkEnableOption "mpv";
    bluetooth = mkEnableOption "bluetooth";
  };
  config = mkMerge [
    (mkIf cfg.mpv {
      nixpkgs.overlays = [
        (final: prev: {
          mpv = prev.mpv.override {
            scripts = [final.mpvScripts.mpris];
          };
        })
      ];

      environment.systemPackages = with pkgs; [mpv];
    })
    (mkIf cfg.bluetooth {
      hardware.bluetooth = {
        enable = true;
        settings = {
          General = {
            Experimental = true;
          };
        };
      };
    })
  ];
}
