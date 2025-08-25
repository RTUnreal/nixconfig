{
  stdenv,
  fetchFromGitHub,

  cmake,
  python3,

}:
stdenv.mkDerivation rec {
  pname = "overte";
  version = "2025.05.1";
  src = fetchFromGitHub {
    owner = "overte-org";
    repo = pname;
    tag = version;
    sha256 = "sha256-6FBwhHXN9ajkw3qxlVYEKwaPIVXLckhQaKRRkuJnc5w=";
  };

  nativeBuildInputs = [
    cmake
    python3
  ];
}
