{...}: {
  networking.retiolum.ipv4 = "10.243.20.24";
  networking.retiolum.ipv6 = "42:0:3c46:984c:8136:5e94:e2a0:f6e2";
  networking.retiolum.nodename = "rtworker";
  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "/etc/nixos/retiolum-cfg/rsa_key.priv";
    ed25519PrivateKeyFile = "/etc/nixos/retiolum-cfg/ed25519_key.priv";
  };
}
