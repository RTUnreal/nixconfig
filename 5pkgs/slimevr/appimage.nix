{
  appimageTools,
  lib,
  fetchurl,
}:
let
  pname = "slimevr";
  version = "0.13.2";
in
appimageTools.wrapType2 rec {
  inherit pname version;
  src = fetchurl {
    url = "https://github.com/SlimeVR/SlimeVR-Server/releases/download/v${version}/SlimeVR-amd64.appimage";
    sha256 = "sha256-YlMLK+1bP+70wYgm0rROYDz2JOgZdzDFn9/sFZblYDk=";
  };

  extraPkgs =
    pkgs:
    (appimageTools.defaultFhsEnvArgs.multiPkgs pkgs)
    ++ [
      pkgs.libthai
      pkgs.jdk17_headless
    ];

  meta = with lib; {
    license = with licenses; [
      asl20
      mit
    ];
    platform = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
