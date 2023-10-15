{
  python311,
  fetchpatch,
}: let
  python = python311.override {
    packageOverrides = self: super: {
      inflate64 =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "inflate64";
              version = "0.3.1";
              # TODO: change back to pyproject
              format = "setuptools";

              src = fetchPypi {
                inherit pname version format;
                hash = "sha256-tS3Y/v0roXnl36GNbsp+L8giWEYWJxwDnV7x+cqQxxw=";
              };

              postPatch = ''
                substituteInPlace setup.py \
                  --replace "packages=packages," "packages=packages,version='${version}',"
              '';

              nativeBuildInputs = with self; [
                setuptools
              ];
            }
        )
        {};
      multivolumefile =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "multivolumefile";
              version = "0.2.3";
              format = "setuptools";

              src = fetchPypi {
                inherit pname version;
                hash = "sha256-oGSNCq+8luWRmNXBfprK1+tTGr6lEDXQjOgGDcrXCdY=";
              };

              nativeBuildInputs = with self; [
                setuptools-scm
              ];
            }
        )
        {};
      pybcj =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "pybcj";
              version = "1.0.1";
              format = "setuptools";

              src = fetchPypi {
                inherit pname version;
                hash = "sha256-i2gu0Iyqv7fAQtS+CD4o3caSr7He/1VnER+IVQcbdcM=";
              };

              nativeBuildInputs = with self; [
                setuptools-scm
              ];
            }
        )
        {};
      pyppmd =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "pyppmd";
              version = "1.0.0";
              format = "setuptools";

              src = fetchPypi {
                inherit pname version;
                hash = "sha256-B1yb0pfjsKh9166ryn/uZoIYrL5p7MHGURBkVY3ohA8=";
              };

              propagatedBuildInputs = with self; [
                setuptools-scm
                pybcj
              ];
            }
        )
        {};
      pyzstd =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "pyzstd";
              version = "0.15.9";
              format = "setuptools";

              src = fetchPypi {
                inherit pname version;
                hash = "sha256-y/3ebFdo/6XS8UEnu8HXw8LQPAzq6wc2lGGX4GJ1zMc=";
              };

              propagatedBuildInputs = with self; [
              ];
            }
        )
        {};
      py7zr =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "py7zr";
              version = "0.20.5";
              format = "pyproject";

              src = fetchPypi {
                inherit pname version;
                hash = "sha256-b7SInA+jJYGBijNmmECDJTWF1seU6CwyQrihLWrqq9M=";
              };

              propagatedBuildInputs = with self; [
                setuptools
                texttable
                pycryptodomex
                pyzstd
                pyppmd
                multivolumefile
                brotli
                inflate64
                psutil
              ];
            }
        )
        {};
      requests-doh =
        self.callPackage
        (
          {
            buildPythonPackage,
            fetchPypi,
          }:
            buildPythonPackage rec {
              pname = "requests-doh";
              version = "0.3.1";
              format = "setuptools";

              src = fetchPypi {
                inherit pname version;
                hash = "sha256-50nIJz7UHLiEvMSo3lzQGxHOAH5X3ndRFg8Kc+UZ4is=";
              };

              propagatedBuildInputs = with self; [
                requests
                dnspython
                requests-toolbelt
                httpx
                h2
              ];
            }
        )
        {};
      # TODO: Remove when posible
      pillow = super.pillow.overridePythonAttrs (old: rec {
        version = "9.5.0";
        src = old.src.override {
          inherit version;
          hash = "sha256-v1SEedM2cm16Ds6252fhefveN4M65CeUYCYxoHDWMPE=";
        };
        patches = [
          (fetchpatch {
            # Fixed type handling for include and lib directories; Remove with 10.0.0
            url = "https://github.com/python-pillow/Pillow/commit/0ec0a89ead648793812e11739e2a5d70738c6be5.patch";
            hash = "sha256-m5R5fLflnbJXbRxFlTjT2X3nKdC05tippMoJUDsJmy0=";
          })
        ];
      });
    };
  };
in
  python.pkgs.buildPythonApplication rec {
    pname = "mangadex-downloader";
    version = "2.10.3";
    format = "setuptools";

    src = python.pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-RM1UCnU7/P913g7HfTCZp166/0msK3OkfExJd9BCpOs=";
    };

    doCheck = false;

    propagatedBuildInputs = with python.pkgs; [
      requests-doh
      requests
      tqdm
      pathvalidate
      packaging
      pyjwt
      beautifulsoup4
      pillow
      chardet
      py7zr
    ];
  }
