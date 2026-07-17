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
scripts/classify_dependency_graph_status.sh
"

for relative in $required_scripts; do
    if [ -x "$ROOT/$relative" ]; then
        pass "$relative is executable"
    else
        fail "$relative is executable"
    fi
done

dependency_graph_classifier="$ROOT/scripts/classify_dependency_graph_status.sh"
expect_success "dependency graph classifier accepts an available graph" \
    "$dependency_graph_classifier" 200 200
assert_stdout_contains "available dependency graph emits a true output" "available=true"
expect_success "dependency graph classifier recognizes a missing graph on an accessible repository" \
    "$dependency_graph_classifier" 200 404
assert_stdout_contains "unavailable dependency graph emits a false output" "available=false"
assert_stderr_contains "unavailable dependency graph emits an explicit workflow warning" "::warning::Dependency graph is unavailable"
expect_failure "dependency graph classifier rejects forbidden graph access" \
    "$dependency_graph_classifier" 200 403
expect_failure "dependency graph classifier rejects a missing repository" \
    "$dependency_graph_classifier" 404 404
expect_failure "dependency graph classifier rejects forbidden repository access" \
    "$dependency_graph_classifier" 403 404
expect_failure "dependency graph classifier rejects unexpected API status" \
    "$dependency_graph_classifier" 200 500

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
fake_dmg_sha=$(shasum -a 256 "$TMP/Fake.dmg" | awk '{print $1}')
expect_failure "notarization rejects colliding evidence outputs before submission" \
    "$ROOT/script/notarize_dmg.sh" --dmg "$TMP/Fake.dmg" --keychain-profile Example \
    --submit --expected-sha256 "$fake_dmg_sha" \
    --response-output "$TMP/notary.json" --log-output "$TMP/notary.json"
assert_stderr_contains "colliding notarization outputs name the defect" "must be different paths"
mkdir -p "$TMP/notary-alias/subdir"
expect_failure "notarization rejects aliased evidence outputs before submission" \
    "$ROOT/script/notarize_dmg.sh" --dmg "$TMP/Fake.dmg" --keychain-profile Example \
    --submit --expected-sha256 "$fake_dmg_sha" \
    --response-output "$TMP/notary-alias/evidence.json" \
    --log-output "$TMP/notary-alias/subdir/../evidence.json"
assert_stderr_contains "aliased notarization outputs name the defect" "must be different paths"

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
ditto "$ROOT/Resources/macOS/PrivacyInfo.xcprivacy" "$TMP/NoRuntime.app/Contents/Resources/PrivacyInfo.xcprivacy"
plutil -create xml1 "$TMP/NoRuntime.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.app-sandbox bool true' "$TMP/NoRuntime.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.files.bookmarks.app-scope bool true' "$TMP/NoRuntime.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.files.user-selected.read-only bool true' "$TMP/NoRuntime.entitlements"
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
ditto "$ROOT/Resources/macOS/PrivacyInfo.xcprivacy" "$TMP/Expected.app/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options runtime --entitlements "$TMP/NoRuntime.entitlements" "$TMP/Expected.app" >/dev/null 2>&1
expect_success "valid runtime-signed community fixture passes without a DMG" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/Expected.app" --mode community

mkdir -p "$TMP/MissingReadOnly"
ditto "$TMP/Expected.app" "$TMP/MissingReadOnly/Expected.app"
plutil -create xml1 "$TMP/MissingReadOnly.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.app-sandbox bool true' "$TMP/MissingReadOnly.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.files.bookmarks.app-scope bool true' "$TMP/MissingReadOnly.entitlements"
codesign --force --sign - --options runtime --entitlements "$TMP/MissingReadOnly.entitlements" "$TMP/MissingReadOnly/Expected.app" >/dev/null 2>&1
expect_failure "verification rejects an app without read-only user-selected file access" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/MissingReadOnly/Expected.app" --mode community
assert_stderr_contains "missing read-only entitlement names the defect" "read-only user-selected file entitlement is missing"

mkdir -p "$TMP/ReadWrite"
ditto "$TMP/Expected.app" "$TMP/ReadWrite/Expected.app"
cp "$TMP/NoRuntime.entitlements" "$TMP/ReadWrite.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.files.user-selected.read-write bool true' "$TMP/ReadWrite.entitlements"
codesign --force --sign - --options runtime --entitlements "$TMP/ReadWrite.entitlements" "$TMP/ReadWrite/Expected.app" >/dev/null 2>&1
expect_failure "verification rejects read-write user-selected file access" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/ReadWrite/Expected.app" --mode community
assert_stderr_contains "read-write entitlement names the defect" "read-write user-selected file entitlement must not ship"

mkdir -p "$TMP/InvalidPrivacy"
ditto "$TMP/Expected.app" "$TMP/InvalidPrivacy/Expected.app"
printf 'not a property list\n' >"$TMP/InvalidPrivacy/Expected.app/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options runtime --entitlements "$TMP/NoRuntime.entitlements" "$TMP/InvalidPrivacy/Expected.app" >/dev/null 2>&1
expect_failure "verification rejects malformed privacy-manifest syntax" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/InvalidPrivacy/Expected.app" --mode community
assert_stderr_contains "malformed privacy manifest names the defect" "privacy manifest is not a valid property list"

mkdir -p "$TMP/MissingPrivacyReason"
ditto "$TMP/Expected.app" "$TMP/MissingPrivacyReason/Expected.app"
/usr/libexec/PlistBuddy -c 'Delete :NSPrivacyAccessedAPITypes:0:NSPrivacyAccessedAPITypeReasons:1' \
    "$TMP/MissingPrivacyReason/Expected.app/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options runtime --entitlements "$TMP/NoRuntime.entitlements" "$TMP/MissingPrivacyReason/Expected.app" >/dev/null 2>&1
expect_failure "verification rejects a privacy manifest missing C617.1" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/MissingPrivacyReason/Expected.app" --mode community
assert_stderr_contains "missing privacy reason names the defect" "privacy manifest is missing required file-timestamp reason: C617.1"

mkdir -p "$TMP/MissingGrantedFileReason"
ditto "$TMP/Expected.app" "$TMP/MissingGrantedFileReason/Expected.app"
/usr/libexec/PlistBuddy -c 'Delete :NSPrivacyAccessedAPITypes:0:NSPrivacyAccessedAPITypeReasons:0' \
    "$TMP/MissingGrantedFileReason/Expected.app/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options runtime --entitlements "$TMP/NoRuntime.entitlements" "$TMP/MissingGrantedFileReason/Expected.app" >/dev/null 2>&1
expect_failure "verification rejects a privacy manifest missing 3B52.1" \
    "$ROOT/script/verify_distribution.sh" --app "$TMP/MissingGrantedFileReason/Expected.app" --mode community
assert_stderr_contains "missing granted-file reason names the defect" "privacy manifest is missing required file-timestamp reason: 3B52.1"

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

if grep -F 'python-version: "3.12.10"' "$ROOT/.github/workflows/ci.yml" >/dev/null \
    && grep -F 'os: macos-26' "$ROOT/.github/workflows/ci.yml" >/dev/null \
    && grep -F 'python-version: "3.12.13"' "$ROOT/.github/workflows/ci.yml" >/dev/null \
    && grep -F 'os: ubuntu-24.04' "$ROOT/.github/workflows/ci.yml" >/dev/null; then
    pass "CI pins supported Python versions for macOS and Linux"
else
    fail "CI pins supported Python versions for macOS and Linux"
fi

if grep -F 'echo "$RUNNER_TEMP/xcodegen/xcodegen/bin" >> "$GITHUB_PATH"' "$ROOT/.github/workflows/ci.yml" >/dev/null \
    && grep -F '090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef' "$ROOT/.github/workflows/ci.yml" >/dev/null; then
    pass "CI exposes the verified XcodeGen archive binary path"
else
    fail "CI exposes the verified XcodeGen archive binary path"
fi

if grep -F 'id: dependency-graph' "$ROOT/.github/workflows/dependency-review.yml" >/dev/null \
    && grep -F '/dependency-graph/sbom' "$ROOT/.github/workflows/dependency-review.yml" >/dev/null \
    && grep -F 'classify_dependency_graph_status.sh "$repository_status" "$graph_status"' "$ROOT/.github/workflows/dependency-review.yml" >/dev/null \
    && grep -F "if: steps.dependency-graph.outputs.available == 'true'" "$ROOT/.github/workflows/dependency-review.yml" >/dev/null; then
    pass "dependency review reports an unavailable external graph without hiding lockfile gates"
else
    fail "dependency review reports an unavailable external graph without hiding lockfile gates"
fi

if grep -F -- '--remove-signature' "$ROOT/script/build_official.sh" >/dev/null \
    && grep -F 'code object is not signed at all' "$ROOT/script/build_official.sh" >/dev/null; then
    pass "official build proves a signature-free pre-sign candidate"
else
    fail "official build proves a signature-free pre-sign candidate"
fi

if grep -F 'final_source_revision=$(release_source_revision)' "$ROOT/script/build_official.sh" >/dev/null \
    && grep -F 'source tree changed during the official build' "$ROOT/script/build_official.sh" >/dev/null; then
    pass "official build rejects source changes during compilation"
else
    fail "official build rejects source changes during compilation"
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

if grep -F 'symbol("atlas_query_index_v2"' "$ROOT/Sources/LiteratureAtlas/Services/AtlasFFI.swift" >/dev/null \
    && grep -F 'atlas_query_index_v2' "$ROOT/analytics/ffi/include/atlas_ffi.h" >/dev/null \
    && ! grep -F 'symbol("atlas_query_index"' "$ROOT/Sources/LiteratureAtlas/Services/AtlasFFI.swift" >/dev/null; then
    pass "length-aware FFI query uses a versioned dynamic symbol"
else
    fail "length-aware FFI query uses a versioned dynamic symbol"
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
