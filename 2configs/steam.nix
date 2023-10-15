{
  config,
  pkgs,
  selfpkgs,
  ...
}: let
  ovrasStarter = pkgs.writeShellScriptBin "ovras-start" ''
    unset LD_LIBRARY_PATH
    unset QML2_IMPORT_PATH
    unset QT_PLUGIN_PATH
    echo "$@" | sed "s|'$HOME/.local/share/Steam/steamapps/common/OVR_AdvancedSettings/run.sh'|appimage-run $HOME/.local/share/Steam/steamapps/common/OVR_AdvancedSettings/OVRAS.AppImage|"|bash -
  '';
in {
  # https://fedoraproject.org/wiki/Changes/IncreaseVmMaxMapCount
  # https://www.youtube.com/watch?v=PsHRbfZhgXM
  boot.kernel.sysctl."vm.max_map_count" = 2147483642; # (SIGNED_)MAX_INT - 5
  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraLibraries = pkgs:
          with config.hardware.opengl;
            (
              if pkgs.hostPlatform.is64bit
              then [package] ++ extraPackages
              else [package32] ++ extraPackages32
            )
            ++ [pkgs.appimage-run ovrasStarter];
      };
    };
    # XXX: rethink gamescop
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    gamemode.enable = true;
  };
  environment = {
    systemPackages = [ovrasStarter];
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${selfpkgs.proton-ge}";
    };
  };
}
