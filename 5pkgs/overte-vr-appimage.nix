{
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "overte-vr";
  version = "2025.12.1";
  src = fetchurl {
    url = "https://public.overte.org/build/overte/release/${version}/Overte-${version}-x86_64.AppImage";
    #url = "https://public.overte.org/build/overte/release-candidate/${version}/Overte-${version}-x86_64.AppImage";
    hash = "sha256-FU8z1JS+1/r5QNzH9iXetas5M9fzj2kOCOANHVBbCUA=";
  };
}
