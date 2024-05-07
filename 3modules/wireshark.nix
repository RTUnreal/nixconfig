{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.rtinf.wireshark;
in {
  options.rtinf.wireshark.enable = mkEnableOption "wireshark stuff";
  config = mkIf cfg.enable {
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    users.users.trr.extraGroups = ["wireshark"];
  };
}
