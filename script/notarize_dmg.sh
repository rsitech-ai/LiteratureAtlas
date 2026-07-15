#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

dmg=
profile=
submit=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dmg) [ "$#" -ge 2 ] || release_die "--dmg requires a value"; dmg=$2; shift 2 ;;
        --keychain-profile) [ "$#" -ge 2 ] || release_die "--keychain-profile requires a value"; profile=$2; shift 2 ;;
        --submit) submit=true; shift ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

[ -n "$dmg" ] || release_die "missing --dmg"
[ -n "$profile" ] || release_die "missing --keychain-profile"
[ -f "$dmg" ] || release_die "DMG not found: $dmg"
[ "$submit" = true ] || release_die "notarization requires --submit and task-specific owner approval"

release_require_command xcrun
xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl -a -vv -t open --context context:primary-signature "$dmg"
printf 'Notarized and stapled DMG: %s\n' "$dmg"
