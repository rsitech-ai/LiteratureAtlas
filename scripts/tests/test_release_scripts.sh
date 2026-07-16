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

assert_stdout_contains() {
    name=$1
    expected=$2
    if grep -F -- "$expected" "$TMP/stdout" >/dev/null; then
        pass "$name"
    else
        fail "$name"
        sed -n '1,20p' "$TMP/stdout" >&2
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
expect_failure "community build rejects xcconfig newline injection" \
    "$ROOT/script/build_community.sh" --product-name $'Safe\nOTHER_SETTING = injected' --bundle-id org.example.Safe --version 1.0.0 --build 1 --output "$TMP/out" --dry-run
expect_failure "community build rejects trailing product whitespace" \
    "$ROOT/script/build_community.sh" --product-name 'Safe ' --bundle-id org.example.Safe --version 1.0.0 --build 1 --output "$TMP/out" --dry-run
expect_failure "community build rejects unsafe bundle identifier" \
    "$ROOT/script/build_community.sh" --product-name Safe --bundle-id 'bad bundle' --version 1.0.0 --build 1 --output "$TMP/out" --dry-run
expect_failure "community build refuses filesystem root output" \
    "$ROOT/script/build_community.sh" --product-name Safe --bundle-id org.example.Safe --version 1.0.0 --build 1 --output / --dry-run
expect_success "community build validates a credential-free dry run" \
    "$ROOT/script/build_community.sh" --product-name LiteratureAtlasCommunity --bundle-id org.example.LiteratureAtlasCommunity --version 1.0.0 --build 1 --output "$TMP/community" --dry-run
assert_stdout_contains "community dry run overrides the display name" 'INFOPLIST_KEY_CFBundleDisplayName=LiteratureAtlasCommunity'
expect_failure "community build rejects trailing-dot bundle identifier" \
    "$ROOT/script/build_community.sh" --product-name Safe --bundle-id 'org.example.' --version 1.0.0 --build 1 --output "$TMP/out" --dry-run

display_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$ROOT/Resources/macOS/Info.plist")
if [ "$display_name" = '$(PRODUCT_NAME)' ]; then
    pass "macOS display name follows the selected product name"
else
    fail "macOS display name follows the selected product name"
fi

if grep -F 'effective_xcconfig=' "$ROOT/script/release_common.sh" >/dev/null \
    && grep -F 'LITERATURE_ATLAS_SOURCE_REVISION = $source_revision' "$ROOT/script/release_common.sh" >/dev/null \
    && grep -F 'MARKETING_VERSION = $version' "$ROOT/script/release_common.sh" >/dev/null \
    && grep -F 'CURRENT_PROJECT_VERSION = $build_number' "$ROOT/script/release_common.sh" >/dev/null; then
    pass "release builds bind identity and provenance in the effective xcconfig"
else
    fail "release builds bind identity and provenance in the effective xcconfig"
fi

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

mkdir -p "$TMP/NoRuntime.app/Contents/MacOS" "$TMP/NoRuntime.app/Contents/Resources/Prompts"
xcrun clang -x c -o "$TMP/TestExecutable" - <<<'int main(void) { return 0; }'
ditto "$TMP/TestExecutable" "$TMP/NoRuntime.app/Contents/MacOS/NoRuntime"
plutil -create xml1 "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert CFBundleExecutable -string NoRuntime "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert CFBundleIdentifier -string org.example.NoRuntime "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert CFBundleName -string NoRuntime "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert CFBundleDisplayName -string NoRuntime "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert CFBundleShortVersionString -string 1.0.0 "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert CFBundleVersion -string 1 "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -insert LSMinimumSystemVersion -string 26.0 "$TMP/NoRuntime.app/Contents/Info.plist"
plutil -create xml1 "$TMP/NoRuntime.app/Contents/Resources/PrivacyInfo.xcprivacy"
plutil -create xml1 "$TMP/NoRuntime.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.app-sandbox bool true' "$TMP/NoRuntime.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.files.bookmarks.app-scope bool true' "$TMP/NoRuntime.entitlements"
codesign --force --sign - --entitlements "$TMP/NoRuntime.entitlements" "$TMP/NoRuntime.app" >/dev/null 2>&1
expect_failure "verification rejects an app without hardened runtime" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/NoRuntime.app" --mode community
assert_stderr_contains "missing runtime failure names hardened runtime" "hardened runtime is missing"

mkdir -p "$TMP/Expected.app/Contents/MacOS" "$TMP/Expected.app/Contents/Resources/Prompts"
ditto "$TMP/TestExecutable" "$TMP/Expected.app/Contents/MacOS/Expected"
plutil -create xml1 "$TMP/Expected.app/Contents/Info.plist"
plutil -insert CFBundleExecutable -string Expected "$TMP/Expected.app/Contents/Info.plist"
plutil -insert CFBundleIdentifier -string org.example.Expected "$TMP/Expected.app/Contents/Info.plist"
plutil -insert CFBundleName -string Expected "$TMP/Expected.app/Contents/Info.plist"
plutil -insert CFBundleDisplayName -string Expected "$TMP/Expected.app/Contents/Info.plist"
plutil -insert CFBundleShortVersionString -string 1.0.0 "$TMP/Expected.app/Contents/Info.plist"
plutil -insert CFBundleVersion -string 1 "$TMP/Expected.app/Contents/Info.plist"
plutil -insert LSMinimumSystemVersion -string 26.0 "$TMP/Expected.app/Contents/Info.plist"
plutil -create xml1 "$TMP/Expected.app/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options runtime --entitlements "$TMP/NoRuntime.entitlements" "$TMP/Expected.app" >/dev/null 2>&1
expect_success "valid runtime-signed community fixture passes without a DMG" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/Expected.app" --mode community
mkdir -p "$TMP/WrongDMG"
touch "$TMP/WrongDMG/Not-The-App"
hdiutil create -quiet -fs HFS+ -format UDZO -volname Wrong -srcfolder "$TMP/WrongDMG" "$TMP/Wrong.dmg"
expect_failure "verification rejects a DMG that does not contain the supplied app" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/Expected.app" --dmg "$TMP/Wrong.dmg" --mode community
assert_stderr_contains "wrong DMG failure names missing app" "DMG does not contain Expected.app"

mkdir -p "$TMP/ModeMismatchDMG"
ditto "$TMP/Expected.app" "$TMP/ModeMismatchDMG/Expected.app"
chmod -x "$TMP/ModeMismatchDMG/Expected.app/Contents/MacOS/Expected"
hdiutil create -quiet -fs HFS+ -format UDZO -volname ModeMismatch -srcfolder "$TMP/ModeMismatchDMG" "$TMP/ModeMismatch.dmg"
expect_failure "verification rejects a DMG app with changed executable mode" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/Expected.app" --dmg "$TMP/ModeMismatch.dmg" --mode community
assert_stderr_contains "mode mismatch failure names supplied-app mismatch" "DMG app does not match the supplied app"

mkdir -p "$TMP/ValidDMG"
ditto "$TMP/Expected.app" "$TMP/ValidDMG/Expected.app"
hdiutil create -quiet -fs HFS+ -format UDZO -volname Valid -srcfolder "$TMP/ValidDMG" "$TMP/Valid.dmg"
expect_success "verification accepts a DMG containing the exact supplied app" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/Expected.app" --dmg "$TMP/Valid.dmg" --mode community

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

if grep -F 'shasum -a 256 "$dmg" >"$dmg.sha256"' "$ROOT/script/notarize_dmg.sh" >/dev/null; then
    pass "notarization refreshes checksum after stapling"
else
    fail "notarization refreshes checksum after stapling"
fi

if grep -F "grep -E 'flags=.*(runtime)'" "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F "grep -F 'Timestamp='" "$ROOT/script/verify_distribution.sh" >/dev/null; then
    pass "official verification requires hardened runtime and secure timestamp"
else
    fail "official verification requires hardened runtime and secure timestamp"
fi

for workflow in dependency-review.yml license-compliance.yml codeql.yml; do
    if grep -Eq '^  pull_request:' "$ROOT/.github/workflows/$workflow"; then
        pass "$workflow runs on pull requests"
    else
        fail "$workflow runs on pull requests"
    fi
done

if grep -F -- '--remove-signature' "$ROOT/script/build_official.sh" >/dev/null \
    && grep -F 'code object is not signed at all' "$ROOT/script/build_official.sh" >/dev/null; then
    pass "official build proves a signature-free pre-sign candidate"
else
    fail "official build proves a signature-free pre-sign candidate"
fi

if grep -F -- '--expected-bundle-id' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F -- '--expected-team-id' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F -- '--expected-version' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F -- '--expected-build' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F -- '--expected-architecture' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F -- '--expected-min-macos' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F -- '--expected-source-revision' "$ROOT/script/verify_distribution.sh" >/dev/null; then
    pass "official verification binds owner-approved release identity"
else
    fail "official verification binds owner-approved release identity"
fi

if grep -F 'source_dsym=' "$ROOT/script/release_common.sh" >/dev/null \
    && grep -F 'ditto "$source_dsym" "$target_dsym"' "$ROOT/script/release_common.sh" >/dev/null; then
    pass "release builds retain dSYM evidence"
else
    fail "release builds retain dSYM evidence"
fi

if grep -F 'release_print_command xcodebuild -quiet' "$ROOT/script/release_common.sh" >/dev/null \
    && grep -F '        -quiet \' "$ROOT/script/release_common.sh" >/dev/null; then
    pass "release builds keep Xcode output diagnostic-focused"
else
    fail "release builds keep Xcode output diagnostic-focused"
fi

if grep -F 'response_tmp=' "$ROOT/script/notarize_dmg.sh" >/dev/null \
    && grep -F 'mv "$response_tmp" "$response_output"' "$ROOT/script/notarize_dmg.sh" >/dev/null; then
    pass "notarization publishes submission evidence atomically"
else
    fail "notarization publishes submission evidence atomically"
fi

if grep -F 'LITERATURE_ATLAS_SOURCE_REVISION=' "$ROOT/script/release_common.sh" >/dev/null \
    && grep -F -- '--expected-source-revision' "$ROOT/script/verify_distribution.sh" >/dev/null \
    && grep -F 'LiteratureAtlasSourceRevision' "$ROOT/Resources/macOS/Info.plist" >/dev/null; then
    pass "official artifacts bind an embedded source revision"
else
    fail "official artifacts bind an embedded source revision"
fi

if [ "$failures" -ne 0 ]; then
    printf '%s release-script test(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'All release-script tests passed\n'
