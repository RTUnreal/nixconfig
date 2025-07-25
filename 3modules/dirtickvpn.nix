# based on: https://www.procustodibus.com/blog/2022/06/multi-hop-wireguard/#internet-gateway-as-a-spoke
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
            if peerName == meta.egress then
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
