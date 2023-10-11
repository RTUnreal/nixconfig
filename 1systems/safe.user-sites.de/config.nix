{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../2configs/base.nix
      ./../../2configs/base-server.nix
      ./../../2configs/safe
      ./../../2configs/mango.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" ];
  };

  networking = {
    hostName = "safe";
    domain = "user-sites.de";

    useDHCP = false;
    interfaces.enp1s0.useDHCP = true;
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAWBFNy2N6Exx7tHlbUDXERJjT7PhIs+vZIWPmhh3qLieeC1tAOf9XcbgVGL3bAryyaCEr1s2bZ6rs2L1JgFFJEGE9TCbfl2dfJIslCPP4OmKxwciIo+T4eXbanGDV0hzW+/vvMyQeWcVT27BrANYR7R28nURmXa1aQ9nWdnHy1Evuv4fI/e+6o3AKEji6Spl5FHs3T9+5vrEwsdq7Mewbfel6gAb3xmp9DIR0Kz0QnitwwErcZYgA2o64C6DLNgsG2l1PrZxE3/MaB6FyzCyOfU8C0FovWlvmmOXkwFPZz1HN1KkKZKV50H4ffiN0cVSLBt6NW6s0v7TWhJyrbIEr trr@spinner"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOQJOT6cBwg5xXHR+zpS7+VMcx4F73Qm+X4cWaFqRp+g5ru0M/xb+T2icX189j0qWe3BwpftupzaHy7h4sZRTIcRGwlu8LRGFY1WpL8ftgvWCG45ZD3Lp1nX3XpOfBTZD+XYoNOWVM4kuL/+wWYGQYKzo4Ui3kKFEPo0hrShN7GEMim76Xm3m7sldGW0vBzSk8DpLykDLt+RxrLeY2xGI112fjAVvaWn82KE+kflaQIF5XZNVPFqNTMvhRL+ZHTal1SeN3i2TdcbxV9DMLQ/s5bcSLatae/SMlYqNipTpX+lodBqc0d7e0LfwYJERkAHB0NX3TfQPB5tB8EReGMoOm2m0TPdIRGhaEAM5abB5cQr3KV/r2BAVTrcA6ij2f2GszVNNllhHQHvpv5RZUw8+htvFbaTv0Ww+3X1CY/B+hQQ9st4DIfC0o2or38BE1cn90mqfqvl1s/uplkX3ToYo8PU8j0SqVtBWNq/E7lHecTIZqUL5NX32xUnXvjmhZgtU= trr@runner"
  ];

  environment.systemPackages = [
    (pkgs.writeScriptBin "upgrade-pg-cluster" ''
      set -eux
      # XXX it's perhaps advisable to stop all services that depend on postgresql
      systemctl stop postgresql

      # XXX replace `<new version>` with the psqlSchema here
      export NEWDATA="/var/lib/postgresql/14"

      # XXX specify the postgresql package you'd like to upgrade to
      export NEWBIN="${pkgs.postgresql_14}/bin"

      export OLDDATA="${config.services.postgresql.dataDir}"
      export OLDBIN="${config.services.postgresql.package}/bin"

      install -d -m 0700 -o postgres -g postgres "$NEWDATA"
      cd "$NEWDATA"
      sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

      sudo -u postgres $NEWBIN/pg_upgrade \
        --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
        --old-bindir $OLDBIN --new-bindir $NEWBIN \
        "$@"
    '')
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
