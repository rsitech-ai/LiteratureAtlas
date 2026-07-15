#!/bin/bash
set -u

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/literatureatlas-release-tests.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

failures=0

pass() {
    printf 'PASS %s\n' "$1"
}

fail() {
    printf 'FAIL %s\n' "$1" >&2
    failures=$((failures + 1))
}

expect_success() {
    name=$1
    shift
    if "$@" >"$TMP/stdout" 2>"$TMP/stderr"; then
        pass "$name"
    else
        fail "$name"
        sed -n '1,20p' "$TMP/stderr" >&2
    fi
}

expect_failure() {
    name=$1
    shift
    if "$@" >"$TMP/stdout" 2>"$TMP/stderr"; then
        fail "$name"
    else
        pass "$name"
    fi
}

assert_stderr_contains() {
    name=$1
    expected=$2
    if grep -F -- "$expected" "$TMP/stderr" >/dev/null; then
        pass "$name"
    else
        fail "$name"
        sed -n '1,20p' "$TMP/stderr" >&2
    fi
}

required_scripts="
script/build_community.sh
script/build_official.sh
script/sign_developer_id.sh
script/create_dmg.sh
script/notarize_dmg.sh
script/verify_distribution.sh
"

for relative in $required_scripts; do
    if [ -x "$ROOT/$relative" ]; then
        pass "$relative is executable"
    else
        fail "$relative is executable"
    fi
done

expect_failure "community build rejects missing arguments" "$ROOT/script/build_community.sh"
expect_failure "community build rejects unsafe product name" \
    "$ROOT/script/build_community.sh" --product-name '../Bad' --bundle-id org.example.Bad --version 1.0.0 --build 1 --output "$TMP/out" --dry-run
expect_failure "community build rejects unsafe bundle identifier" \
    "$ROOT/script/build_community.sh" --product-name Safe --bundle-id 'bad bundle' --version 1.0.0 --build 1 --output "$TMP/out" --dry-run
expect_failure "community build refuses filesystem root output" \
    "$ROOT/script/build_community.sh" --product-name Safe --bundle-id org.example.Safe --version 1.0.0 --build 1 --output / --dry-run
expect_success "community build validates a credential-free dry run" \
    "$ROOT/script/build_community.sh" --product-name LiteratureAtlasCommunity --bundle-id org.example.LiteratureAtlasCommunity --version 1.0.0 --build 1 --output "$TMP/community" --dry-run

mkdir -p "$TMP/Fake.app/Contents/MacOS"
expect_failure "official signer rejects non-Developer-ID identity" \
    "$ROOT/script/sign_developer_id.sh" --app "$TMP/Fake.app" --identity 'Apple Development: Example'
expect_failure "official signer rejects missing identity" \
    "$ROOT/script/sign_developer_id.sh" --app "$TMP/Fake.app"

touch "$TMP/Fake.dmg"
expect_failure "notarization refuses implicit submission" \
    "$ROOT/script/notarize_dmg.sh" --dmg "$TMP/Fake.dmg" --keychain-profile Example
assert_stderr_contains "notarization names explicit approval flag" "requires --submit"

expect_failure "corpus smoke rejects an implicit sample source" \
    "$ROOT/scripts/run_example_smoke.sh" --count 1
assert_stderr_contains "corpus smoke requires authorized user input" "--source DIR is required"

expect_failure "DMG creation rejects missing app bundle" \
    "$ROOT/script/create_dmg.sh" --app "$TMP/Missing.app" --output "$TMP/Fake.dmg"
expect_failure "verification rejects unknown mode" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/Fake.app" --mode unknown

if grep -R "notarytool submit" "$TMP" >/dev/null 2>&1; then
    fail "tests perform no notarization submission"
else
    pass "tests perform no notarization submission"
fi

if grep -F -- '--output-format json' "$ROOT/script/notarize_dmg.sh" >/dev/null \
    && grep -F 'notarytool log' "$ROOT/script/notarize_dmg.sh" >/dev/null; then
    pass "notarization records structured submission evidence"
else
    fail "notarization records structured submission evidence"
fi

if grep -F -- '--remove-signature' "$ROOT/script/build_official.sh" >/dev/null \
    && grep -F 'code object is not signed at all' "$ROOT/script/build_official.sh" >/dev/null; then
    pass "official build proves a signature-free pre-sign candidate"
else
    fail "official build proves a signature-free pre-sign candidate"
fi

if [ "$failures" -ne 0 ]; then
    printf '%s release-script test(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'All release-script tests passed\n'
