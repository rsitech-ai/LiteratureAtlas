import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class ReleaseConfigurationTests(unittest.TestCase):
    def copy_release_fixture(self, destination: Path) -> Path:
        repo_root = Path(__file__).resolve().parents[2]
        fixture_root = destination / "repository"
        shutil.copytree(
            repo_root,
            fixture_root,
            ignore=shutil.ignore_patterns(
                ".git",
                ".build",
                ".venv",
                "target",
                "Output",
                "dist",
            ),
        )
        return fixture_root

    def run_validator(self, root: Path, *extra_arguments: str) -> subprocess.CompletedProcess[str]:
        repo_root = Path(__file__).resolve().parents[2]
        validator = repo_root / "scripts" / "validate_release_configuration.py"
        return subprocess.run(
            [
                sys.executable,
                str(validator),
                "--root",
                str(root),
                "--json",
                *extra_arguments,
            ],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_validator_names_missing_project_spec_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = self.run_validator(Path(tmp))

        self.assertNotEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertIn("project_spec", payload["failed_gates"])

    def test_xcode_run_and_archive_use_distributed_runtime_boundary(self):
        repo_root = Path(__file__).resolve().parents[2]

        result = self.run_validator(repo_root)

        payload = json.loads(result.stdout)
        self.assertTrue(payload["gates"]["xcode_app_runtime_boundary"]["passed"])

    def test_sandboxed_ingest_opens_folder_scope_before_enumeration(self):
        repo_root = Path(__file__).resolve().parents[2]

        result = self.run_validator(repo_root)

        payload = json.loads(result.stdout)
        self.assertTrue(payload["gates"]["security_scoped_ingest"]["passed"])

    def test_logs_and_analytics_minimize_document_context(self):
        repo_root = Path(__file__).resolve().parents[2]

        result = self.run_validator(repo_root)

        payload = json.loads(result.stdout)
        self.assertTrue(payload["gates"]["privacy_safe_diagnostics"]["passed"])

    def test_validator_can_allow_an_explicit_known_blocker(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture_root = self.copy_release_fixture(Path(tmp))
            icon = fixture_root / ("Resources/Shared/Assets.xcassets/AppIcon.appiconset/AppIcon-16.png")
            icon.unlink()

            result = self.run_validator(
                fixture_root,
                "--allow-blocker",
                "app_icon_artwork",
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["allowed_blockers"], ["app_icon_artwork"])
        self.assertEqual(payload["failed_gates"], ["app_icon_artwork"])
        self.assertEqual(payload["unallowed_failed_gates"], [])

    def test_committed_icon_artwork_passes(self):
        repo_root = Path(__file__).resolve().parents[2]

        result = self.run_validator(repo_root)

        payload = json.loads(result.stdout)
        gate = payload["gates"]["app_icon_artwork"]
        self.assertTrue(gate["passed"])
        self.assertEqual(
            gate["detail"],
            "AppIcon catalog references real committed artwork for all declared entries",
        )


if __name__ == "__main__":
    unittest.main()
