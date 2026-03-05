{ pkgs, ... }:
{
  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
          rocminfo
          llvm.llvm
          rocm-device-libs
        ];
      };
    in
    [
      "d /opt 0755 root root - -"
      "L+ /opt/rocm - - - - ${rocmEnv}"
    ];
}
