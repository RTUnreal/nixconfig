{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.rtinf.steam;

  # expects appimage binfmt
  ovrasStarter = pkgs.writeShellScriptBin "ovras-start" ''
    unset LD_LIBRARY_PATH
    unset QML2_IMPORT_PATH
    unset QT_PLUGIN_PATH
    #echo "$@" | sed "s|'$HOME/.local/share/Steam/steamapps/common/OVR_AdvancedSettings/run.sh'|appimage-run $HOME/.local/share/Steam/steamapps/common/OVR_AdvancedSettings/OVRAS.AppImage|"|exec bash -
    echo "$@" | exec bash -
  '';

  # copied from: https://www.gamingonlinux.com/forum/topic/5716/
  clear_cache = pkgs.writeShellApplication {
    name = "steam_clear_shader_caches";
    text = ''
      ### Clean out ~/.cache/mesa_shader_cache(_sf) and radv_builtin shaders
      ### Clean out the mesa_shader_cache(_sf) directories from Steam's compatdata
      ### Note that the fossilize cache (MESA_DISK_CACHE_SINGLE_FILE=1) isn't used by default,
      ### so we cover the mesa_shader_cache_sf case with a wildcard

      # System specific path, you may need to edit below if the following doesn't lead
      # to the real path correctly

      cd "$HOME"/.steam/root/steamapps/compatdata || exit 1
      COMPATDATA=$(pwd -P)

      find "$COMPATDATA" -name 'mesa_shader_cache*' -exec du -sh '{}' \;
      find "$HOME"/.cache -name 'mesa_shader_cache*' -exec du -sh '{}' \;

      echo "Look at all the CRUD that is accumulating..."

      while true; do
      read -rp "Do you wish to clean it out? (y/n) " yn
      case $yn in
              [yY] ) echo Nuking...;
                      break;;
              [nN] ) echo Aborting...;
                      exit 0;;
              * ) echo "Enter y or n, silly!";;
      esac
      done

      rm -vf "$HOME"/.cache/radv_builtin_shaders32 || true
      rm -vf "$HOME"/.cache/radv_builtin_shaders64 || true
      rm -rvf "$HOME"/.cache/mesa_shader_cache* || true
      find "$COMPATDATA" -name 'mesa_shader_cache*' -exec rm -rvf '{}' + || true
    '';
  };

  delete_vrc_eac = pkgs.writeShellApplication {
    name = "steam_delete_vrc_eac";
    text = ''
      rm -rf ~/.local/share/Steam/steamapps/compatdata/438100/pfx/drive_c/users/steamuser/AppData/Roaming/
    '';
  };
in
{
  options.rtinf.steam = {
    enable = mkEnableOption "steam";
    enableMonado = mkEnableOption "monado integration for steam";
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        programs = {
          steam = {
            enable = true;
            extraPackages = [
              ovrasStarter
            ];
            extraCompatPackages = [
              nixpkgs-unstable.proton-ge-rtsp-bin
              nixpkgs-unstable.proton-ge-bin
            ];
            platformOptimizations.enable = true;
          };
          gamemode.enable = true;
        };

        environment.systemPackages = [
          ovrasStarter
          clear_cache
          delete_vrc_eac
        ];
      }
      (lib.mkIf cfg.enableMonado {
        # TODO: it doesnt work correctly yet
        services.monado = {
          enable = true;
          defaultRuntime = true;
        };
        systemd.user.services."monado".environment = {
          STEAMVR_LH_ENABLE = "true";
          XRT_COMPOSITOR_COMPUTE = "1";
        };
        environment.systemPackages = [
          pkgs.wlx-overlay-s
          pkgs.libsurvive
          pkgs.xrgears
        ];
        home-manager.users.trr = {
          home.file = {
            ".local/share/monado/hand-tracking-models".source = pkgs.fetchgit {
              url = "https://gitlab.freedesktop.org/monado/utilities/hand-tracking-models.git";
              fetchLFS = true;
              sha256 = "sha256-x/X4HyyHdQUxn3CdMbWj5cfLvV7UyQe1D01H93UCk+M=";
            };
          };
          xdg.configFile = {
            "openvr/openvrpaths.vrpath".text = ''
              {
                "config" :
                [
                  "${config.home-manager.users.trr.xdg.dataHome}/Steam/config"
                ],
                "external_drivers" : null,
                "jsonid" : "vrpathreg",
                "log" :
                [
                  "${config.home-manager.users.trr.xdg.dataHome}/Steam/logs"
                ],
                "runtime" :
                [
                  "${pkgs.opencomposite}/lib/opencomposite",
                  "${config.home-manager.users.trr.xdg.dataHome}/Steam/steamapps/common/SteamVR"
                ],
                "version" : 1
              }
            '';
            "openxr/1/active_runtime.json".source =
              config.environment.etc."xdg/openxr/1/active_runtime.json".source;
          };
        };

      })
    ]
  );
}
