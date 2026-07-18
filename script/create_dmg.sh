#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

app=
output=
volume_name=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) [ "$#" -ge 2 ] || release_die "--app requires a value"; app=$2; shift 2 ;;
        --output) [ "$#" -ge 2 ] || release_die "--output requires a value"; output=$2; shift 2 ;;
        --volume-name) [ "$#" -ge 2 ] || release_die "--volume-name requires a value"; volume_name=$2; shift 2 ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

[ -n "$app" ] || release_die "missing --app"
[ -n "$output" ] || release_die "missing --output"
[ -d "$app/Contents" ] || release_die "app bundle not found: $app"
case "$output" in
    *.dmg) ;;
    *) release_die "output must end in .dmg" ;;
esac
[ ! -e "$output" ] || release_die "output already exists: $output"

release_require_command hdiutil
release_require_command ditto

app_name=$(basename -- "$app" .app)
[ -n "$volume_name" ] || volume_name="$app_name"
release_validate_product_name "$volume_name"

mkdir -p "$(dirname -- "$output")"
output=$(cd "$(dirname -- "$output")" && printf '%s/%s' "$(pwd -P)" "$(basename -- "$output")")
stage=$(mktemp -d "${TMPDIR:-/tmp}/literatureatlas-dmg.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/$(basename -- "$app")"
ln -s /Applications "$stage/Applications"
hdiutil create -quiet -fs HFS+ -format UDZO -imagekey zlib-level=9 \
    -volname "$volume_name" -srcfolder "$stage" "$output"
hdiutil verify "$output" >/dev/null
release_write_sha256_file "$output"
printf 'DMG: %s\nChecksum: %s.sha256\n' "$output" "$output"
