import json
import tempfile
import unittest
from pathlib import Path

import duckdb
import numpy as np
import pandas as pd

from analytics.rebuild_analytics import (
    cluster_stability_multi_seed_kmeans,
    compute_factor_loadings,
    load_chunks,
    load_papers,
    load_user_events,
    paper_layout_quality_metrics,
    persist_duckdb,
    write_embeddings_whitened_parquet,
)


class RebuildAnalyticsUnitTests(unittest.TestCase):
    def test_paper_layout_quality_small_n_does_not_crash(self):
        n = 9
        df = pd.DataFrame({"paper_id": [f"p{i}" for i in range(n)]})
        rng = np.random.default_rng(seed=0)
        Z = rng.standard_normal((n, 8), dtype=np.float32)

        summary, distort = paper_layout_quality_metrics(df, Z, k=15, max_n=4000, seed=0)

        self.assertTrue(summary.get("available"), summary)
        self.assertLessEqual(summary.get("k", 999), n - 2)
        self.assertEqual(len(distort), n)

    def test_cluster_stability_multi_seed_runs(self):
        # 2 well-separated clusters, 2 points each.
        df = pd.DataFrame(
            {
                "paper_id": ["a", "b", "c", "d"],
                "cluster_id": [0, 0, 1, 1],
            }
        )
        Z = np.array(
            [
                [0.0, 0.0, 0.0],
                [0.1, 0.0, 0.0],
                [10.0, 0.0, 0.0],
                [10.1, 0.0, 0.0],
            ],
            dtype=np.float32,
        )

        stability = cluster_stability_multi_seed_kmeans(df, Z, runs=5, seed=0)

        self.assertTrue(stability.get("available"), stability)
        per_paper = stability.get("per_paper") or []
        self.assertEqual(len(per_paper), 4)
        # Confidence should be non-trivial for obvious clusters.
        self.assertGreaterEqual(float(per_paper[0].get("cluster_confidence", 0.0)), 0.6)

    def test_load_papers_skips_malformed_and_missing_id_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)

            valid = {
                "id": "paper-1",
                "title": "Valid Paper",
                "embedding": [0.1, 0.2, 0.3],
                "summary": "ok",
            }
            (papers_dir / "valid.paper.json").write_text(json.dumps(valid), encoding="utf-8")
            (papers_dir / "broken.paper.json").write_text('{"id": "oops"', encoding="utf-8")
            (papers_dir / "missing_id.paper.json").write_text(
                json.dumps({"embedding": [1.0, 2.0], "title": "no id"}),
                encoding="utf-8",
            )

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual(len(rows), 1)
            self.assertEqual(len(embeddings), 1)
            self.assertEqual(len(trading_rows), 1)
            self.assertEqual(rows[0].paper_id, "paper-1")

    def test_load_papers_deduplicates_paper_and_document_exports_by_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_root = Path(tmp)
            papers_dir = output_root / "papers"
            documents_dir = output_root / "documents"
            papers_dir.mkdir()
            documents_dir.mkdir()
            canonical = {
                "id": "paper-1",
                "title": "Canonical paper export",
                "embedding": [0.1, 0.2, 0.3],
                "summary": "canonical",
            }
            duplicate = {
                **canonical,
                "title": "Duplicate document export",
                "summary": "duplicate",
            }
            (papers_dir / "paper.paper.json").write_text(json.dumps(canonical), encoding="utf-8")
            (documents_dir / "paper.document.json").write_text(json.dumps(duplicate), encoding="utf-8")

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual(len(rows), 1)
            self.assertEqual(len(embeddings), 1)
            self.assertEqual(len(trading_rows), 1)
            self.assertEqual(rows[0].paper_id, "paper-1")
            self.assertEqual(rows[0].title, "Canonical paper export")

    def test_load_papers_rejects_non_numeric_and_non_finite_embeddings(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            fixtures = {
                "valid.paper.json": {
                    "id": "valid",
                    "title": "Valid",
                    "embedding": [0.1, 0.2, 0.3],
                },
                "text.paper.json": {
                    "id": "text",
                    "title": "Text",
                    "embedding": [0.1, "not-a-number", 0.3],
                },
                "nan.paper.json": {
                    "id": "nan",
                    "title": "NaN",
                    "embedding": [0.1, float("nan"), 0.3],
                },
                "boolean.paper.json": {
                    "id": "boolean",
                    "title": "Boolean",
                    "embedding": [0.1, True, 0.3],
                },
            }
            for filename, payload in fixtures.items():
                (papers_dir / filename).write_text(json.dumps(payload), encoding="utf-8")

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual([row.paper_id for row in rows], ["valid"])
            self.assertEqual(embeddings, [[0.1, 0.2, 0.3]])
            self.assertEqual([row["paper_id"] for row in trading_rows], ["valid"])

    def test_load_papers_uses_modal_embedding_dimension(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            fixtures = {
                "a-short.paper.json": {"id": "short", "embedding": [0.1, 0.2]},
                "b-valid.paper.json": {"id": "valid-1", "embedding": [0.1, 0.2, 0.3]},
                "c-valid.paper.json": {"id": "valid-2", "embedding": [0.4, 0.5, 0.6]},
            }
            for filename, payload in fixtures.items():
                (papers_dir / filename).write_text(json.dumps(payload), encoding="utf-8")

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual([row.paper_id for row in rows], ["valid-1", "valid-2"])
            self.assertTrue(all(len(embedding) == 3 for embedding in embeddings))
            self.assertEqual(
                [row["paper_id"] for row in trading_rows],
                ["valid-1", "valid-2"],
            )

    def test_load_chunks_handles_malformed_and_non_dict_entries(self):
        with tempfile.TemporaryDirectory() as tmp:
            chunks_path = Path(tmp) / "chunks.json"
            chunks_path.write_text('{"bad": true', encoding="utf-8")
            self.assertEqual(load_chunks(chunks_path), [])

            chunks_path.write_text(
                json.dumps(
                    [
                        {"paperID": "p1", "embedding": [0.1, 0.2]},
                        {"paperID": "p2", "embedding": []},
                        {"paperID": "p3"},
                        "not-a-dict",
                    ]
                ),
                encoding="utf-8",
            )

            chunks = load_chunks(chunks_path)
            self.assertEqual(len(chunks), 1)
            self.assertEqual(chunks[0]["paperID"], "p1")

    def test_load_user_events_logs_malformed_lines(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_root = Path(tmp)
            analytics_dir = output_root / "analytics"
            analytics_dir.mkdir()
            (analytics_dir / "user_events.jsonl").write_text('{"type":"valid"}\nnot-json\n', encoding="utf-8")

            with self.assertLogs("analytics.rebuild_analytics", level="WARNING") as logs:
                events = load_user_events(output_root)

            self.assertEqual(events, [{"type": "valid"}])
            self.assertTrue(any("line 2" in message for message in logs.output))

    def test_compute_factor_loadings_handles_empty_tag_vocabulary(self):
        embeddings = np.array(
            [
                [0.1, 0.2, 0.3, 0.4],
                [0.2, 0.1, 0.4, 0.3],
            ],
            dtype=np.float32,
        )
        paper_ids = ["p1", "p2"]
        tag_texts = ["", ""]

        factors, loadings, labels = compute_factor_loadings(
            embeddings,
            paper_ids,
            tag_texts,
            n_factors=3,
        )

        self.assertEqual(len(loadings), 2)
        self.assertEqual([row["paper_id"] for row in loadings], paper_ids)
        self.assertGreaterEqual(len(factors), 1)
        self.assertEqual(labels, ["Factor 1", "Factor 2", "Factor 3"])

    def test_write_embeddings_whitened_parquet_uses_duckdb_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            out_path = Path(tmp) / "embeddings_whitened.parquet"
            paper_ids = ["p1", "p2"]
            embeddings = np.array([[0.1, 0.2], [0.3, 0.4]], dtype=np.float32)

            write_embeddings_whitened_parquet(paper_ids, embeddings, out_path)

            self.assertTrue(out_path.exists())
            self.assertGreater(out_path.stat().st_size, 0)

    def test_persist_duckdb_handles_empty_claims_and_methods(self):
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "atlas.duckdb"
            df_papers = pd.DataFrame(
                [
                    {
                        "paper_id": "p1",
                        "claims": None,
                        "method_pipeline": None,
                    }
                ]
            )
            embeddings = np.array([[0.1, 0.2, 0.3]], dtype=np.float32)

            persist_duckdb(db_path, df_papers, embeddings, chunks=[])

            con = duckdb.connect(str(db_path))
            try:
                claims_count = con.execute("SELECT COUNT(*) FROM claims").fetchone()[0]
                methods_count = con.execute("SELECT COUNT(*) FROM methods").fetchone()[0]
            finally:
                con.close()

            self.assertEqual(claims_count, 0)
            self.assertEqual(methods_count, 0)


if __name__ == "__main__":
    unittest.main()
