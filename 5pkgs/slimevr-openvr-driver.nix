{ stdenvNoCC, fetchzip }:
stdenvNoCC.mkDerivation rec {
  pname = "SlimeVR-OpenVR-Driver";
  version = "6.0.0";

  src = fetchzip {
    url = "https://github.com/SlimeVR/${pname}/releases/download/v${version}/slimevr-openvr-driver-x64-linux.zip";
    hash = "sha256-0/jgVM+EPa3bh2EGqxxL+JqrTadajvULHA6JPP+uZro=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
  '';
}
