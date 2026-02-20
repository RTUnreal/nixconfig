{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  selfpkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkPackageOption;

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
    enableKernelPatch = mkEnableOption "AMD gpu kernel patches";
    overtePackage = mkPackageOption pkgs "overte" {
      nullable = true;
      default = null;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        programs = {
          steam = {
            enable = true;
            extraPackages = [
              # So we don't have that ugly cursor when hovering over Steam
              pkgs.kdePackages.breeze
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
      (lib.mkIf (cfg.overtePackage != null) {
        environment.systemPackages = [ cfg.overtePackage ];
      })
      (lib.mkIf cfg.enableMonado {
        # TODO: it doesnt work correctly yet
        services.monado = {
          enable = true;
          defaultRuntime = true;
          highPriority = true;
          package = nixpkgs-unstable.monado;
        };
        systemd.user.services."monado".environment = {
          STEAMVR_LH_ENABLE = "1";
          XRT_COMPOSITOR_COMPUTE = "1";
          XRT_DEBUG_GUI = "1";

          SOLARXR_LOG = "debug";
        };
        environment.systemPackages = [
          nixpkgs-unstable.wayvr
          nixpkgs-unstable.slimevr
          selfpkgs.libsurvive
          pkgs.xrgears
          pkgs.corectrl
        ];
        boot.kernelPatches = mkIf cfg.enableKernelPatch [
          {
            name = "amdgpu-ignore-ctx-privileges";
            patch = pkgs.fetchpatch {
              name = "cap_sys_nice_begone.patch";
              url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
              hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
            };
          }
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
            # to use the correct openvr comp prepend: "PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc"
            "openvr/openvrpaths.vrpath".text = ''
              {
                "config": [
                  "${config.home-manager.users.trr.xdg.dataHome}/Steam/config"
                ],
                "external_drivers" : null,
                "jsonid": "vrpathreg",
                "log": [
                  "${config.home-manager.users.trr.xdg.dataHome}/Steam/logs"
                ],
                "runtime": [
                  "${nixpkgs-unstable.opencomposite}/lib/opencomposite"
                ],
                "version" : 1
              }
            '';
            "openxr/1/active_runtime.json".source =
              config.environment.etc."xdg/openxr/1/active_runtime.json".source;

            # reference: https://raw.githubusercontent.com/galister/wlx-overlay-s/main/src/backend/openxr/openxr_actions.json5
            "wlxoverlay/openxr_actions.json5".source =
              let
                map_paths = prefixes: path: builtins.mapAttrs (_name: val: val + path) prefixes;
                left = map_paths { left = "/user/hand/left"; };
                right = map_paths { right = "/user/hand/right"; };
                both = map_paths {
                  left = "/user/hand/left";
                  right = "/user/hand/right";
                };
                double_click = {
                  double_click = true;
                };
              in
              (pkgs.formats.json { }).generate "openxr_actions.json5" [
                # Fallback controller, intended for testing
                {
                  profile = "/interaction_profiles/khr/simple_controller";
                  pose = both "/input/aim/pose";
                  haptic = both "/output/haptic";
                  # left trigger is click
                  click = left "/input/select/click";
                  # right trigger is grab
                  grab = right "/input/select/click";
                  show_hide = left "/input/menu/click";
                }

                # Index controller
                {
                  profile = "/interaction_profiles/valve/index_controller";
                  # -- pose, haptic --
                  # do not mess with these, unless you know what you're doing
                  pose = both "/input/aim/pose";
                  haptic = both "/output/haptic";
                  # primary click to interact with the watch or overlays. required
                  click = both "/input/trigger/value";
                  # left trackpad is space_drag
                  #alt_click = right "/input/trackpad/force";
                  alt_click = { };
                  # used to manipulate position, size, orientation of overlays in 3D space
                  grab = both "/input/squeeze/force";
                  scroll = both "/input/thumbstick/y";
                  scroll_horizontal = both "/input/thumbstick/x";
                  # run or toggle visibility of a previously configured WayVR-compatible dashboard
                  toggle_dashboard = right "/input/system/click";
                  # used to quickly hide and show your last selection of screens + keyboard
                  #show_hide = left "/input/b/click" // double_click;
                  show_hide = { };
                  # move your stage (playspace drag)
                  #space_drag = left "/input/trackpad/force"; # right trackpad is alt_click
                  space_drag = both "/input/trackpad/touch";
                  # rotate your stage (playspace rotate, WIP)
                  space_rotate = { };
                  # reset your stage (reset the offset from playspace drag)
                  #space_reset = left "/input/trackpad/force";
                  space_reset = left "/input/b/click" // double_click;
                  # while this is held, your pointer will turn ORANGE and your mouse clicks will be RIGHT clicks
                  click_modifier_right = both "/input/b/touch";
                  # while this is held, your pointer will turn PURPLE and your mouse clicks will be MIDDLE clicks
                  click_modifier_middle = both "/input/a/touch";
                  # when using `focus_follows_mouse_mode`, you need to hold this for the mouse to move
                  #move_mouse = both "/input/trigger/touch";
                  move_mouse = { };
                }
              ];
          };
        };
      })
    ]
  );
}
