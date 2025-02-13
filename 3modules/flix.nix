# thx lass
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    ;
  cfg = config.rtinf.flix;
in
{
  options.rtinf.flix = {
    enable = mkEnableOption "enable magnet";

    magnet = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            wgConfPath = mkOption {
              type = types.str;
              example = "/var/lib/";
              description = lib.mdDoc "`/sys/acpi/backlight` display name";
            };
          };
        }
      );
      default = null;
      description = lib.mdDoc "set laptop server specific configs. `null` to disable.";
    };

  };

  config = mkIf cfg.enable (mkMerge [
    {
      users.users.download = {
        isSystemUser = true;
        uid = 1001;
        group = "download";
      };
    }
    (mkIf (cfg.magnet != null) {
      users.groups.download.members = [ "transmission" ];

      services.transmission = {
        enable = true;
        home = "/var/state/transmission";
        group = "download";
        downloadDirPermissions = "775";
        settings = {
          download-dir = "/var/download/transmission";
          incomplete-dir-enabled = false;
          rpc-bind-address = "::";
          message-level = 1;
          umask = 18;
          rpc-whitelist-enabled = false;
          rpc-host-whitelist-enabled = false;
        };
      };

      # Transmission networking stuff
      # we need to set a namserver here that can be also be reached from the transmission network namespace
      environment.etc."resolv.conf".text = ''
        options edns0
        nameserver 9.9.9.9
      '';
      services.resolved.enable = lib.mkForce false;

      systemd.services."netns@" = {
        description = "%I network namespace";
        before = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
          ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
        };
      };

      systemd.services.transmission-netns = {
        bindsTo = [ "netns@transmission.service" ];
        after = [ "netns@transmission.service" ];
        path = [
          pkgs.iproute2
          pkgs.wireguard-tools
        ];
        script = ''
          set -efux
          until ${pkgs.dig.host}/bin/host europe.vpn.airdns.org; do sleep; done

          ip link del t2 || :
          ip -n transmission link set lo up
          ip link add airvpn type wireguard
          ip -n transmission link del airvpn || :
          ip link set airvpn netns transmission
          ip -n transmission addr add 10.130.221.29/32 dev airvpn
          ip -n transmission addr add fd7d:76ee:e68f:a993:7cf4:ae12:453e:1e8c/128 dev airvpn
          ip netns exec transmission wg syncconf airvpn <(wg-quick strip ${cfg.magnet.wgConfPath})

          ip -n transmission link set airvpn up
          ip -n transmission route add default dev airvpn
          ip -6 -n transmission route add default dev airvpn

          ip link add t1 type veth peer name t2

          ip -n transmission link del t1 || :
          ip link set t1 netns transmission

          ip addr add 128.0.0.2/30 dev t2
          ip addr add fdb4:3310:947::1/64 dev t2
          ip link set t2 up
          ip -n transmission addr add 128.0.0.1/30 dev t1
          ip -n transmission addr add fdb4:3310:947::2/64 dev t1
          ip -n transmission link set t1 up
          ip -n transmission route add 42:0:ce16::3110/16 via fdb4:3310:947::1 dev t1
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
      };

      # so we can forward traffic from the transmission network namespace
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      systemd.services.transmission = {
        after = [ "transmission-netns.service" ];
        wants = [ "transmission-netns.service" ];
        bindsTo = [ "netns@transmission.service" ];
        serviceConfig = {
          NetworkNamespacePath = "/var/run/netns/transmission";
          # https://github.com/NixOS/nixpkgs/issues/258793
          #RootDirectoryStartOnly = lib.mkForce false;
          #RootDirectory = lib.mkForce "";
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      };
    })
  ]);
}
