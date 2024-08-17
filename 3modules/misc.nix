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
    adb = mkEnableOption "adb";
    bluetooth = mkEnableOption "bluetooth";
    docker = mkEnableOption "docker support";
    mpv = mkEnableOption "mpv";
    wacom = mkEnableOption "wacom support";
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
    (mkIf cfg.adb {
      programs.adb.enable = true;
      users.users.trr.extraGroups = ["adbusers"];
    })
    (mkIf cfg.docker {
      virtualisation.docker.enable = true;
      users.users.trr.extraGroups = ["docker"];
    })
    (mkIf cfg.wacom {
      services.xserver.wacom.enable = true;
    })
  ];
}
