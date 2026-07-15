#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

dmg=
profile=
submit=false
response_output=
log_output=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dmg) [ "$#" -ge 2 ] || release_die "--dmg requires a value"; dmg=$2; shift 2 ;;
        --keychain-profile) [ "$#" -ge 2 ] || release_die "--keychain-profile requires a value"; profile=$2; shift 2 ;;
        --response-output) [ "$#" -ge 2 ] || release_die "--response-output requires a value"; response_output=$2; shift 2 ;;
        --log-output) [ "$#" -ge 2 ] || release_die "--log-output requires a value"; log_output=$2; shift 2 ;;
        --submit) submit=true; shift ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

[ -n "$dmg" ] || release_die "missing --dmg"
[ -n "$profile" ] || release_die "missing --keychain-profile"
[ -f "$dmg" ] || release_die "DMG not found: $dmg"
[ "$submit" = true ] || release_die "notarization requires --submit and task-specific owner approval"

release_require_command xcrun
release_require_command plutil

dmg_without_extension=${dmg%.dmg}
[ -n "$response_output" ] || response_output="$dmg_without_extension.notary-submission.json"
[ -n "$log_output" ] || log_output="$dmg_without_extension.notary-log.json"
[ ! -e "$response_output" ] || release_die "submission response output already exists: $response_output"
[ ! -e "$log_output" ] || release_die "notary log output already exists: $log_output"

response_parent=$(dirname "$response_output")
log_parent=$(dirname "$log_output")
mkdir -p "$response_parent" "$log_parent"

xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait \
    --output-format json >"$response_output"

submission_id=$(plutil -extract id raw -o - "$response_output" 2>/dev/null) \
    || release_die "notary response did not contain a submission id: $response_output"
status=$(plutil -extract status raw -o - "$response_output" 2>/dev/null) \
    || release_die "notary response did not contain a status: $response_output"

# Preserve Apple's complete diagnostic record for both accepted and rejected submissions.
xcrun notarytool log "$submission_id" --keychain-profile "$profile" "$log_output"
[ "$status" = Accepted ] \
    || release_die "notarization status was $status; inspect $response_output and $log_output"

xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl -a -vv -t open --context context:primary-signature "$dmg"
printf 'Notarized and stapled DMG: %s\nSubmission: %s\nResponse: %s\nLog: %s\n' \
    "$dmg" "$submission_id" "$response_output" "$log_output"
