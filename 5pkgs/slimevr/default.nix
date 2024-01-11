{
  fetchurl,
  fetchFromGitHub,
  fetchgit,
  buildNpmPackage,
  rustPlatform,
  libthai,
  jdk17_headless,
  cargo,
  rustc,
  typescript,
  jq,
  lib,
  git,
}: let
  pname = "SlimeVR";
  version = "0.11.0";

  src =
    /*
    fetchFromGitHub {
    owner = "SlimeVR";
    repo = "SlimeVR-Server";
    hash = "sha256-F+J7Eugo4v1/lA/hqmdkcWnW4IxE8RQ2rYahhovfW2g=";
    */
    fetchgit {
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

    #nativeBuildInputs = [typescript];
    postPatch = ''
      ${lib.getExe jq} '.dependencies += .devDependencies' package.json > p.json
      mv p.json package.json
    '';
    postBuild = ''
      #rm -rf node_modules package-lock.json
    '';

    installPhase = "mkdir $out && mv * $out";
    #dontInstall = true;
  };

  frontend-build = buildNpmPackage {
    pname = "${pname}-ui";
    inherit src version;

    npmDepsHash = "sha256-fgt2c5o48zmCAvXrxAKQbZmIKyDD777GCz3u62bu5MA=";
    nativeBuildInputs = [rustc cargo git];

    postPatch = ''
      rm -rf solarxr-protocol
      cp -R ${solarxr} solarxr-protocol
      chmod -R u+w solarxr-protocol

      #sed '/git --no-pager tag /{n;N;N;d}' -i gui/vite.config.ts
      #substituteInPlace gui/vite.config.ts \
      #  --replace "const commitHash = execSync('git rev-parse --verify --short HEAD').toString().trim();" 'const commitHash = "NOT AVAILABLE";' \
      #  --replace "const versionTag = execSync('git --no-pager tag --sort -taggerdate --points-at HEAD')" 'const versionTag = "v${version}-nixos";' \
      #  --replace "const gitClean = execSync('git status --porcelain').toString() ? false : true;" 'const gitClean = true;'

      cat gui/vite.config.ts
    '';

    postConfigure = ''
      #npm --prefer-offline run update-solarxr
    '';

    npmBuildScript = "skipbundler";
    #npmBuildFlags = ["build"];

    /*
    buildPhase = ''
      export HOME=$(mktemp -d)
      npm --cwd gui --prefer-offline run skipbundle

      echo "this is not finished"
      exit 1
    '';
    */

    postBuild = ''
      ls -tal .
    '';

    distPhase = "true";
    dontInstall = true;
  };
in
  rustPlatform.buildRustPackage {
    inherit pname;
    inherit version src;
    cargoLock = {
      lockFile = src + "/Cargo.lock";
    };
    postPatch = ''
      mkdir -p frontend-build
      cp -R ${frontend-build}/src frontend-build

      substituteInPlace tauri.conf.json --replace '"distDir": "../out/src",' '"distDir": "frontend-build/src",'
    '';

    passthru = {
      inherit src serverJar solarxr;
    };

    buildInputs = [
      libthai
      jdk17_headless
    ];
  }
