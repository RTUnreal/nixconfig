# based on: https://www.procustodibus.com/blog/2022/06/multi-hop-wireguard/#internet-gateway-as-a-spoke
# TODO: support ipv6?
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    optionalString
    optionalAttrs
    concatMapStrings
    concatStringsSep
    nameValuePair
    filterAttrs
    mapAttrs
    ;

  cfg = config.rtinf.dirtickvpn;

  enable = builtins.length (builtins.attrNames cfg.interfaces) > 0;

  # interfaces managed by NetworkManager vs. the NixOS wireguard module
  nmInterfaces = filterAttrs (_: i: i.networkManager.enable) cfg.interfaces;
  kernelInterfaces = filterAttrs (_: i: !i.networkManager.enable) cfg.interfaces;

  hostInfo =
    wgConf:
    let
      meta = wgConf.meta.meta;
    in
    {
      inherit meta;
      ownCfg = wgConf.meta.hosts.${wgConf.hostName};
      isIngress = wgConf.hostName == meta.ingress;
      isEgress = wgConf.hostName == meta.egress;
    };

  # backend-independent peer list:
  # [ { publicKey, allowedIPs, endpoint?, persistentKeepalive? } ]
  peersOf =
    wgConf:
    let
      inherit (hostInfo wgConf) meta isIngress isEgress;

      ingress =
        peerName: peerCfg:
        if !meta.isLocal && peerName == meta.egress then
          { allowedIPs = [ "0.0.0.0/0" ]; }
        else
          { allowedIPs = [ "${peerCfg.ip}/32" ]; };

      egress =
        peerName: _peerCfg:
        if peerName == meta.ingress then
          {
            allowedIPs = [ meta.base ];
            endpoint = "${meta.ingressHost}:${toString meta.listenPort}";
            persistentKeepalive = 25;
          }
        else
          null;

      default =
        peerName: _peerCfg:
        if peerName == meta.ingress then
          {
            allowedIPs = [ meta.base ];
            endpoint = "${meta.ingressHost}:${toString meta.listenPort}";
            persistentKeepalive = 25;
          }
        else
          null;

      peer =
        if isEgress then
          egress
        else if isIngress then
          ingress
        else
          default;
    in
    builtins.filter (x: x != null) (
      builtins.attrValues (
        builtins.mapAttrs (
          peerName: peerCfg:
          let
            specific = if wgConf.hostName == peerName then null else peer peerName peerCfg;
          in
          if specific == null then null else { inherit (peerCfg) publicKey; } // specific
        ) wgConf.meta.hosts
      )
    );

  wireguardConfig =
    name: wgConf:
    let
      inherit (hostInfo wgConf)
        meta
        ownCfg
        isIngress
        isEgress
        ;
    in
    {
      ips = [ "${ownCfg.ip}/32" ];
      inherit (meta) listenPort;

      inherit (wgConf) privateKeyFile;

      interfaceNamespace = mkIf isIngress name;
      preSetup =
        if isIngress then
          # sh
          ''
            ip netns add ${name} || true
          ''
        else if isEgress then
          # sh
          ''
            ${pkgs.iptables}/bin/iptables -A FORWARD -i ${name} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${meta.base} -o ${cfg.egressInterfaceName} -j MASQUERADE
          ''
        else
          "";

      postSetup =
        if isIngress && wgConf.connectOutside != null then
          let
            inherit (wgConf.connectOutside)
              vethInside
              vethOutside
              vethInsideAddress
              vethOutsideAddress
              vethNetwork
              vethPrefixLength
              forwardedTcpPorts
              ;
          in
          # sh
          ''
            echo "add veth"
            ip link add ${vethInside} type veth peer name ${vethOutside} || true
            echo "set veth netns"
            ip link set dev ${vethInside} netns ${name} || true
            echo "add vethinside addr"
            ip netns exec ${name} ip addr add ${vethInsideAddress}/${toString vethPrefixLength} dev ${vethInside} || true
            echo "set vethoutside addr"
            ip addr add ${vethOutsideAddress}/${toString vethPrefixLength} dev ${vethOutside} || true
            echo "vetinside up"
            ip netns exec ${name} ip link set dev ${vethInside} up || true
            echo "vetoutside up"
            ip link set ${vethOutside} up || true
            echo "add vethinside route"
            #ip netns exec ${name} ip route add ${vethNetwork}/${toString vethPrefixLength} dev ${vethInside} || true
            echo "set vethoutside route"
            ip route add ${wgConf.meta.meta.base} via ${vethInsideAddress} dev ${vethOutside} src ${vethOutsideAddress} || true
            ip netns exec ${name} ${pkgs.iptables}/bin/iptables -t nat -A PREROUTING -j LOG --log-level 4 --log-prefix "[PREROUTING]"
            ip netns exec ${name} ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -j LOG --log-level 4 --log-prefix "[POSTROUTING]"
            ip netns exec ${name} ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o ${name} -s ${vethOutsideAddress} -j SNAT --to-source ${ownCfg.ip}
            ${concatMapStrings (v: ''
              ip netns exec ${name} ${pkgs.iptables}/bin/iptables -t nat -A PREROUTING -p tcp -i ${name} -d ${ownCfg.ip} --dport ${toString v} -j DNAT --to-destination ${vethOutsideAddress}:${toString v}
            '') forwardedTcpPorts}
          ''
        else
          "";

      postShutdown =
        if isIngress then
          optionalString (wgConf.connectOutside != null) (
            let
              inherit (wgConf.connectOutside) vethInside vethOutside;
            in
            # sh
            ''
              ip netns exec ${name} ip link del ${vethInside} down || true
              ip link del ${vethOutside} down || true
            ''
          )
          # sh
          + ''
            ip netns del ${name} || true
          ''
        else if isEgress then
          # sh
          ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i ${name} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${meta.base} -o ${cfg.egressInterfaceName} -j MASQUERADE
          ''
        else
          "";

      peers = peersOf wgConf;
    };

  # deterministic UUID so the profile keeps its identity across rebuilds
  mkUuid =
    name:
    let
      h = builtins.hashString "md5" "dirtickvpn-${name}";
      s = start: len: builtins.substring start len h;
    in
    "${s 0 8}-${s 8 4}-${s 12 4}-${s 16 4}-${s 20 12}";

  # NetworkManager connection profile (keyfile format) for ensureProfiles
  networkManagerProfile =
    name: wgConf:
    let
      inherit (hostInfo wgConf) meta ownCfg;
    in
    {
      connection = {
        id = name;
        uuid = mkUuid name;
        type = "wireguard";
        interface-name = name;
        autoconnect = wgConf.networkManager.autoconnect;
      };
      wireguard = {
        # substituted by ensureProfiles from the environment file(s)
        private-key = "$" + wgConf.networkManager.privateKeyEnvVar;
        listen-port = meta.listenPort;
      };
      ipv4 = {
        method = "manual";
        address1 = "${ownCfg.ip}/32";
      };
      ipv6.method = "ignore";
    }
    // builtins.listToAttrs (
      map (
        p:
        nameValuePair "wireguard-peer.${p.publicKey}" (
          {
            # NM wants a trailing semicolon on lists
            allowed-ips = concatStringsSep ";" p.allowedIPs + ";";
          }
          // optionalAttrs (p ? endpoint) { inherit (p) endpoint; }
          // optionalAttrs (p ? persistentKeepalive) { persistent-keepalive = p.persistentKeepalive; }
        )
      ) (peersOf wgConf)
    );
in
{
  options.rtinf.dirtickvpn = {
    interfaces = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            meta = mkOption {
              type = types.submodule {
                options = {
                  meta = {
                    listenPort = mkOption {
                      type = types.port;
                    };

                    ingressHost = mkOption {
                      type = types.str;
                    };

                    ingress = mkOption {
                      type = types.str;
                    };

                    egress = mkOption {
                      type = types.str;
                    };

                    base = mkOption {
                      type = types.str;
                    };
                    isLocal = mkOption {
                      type = types.bool;
                      default = false;
                    };
                  };
                  hosts = mkOption {
                    type = types.attrsOf (
                      types.submodule {
                        options = {
                          publicKey = mkOption {
                            type = types.str;
                          };

                          ip = mkOption {
                            type = types.str;
                          };
                        };
                      }
                    );
                  };
                };
              };
              default = null;
              description = lib.mdDoc "Set the vpn meta to follow. `null` to disable.";
            };

            hostName = mkOption {
              type = types.str;
              default = config.networking.hostName;
              defaultText = "config.networking.hostName";
            };

            privateKeyFile = mkOption {
              example = "/private/wireguard_key";
              type = types.nullOr types.str;
              default = null;
              description = ''
                Private key file as generated by {command}`wg genkey`.
                Not used when `networkManager.enable` is set; see
                `networkManager.environmentFile` instead.
              '';
            };

            networkManager = {
              enable = mkEnableOption ''
                managing this interface with NetworkManager (via a connection profile
                in `networking.networkmanager.ensureProfiles`) instead of the NixOS
                wireguard module. Only supported for spoke hosts (neither ingress nor egress)
              '';

              autoconnect = mkOption {
                type = types.bool;
                default = true;
                description = "Whether NetworkManager activates the connection automatically.";
              };

              privateKeyEnvVar = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "DIRTICKVPN_PRIVATE_KEY";
                description = ''
                  Name of the environment variable holding the WireGuard private key.
                  Must be set when `networkManager.enable` is true.
                  The profile references it as `$VAR`, and ensureProfiles substitutes it
                  from {option}`networkManager.environmentFile` at activation time,
                  which keeps the key out of the world-readable Nix store.
                '';
              };

              environmentFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                example = "/run/secrets/dirtickvpn.env";
                description = ''
                  File containing `VAR=<private key>` (VAR being `privateKeyEnvVar`).
                  Added to `networking.networkmanager.ensureProfiles.environmentFiles`.
                '';
              };
            };

            connectOutside = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    vethInside = mkOption {
                      type = types.str;
                      default = "veth0";
                      description = lib.mdDoc "interface name inside of netns";
                    };
                    vethInsideAddress = mkOption {
                      type = types.str;
                      default = "192.168.0.1";
                      description = "IPv4 address of the interface.";
                    };

                    vethOutside = mkOption {
                      type = types.str;
                      default = "veth1";
                      example = "intel_backlight";
                      description = lib.mdDoc "interface name outside of netns";
                    };
                    vethOutsideAddress = mkOption {
                      type = types.str;
                      default = "192.168.0.2";
                      description = "IPv4 address of the interface.";
                    };
                    vethNetwork = mkOption {
                      type = types.str;
                      default = "192.168.0.0";
                      description = "IPv4 prefix of the interface.";
                    };
                    # https://github.com/NixOS/nixpkgs/blob/b2a3852bd078e68dd2b3dfa8c00c67af1f0a7d20/nixos/modules/tasks/network-interfaces.nix#L83-L89
                    vethPrefixLength = mkOption {
                      type = types.addCheck types.int (n: n >= 0 && n <= 32);
                      default = 29;
                      description = "Subnet mask of the veth interfaces, specified as the number of bits in the prefix (`24`).";
                    };
                    forwardedTcpPorts = mkOption {
                      type = lib.types.listOf lib.types.port;
                      default = [ ];
                      apply = ports: lib.unique (builtins.sort builtins.lessThan ports);
                      example = [
                        22
                        80
                      ];
                      description = "List of TCP ports on which incoming connections are forwarded.";
                    };
                  };
                }
              );
              default = null;
              description = lib.mdDoc "enable connection to internal services for ingress. `null` to disable. has no effect if not ingress.";
            };
          };
        }
      );
      default = { };
    };
    egressInterfaceName = mkOption {
      type = types.str;
      default = "eth0";
    };
  };

  config = mkIf enable {
    assertions =
      (lib.mapAttrsToList (name: i: {
        assertion =
          let
            info = hostInfo i;
          in
          !(info.isIngress || info.isEgress);
        message = "rtinf.dirtickvpn.interfaces.${name}: networkManager.enable is only supported on spoke hosts (neither ingress nor egress), since the netns/veth/NAT setup needs the NixOS wireguard module.";
      }) nmInterfaces)
      ++ (lib.mapAttrsToList (name: i: {
        assertion = i.networkManager.privateKeyEnvVar != null;
        message = "rtinf.dirtickvpn.interfaces.${name}: networkManager.privateKeyEnvVar must be set when networkManager.enable is true.";
      }) nmInterfaces)
      ++ [
        {
          assertion = nmInterfaces == { } || config.networking.networkmanager.enable;
          message = "rtinf.dirtickvpn: networkManager.enable requires networking.networkmanager.enable = true.";
        }
      ];

    networking = {
      nat =
        mkIf (builtins.any (i: i.meta.meta.egress == i.hostName) (builtins.attrValues cfg.interfaces))
          {
            enable = true;
            #enableIPv6 = true;
            externalInterface = cfg.egressInterfaceName;
            internalInterfaces = builtins.filter (x: x != null) (
              builtins.attrValues (
                builtins.mapAttrs (name: i: if i.meta.meta.egress == i.hostName then name else null) cfg.interfaces
              )
            );
          };
      firewall = {
        allowedUDPPorts = map (i: i.meta.meta.listenPort) (builtins.attrValues cfg.interfaces);
      };
      wireguard = {
        useNetworkd = false;
        interfaces = builtins.mapAttrs wireguardConfig kernelInterfaces;
      };
      networkmanager.ensureProfiles = mkIf (nmInterfaces != { }) {
        environmentFiles = builtins.filter (x: x != null) (
          map (i: i.networkManager.environmentFile) (builtins.attrValues nmInterfaces)
        );
        profiles = mapAttrs networkManagerProfile nmInterfaces;
      };
    };
    systemd.services = mkIf config.systemd.network.enable (
      builtins.listToAttrs (
        map (name: nameValuePair "wireguard-${name}" { after = [ "systemd-networkd.service" ]; }) (
          builtins.attrNames kernelInterfaces
        )
      )
    );

    boot.kernel.sysctl =
      mkIf
        (builtins.any (i: i.meta.meta.ingress == i.hostName || i.meta.meta.egress == i.hostName) (
          builtins.attrValues cfg.interfaces
        ))
        {
          "net.ipv4.ip_forward" = true;
        };
  };
}
