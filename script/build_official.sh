#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=release_common.sh
. "$ROOT/script/release_common.sh"

product_name=
bundle_id=
version=
build_number=
output=
dry_run=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --product-name) [ "$#" -ge 2 ] || release_die "--product-name requires a value"; product_name=$2; shift 2 ;;
        --bundle-id) [ "$#" -ge 2 ] || release_die "--bundle-id requires a value"; bundle_id=$2; shift 2 ;;
        --version) [ "$#" -ge 2 ] || release_die "--version requires a value"; version=$2; shift 2 ;;
        --build) [ "$#" -ge 2 ] || release_die "--build requires a value"; build_number=$2; shift 2 ;;
        --output) [ "$#" -ge 2 ] || release_die "--output requires a value"; output=$2; shift 2 ;;
        --dry-run) dry_run=true; shift ;;
        *) release_die "unknown argument: $1" ;;
    esac
done

[ -n "$product_name" ] || release_die "missing --product-name"
[ -n "$bundle_id" ] || release_die "missing --bundle-id"
[ -n "$version" ] || release_die "missing --version"
[ -n "$build_number" ] || release_die "missing --build"
[ -n "$output" ] || release_die "missing --output"

if [ "$dry_run" = true ]; then
    release_build_presign_app "$product_name" "$bundle_id" "$version" "$build_number" "$output" true
    exit 0
fi

app=$(release_build_presign_app "$product_name" "$bundle_id" "$version" "$build_number" "$output" false)
release_require_command codesign
codesign --remove-signature "$app"
if signature_details=$(codesign -dv "$app" 2>&1); then
    release_die "official pre-sign candidate unexpectedly retains a signature: $signature_details"
fi
printf '%s\n' "$signature_details" | grep -F 'code object is not signed at all' >/dev/null \
    || release_die "unable to prove signature-free candidate: $signature_details"
printf 'Signature-free official pre-sign candidate: %s\n' "$app"
printf 'Next: script/sign_developer_id.sh --app %q --identity %q\n' "$app" 'Developer ID Application: ...'
