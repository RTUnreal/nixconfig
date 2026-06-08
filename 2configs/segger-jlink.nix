{ pkgs, ... }:
{
  nixpkgs.config.segger-jlink.acceptLicense = true;
  environment.systemPackages = [ pkgs.segger-jlink ];
  services.udev.packages = [ pkgs.segger-jlink ];
}
