#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq unzip
# shellcheck shell=bash
set -eu -o pipefail

# can be added to your configuration with the following command and snippet:
# $ ./2configs/safe/update_installed_exts.sh > ./nc-apps.nix
#
# packages = with pkgs;
#   (vscode-with-extensions.override {
#     vscodeExtensions = map
#       (extension: vscode-utils.buildVscodeMarketplaceExtension {
#         mktplcRef = {
#          inherit (extension) name publisher version sha256;
#         };
#       })
#       (import ./extensions.nix).extensions;
#   })
# ]

# Helper to just fail with a message and non-zero exit code.
function fail() {
	echo "$1" >&2
	exit 1
}

# Helper to clean up after ourselves if we're killed by SIGINT.
function clean_up() {
	TDIR="${TMPDIR:-/tmp}"
	echo "Script killed, cleaning up tmpdirs: $TDIR/nc_apps_*" >&2
	rm -Rf "$TDIR/nc_apps_*"
}

while getopts ':n:' OPTION; do
	case "$OPTION" in
	n)
		NCVERSION="$OPTARG"
		;;
	?)
		echo "Usage: $(basename "$0") [-n version] current_file"
		exit 1
		;;
	esac
done

NCVERSION="${NCVERSION:-27}"

# Try to be a good citizen and clean up after ourselves if we'res killed.
trap clean_up SIGINT

if [ ! -r "$1" ]; then
	fail "cannot read: $1"
fi

# Create a tempdir for the extension download.
EXTTMP=$(mktemp -d -t nc_apps_XXXXXXXX)

curl --silent --show-error --retry 3 --fail -X GET -o "$EXTTMP/apps.json" "https://apps.nextcloud.com/api/v1/apps.json"

jq \
	-c \
	--argjson ps "$NCVERSION" \
	--argjson filter \
	"$(jq \
		-r \
		'[.[].name]|reduce .[] as $a (""; .+",\""+$a+"\"")|ltrimstr(",")|"["+.+"]"' \
		<"$1")" \
	'
    def versionCompatible(rPVS):
      rPVS |
      capture("^>=(?<a>[0-9]+) <=(?<b>[0-9]+)$") |
      (.a | tonumber | . <= $ps) and (.b | tonumber | $ps <= .);
    def license(l):
      {
        "agpl": "agpl3Plus"
      }[l];

    .[] |
    select(
      .id |
      IN($filter[])
    ) |
    { id
    , package:
      .releases |
      map(select(
        .isNightly == false and
        (.version | contains("-") | not) and
        versionCompatible(.rawPlatformVersionSpec)
      )) |
      .[0]
    , description: .translations.en.summary
    } |
    select(.package != null) |
    { name: .id
    , version: .package.version
    , url: .package.download
    , license: license(.package.licenses[0])
    , description
    }
  ' \
	<"$EXTTMP/apps.json" |
	while read -r line; do
		echo "$line" |
			jq --arg hashsum "$(nix-prefetch-url --unpack "$(echo "$line" | jq -r '.url')")" '.sha256 |= $hashsum'
	done |
	jq -s '. | sort_by(.name)'

# Clean up.
rm -Rf "$EXTTMP"
