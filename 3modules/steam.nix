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
      (lib.mkIf cfg.enableMonado {
        # TODO: it doesnt work correctly yet
        services.monado = {
          enable = true;
          defaultRuntime = true;
          highPriority = true;
          package = selfpkgs.monado;
        };
        systemd.user.services."monado".environment = {
          STEAMVR_LH_ENABLE = "true";
          XRT_COMPOSITOR_COMPUTE = "1";
          XRT_DEBUG_GUI = "1";
          XRT_CURATED_GUI = "1";
          U_PACING_APP_USE_MIN_FRAME_PERIOD = "1";
          XRT_COMPOSITOR_DESIRED_MODE = "0";
          XRT_COMPOSITOR_SCALE_PERCENTAGE = "140";

          LH_LOAD_SLIMEVR = "TRUE";
        };
        environment.systemPackages = [
          pkgs.wlx-overlay-s
          selfpkgs.libsurvive
          pkgs.xrgears
        ];
        boot.kernelPatches = [
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
                  "${pkgs.opencomposite}/lib/opencomposite"
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
            # reference: https://github.com/galister/wlx-overlay-s/blob/main/src/res/wayvr.yaml
            "wlxoverlay/wayvr.yaml".source = (pkgs.formats.yaml { }).generate "wayvr.yaml" {
              version = 1;

              # If your gpu has some issues with zero-copy textures, you can set this option to "software".
              #
              # Possible options:
              # "dmabuf": Use zero-copy texture access (from EGL to Vulkan) - no performance impact
              # "software": Read pixel data to memory via glReadPixels() every time a content has been updated. Minor performance impact on large resolutions
              blit_method = "dmabuf";

              # Set to true if you want to make Wyland server instantly available.
              # By default, WayVR starts only when it's needed.
              # (this option is primarily used for remote starting external processes and development purposes)
              run_compositor_at_start = false;

              # Automatically close overlays with zero window count?
              auto_hide = true;

              # For how long an overlay should be visible in case if there are no windows present? (in milliseconds, auto_hide needs to be enabled)
              # This value shouldn't be set at 0, because some programs could re-initialize a window during startup (splash screens for example)
              auto_hide_delay = 750;

              # In milliseconds
              keyboard_repeat_delay = 200;

              # Chars per second
              keyboard_repeat_rate = 50;

              # WayVR-compatible dashboard.
              # For now, there is only one kind of dashboard with WayVR IPC support (WayVR Dashboard).
              #
              # Build instructions: https://github.com/olekolek1000/wayvr-dashboard
              #
              # exec: Executable path, for example "/home/USER/wayvr-dashboard/src-tauri/target/release/wayvr-dashboard"
              # or just "wayvr-dashboard" if you have it installed from your package manager.
              dashboard = {
                exec = "${lib.getExe inputs.nixpkgs-xr.packages."x86_64-linux".wayvr-dashboard}";
                args = "";
                env = [ ];
              };

              displays = {
                watch = {
                  width = 400;
                  height = 600;
                  scale = 0.4;
                  attach_to = "HandRight"; # HandLeft, HandRight
                  pos = [
                    0.0
                    0.0
                    0.125
                  ];
                  rotation = {
                    axis = [
                      1.0
                      0.0
                      0.0
                    ];
                    angle = -45.0;
                  };
                };
                disp1 = {
                  width = 640;
                  height = 480;
                  primary = true; # Required if you want to attach external processes (not spawned by WayVR itself) without WAYVR_DISPLAY_NAME set
                };
                disp2 = {
                  width = 1280;
                  height = 720;
                  scale = 2.0;
                };
              };

              catalogs.default_catalog.apps = [
                {
                  name = "Calc";
                  target_display = "disp1";
                  exec = "kcalc";
                  env = [ "FOO=bar" ];
                  shown_at_start = false;
                }

                {
                  name = "htop";
                  target_display = "watch";
                  exec = "konsole";
                  args = "-e htop";
                }
              ];
            };
            # reference: https://github.com/galister/wlx-overlay-s/blob/main/contrib/wayvr/watch_wayvr_example.yaml
            "wlxoverlay/watch.yaml".source =
              let
                rect = l: r: w: h: [
                  l
                  r
                  w
                  h
                ];
              in
              (pkgs.formats.yaml { }).generate "watch.yaml" {
                elements = [
                  {
                    bg_color = "#24273a";
                    corner_radius = 20;
                    rect = rect 0 30 400 130;
                    type = "Panel";
                  }
                  {
                    bg_color = "#c6a0f6";
                    click_up = [
                      {
                        action = "ShowUi";
                        target = "settings";
                        type = "Window";
                      }
                      {
                        action = "Destroy";
                        target = "settings";
                        type = "Window";
                      }
                    ];
                    corner_radius = 4;
                    fg_color = "#24273a";
                    font_size = 15;
                    rect = rect 2 162 26 36;
                    text = "C";
                    type = "Button";
                  }
                  {
                    bg_color = "#2288FF";
                    click_up = [
                      {
                        action = "ToggleDashboard";
                        type = "WayVR";
                      }
                    ];
                    corner_radius = 4;
                    fg_color = "#24273a";
                    font_size = 15;
                    rect = rect 32 162 48 36;
                    text = "Dash";
                    type = "Button";
                  }
                  {
                    bg_color = "#a6da95";
                    click_up = [
                      {
                        action = "ToggleVisible";
                        target = "kbd";
                        type = "Overlay";
                      }
                    ];
                    corner_radius = 4;
                    fg_color = "#24273a";
                    font_size = 15;
                    long_click_up = [
                      {
                        action = "Reset";
                        target = "kbd";
                        type = "Overlay";
                      }
                    ];
                    middle_up = [
                      {
                        action = "ToggleInteraction";
                        target = "kbd";
                        type = "Overlay";
                      }
                    ];
                    rect = rect 84 162 48 36;
                    right_up = [
                      {
                        action = "ToggleImmovable";
                        target = "kbd";
                        type = "Overlay";
                      }
                    ];
                    scroll_down = [
                      {
                        action.Opacity.delta = -0.025;
                        target = "kbd";
                        type = "Overlay";
                      }
                    ];
                    scroll_up = [
                      {
                        action.Opacity.delta = 0.025;
                        target = "kbd";
                        type = "Overlay";
                      }
                    ];
                    text = "Kbd";
                    type = "Button";
                  }
                  {
                    bg_color = "#1e2030";
                    click_up = "ToggleVisible";
                    corner_radius = 4;
                    fg_color = "#cad3f5";
                    font_size = 15;
                    layout = "Horizontal";
                    long_click_up = "Reset";
                    middle_up = "ToggleInteraction";
                    rect = rect 134 160 266 40;
                    right_up = "ToggleImmovable";
                    scroll_down.Opacity.delta = -0.025;
                    scroll_up.Opacity.delta = 0.025;
                    type = "OverlayList";
                  }
                  {
                    bg_color = "#e590c4";
                    catalog_name = "default_catalog";
                    corner_radius = 4;
                    fg_color = "#24273a";
                    font_size = 15;
                    rect = rect 0 200 400 36;
                    type = "WayVRLauncher";
                  }
                  {
                    bg_color = "#ca68a4";
                    corner_radius = 4;
                    fg_color = "#24273a";
                    font_size = 15;
                    rect = rect 0 236 400 36;
                    type = "WayVRDisplayList";
                  }
                  {
                    corner_radius = 4;
                    fg_color = "#cad3f5";
                    font_size = 46;
                    format = "%H:%M";
                    rect = rect 19 90 200 50;
                    source = "Clock";
                    type = "Label";
                  }
                  {
                    corner_radius = 4;
                    fg_color = "#cad3f5";
                    font_size = 14;
                    format = "%x";
                    rect = rect 20 117 200 20;
                    source = "Clock";
                    type = "Label";
                  }
                  {
                    corner_radius = 4;
                    fg_color = "#cad3f5";
                    font_size = 14;
                    format = "%A";
                    rect = rect 20 137 200 50;
                    source = "Clock";
                    type = "Label";
                  }
                  {
                    corner_radius = 4;
                    fg_color = "#8bd5ca";
                    fg_color_charging = "#6080A0";
                    fg_color_low = "#B06060";
                    font_size = 16;
                    layout = "Horizontal";
                    low_threshold = 33;
                    num_devices = 9;
                    rect = rect 0 5 400 30;
                    type = "BatteryList";
                  }
                  {
                    bg_color = "#5b6078";
                    click_down = [
                      {
                        command = [
                          "pactl"
                          "set-sink-volume"
                          "@DEFAULT_SINK@"
                          "+5%"
                        ];
                        type = "Exec";
                      }
                    ];
                    corner_radius = 4;
                    fg_color = "#cad3f5";
                    font_size = 13;
                    rect = rect 315 52 70 32;
                    text = "Vol +";
                    type = "Button";
                  }
                  {
                    bg_color = "#5b6078";
                    click_down = [
                      {
                        command = [
                          "pactl"
                          "set-sink-volume"
                          "@DEFAULT_SINK@"
                          "-5%"
                        ];
                        type = "Exec";
                      }
                    ];
                    corner_radius = 4;
                    fg_color = "#cad3f5";
                    font_size = 13;
                    rect = rect 315 116 70 32;
                    text = "Vol -";
                    type = "Button";
                  }
                ];
                size = [
                  400
                  272
                ];
                width = 0.115;
              };
          };
        };
      })
    ]
  );
}
