{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libglut,
  lapack,
  libusb1,
  blas,
  zlib,
  eigen,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "libsurvive";
  version = "unstable-2025-04-07";

  src = fetchFromGitHub {
    owner = "collabora";
    repo = "libsurvive";
    rev = "32cf62c52744fdc32003ef8169e8b81f6f31526b";
    hash = "sha256-PIQW5L0vtaYD2b8wuDAthWS+mDX4cvFELDSUZ7RD4Ac=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    libglut
    lapack
    libusb1
    blas
    zlib
    eigen

  ];

  # https://github.com/cntools/libsurvive/issues/272
  postPatch = ''
    substituteInPlace survive.pc.in \
      libs/cnkalman/cnkalman.pc.in libs/cnmatrix/cnmatrix.pc.in \
      --replace '$'{exec_prefix}/@CMAKE_INSTALL_LIBDIR@ @CMAKE_INSTALL_FULL_LIBDIR@
  '';

  postInstall = ''
    install -Dm 644 $src/useful_files/81-vive.rules $out/lib/udev/rules.d/81-vive.rules
  '';

  meta = with lib; {
    description = "Open Source Lighthouse Tracking System";
    homepage = "https://github.com/cntools/libsurvive";
    license = licenses.mit;
    maintainers = with maintainers; [ prusnak ];
    platforms = platforms.linux;
  };
}
