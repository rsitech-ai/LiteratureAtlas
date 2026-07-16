#!/bin/bash

RELEASE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

release_die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

release_require_command() {
    command -v "$1" >/dev/null 2>&1 || release_die "required command not found: $1"
}

release_reject_control_characters() {
    value=$1
    label=$2
    case "$value" in
        *$'\n'*|*$'\r'*|*$'\t'*) release_die "$label contains a control character" ;;
    esac
}

release_validate_product_name() {
    value=$1
    release_reject_control_characters "$value" "product name"
    case "$value" in
        ""|.|..|*/*|*\\*) release_die "unsafe product name: $value" ;;
    esac
    printf '%s' "$value" | LC_ALL=C grep -Eq '^[A-Za-z0-9]([A-Za-z0-9._ -]*[A-Za-z0-9._-])?$' \
        || release_die "unsafe product name: $value"
}

release_validate_bundle_id() {
    value=$1
    release_reject_control_characters "$value" "bundle identifier"
    printf '%s' "$value" | LC_ALL=C grep -Eq '^[A-Za-z0-9][A-Za-z0-9-]*(\.[A-Za-z0-9][A-Za-z0-9-]*)+$' \
        || release_die "unsafe bundle identifier: $value"
}

release_validate_version() {
    release_reject_control_characters "$1" "version"
    printf '%s' "$1" | LC_ALL=C grep -Eq '^[0-9]+(\.[0-9]+){1,3}$' \
        || release_die "invalid version: $1"
}

release_validate_build_number() {
    release_reject_control_characters "$1" "build number"
    printf '%s' "$1" | LC_ALL=C grep -Eq '^[1-9][0-9]*$' \
        || release_die "invalid build number: $1"
}

release_validate_output() {
    value=$1
    case "$value" in
        ""|/) release_die "unsafe output directory: $value" ;;
    esac
}

release_print_command() {
    printf 'DRY-RUN'
    printf ' %q' "$@"
    printf '\n'
}

release_source_revision() {
    release_require_command git
    revision=$(git -C "$RELEASE_ROOT" rev-parse HEAD) \
        || release_die "unable to resolve source revision"
    if [ -n "$(git -C "$RELEASE_ROOT" status --porcelain --untracked-files=normal)" ]; then
        revision="$revision-dirty"
    fi
    printf '%s\n' "$revision"
}

release_build_presign_app() {
    product_name=$1
    bundle_id=$2
    version=$3
    build_number=$4
    output=$5
    dry_run=$6
    source_revision=$(release_source_revision)

    release_validate_product_name "$product_name"
    release_validate_bundle_id "$bundle_id"
    release_validate_version "$version"
    release_validate_build_number "$build_number"
    release_validate_output "$output"

    if [ "$dry_run" = true ]; then
        release_print_command xcodebuild \
            -project "$RELEASE_ROOT/LiteratureAtlas.xcodeproj" \
            -scheme LiteratureAtlas-macOS \
            -configuration Release \
            -xcconfig "$RELEASE_ROOT/Config/DirectDistribution.xcconfig" \
            -destination generic/platform=macOS \
            PRODUCT_NAME="$product_name" \
            PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" \
            INFOPLIST_KEY_CFBundleDisplayName="$product_name" \
            LITERATURE_ATLAS_SOURCE_REVISION="$source_revision" \
            MARKETING_VERSION="$version" \
            CURRENT_PROJECT_VERSION="$build_number" \
            ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
            CODE_SIGNING_ALLOWED=NO build
        return 0
    fi

    release_require_command xcodebuild
    release_require_command ditto
    [ -f "$RELEASE_ROOT/LiteratureAtlas.xcodeproj/project.pbxproj" ] \
        || release_die "generated Xcode project is missing"

    mkdir -p "$output"
    output=$(cd "$output" && pwd)
    target="$output/$product_name.app"
    [ ! -e "$target" ] || release_die "output already exists: $target"

    build_root=$(mktemp -d "${TMPDIR:-/tmp}/literatureatlas-build.XXXXXX")
    trap 'rm -rf "$build_root"' EXIT

    effective_xcconfig="$build_root/ReleaseOverrides.xcconfig"
    cat >"$effective_xcconfig" <<EOF
#include "$RELEASE_ROOT/Config/DirectDistribution.xcconfig"
PRODUCT_NAME = $product_name
PRODUCT_BUNDLE_IDENTIFIER = $bundle_id
INFOPLIST_KEY_CFBundleDisplayName = $product_name
LITERATURE_ATLAS_SOURCE_REVISION = $source_revision
MARKETING_VERSION = $version
CURRENT_PROJECT_VERSION = $build_number
EOF

    xcodebuild \
        -project "$RELEASE_ROOT/LiteratureAtlas.xcodeproj" \
        -scheme LiteratureAtlas-macOS \
        -configuration Release \
        -xcconfig "$effective_xcconfig" \
        -destination 'generic/platform=macOS' \
        -derivedDataPath "$build_root/DerivedData" \
        ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
        CODE_SIGNING_ALLOWED=NO \
        build >&2

    source_app="$build_root/DerivedData/Build/Products/Release/$product_name.app"
    source_dsym="$build_root/DerivedData/Build/Products/Release/$product_name.app.dSYM"
    [ -d "$source_app" ] || release_die "Xcode did not produce $source_app"
    [ -d "$source_dsym" ] || release_die "Xcode did not produce $source_dsym"
    ditto "$source_app" "$target"
    target_dsym="$output/$product_name.app.dSYM"
    ditto "$source_dsym" "$target_dsym"
    rm -rf "$build_root"
    trap - EXIT

    printf '%s\n' "$target"
}
