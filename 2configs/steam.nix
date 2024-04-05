{
  config,
  pkgs,
  nixpkgs-unstable,
  ...
}: let
  ovrasStarter = pkgs.writeShellScriptBin "ovras-start" ''
    unset LD_LIBRARY_PATH
    unset QML2_IMPORT_PATH
    unset QT_PLUGIN_PATH
    echo "$@" | sed "s|'$HOME/.local/share/Steam/steamapps/common/OVR_AdvancedSettings/run.sh'|appimage-run $HOME/.local/share/Steam/steamapps/common/OVR_AdvancedSettings/OVRAS.AppImage|"|bash -
  '';
in {
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
      extraCompatPackages = [nixpkgs-unstable.proton-ge-bin];
      platformOptimizations.enable = true;
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
  };
}
