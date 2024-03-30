{
  appimageTools,
  lib,
  fetchurl,
}: let
  pname = "slimevr";
  version = "0.11.0";
in
  appimageTools.wrapType2 rec {
    inherit pname version;
    src = fetchurl {
      url = "https://github.com/SlimeVR/SlimeVR-Server/releases/download/v${version}/SlimeVR-amd64.appimage";
      sha256 = "sha256-+gLKE2E53xCr8Z/Mum9bRwsbos/KOr9rJQpHoRPqdQE=";
    };

    extraInstallCommands = ''
      mv $out/bin/${pname}-${version} $out/bin/${pname}
    '';
    extraPkgs = pkgs: (appimageTools.defaultFhsEnvArgs.multiPkgs pkgs) ++ [pkgs.libthai pkgs.jdk17_headless];

    meta = with lib; {
      license = with licenses; [asl20 mit];
      platform = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
