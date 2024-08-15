{
  config,
  pkgs,
  selfpkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkPackageOption mkIf optionalAttrs optionalString types literalExpression mapAttrs filterAttrs;
  cfg = config.rtinf.mofongo;

  settingsFormat = let
    mkValueString = with lib;
      v:
        if isInt v
        then toString v
        else if isBool v
        then
          (
            if v
            then "true"
            else "false"
          )
        else if isString v
        then "\"" + v + "\""
        else throw "unsupported type ${builtins.typeOf v}: ${(lib.generators.toPretty {}) v}";

    base = pkgs.formats.keyValue {
      mkKeyValue = lib.generators.mkKeyValueDefault {inherit mkValueString;} "=";
    };
    # OpenSSH is very inconsistent with options that can take multiple values.
    # For some of them, they can simply appear multiple times and are appended, for others the
    # values must be separated by whitespace or even commas.
    # Consult either sshd_config(5) or, as last resort, the OpehSSH source for parsing
    # the options at servconf.c:process_server_config_line_depth() to determine the right "mode"
    # for each. But fortunaly this fact is documented for most of them in the manpage.
    #commaSeparated = ["Ciphers" "KexAlgorithms" "Macs"];
    #spaceSeparated = ["AuthorizedKeysFile" "AllowGroups" "AllowUsers" "DenyGroups" "DenyUsers"];
  in {
    inherit (base) type;
    generate = name: value: let
      transformedValue =
        mapAttrs (
          _key: val: val
          /*
          if isList val
          then
            if elem key commaSeparated
            then concatStringsSep "," val
            else if elem key spaceSeparated
            then concatStringsSep " " val
            else throw "list value for unknown key ${key}: ${(lib.generators.toPretty {}) val}"
          else val
          */
        )
        value;
    in
      base.generate name transformedValue;
  };

  configFile = settingsFormat.generate "mofongo-config.txt" (filterAttrs (_n: v: v != null) cfg.settings);
in {
  options.rtinf.mofongo = {
    enable = mkEnableOption "enable mofongo";
    package = mkPackageOption selfpkgs "jmusicbot" {};
    javaPkg = mkPackageOption pkgs "jdk" {};
    user = mkOption {
      type = types.str;
      default = "mofongo";
      description = lib.mdDoc "User account under which mofongo runs.";
    };
    group = mkOption {
      type = types.str;
      default = "mofongo";
      description = lib.mdDoc "Group account under which mofongo runs.";
    };
    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/mofongo";
      description = "mofongo data directory.";
    };

    settings = mkOption {
      description = "configuration of JMusicBot https://jmusicbot.com/config/";
      default = {};
      example = literalExpression ''
        {
          owner = 0;
          prefix = "!";
        }
      '';
      type = types.submodule ({...}: {
        freeformType = settingsFormat.type;
        options = {
          game = mkOption {
            type = types.either (types.enum ["DEFAULT" "NONE"]) types.str;
            default = "DEFAULT";
          };
          owner = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "sets the owner of the bot. This needs to be the owner's ID (a 17-18 digit number). https://github.com/jagrosh/MusicBot/wiki/Finding-Your-User-ID";
          };
          prefix = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          status = mkOption {
            type = types.enum ["ONLINE" "IDLE" "DND" "INVISIBLE"];
            default = "ONLINE";
          };
          songinstatus = mkEnableOption "shows the currently playing song in the status. Does not work if it is playing in multiple guilds." // {default = false;};
          altprefix = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          loglevel = mkOption {
            type = types.enum ["off" "error" "warn" "info" "debug" "trace" "all"];
            default = "info";
          };
        };
      });
    };

    appendConfigWithFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "File to dynamically load settings";
    };
    openFirewall = mkEnableOption "open the mofongo port on the firewall";
  };
  config = mkIf (cfg.enable) {
    users = {
      users = optionalAttrs (cfg.user == "mofongo") {
        mofongo = {
          group = cfg.group;
          isSystemUser = true;
          home = cfg.stateDir;
        };
      };
      groups = optionalAttrs (cfg.group == "mofongo") {
        mofongo = {};
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d '${cfg.stateDir}' 750 ${cfg.user} ${cfg.group}"
      ];
      services.mofongo = {
        description = "Mofongo music bot service";
        wantedBy = ["multi-user.target"];
        wants = ["network-online.target"];
        after = ["network.target" "local-fs.target" "network-online.target" "nss-lookup.target"];

        preStart = optionalString (cfg.appendConfigWithFile != null) ''
          cat "${configFile}" "${cfg.appendConfigWithFile}" > "${cfg.stateDir}/config.txt"
        '';

        serviceConfig = {
          Type = "exec";
          DynamicUser = false;
          User = cfg.user;
          Group = cfg.group;
          PrivateTmp = false;
          TimeoutStopSec = 1800;
          ExecStart = "${cfg.javaPkg}/bin/java -Dnogui=true -Dconfig=\"${
            if (cfg.appendConfigWithFile != null)
            then "${cfg.stateDir}/config.txt"
            else configFile
          }\" -jar ${cfg.package}";
          UMask = "0002";
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];
  };
}
