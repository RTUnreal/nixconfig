{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.kernelModules = [ "kvm-amd" ];
  fileSysyems."/" = {
    device = "/dev/disk/by-name/nixos";
    fsType = "ext4";
  };
  fileSysyems."/boot" = {
    device = "/dev/disk/by-name/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  nixpkgs.hostPaltform = "x86_64-linux";
}
