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
  # taken from https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/steamos-customizations-jupiter-20230911.1-1-any.pkg.tar.zst
  boot.kernel.sysctl = {
    # 20-shed.conf
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    # 20-net-timeout.conf
    # This is required due to some games being unable to reuse their TCP ports
    # if they're killed and restarted quickly - the default timeout is too large.
    "net.ipv4.tcp_fin_timeout" = 5;
    # 30-vm.conf
    # USE MAX_INT - MAPCOUNT_ELF_CORE_MARGIN.
    # see comment in include/linux/mm.h in the kernel tree.
    "vm.max_map_count" = 2147483642;
  };
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
