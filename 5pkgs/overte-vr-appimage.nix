{
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "overte-vr";
  version = "2026.04.1";
  src = fetchurl {
    url = "https://public.overte.org/build/overte/release/${version}/Overte-${version}-x86_64.AppImage";
    #url = "https://public.overte.org/build/overte/release-candidate/${version}/Overte-${version}-x86_64.AppImage";
    hash = "sha256-3Dn1tGlKHEjPsUVKiSL2ol+k21ggv5NxE+v0CGqpkUU=";
  };
}
