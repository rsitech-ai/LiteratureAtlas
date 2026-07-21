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
expected_sha256=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dmg) [ "$#" -ge 2 ] || release_die "--dmg requires a value"; dmg=$2; shift 2 ;;
        --keychain-profile) [ "$#" -ge 2 ] || release_die "--keychain-profile requires a value"; profile=$2; shift 2 ;;
        --response-output) [ "$#" -ge 2 ] || release_die "--response-output requires a value"; response_output=$2; shift 2 ;;
        --log-output) [ "$#" -ge 2 ] || release_die "--log-output requires a value"; log_output=$2; shift 2 ;;
        --expected-sha256) [ "$#" -ge 2 ] || release_die "--expected-sha256 requires a value"; expected_sha256=$2; shift 2 ;;
        --submit) submit=true; shift ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

[ -n "$dmg" ] || release_die "missing --dmg"
[ -n "$profile" ] || release_die "missing --keychain-profile"
[ -f "$dmg" ] || release_die "DMG not found: $dmg"
[ "$submit" = true ] || release_die "notarization requires --submit and task-specific owner approval"
[ -n "$expected_sha256" ] || release_die "notarization requires --expected-sha256 for the approved DMG"
release_require_command awk
release_require_command shasum
release_require_command tr
printf '%s' "$expected_sha256" | LC_ALL=C grep -Eq '^[0-9a-fA-F]{64}$' \
    || release_die "invalid --expected-sha256"
actual_sha256=$(shasum -a 256 "$dmg" | awk '{print $1}')
[ "$(printf '%s' "$actual_sha256" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$expected_sha256" | tr '[:upper:]' '[:lower:]')" ] \
    || release_die "DMG SHA-256 does not match the owner-approved artifact"

release_require_command xcrun
release_require_command plutil

dmg_without_extension=${dmg%.dmg}
[ -n "$response_output" ] || response_output="$dmg_without_extension.notary-submission.json"
[ -n "$log_output" ] || log_output="$dmg_without_extension.notary-log.json"
response_parent=$(dirname "$response_output")
log_parent=$(dirname "$log_output")
mkdir -p "$response_parent" "$log_parent"
response_output_canonical=$(cd "$response_parent" && printf '%s/%s' "$(pwd -P)" "$(basename "$response_output")")
log_output_canonical=$(cd "$log_parent" && printf '%s/%s' "$(pwd -P)" "$(basename "$log_output")")
[ "$response_output_canonical" != "$log_output_canonical" ] \
    || release_die "submission response and notary log must be different paths"
[ ! -e "$response_output" ] || release_die "submission response output already exists: $response_output"
[ ! -e "$log_output" ] || release_die "notary log output already exists: $log_output"

response_tmp=$(mktemp "$response_parent/.notary-response.XXXXXX")
log_tmp=$(mktemp "$log_parent/.notary-log.XXXXXX")
cleanup() {
    rm -f "$response_tmp" "$log_tmp"
}
trap cleanup EXIT

xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait \
    --output-format json >"$response_tmp"

submission_id=$(plutil -extract id raw -o - "$response_tmp" 2>/dev/null) \
    || release_die "notary response did not contain a submission id"
status=$(plutil -extract status raw -o - "$response_tmp" 2>/dev/null) \
    || release_die "notary response did not contain a status"

# Preserve Apple's complete diagnostic record for both accepted and rejected submissions.
xcrun notarytool log "$submission_id" --keychain-profile "$profile" "$log_tmp"
mv "$response_tmp" "$response_output"
mv "$log_tmp" "$log_output"
[ "$status" = Accepted ] \
    || release_die "notarization status was $status; inspect $response_output and $log_output"

xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
# The disk image is an unsigned transport container. Gatekeeper evaluates the
# Developer ID-signed app in verify_distribution.sh; stapler validates the
# notarization ticket attached to this exact submitted DMG.
release_write_sha256_file "$dmg"
trap - EXIT
printf 'Notarized and stapled DMG: %s\nSubmission: %s\nResponse: %s\nLog: %s\n' \
    "$dmg" "$submission_id" "$response_output" "$log_output"
