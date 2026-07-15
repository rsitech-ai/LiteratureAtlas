#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

app=
dmg=
mode=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) [ "$#" -ge 2 ] || release_die "--app requires a value"; app=$2; shift 2 ;;
        --dmg) [ "$#" -ge 2 ] || release_die "--dmg requires a value"; dmg=$2; shift 2 ;;
        --mode) [ "$#" -ge 2 ] || release_die "--mode requires a value"; mode=$2; shift 2 ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

case "$mode" in
    community|official|notarized) ;;
    *) release_die "mode must be community, official, or notarized" ;;
esac
[ -n "$app" ] || release_die "missing --app"
[ -d "$app/Contents" ] || release_die "app bundle not found: $app"

release_require_command codesign
release_require_command plutil
release_require_command strings

info="$app/Contents/Info.plist"
executable_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$info" 2>/dev/null) \
    || release_die "CFBundleExecutable is missing"
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info" 2>/dev/null) \
    || release_die "CFBundleIdentifier is missing"
executable="$app/Contents/MacOS/$executable_name"
[ -x "$executable" ] || release_die "bundle executable is missing: $executable"
[ -d "$app/Contents/Resources/Prompts" ] || release_die "bundled prompts are missing"
[ -f "$app/Contents/Resources/PrivacyInfo.xcprivacy" ] || release_die "privacy manifest is missing"

if LC_ALL=C strings "$executable" | grep -E 'OPENAI_API_KEY|rebuild_analytics\.py|\.venv/bin/python|libatlas_ffi\.dylib' >/dev/null; then
    release_die "distributed executable contains a checkout-only runtime marker"
fi

codesign --verify --deep --strict --verbose=2 "$app"
details=$(codesign -dvv "$app" 2>&1)
entitlements=$(mktemp "${TMPDIR:-/tmp}/literatureatlas-entitlements.XXXXXX")
trap 'rm -f "$entitlements"' EXIT
codesign -d --entitlements :- "$app" >"$entitlements" 2>/dev/null
plutil -extract 'com\.apple\.security\.app-sandbox' raw -o - "$entitlements" 2>/dev/null | grep -Fx true >/dev/null \
    || release_die "app sandbox entitlement is missing"
if plutil -extract 'com\.apple\.security\.get-task-allow' raw -o - "$entitlements" >/dev/null 2>&1; then
    release_die "debug get-task-allow entitlement must not ship"
fi

case "$mode" in
    community)
        printf '%s\n' "$details" | grep -F 'Signature=adhoc' >/dev/null \
            || release_die "community app is not ad-hoc signed"
        ;;
    official|notarized)
        printf '%s\n' "$details" | grep -F 'Authority=Developer ID Application:' >/dev/null \
            || release_die "official app is not signed with Developer ID Application"
        ;;
esac

if [ -n "$dmg" ]; then
    [ -f "$dmg" ] || release_die "DMG not found: $dmg"
    hdiutil verify "$dmg" >/dev/null
fi

if [ "$mode" = notarized ]; then
    xcrun stapler validate "$app"
    [ -z "$dmg" ] || xcrun stapler validate "$dmg"
    spctl -a -vv -t exec "$app"
fi

printf '{"ok":true,"mode":"%s","bundle_id":"%s","app":"%s"}\n' \
    "$mode" "$bundle_id" "$app"
