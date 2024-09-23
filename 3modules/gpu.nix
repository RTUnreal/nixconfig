{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkOption types optional mkIf;
  cfg = config.rtinf.gpu;
in {
  options.rtinf.gpu = {
    type = mkOption {
      type = types.nullOr (types.enum ["amd" "nvidia"]);
    };
  };

  config = mkIf (cfg.type != null) {
    environment.systemPackages =
      []
      ++ optional (cfg.type == "amd") pkgs.nvtopPackages.amd
      ++ optional (cfg.type == "nvidia") pkgs.nvtopPackages.nvidia;
  };
}
