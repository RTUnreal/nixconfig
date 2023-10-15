# I hate this
{
  stdenv,
  fetchurl,
  makeWrapper,
  cacert,
}:
stdenv.mkDerivation rec {
  pname = "mango";
  version = "0.27.0";
  src = fetchurl {
    url = "https://github.com/getmango/Mango/releases/download/v${version}/mango";
    sha256 = "sha256-PFHqz0NRSq5EvDL59nxjYsYFnlIRO5yvKlRuK8HTXLE=";
    executable = true;
  };
  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];
  buildPhase = ''
    mkdir -p $out/bin
    # don't wan't to duplicate unchanged/static binary
    ln -s $src $out/bin/mango
    #chmod +x $out/bin/mango
    wrapProgram $out/bin/mango \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';
}
