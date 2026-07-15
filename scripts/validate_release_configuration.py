#!/usr/bin/env python3
"""Validate committed LiteratureAtlas App Store packaging without Xcode APIs."""

from __future__ import annotations

import argparse
import json
import plistlib
import sys
from pathlib import Path
from typing import Any


EXPECTED_TARGETS = ("LiteratureAtlas-macOS", "LiteratureAtlas-iOS")
EXPECTED_REASONS = {"3B52.1", "C617.1"}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return ""


def read_plist(path: Path) -> dict[str, Any]:
    try:
        with path.open("rb") as handle:
            value = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException):
        return {}
    return value if isinstance(value, dict) else {}


def add_gate(
    results: dict[str, dict[str, Any]], name: str, passed: bool, detail: str
) -> None:
    results[name] = {"passed": passed, "detail": detail}


def validate(root: Path) -> dict[str, Any]:
    gates: dict[str, dict[str, Any]] = {}
    project_spec = root / "project.yml"
    spec_text = read_text(project_spec)
    spec_fragments = (
        "LiteratureAtlas-macOS:",
        "LiteratureAtlas-iOS:",
        "platform: macOS",
        "platform: iOS",
        "type: application",
        "productName: LiteratureAtlas",
        'TARGETED_DEVICE_FAMILY: "2"',
        "archive:",
        "config: Release",
    )
    add_gate(
        gates,
        "project_spec",
        project_spec.is_file()
        and all(fragment in spec_text for fragment in spec_fragments),
        "project.yml defines macOS and iPadOS application targets with Release archive schemes",
    )

    shared_config = read_text(root / "Config/Shared.xcconfig")
    debug_config = read_text(root / "Config/Debug.xcconfig")
    release_config = read_text(root / "Config/Release.xcconfig")
    coordinates_ok = (
        all(
            fragment in shared_config
            for fragment in (
                "MARKETING_VERSION = 1.0.0",
                "CURRENT_PROJECT_VERSION = 1",
                "CODE_SIGN_STYLE = Automatic",
            )
        )
        and "DEVELOPMENT_TEAM" not in shared_config
        and "DEVELOPMENT_TEAM" not in spec_text
    )
    add_gate(
        gates,
        "release_coordinates",
        coordinates_ok,
        "version/build have one xcconfig source and Apple Team remains owner-confirmed",
    )
    add_gate(
        gates,
        "release_optimization",
        "SWIFT_COMPILATION_MODE = wholemodule" in release_config
        and "SWIFT_OPTIMIZATION_LEVEL = -O" in release_config,
        "Release configuration uses whole-module optimized App Store compilation",
    )
    add_gate(
        gates,
        "xcode_app_runtime_boundary",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS = APP_STORE_BUILD $(inherited)"
        in shared_config
        and '#include "Shared.xcconfig"' in debug_config
        and '#include "Shared.xcconfig"' in release_config
        and "APP_STORE_BUILD" not in debug_config
        and "APP_STORE_BUILD" not in release_config,
        "Debug runs and Release archives inherit the same App Store runtime boundary",
    )

    platform_paths = {
        "macOS": root / "Resources/macOS",
        "iOS": root / "Resources/iOS",
    }
    for platform, resource_root in platform_paths.items():
        info = read_plist(resource_root / "Info.plist")
        expected_bundle = (
            "com.literatureatlas.app"
            if platform == "macOS"
            else "com.literatureatlas.app.ios"
        )
        info_ok = (
            info.get("CFBundleIdentifier") == "$(PRODUCT_BUNDLE_IDENTIFIER)"
            and info.get("CFBundleShortVersionString") == "$(MARKETING_VERSION)"
            and info.get("CFBundleVersion") == "$(CURRENT_PROJECT_VERSION)"
            and expected_bundle in spec_text
        )
        add_gate(
            gates,
            f"{platform.lower()}_info",
            info_ok,
            f"{platform} Info.plist inherits centralized coordinates and expected bundle ID",
        )

        privacy = read_plist(resource_root / "PrivacyInfo.xcprivacy")
        accessed = privacy.get("NSPrivacyAccessedAPITypes", [])
        reasons: set[str] = set()
        for entry in accessed if isinstance(accessed, list) else []:
            if isinstance(entry, dict) and entry.get("NSPrivacyAccessedAPIType") == (
                "NSPrivacyAccessedAPICategoryFileTimestamp"
            ):
                values = entry.get("NSPrivacyAccessedAPITypeReasons", [])
                if isinstance(values, list):
                    reasons.update(value for value in values if isinstance(value, str))
        privacy_ok = (
            EXPECTED_REASONS.issubset(reasons)
            and "NSPrivacyCollectedDataTypes" not in privacy
        )
        add_gate(
            gates,
            f"{platform.lower()}_privacy_manifest",
            privacy_ok,
            f"{platform} declares validated file-timestamp reasons without owner data answers",
        )

    mac_entitlements = read_plist(root / "Resources/macOS/LiteratureAtlas.entitlements")
    add_gate(
        gates,
        "macos_entitlements",
        mac_entitlements.get("com.apple.security.app-sandbox") is True
        and mac_entitlements.get("com.apple.security.files.user-selected.read-only")
        is True
        and "com.apple.security.files.user-selected.read-write" not in mac_entitlements,
        "Mac target uses App Sandbox and read-only user-selected file access",
    )
    ios_entitlements = read_plist(root / "Resources/iOS/LiteratureAtlas.entitlements")
    add_gate(
        gates,
        "ios_entitlements",
        ios_entitlements == {},
        "iOS target declares no unverified capabilities",
    )

    project_file = root / "LiteratureAtlas.xcodeproj/project.pbxproj"
    schemes_ok = project_file.is_file()
    for target in EXPECTED_TARGETS:
        scheme = (
            root / f"LiteratureAtlas.xcodeproj/xcshareddata/xcschemes/{target}.xcscheme"
        )
        scheme_text = read_text(scheme)
        schemes_ok = (
            schemes_ok
            and scheme.is_file()
            and 'buildConfiguration = "Release"' in scheme_text
        )
    add_gate(
        gates,
        "generated_project",
        schemes_ok,
        "generated project and shared schemes contain Release archive actions",
    )

    app_model = read_text(root / "Sources/LiteratureAtlas/App/AppModel.swift")
    analytics_view = read_text(
        root / "Sources/LiteratureAtlas/Views/AnalyticsView.swift"
    )
    ffi_source = read_text(root / "Sources/LiteratureAtlas/Services/AtlasFFI.swift")
    compiler_source = read_text(
        root / "Sources/LiteratureAtlas/Services/DocumentCompilerProvider.swift"
    )
    self_contained_ok = (
        "#if os(macOS) && !APP_STORE_BUILD" in app_model
        and "#if os(macOS) && !APP_STORE_BUILD" in analytics_view
        and "#if APP_STORE_BUILD\n    nonisolated(unsafe) private static let handle"
        in ffi_source
        and "#if !APP_STORE_BUILD\n@available(macOS 26, iOS 26, *)\nactor OpenAIDocumentCompilerProvider"
        in compiler_source
    )
    add_gate(
        gates,
        "app_store_self_contained",
        self_contained_ok,
        "App Store compilation excludes external Python, relative FFI loading, and dormant remote compilation",
    )
    folder_scope_index = app_model.find(
        "let folderScopeAccess = folderURL.startAccessingSecurityScopedResource()"
    )
    folder_enumeration_index = app_model.find(
        "let sourceFiles = discoverSourceDocuments(in: folderURL)"
    )
    add_gate(
        gates,
        "security_scoped_ingest",
        folder_scope_index >= 0 and folder_scope_index < folder_enumeration_index,
        "sandboxed ingest opens the selected folder security scope before enumeration",
    )

    icon_root = root / "Resources/Shared/Assets.xcassets/AppIcon.appiconset"
    try:
        icon_spec = json.loads(read_text(icon_root / "Contents.json"))
    except json.JSONDecodeError:
        icon_spec = {}
    images = icon_spec.get("images", []) if isinstance(icon_spec, dict) else []
    filenames = [entry.get("filename") for entry in images if isinstance(entry, dict)]
    filenames = [value for value in filenames if isinstance(value, str) and value]
    icon_ok = bool(filenames) and all(
        (icon_root / filename).is_file() for filename in filenames
    )
    add_gate(
        gates,
        "app_icon_artwork",
        icon_ok,
        "AppIcon catalog references real committed artwork for all declared entries",
    )

    failed_gates = [name for name, result in gates.items() if not result["passed"]]
    return {
        "ok": not failed_gates,
        "root": str(root.resolve()),
        "failed_gates": failed_gates,
        "gates": gates,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    payload = validate(args.root)
    if args.json:
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        for name, result in payload["gates"].items():
            status = "PASS" if result["passed"] else "FAIL"
            print(f"{status} {name}: {result['detail']}")
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
