{
  config,
  pkgs,
  lib,
  ...
}:
# See: https://gist.github.com/techhazard/1be07805081a4d7a51c527e452b87b26
let
  inherit (lib) mkOption mkEnableOption types mkIf mkMerge;
  cfg = config.rtinf.virtualisation;
in {
  options.rtinf.virtualisation = {
    enable = mkEnableOption "virtualisation";

    cpuType = mkOption {
      description = "One of `intel` or `amd`";
      default = "intel";
      type = types.enum ["intel" "amd"];
    };

    libvirtUsers = mkOption {
      description = "Extra users to add to libvirtd (root is already included)";
      type = types.listOf types.str;
      default = ["trr"];
    };

    pciPassthrough = mkEnableOption "PCI Passthrough";

    pciPassthroughIDs = mkOption {
      description = "Comma-separated list of PCI IDs to pass-through";
      type = types.list (types.strMatching "[0-9a-z]{4}:[0-9a-z]{4}");
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      boot.kernelParams = ["${cfg.cpuType}_iommu=on"];

      environment.systemPackages = with pkgs; [
        virtmanager
        qemu
        OVMF
      ];

      users.groups.libvirtd.members = ["root"] ++ cfg.libvirtUsers;

      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          #package = pkgs.qemu_kvm;
          verbatimConfig = ''
            nvram = [
            "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
            ]
          '';
        };
      };
    }
    (mkIf cfg.pciPassthrough {
      # These modules are required for PCI passthrough, and must come before early modesetting stuff
      boot = {
        kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
        extraModprobeConfig = "options vfio-pci ids=${builtins.concatStringsSep "," cfg.pciIDs}";
      };
    })
  ]);
}
