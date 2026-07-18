import json
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "docs" / "open-source" / "OPEN_SOURCE_MANIFEST.json"


class OpenSourceManifestTests(unittest.TestCase):
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
