import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT_PATH = Path(__file__).resolve().parents[2] / "scripts" / "generate_spdx_sbom.py"
SPEC = importlib.util.spec_from_file_location("generate_spdx_sbom", SCRIPT_PATH)
assert SPEC and SPEC.loader
SBOM = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SBOM)


class SPDXGenerationTests(unittest.TestCase):
    def test_source_document_contains_real_sha256_for_only_requested_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Sources").mkdir()
            (root / "Sources" / "App.swift").write_text("print(1)\n", encoding="utf-8")
            (root / "README.md").write_text("# Test\n", encoding="utf-8")
            paths = [Path("README.md"), Path("Sources/App.swift")]

            document = SBOM.build_source_document(
                root=root,
                paths=paths,
                revision="abc123",
                created="2026-07-16T00:00:00Z",
            )

            self.assertEqual([item["fileName"] for item in document["files"]], ["README.md", "Sources/App.swift"])
            expected = hashlib.sha256((root / "Sources" / "App.swift").read_bytes()).hexdigest()
            app_entry = next(item for item in document["files"] if item["fileName"] == "Sources/App.swift")
            self.assertEqual(app_entry["checksums"], [{"algorithm": "SHA256", "checksumValue": expected}])
            self.assertNotIn("0000000000000000000000000000000000000000", json.dumps(document))

    def test_artifact_document_hashes_every_regular_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            app = Path(tmp) / "Example.app"
            executable = app / "Contents" / "MacOS" / "Example"
            executable.parent.mkdir(parents=True)
            executable.write_bytes(b"binary")
            info = app / "Contents" / "Info.plist"
            info.write_text("plist", encoding="utf-8")

            document = SBOM.build_artifact_document(app, version="1.2.3", created="2026-07-16T00:00:00Z")

            self.assertEqual(
                [item["fileName"] for item in document["files"]],
                ["Contents/Info.plist", "Contents/MacOS/Example"],
            )
            self.assertTrue(all(item["checksums"][0]["algorithm"] == "SHA256" for item in document["files"]))

    def test_artifact_namespace_changes_for_path_mode_and_symlink_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            app = Path(tmp) / "Example.app"
            executable = app / "Contents" / "MacOS" / "Example"
            executable.parent.mkdir(parents=True)
            executable.write_bytes(b"same bytes")
            executable.chmod(0o644)
            first = SBOM.build_artifact_document(app, version="1", created="2026-07-16T00:00:00Z")

            executable.chmod(0o755)
            second = SBOM.build_artifact_document(app, version="1", created="2026-07-16T00:00:00Z")
            self.assertNotEqual(first["documentNamespace"], second["documentNamespace"])

            link = app / "Contents" / "Current"
            link.symlink_to("MacOS")
            third = SBOM.build_artifact_document(app, version="1", created="2026-07-16T00:00:00Z")
            self.assertNotEqual(second["documentNamespace"], third["documentNamespace"])

    def test_cyclonedx_sanitizer_removes_local_workspace_path(self):
        payload = {
            "metadata": {
                "component": {
                    "bom-ref": "path+file:///Users/example/work/LiteratureAtlas/analytics/ffi#atlas_ffi@0.1.0"
                }
            }
        }

        sanitized = SBOM.sanitize_cyclonedx(payload, Path("/Users/example/work/LiteratureAtlas"))

        rendered = json.dumps(sanitized)
        self.assertNotIn("/Users/example", rendered)
        self.assertIn("/workspace/LiteratureAtlas", rendered)

    def test_source_date_epoch_is_rendered_as_spdx_timestamp(self):
        with patch.dict("os.environ", {"SOURCE_DATE_EPOCH": "0"}, clear=False):
            self.assertEqual(SBOM.reproducible_created_at(), "1970-01-01T00:00:00Z")

    def test_source_inventory_honors_source_date_epoch(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            (root / "README.md").write_text("# Test\n", encoding="utf-8")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "add", "README.md"], check=True)
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(root),
                    "-c",
                    "user.name=SBOM Test",
                    "-c",
                    "user.email=sbom@example.invalid",
                    "commit",
                    "-q",
                    "-m",
                    "fixture",
                ],
                check=True,
            )
            output = Path(tmp) / "source.spdx.json"
            environment = os.environ.copy()
            environment["SOURCE_DATE_EPOCH"] = "0"

            subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--source-root",
                    str(root),
                    "--output",
                    str(output),
                ],
                check=True,
                env=environment,
            )

            payload = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(payload["creationInfo"]["created"], "1970-01-01T00:00:00Z")

    def test_source_revision_changes_for_mode_and_symlink_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.txt"
            source.write_text("same bytes", encoding="utf-8")
            source.chmod(0o644)
            first = SBOM.source_inventory_revision(root, [Path("source.txt")])

            source.chmod(0o755)
            second = SBOM.source_inventory_revision(root, [Path("source.txt")])
            self.assertNotEqual(first, second)

            (root / "target-a").write_text("a", encoding="utf-8")
            (root / "target-b").write_text("b", encoding="utf-8")
            link = root / "current"
            link.symlink_to("target-a")
            link_a = SBOM.source_inventory_revision(root, [Path("current")])
            link.unlink()
            link.symlink_to("target-b")
            link_b = SBOM.source_inventory_revision(root, [Path("current")])
            self.assertNotEqual(link_a, link_b)


if __name__ == "__main__":
    unittest.main()
