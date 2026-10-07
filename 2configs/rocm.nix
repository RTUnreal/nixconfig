{ nixpkgs-unstable, ... }:
{
  systemd.tmpfiles.rules =
    let
      rocmEnv = nixpkgs-unstable.symlinkJoin {
        name = "rocm-combined";
        paths = with nixpkgs-unstable.rocmPackages; [
          rocblas
          hipblas
          clr
          clang
          rocminfo
          llvm.llvm
          llvm.compiler-rt
          rocm-device-libs
        ];
      };
    in
    [
      "d /opt 0755 root root - -"
      "L+ /opt/rocm - - - - ${rocmEnv}"
    ];
}
