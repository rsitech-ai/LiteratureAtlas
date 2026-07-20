import json
import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "docs" / "open-source" / "OPEN_SOURCE_MANIFEST.json"


class OpenSourceManifestTests(unittest.TestCase):
    def test_dependency_inventory_matches_manifests_and_sboms(self):
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        pyproject = tomllib.loads((ROOT / "analytics" / "pyproject.toml").read_text(encoding="utf-8"))
        cargo = tomllib.loads((ROOT / "analytics" / "ffi" / "Cargo.toml").read_text(encoding="utf-8"))
        python_sbom = json.loads(
            (ROOT / "docs" / "open-source" / "sbom" / "python-environment.cdx.json").read_text(encoding="utf-8")
        )
        rust_sbom = json.loads(
            (ROOT / "docs" / "open-source" / "sbom" / "rust-source.cdx.json").read_text(encoding="utf-8")
        )

        direct_python = sorted(
            re.split(r"[<>=!~]", requirement, maxsplit=1)[0] for requirement in pyproject["project"]["dependencies"]
        )
        self.assertEqual(manifest["python_direct_dependencies"], direct_python)
        self.assertEqual(manifest["rust_direct_dependencies"], cargo["dependencies"])
        self.assertEqual(manifest["python_sbom_dependency_component_count"], len(python_sbom["components"]))
        self.assertEqual(manifest["rust_sbom_dependency_component_count"], len(rust_sbom["components"]))

    def test_locked_counts_and_artifact_provenance_match_their_sources(self):
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        uv_lock = tomllib.loads((ROOT / "analytics" / "uv.lock").read_text(encoding="utf-8"))
        cargo_lock = tomllib.loads((ROOT / "analytics" / "ffi" / "Cargo.lock").read_text(encoding="utf-8"))

        expected_locked_count = len(uv_lock["package"]) + len(cargo_lock["package"])
        self.assertEqual(manifest["locked_ecosystem_component_count"], expected_locked_count)

        current = manifest["published_community_artifact"]
        self.assertRegex(current["source_commit"], r"^[0-9a-f]{40}$")
        self.assertRegex(current["dmg_sha256"], r"^[0-9a-f]{64}$")
        self.assertRegex(current["app_sbom_sha256"], r"^[0-9a-f]{64}$")
        self.assertTrue(current["app_sbom_url"].startswith("https://github.com/"))

        for historical in manifest["tracked_historical_app_sboms"]:
            source_commit = historical["source_commit"]
            self.assertRegex(source_commit, r"^[0-9a-f]{40}$")
            payload = json.loads((ROOT / historical["path"]).read_text(encoding="utf-8"))
            version = payload["packages"][0]["versionInfo"]
            self.assertIn(source_commit[:7], version)
            self.assertNotEqual(source_commit, current["source_commit"])

        tracked_paths = manifest["tracked_current_source_dependency_sbom_paths"]
        tracked_paths.extend(item["path"] for item in manifest["tracked_historical_app_sboms"])
        self.assertNotIn(current["app_sbom_url"], tracked_paths)


if __name__ == "__main__":
    unittest.main()
