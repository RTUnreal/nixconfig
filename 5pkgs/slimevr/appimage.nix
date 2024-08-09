{
  appimageTools,
  lib,
  fetchurl,
}: let
  pname = "slimevr";
  version = "0.12.1";
in
  appimageTools.wrapType2 rec {
    inherit pname version;
    src = fetchurl {
      url = "https://github.com/SlimeVR/SlimeVR-Server/releases/download/v${version}/SlimeVR-amd64.appimage";
      sha256 = "sha256-AyXL1oVmbEmGbAXQT4cWKvAHM+fkK2DfMSrizwuYRbU=";
    };

    extraPkgs = pkgs: (appimageTools.defaultFhsEnvArgs.multiPkgs pkgs) ++ [pkgs.libthai pkgs.jdk17_headless];

    meta = with lib; {
      license = with licenses; [asl20 mit];
      platform = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
