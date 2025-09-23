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
    types
    mkIf
    optionalString
    concatMapStrings
    nameValuePair
    ;

  cfg = config.rtinf.dirtickvpn;

  enable = builtins.length (builtins.attrNames cfg.interfaces) > 0;

  wireguardConfig =
    name: wgConf:
    let
      meta = wgConf.meta.meta;
      ownCfg = wgConf.meta.hosts.${wgConf.hostName};

      isIngress = wgConf.hostName == meta.ingress;
      isEgress = wgConf.hostName == meta.egress;
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
          + optionalString (wgConf.connectOutside != null) (
            let
              inherit (wgConf.connectOutside)
                vethInside
                vethOutside
                vethInsideAddress
                vethOutsideAddress
                vethPrefixLength
                forwardedTcpPorts
                ;
            in
            # sh
            ''
              ip link add ${vethInside} type veth peer name ${vethOutside} || true
              ip link set ${vethInside} netns ${name} || true
              ip netns exec ${name} ip addr add ${vethInsideAddress}/${toString vethPrefixLength} dev ${vethInside} || true
              ip addr add ${vethOutsideAddress}/${toString vethPrefixLength} dev ${vethOutside} || true
              ip route add ${wgConf.meta.meta.base} dev ${name} || true
              ip netns exec ${name} iptables -t nat -A POSTROUTING -o ${name} -j MASQUERADE || true
              ${concatMapStrings (v: ''
                iptables -t nat -A PREROUTING -p tcp -i ${name} --dport 6000 -j DNAT --to-destination 192.168.0.2:8080
              '') forwardedTcpPorts}
            ''
          )
        else if isEgress then
          # sh
          ''
            ${pkgs.iptables}/bin/iptables -A FORWARD -i ${name} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${meta.base} -o ${cfg.egressInterfaceName} -j MASQUERADE
          ''
        else
          "";

      postShutdown =
        if isIngress then
          # sh
          ''
            ip netns del ${name} || true
          ''
          + optionalString (wgConf.connectOutside != null) (
            let
              inherit (wgConf.connectOutside) vethInside vethOutside;
            in
            # sh
            ''
              ip netns exec ${name} ip link del ${vethInside} down || true
              ip link del ${vethOutside} down || true
            ''
          )
        else if isEgress then
          # sh
          ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i ${name} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${meta.base} -o ${cfg.egressInterfaceName} -j MASQUERADE
          ''
        else
          "";

      peers =
        let
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
    };
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
              '';
            };

            connectOutside = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    vethInside = mkOption {
                      type = types.str;
                      default = "veth0";
                      example = "intel_backlight";
                      description = lib.mdDoc "interface name inside of netns";
                    };
                    vethInsideAddress = mkOption {
                      type = types.str;
                      default = "192.168.0.1";
                      description = ''
                        IPv4 address of the interface.
                      '';
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
                      description = ''
                        IPv4 address of the interface.
                      '';
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
                      description = ''
                        List of TCP ports on which incoming connections are
                        forwarded.
                      '';
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
        interfaces = builtins.mapAttrs wireguardConfig cfg.interfaces;
      };
    };
    systemd.services = mkIf config.systemd.network.enable (
      builtins.listToAttrs (
        builtins.map (name: nameValuePair "wireguard-${name}" { after = [ "systemd-networkd.service" ]; }) (
          builtins.attrNames cfg.interfaces
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
