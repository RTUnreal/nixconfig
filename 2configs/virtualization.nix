{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  users.users.trr.extraGroups = [ "libvirtd" ];
  environment.systemPackages = with pkgs; [
    virt-manager
  ];
}
