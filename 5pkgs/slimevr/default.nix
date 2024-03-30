{
  fetchurl,
  fetchgit,
  buildNpmPackage,
  rustPlatform,
  libthai,
  jdk17_headless,
  cargo,
  rustc,
  jq,
  lib,
  git,
  makeWrapper,
  pkg-config,
  glib,
  dbus,
  openssl,
  freetype,
  libsoup,
  gtk3,
  webkitgtk_4_1,
}: let
  pname = "SlimeVR";
  version = "0.11.0";

  src = fetchgit {
    url = "https://github.com/SlimeVR/SlimeVR-Server.git";
    rev = "v${version}";
    hash = "sha256-W1POuIuhKv8/QCMr47O1l1Bjvbceg/yg3TgF/3+2xC4=";
    fetchSubmodules = true;
  };

  serverJar = fetchurl {
    url = "https://github.com/SlimeVR/SlimeVR-Server/releases/download/v${version}/slimevr.jar";
    hash = "sha256-bOSF5NQLUgu0yaIC3q9aQ+uIWjWdyw3wON9/UEEUPJQ=";
  };

  solarxr = buildNpmPackage {
    pname = "${pname}-solarxr";
    inherit version;
    src = src + "/solarxr-protocol";

    npmDepsHash = "sha256-jHd0yf1eO5fCre59IOjvadI14Rulfd978wAAkD5MurY=";

    postPatch = ''
      ${lib.getExe jq} '.dependencies += .devDependencies' package.json > p.json
      mv p.json package.json
    '';

    installPhase = "mkdir $out && mv * $out";
  };

  frontend = buildNpmPackage {
    pname = "${pname}-ui";
    inherit src version;

    npmDepsHash = "sha256-fgt2c5o48zmCAvXrxAKQbZmIKyDD777GCz3u62bu5MA=";
    nativeBuildInputs = [rustc cargo git];

    postPatch = ''
      rm -rf solarxr-protocol
      cp -R ${solarxr} solarxr-protocol
      chmod -R u+w solarxr-protocol

      ${lib.getExe jq} '.scripts.febuild = "cd gui && npm run build"' package.json > p.json
      mv p.json package.json

      sed '/git --no-pager tag /{n;N;N;d}' -i gui/vite.config.ts
      substituteInPlace gui/vite.config.ts \
        --replace "const commitHash = execSync('git rev-parse --verify --short HEAD').toString().trim();" 'const commitHash = "NOT AVAILABLE";' \
        --replace "const versionTag = execSync('git --no-pager tag --sort -taggerdate --points-at HEAD')" 'const versionTag = "v${version}-nixos";' \
        --replace "const gitClean = execSync('git status --porcelain').toString() ? false : true;" 'const gitClean = true;'

      cat gui/vite.config.ts
    '';

    npmBuildScript = "febuild";

    installPhase = ''
      runHook preInstall

      cp -r gui/dist $out

      runHook postInstall
    '';
  };
in
  rustPlatform.buildRustPackage {
    inherit pname;
    inherit version src;
    cargoLock = {
      lockFile = src + "/Cargo.lock";
    };
    postPatch = ''
      ${lib.getExe jq} '.build.distDir = "${frontend}"' gui/src-tauri/tauri.conf.json > t.json
      mv t.json gui/src-tauri/tauri.conf.json
      #substituteInPlace tauri.conf.json --replace '"distDir": "../out/src",' '"distDir": "frontend-build/src",'
    '';

    passthru = {
      inherit src serverJar solarxr frontend;
    };

    nativeBuildInputs = [
      makeWrapper
      pkg-config
    ];

    buildInputs = [
      dbus
      openssl
      freetype
      libsoup
      gtk3
      webkitgtk_4_1
      glib
      libthai
      jdk17_headless
    ];

    postInstall = ''
      mkdir -p $out/share/java/jre/
      ln -s ${jdk17_headless}/bin $out/share/java/jre/bin
      ln -s ${serverJar} $out/share/java/slimevr.jar
      wrapProgram $out/bin/slimevr \
        --add-flags "--launch-from-path $out/share/java"
    '';

    meta = {
      mainProgram = "slimevr";
    };
  }
