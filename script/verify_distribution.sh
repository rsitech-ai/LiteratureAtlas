#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

app=
dmg=
mode=
expected_bundle_id=
expected_team_id=
expected_version=
expected_build=
expected_architecture=
expected_min_macos=
expected_source_revision=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) [ "$#" -ge 2 ] || release_die "--app requires a value"; app=$2; shift 2 ;;
        --dmg) [ "$#" -ge 2 ] || release_die "--dmg requires a value"; dmg=$2; shift 2 ;;
        --mode) [ "$#" -ge 2 ] || release_die "--mode requires a value"; mode=$2; shift 2 ;;
        --expected-bundle-id) [ "$#" -ge 2 ] || release_die "--expected-bundle-id requires a value"; expected_bundle_id=$2; shift 2 ;;
        --expected-team-id) [ "$#" -ge 2 ] || release_die "--expected-team-id requires a value"; expected_team_id=$2; shift 2 ;;
        --expected-version) [ "$#" -ge 2 ] || release_die "--expected-version requires a value"; expected_version=$2; shift 2 ;;
        --expected-build) [ "$#" -ge 2 ] || release_die "--expected-build requires a value"; expected_build=$2; shift 2 ;;
        --expected-architecture) [ "$#" -ge 2 ] || release_die "--expected-architecture requires a value"; expected_architecture=$2; shift 2 ;;
        --expected-min-macos) [ "$#" -ge 2 ] || release_die "--expected-min-macos requires a value"; expected_min_macos=$2; shift 2 ;;
        --expected-source-revision) [ "$#" -ge 2 ] || release_die "--expected-source-revision requires a value"; expected_source_revision=$2; shift 2 ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

case "$mode" in
    community|official|notarized) ;;
    *) release_die "mode must be community, official, or notarized" ;;
esac
[ -n "$app" ] || release_die "missing --app"
[ -d "$app/Contents" ] || release_die "app bundle not found: $app"

if [ "$mode" != community ]; then
    [ -n "$expected_bundle_id" ] || release_die "official verification requires --expected-bundle-id"
    [ -n "$expected_team_id" ] || release_die "official verification requires --expected-team-id"
    [ -n "$expected_version" ] || release_die "official verification requires --expected-version"
    [ -n "$expected_build" ] || release_die "official verification requires --expected-build"
    [ -n "$expected_architecture" ] || release_die "official verification requires --expected-architecture"
    [ -n "$expected_min_macos" ] || release_die "official verification requires --expected-min-macos"
    [ -n "$expected_source_revision" ] || release_die "official verification requires --expected-source-revision"
    release_validate_bundle_id "$expected_bundle_id"
    release_validate_version "$expected_version"
    release_validate_build_number "$expected_build"
    printf '%s' "$expected_team_id" | LC_ALL=C grep -Eq '^[A-Z0-9]{10}$' \
        || release_die "invalid expected Team ID: $expected_team_id"
    printf '%s' "$expected_architecture" | LC_ALL=C grep -Eq '^[A-Za-z0-9_]+$' \
        || release_die "invalid expected architecture: $expected_architecture"
    release_validate_version "$expected_min_macos"
    printf '%s' "$expected_source_revision" | LC_ALL=C grep -Eq '^[0-9a-f]{40}$' \
        || release_die "invalid expected source revision: $expected_source_revision"
fi

release_require_command codesign
release_require_command diff
release_require_command find
release_require_command lipo
release_require_command awk
release_require_command readlink
release_require_command plutil
release_require_command shasum
release_require_command stat
release_require_command strings

write_app_manifest() {
    manifest_app=$1
    manifest_output=$2
    manifest_parent=$(dirname "$manifest_app")
    manifest_name=$(basename "$manifest_app")
    (
        cd "$manifest_parent"
        find "$manifest_name" -print | LC_ALL=C sort | while IFS= read -r item; do
            mode=$(stat -f '%Lp' "$item")
            if [ -L "$item" ]; then
                printf 'L\t%s\t%s\t%s\n' "$mode" "$item" "$(readlink "$item")"
            elif [ -f "$item" ]; then
                size=$(stat -f '%z' "$item")
                digest=$(shasum -a 256 "$item" | awk '{print $1}')
                printf 'F\t%s\t%s\t%s\t%s\n' "$mode" "$size" "$digest" "$item"
            elif [ -d "$item" ]; then
                printf 'D\t%s\t%s\n' "$mode" "$item"
            else
                printf 'O\t%s\t%s\n' "$mode" "$item"
            fi
        done
    ) >"$manifest_output"
}

info="$app/Contents/Info.plist"
executable_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$info" 2>/dev/null) \
    || release_die "CFBundleExecutable is missing"
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info" 2>/dev/null) \
    || release_die "CFBundleIdentifier is missing"
bundle_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$info" 2>/dev/null) \
    || release_die "CFBundleName is missing"
display_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$info" 2>/dev/null) \
    || release_die "CFBundleDisplayName is missing"
bundle_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info" 2>/dev/null) \
    || release_die "CFBundleShortVersionString is missing"
bundle_build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$info" 2>/dev/null) \
    || release_die "CFBundleVersion is missing"
minimum_macos=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$info" 2>/dev/null) \
    || release_die "LSMinimumSystemVersion is missing"
source_revision=$(/usr/libexec/PlistBuddy -c 'Print :LiteratureAtlasSourceRevision' "$info" 2>/dev/null || true)
expected_name=$(basename "$app" .app)
[ "$executable_name" = "$expected_name" ] \
    || release_die "CFBundleExecutable does not match the app name: $executable_name"
[ "$bundle_name" = "$expected_name" ] \
    || release_die "CFBundleName does not match the app name: $bundle_name"
[ "$display_name" = "$expected_name" ] \
    || release_die "CFBundleDisplayName does not match the app name: $display_name"
release_validate_bundle_id "$bundle_id"
executable="$app/Contents/MacOS/$executable_name"
[ -x "$executable" ] || release_die "bundle executable is missing: $executable"
[ -d "$app/Contents/Resources/Prompts" ] || release_die "bundled prompts are missing"
[ -f "$app/Contents/Resources/PrivacyInfo.xcprivacy" ] || release_die "privacy manifest is missing"

if LC_ALL=C strings "$executable" | grep -E 'OPENAI_API_KEY|rebuild_analytics\.py|\.venv/bin/python|libatlas_ffi\.dylib|LITERATURE_ATLAS_PROMPTS_DIR|LITERATURE_ATLAS_SMOKE_FAST' >/dev/null; then
    release_die "distributed executable contains a checkout-only runtime marker"
fi

codesign --verify --deep --strict --verbose=2 "$app"
details=$(codesign -dvv "$app" 2>&1)
printf '%s\n' "$details" | grep -E 'flags=.*(runtime)' >/dev/null \
    || release_die "hardened runtime is missing"
entitlements=$(mktemp "${TMPDIR:-/tmp}/literatureatlas-entitlements.XXXXXX")
mount_point=
source_manifest=
embedded_manifest=
cleanup() {
    if [ -n "$mount_point" ] && mount | grep -F " on $mount_point " >/dev/null 2>&1; then
        hdiutil detach "$mount_point" -quiet || true
    fi
    rm -f "$entitlements"
    [ -z "$source_manifest" ] || rm -f "$source_manifest"
    [ -z "$embedded_manifest" ] || rm -f "$embedded_manifest"
    if [ -n "$mount_point" ]; then
        rmdir "$mount_point" 2>/dev/null || true
    fi
}
trap cleanup EXIT
codesign -d --entitlements :- "$app" >"$entitlements" 2>/dev/null
plutil -extract 'com\.apple\.security\.app-sandbox' raw -o - "$entitlements" 2>/dev/null | grep -Fx true >/dev/null \
    || release_die "app sandbox entitlement is missing"
plutil -extract 'com\.apple\.security\.files\.bookmarks\.app-scope' raw -o - "$entitlements" 2>/dev/null | grep -Fx true >/dev/null \
    || release_die "app-scoped bookmark entitlement is missing"
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
        printf '%s\n' "$details" | grep -F 'Timestamp=' >/dev/null \
            || release_die "official app is missing a secure timestamp"
        team_id=$(printf '%s\n' "$details" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
        [ "$bundle_id" = "$expected_bundle_id" ] \
            || release_die "bundle identifier does not match owner-approved identity"
        [ "$team_id" = "$expected_team_id" ] \
            || release_die "Team ID does not match owner-approved identity"
        [ "$bundle_version" = "$expected_version" ] \
            || release_die "version does not match owner-approved release"
        [ "$bundle_build" = "$expected_build" ] \
            || release_die "build does not match owner-approved release"
        [ "$minimum_macos" = "$expected_min_macos" ] \
            || release_die "minimum macOS does not match owner-approved release"
        [ "$source_revision" = "$expected_source_revision" ] \
            || release_die "source revision does not match the approved release source"
        architectures=$(lipo -archs "$executable")
        [ "$architectures" = "$expected_architecture" ] \
            || release_die "architecture does not match owner-approved release: $architectures"
        ;;
esac

if [ -n "$dmg" ]; then
    release_require_command hdiutil
    release_require_command mount
    [ -f "$dmg" ] || release_die "DMG not found: $dmg"
    hdiutil verify "$dmg" >/dev/null
    mount_point=$(mktemp -d "${TMPDIR:-/tmp}/literatureatlas-dmg-verify.XXXXXX")
    hdiutil attach -quiet -readonly -nobrowse -mountpoint "$mount_point" "$dmg"
    embedded_app="$mount_point/$(basename "$app")"
    [ -d "$embedded_app/Contents" ] \
        || release_die "DMG does not contain $(basename "$app")"
    embedded_executable="$embedded_app/Contents/MacOS/$executable_name"
    [ -x "$embedded_executable" ] \
        || release_die "DMG app does not match the supplied app"
    codesign --verify --deep --strict --verbose=2 "$embedded_app" \
        || release_die "DMG app signature is invalid"
    source_manifest=$(mktemp "${TMPDIR:-/tmp}/literatureatlas-source-manifest.XXXXXX")
    embedded_manifest=$(mktemp "${TMPDIR:-/tmp}/literatureatlas-embedded-manifest.XXXXXX")
    write_app_manifest "$app" "$source_manifest"
    write_app_manifest "$embedded_app" "$embedded_manifest"
    diff -u "$source_manifest" "$embedded_manifest" >/dev/null \
        || release_die "DMG app does not match the supplied app"
    hdiutil detach "$mount_point" -quiet
    rmdir "$mount_point"
    mount_point=
fi

if [ "$mode" = notarized ]; then
    if [ -n "$dmg" ]; then
        # The DMG is the submitted and stapled artifact. Stapling the app after
        # creating the DMG would change content that Apple did not notarize.
        xcrun stapler validate "$dmg"
    else
        xcrun stapler validate "$app"
    fi
    spctl -a -vv -t exec "$app"
fi

printf '{"ok":true,"mode":"%s","bundle_id":"%s","app":"%s"}\n' \
    "$mode" "$bundle_id" "$app"
