import json
import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "docs" / "open-source" / "OPEN_SOURCE_MANIFEST.json"


class OpenSourceManifestTests(unittest.TestCase):
    def test_project_identity_and_license_are_canonical(self):
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        pyproject = tomllib.loads((ROOT / "analytics" / "pyproject.toml").read_text(encoding="utf-8"))
        cargo = tomllib.loads((ROOT / "analytics" / "ffi" / "Cargo.toml").read_text(encoding="utf-8"))
        citation = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
        reuse = (ROOT / "REUSE.toml").read_text(encoding="utf-8")
        license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")

        self.assertEqual(manifest["repository"], "https://github.com/rsitech-ai/LiteratureAtlas")
        self.assertEqual(manifest["effective_primary_license"], "Apache-2.0")
        self.assertEqual(manifest["copyright_holder"], "Rafal Sikora")
        self.assertEqual(manifest["public_maintainer"], "RSI Tech")
        self.assertEqual(manifest["website"], "https://rsitech.ai")
        self.assertEqual(manifest["project_contact"], "info@rsitech.ai")
        self.assertEqual(pyproject["project"]["license"], "Apache-2.0")
        self.assertEqual(pyproject["project"]["authors"], [{"name": "Rafal Sikora", "email": "info@rsitech.ai"}])
        self.assertEqual(pyproject["project"]["maintainers"], [{"name": "RSI Tech", "email": "info@rsitech.ai"}])
        self.assertEqual(pyproject["project"]["urls"]["Homepage"], "https://rsitech.ai")
        self.assertEqual(
            pyproject["project"]["urls"]["Repository"],
            "https://github.com/rsitech-ai/LiteratureAtlas",
        )
        self.assertEqual(cargo["package"]["license"], "Apache-2.0")
        self.assertEqual(cargo["package"]["authors"], ["Rafal Sikora <info@rsitech.ai>"])
        self.assertEqual(cargo["package"]["homepage"], "https://rsitech.ai")
        self.assertEqual(cargo["package"]["repository"], "https://github.com/rsitech-ai/LiteratureAtlas")
        self.assertIn("license: Apache-2.0", citation)
        self.assertIn('repository-code: "https://github.com/rsitech-ai/LiteratureAtlas"', citation)
        self.assertIn('name: "Rafal Sikora"', citation)
        self.assertIn('SPDX-FileCopyrightText = "2025-2026 Rafal Sikora"', reuse)
        self.assertIn('SPDX-License-Identifier = "Apache-2.0"', reuse)
        self.assertIn('path = "DCO.txt"', reuse)
        self.assertIn('SPDX-License-Identifier = "LicenseRef-DCO-1.1"', reuse)
        self.assertEqual(
            (ROOT / "DCO.txt").read_text(encoding="utf-8"),
            (ROOT / "LICENSES" / "LicenseRef-DCO-1.1.txt").read_text(encoding="utf-8"),
        )
        self.assertTrue(license_text.startswith("Apache License\nVersion 2.0, January 2004"))

    def test_bundle_identifiers_use_the_rsi_tech_namespace(self):
        project_spec = (ROOT / "project.yml").read_text(encoding="utf-8")
        build_and_run = (ROOT / "script" / "build_and_run.sh").read_text(encoding="utf-8")

        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER: ai.rsitech.LiteratureAtlas", project_spec)
        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER: ai.rsitech.LiteratureAtlas.iOS", project_spec)
        self.assertIn('BUNDLE_ID="ai.rsitech.LiteratureAtlas"', build_and_run)

    def test_workflows_fit_the_org_action_policy(self):
        workflow_text = "\n".join(
            path.read_text(encoding="utf-8") for path in sorted((ROOT / ".github" / "workflows").glob("*.yml"))
        )

        self.assertNotIn("astral-sh/setup-uv@", workflow_text)
        self.assertNotIn("fsfe/reuse-action@", workflow_text)
        self.assertNotIn("--allow-blocker", workflow_text)
        self.assertFalse((ROOT / ".github" / "workflows" / "scorecard.yml").exists())

    def test_unsigned_release_candidate_workflow_is_credential_free(self):
        workflow = (ROOT / ".github" / "workflows" / "unsigned-release-candidate.yml").read_text(encoding="utf-8")

        self.assertIn("workflow_dispatch", workflow)
        self.assertIn("if: github.ref == 'refs/heads/main'", workflow)
        self.assertIn("script/build_official.sh", workflow)
        self.assertIn(
            "actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02",
            workflow,
        )
        self.assertNotIn("secrets.", workflow)

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

    def test_locked_counts_and_release_candidate_match_their_sources(self):
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        uv_lock = tomllib.loads((ROOT / "analytics" / "uv.lock").read_text(encoding="utf-8"))
        cargo_lock = tomllib.loads((ROOT / "analytics" / "ffi" / "Cargo.lock").read_text(encoding="utf-8"))

        expected_locked_count = len(uv_lock["package"]) + len(cargo_lock["package"])
        self.assertEqual(manifest["locked_ecosystem_component_count"], expected_locked_count)

        candidate = manifest["release_candidate"]
        self.assertEqual(candidate["version"], "1.0.0")
        self.assertEqual(candidate["build"], "1")
        self.assertEqual(candidate["bundle_id"], "ai.rsitech.LiteratureAtlas")
        self.assertEqual(candidate["developer_id_team"], "2NY8A789TN")
        self.assertFalse(candidate["published"])
        self.assertEqual(manifest["tracked_historical_app_sboms"], [])

        tracked_paths = manifest["tracked_current_source_dependency_sbom_paths"]
        for tracked_path in tracked_paths:
            self.assertTrue((ROOT / tracked_path).is_file())


if __name__ == "__main__":
    unittest.main()
