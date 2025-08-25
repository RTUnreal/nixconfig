{
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "overte-vr";
  version = "2025.05.1";
  src = fetchurl {
    url = "https://public.overte.org/build/overte/release/${version}/Overte-${version}-x86_64.AppImage";
    hash = "sha256-hWVIgduH/WyPZ53QDsbii0Ad8o4TB8lE0WjMcha7hVw=";
  };
}
