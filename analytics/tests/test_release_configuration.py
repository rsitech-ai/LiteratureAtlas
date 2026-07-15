import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class ReleaseConfigurationTests(unittest.TestCase):
    def test_validator_names_missing_project_spec_gate(self):
        repo_root = Path(__file__).resolve().parents[2]
        validator = repo_root / "scripts" / "validate_release_configuration.py"

        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                [sys.executable, str(validator), "--root", tmp, "--json"],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertIn("project_spec", payload["failed_gates"])


if __name__ == "__main__":
    unittest.main()
