import hashlib
import importlib.util
import json
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


if __name__ == "__main__":
    unittest.main()
