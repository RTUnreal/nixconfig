{...}: {
  networking.retiolum.ipv4 = "10.243.20.18";
  networking.retiolum.ipv6 = "42:0:3c46:7109:4c9a:3c86:73e0:a786";
  networking.retiolum.nodename = "rtworker";
  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "/etc/nixos/retiolum-cfg/rsa_key.priv";
    ed25519PrivateKeyFile = "/etc/nixos/retiolum-cfg/ed25519_key.priv";
  };
}
