{...}: {
  networking.retiolum.ipv4 = "10.243.20.22";
  networking.retiolum.ipv6 = "42:0:3c46:d00e:e9e8:5fc8:987d:252f";
  networking.retiolum.nodename = "rtrunner";
  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "/etc/nixos/retiolum-cfg/rsa_key.priv";
    ed25519PrivateKeyFile = "/etc/nixos/retiolum-cfg/ed25519_key.priv";
  };
}
