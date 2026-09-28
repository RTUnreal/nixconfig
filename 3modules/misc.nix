{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkMerge mkIf mkEnableOption;

  cfg = config.rtinf.misc;
in
{
  options.rtinf.misc = {
    adb = mkEnableOption "adb";
    bluetooth = mkEnableOption "bluetooth";
    docker = mkEnableOption "docker support";
    mpv = mkEnableOption "mpv";
    virtualization = mkEnableOption "virtualization support";
    wacom = mkEnableOption "wacom support";
    riscv-nixbuild = mkEnableOption "RISC-V binfmt with nix sandbox";
  };
  config = mkMerge [
    (mkIf cfg.mpv {
      nixpkgs.overlays = [
        (final: prev: { mpv = prev.mpv.override { scripts = [ final.mpvScripts.mpris ]; }; })
      ];

      environment.systemPackages = [ pkgs.mpv ];
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
    })
    (mkIf cfg.docker {
      virtualisation.docker.enable = true;
      users.users.trr.extraGroups = [ "docker" ];
    })
    (mkIf cfg.virtualization {
      virtualisation.libvirtd.enable = true;
      users.users.trr.extraGroups = [ "libvirtd" ];
      environment.systemPackages = [ pkgs.virt-manager ];
    })
    (mkIf cfg.wacom { services.xserver.wacom.enable = true; })
    (mkIf cfg.riscv-nixbuild {
      boot.binfmt = {
        emulatedSystems = [ "riscv64-linux" ];
        addEmulatedSystemsToNixSandbox = true;
      };
    })
  ];
}
