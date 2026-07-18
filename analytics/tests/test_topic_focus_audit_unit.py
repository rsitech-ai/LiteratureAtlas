import argparse
import importlib.util
import json
import os
import sys
import tempfile
import unittest
import uuid
from pathlib import Path
from unittest.mock import patch

import numpy as np


def _load_module():
    repo_root = Path(__file__).resolve().parents[2]
    script_path = repo_root / "scripts" / "topic_focus_audit.py"
    spec = importlib.util.spec_from_file_location("topic_focus_audit", script_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load script: {script_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)  # type: ignore[attr-defined]
    return module


def _args(base: Path) -> argparse.Namespace:
    return argparse.Namespace(
        base=str(base),
        min_cluster_coverage=0.60,
        kmeans_min_k=2,
        kmeans_max_k=4,
        seed=0,
        min_reliable_topics=1,
        min_primary_topic_size=5,
        min_topic_size=4,
        min_top_term_coverage=0.30,
        min_year_coverage=1.0,
        min_note_coverage=1.0,
        min_embedding_coverage=1.0,
        max_global_term_ratio=0.40,
        min_silhouette=0.01,
        max_topics=20,
    )


def _write_paper(path: Path, title: str, summary: str, keywords: list[str], embedding: list[float], year: int) -> str:
    paper_id = str(uuid.uuid4()).upper()
    payload = {
        "id": paper_id,
        "version": 1,
        "title": title,
        "summary": summary,
        "keywords": keywords,
        "embedding": embedding,
        "year": year,
    }
    path.write_text(json.dumps(payload), encoding="utf-8")
    return paper_id


class TopicFocusAuditUnitTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = _load_module()

    def test_run_audit_passes_when_clear_topic_exists(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            papers_dir = root / "Output" / "papers"
            notes_dir = root / "Output" / "obsidian" / "papers"
            papers_dir.mkdir(parents=True, exist_ok=True)
            notes_dir.mkdir(parents=True, exist_ok=True)

            rng = np.random.default_rng(seed=0)

            ids: list[str] = []
            for i in range(6):
                emb = (rng.normal(loc=0.0, scale=0.01, size=8) + np.array([2, 0, 0, 0, 0, 0, 0, 0])).tolist()
                pid = _write_paper(
                    papers_dir / f"causal_{i}.paper.json",
                    title=f"Causal Inference Study {i}",
                    summary="causal inference treatment effect identification econometrics",
                    keywords=["causal", "inference", "econometrics", "treatment"],
                    embedding=emb,
                    year=2024,
                )
                ids.append(pid)

            for i in range(6):
                emb = (rng.normal(loc=0.0, scale=0.01, size=8) + np.array([0, 2, 0, 0, 0, 0, 0, 0])).tolist()
                pid = _write_paper(
                    papers_dir / f"trading_{i}.paper.json",
                    title=f"Order Book Microstructure {i}",
                    summary="limit order book market microstructure execution alpha",
                    keywords=["order", "book", "microstructure", "execution"],
                    embedding=emb,
                    year=2023,
                )
                ids.append(pid)

            for pid in ids:
                (notes_dir / f"Paper [{pid}].md").write_text("obsidian_format_version: 2\n", encoding="utf-8")

            args = _args(root)
            code, message = self.mod.run_audit(args)
            self.assertEqual(code, 0, message)
            self.assertIn("PASS", message)

    def test_run_audit_fails_when_topics_are_not_reliable(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            papers_dir = root / "Output" / "papers"
            notes_dir = root / "Output" / "obsidian" / "papers"
            papers_dir.mkdir(parents=True, exist_ok=True)
            notes_dir.mkdir(parents=True, exist_ok=True)

            rng = np.random.default_rng(seed=1)
            for i in range(8):
                emb = rng.normal(loc=0.0, scale=1.0, size=8).tolist()
                _write_paper(
                    papers_dir / f"misc_{i}.paper.json",
                    title=f"Misc Unique Topic {i}",
                    summary=f"token{i} unique{i} isolated{i}",
                    keywords=[f"token{i}", f"unique{i}"],
                    embedding=emb,
                    year=2024,
                )

            args = _args(root)
            args.min_reliable_topics = 1
            args.min_primary_topic_size = 6
            args.min_topic_size = 6
            args.min_top_term_coverage = 0.70
            # No notes were written: this should force failure.
            code, message = self.mod.run_audit(args)
            self.assertEqual(code, 1, message)
            self.assertIn("FAIL", message)

    def test_run_audit_fails_closed_when_silhouette_computation_errors(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            papers_dir = root / "Output" / "papers"
            notes_dir = root / "Output" / "obsidian" / "papers"
            papers_dir.mkdir(parents=True, exist_ok=True)
            notes_dir.mkdir(parents=True, exist_ok=True)

            for index in range(8):
                center = np.array([2.0, 0.0, 0.0, 0.0]) if index < 4 else np.array([0.0, 2.0, 0.0, 0.0])
                paper_id = _write_paper(
                    papers_dir / f"paper_{index}.paper.json",
                    title=f"Topic Paper {index}",
                    summary="coherent alpha beta gamma topic",
                    keywords=["alpha", "beta", "gamma"],
                    embedding=(center + (index * 0.01)).tolist(),
                    year=2024,
                )
                (notes_dir / f"Paper [{paper_id}].md").write_text(
                    "obsidian_format_version: 2\n",
                    encoding="utf-8",
                )

            args = _args(root)
            args.kmeans_min_k = 2
            args.kmeans_max_k = 2
            with patch.object(self.mod, "silhouette_score", side_effect=RuntimeError("metric failed")):
                code, message = self.mod.run_audit(args)

            self.assertEqual(code, 2, message)
            self.assertIn("silhouette", message.lower())

    def test_load_papers_rejects_malformed_json(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_root = Path(tmpdir) / "Output"
            papers_dir = output_root / "papers"
            papers_dir.mkdir(parents=True)
            (papers_dir / "broken.paper.json").write_text("{not-json", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "broken.paper.json"):
                self.mod.load_papers(output_root)

    def test_load_papers_rejects_non_finite_and_ragged_embeddings(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_root = Path(tmpdir) / "Output"
            papers_dir = output_root / "papers"
            papers_dir.mkdir(parents=True)
            _write_paper(papers_dir / "valid.paper.json", "Valid", "", [], [0.1, 0.2], 2024)
            _write_paper(papers_dir / "ragged.paper.json", "Ragged", "", [], [0.1, 0.2, 0.3], 2024)

            with self.assertRaisesRegex(ValueError, "embedding dimension"):
                self.mod.load_papers(output_root)

            (papers_dir / "ragged.paper.json").unlink()
            payload = {
                "id": str(uuid.uuid4()),
                "title": "Non-finite",
                "embedding": [float("nan"), 0.2],
                "year": 2024,
            }
            (papers_dir / "nonfinite.paper.json").write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "non-finite"):
                self.mod.load_papers(output_root)

    def test_safe_int_rejects_non_finite_and_fractional_metadata(self):
        self.assertIsNone(self.mod._safe_int(float("inf")))
        self.assertIsNone(self.mod._safe_int(float("-inf")))
        self.assertIsNone(self.mod._safe_int(2020.5))
        self.assertEqual(self.mod._safe_int(2020.0), 2020)

    def test_load_papers_uses_freshest_export_for_duplicate_id(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_root = Path(tmpdir) / "Output"
            papers_dir = output_root / "papers"
            papers_dir.mkdir(parents=True)
            paper_id = str(uuid.uuid4())
            stale = {
                "id": paper_id,
                "title": "Stale title",
                "embedding": [0.1, 0.2],
                "year": 2024,
            }
            fresh = {**stale, "title": "Fresh title"}
            stale_path = papers_dir / "A.paper.json"
            fresh_path = papers_dir / "Z.paper.json"
            stale_path.write_text(json.dumps(stale), encoding="utf-8")
            fresh_path.write_text(json.dumps(fresh), encoding="utf-8")
            os.utime(stale_path, ns=(1_000_000_000, 1_000_000_000))
            os.utime(fresh_path, ns=(2_000_000_000, 2_000_000_000))

            papers = self.mod.load_papers(output_root)

            self.assertEqual(len(papers), 1)
            self.assertEqual(papers[0].title, "Fresh title")


if __name__ == "__main__":
    unittest.main()
