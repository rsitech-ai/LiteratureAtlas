#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

app=
identity=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) [ "$#" -ge 2 ] || release_die "--app requires a value"; app=$2; shift 2 ;;
        --identity) [ "$#" -ge 2 ] || release_die "--identity requires a value"; identity=$2; shift 2 ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

[ -n "$app" ] || release_die "missing --app"
[ -n "$identity" ] || release_die "missing --identity"
case "$identity" in
    "Developer ID Application: "*) ;;
    *) release_die "identity must be an exact Developer ID Application identity" ;;
esac
[ -d "$app/Contents" ] || release_die "app bundle not found: $app"

release_require_command security
release_require_command codesign
release_require_command ditto
security find-identity -v -p codesigning | grep -F "\"$identity\"" >/dev/null \
    || release_die "Developer ID Application identity is not installed: $identity"

entitlements="$ROOT/Resources/macOS/LiteratureAtlas.entitlements"
[ -f "$entitlements" ] || release_die "entitlements file not found: $entitlements"

app_parent=$(cd "$(dirname "$app")" && pwd)
app_name=$(basename "$app")
stage=$(mktemp -d "$app_parent/.literatureatlas-signing.XXXXXX")
candidate="$stage/$app_name"
backup=
cleanup() {
    if [ -n "$backup" ] && [ -e "$backup" ] && [ ! -e "$app" ]; then
        mv "$backup" "$app" || true
    fi
    rm -rf "$stage"
}
trap cleanup EXIT
trap 'exit 130' HUP INT
trap 'exit 143' TERM
ditto "$app" "$candidate"

for nested_root in Frameworks PlugIns XPCServices Library/SystemExtensions Extensions; do
    if [ -d "$candidate/Contents/$nested_root" ]; then
        find "$candidate/Contents/$nested_root" -depth \
            \( -name '*.framework' -o -name '*.dylib' -o -name '*.xpc' -o -name '*.appex' -o -perm -111 \) \
            -print | while IFS= read -r nested; do
                codesign --force --sign "$identity" --options runtime --timestamp "$nested"
            done
    fi
done

codesign --force --sign "$identity" --options runtime --timestamp \
    --entitlements "$entitlements" "$candidate"
codesign --verify --deep --strict --verbose=2 "$candidate"
codesign -dvv "$candidate" 2>&1 | grep -F "Authority=Developer ID Application:" >/dev/null \
    || release_die "signed app does not report Developer ID Application authority"

backup="$app_parent/.$app_name.unsigned.$$"
mv "$app" "$backup"
if mv "$candidate" "$app"; then
    rm -rf "$backup"
    backup=
else
    mv "$backup" "$app"
    backup=
    release_die "failed to replace unsigned app with verified signed app"
fi
rm -rf "$stage"
trap - EXIT
printf 'Developer ID signed app: %s\n' "$app"
