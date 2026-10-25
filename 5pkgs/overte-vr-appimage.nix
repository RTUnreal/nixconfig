{
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "overte-vr";
  version = "2026.10.1";
  src = fetchurl {
    url = "https://public.overte.org/build/overte/release/${version}/Overte-${version}-OpenGL-x86_64.AppImage";
    # url = "https://public.overte.org/build/overte/release-candidate/${version}/Overte-${version}-OpenGL-x86_64.AppImage";
    hash = "sha256-zR5hoDUfDt+uEj5zSoOP+VNmJYEdU+sYcvmPnsZbNtI=";
  };
}
