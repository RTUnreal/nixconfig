{
  lib,
  fetchurl,
  fetchgit,
  rustPlatform,
  wrapGAppsHook,
  makeWrapper,
  substituteAll,
  pkg-config,
  jq,
  cargo-tauri,
  nodejs,
  pnpm_9,
  jdk17_headless,
  glib,
  gtk3,
  libayatana-appindicator,
  webkitgtk_4_1,
  gst_all_1,
  withDebug ? false,

}:
let
  pnpm = pnpm_9;
in
let
  version = "0.13.2";

  src = fetchgit {
    url = "https://github.com/SlimeVR/SlimeVR-Server.git";
    rev = "v${version}";
    hash = "sha256-XQDbP+LO/brpl7viSxuV3H4ALN0yIkj9lwr5eS1txNs=";
    fetchSubmodules = true;
  };

  serverJar = fetchurl {
    url = "https://github.com/SlimeVR/SlimeVR-Server/releases/download/v${version}/slimevr.jar";
    hash = "sha256-s6uznJtsa1bQAM1QIdBMey+m9Q/v2OfKQPXjD5RAR78=";
  };

in
rustPlatform.buildRustPackage rec {
  pname = "SlimeVR";
  inherit src version;

  nativeBuildInputs = [
    cargo-tauri.hook
    pnpm.configHook
    wrapGAppsHook

    pkg-config
    nodejs

    makeWrapper
  ];

  buildInputs =
    [
      glib
      gtk3
      webkitgtk_4_1
      libayatana-appindicator
      jdk17_headless
    ]
    ++ (with gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
    ]);

  cargoHash = "sha256-Y3ajrtIFb2gdU1zuZyIA8+XDB8JSdBdE8Vo+5gYVYrM=";

  pnpmDeps = pnpm.fetchDeps {
    inherit pname version src;
    hash = "sha256-5IqIUwVvufrws6/xpCAilmgRNG4mUGX8NXajZcVZypM=";
  };

  patches = [
    (substituteAll {
      src = ./version-fix.patch;
      env = {
        inherit version;
      };
    })
  ];

  cargoBuildType = lib.optionalString withDebug "debug";

  postPatch = ''
    tmp=$(mktemp)
    ${lib.getExe jq} '.main = "protocol/typescript/src/all_generated.ts"' solarxr-protocol/package.json > "$tmp"
    mv "$tmp" solarxr-protocol/package.json

    tmp=$(mktemp)
    ${lib.getExe jq} '.bundle.linux.deb.files."/usr/share/slimevr/slimevr.jar" = "/build/SlimeVR-Server/server/desktop/build/libs/server.jar"' gui/src-tauri/tauri.conf.json > "$tmp"
    mv "$tmp" gui/src-tauri/tauri.conf.json


    mkdir -p server/desktop/build/libs
    cp ${serverJar} server/desktop/build/libs/server.jar
  '';

  buildAndTestSubdir = "gui/src-tauri";

  postInstall = ''
    wrapProgram $out/bin/slimevr \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath [ libayatana-appindicator ]}" \
      --set JAVA_HOME "${jdk17_headless}" \
      --add-flags "--launch-from-path $out/share/slimevr"
  '';

  meta = {
    mainProgram = "slimevr";
  };
}
