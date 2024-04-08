{
  lib,
  fetchurl,
  fetchgit,
  buildNpmPackage,
  rustPlatform,
  wrapGAppsHook,
  makeWrapper,
  pkg-config,
  jq,
  cargo,
  rustc,
  jdk17_headless,
  dbus,
  openssl,
  gtk3,
  glib-networking,
  webkitgtk_4_1,
  gst_all_1,
  withDebug ? false,
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
    nativeBuildInputs = [rustc cargo];

    postPatch = ''
      rm -rf solarxr-protocol
      cp -R ${solarxr} solarxr-protocol
      chmod -R u+w solarxr-protocol

      ${lib.getExe jq} '.scripts.febuild = "cd gui && npm run build"' package.json > p.json
      mv p.json package.json

      sed '/git --no-pager tag /{n;N;N;d}' -i gui/vite.config.ts
      substituteInPlace gui/vite.config.ts \
        --replace "const commitHash = execSync('git rev-parse --verify --short HEAD').toString().trim();" 'const commitHash = "NOT AVAILABLE";' \
        --replace "const versionTag = execSync('git --no-pager tag --sort -taggerdate --points-at HEAD')" 'const versionTag = "v${version}";' \
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
    postPatch =
      ''
        ${lib.getExe jq} '.build.distDir = "${frontend}"' gui/src-tauri/tauri.conf.json > t.json
        mv t.json gui/src-tauri/tauri.conf.json
      ''
      + lib.optionalString withDebug ''
        substituteInPlace gui/src-tauri/src/main.rs \
          --replace "if window_state.is_old()" "window.open_devtools();if window_state.is_old()"
      '';

    passthru = {
      inherit src serverJar solarxr frontend;
    };

    nativeBuildInputs = [
      makeWrapper
      wrapGAppsHook
      pkg-config
    ];

    buildInputs =
      [
        dbus
        openssl
        gtk3
        glib-networking
        webkitgtk_4_1
        jdk17_headless
      ]
      ++ (with gst_all_1; [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
      ]);

    postInstall = ''
      mkdir -p $out/share/java
      ln -s ${serverJar} $out/share/java/slimevr.jar
      wrapProgram $out/bin/slimevr \
        --set JAVA_HOME "${jdk17_headless}" \
        --add-flags "--launch-from-path $out/share/java"
    '';

    meta = {
      mainProgram = "slimevr";
    };
  }
