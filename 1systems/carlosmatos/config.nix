{...}: {
  imports = [
    ./hardware-configuration.nix
  ];
  rtinf = {
    base.systemType = "desktop";
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  system.stateVersion = "24.05";
}
