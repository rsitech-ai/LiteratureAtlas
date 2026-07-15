import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class ReleaseConfigurationTests(unittest.TestCase):
    def run_validator(self, root: Path) -> subprocess.CompletedProcess[str]:
        repo_root = Path(__file__).resolve().parents[2]
        validator = repo_root / "scripts" / "validate_release_configuration.py"
        return subprocess.run(
            [sys.executable, str(validator), "--root", str(root), "--json"],
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


if __name__ == "__main__":
    unittest.main()
