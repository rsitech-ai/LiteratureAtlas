import json
import os
import tempfile
import unittest
import warnings
from pathlib import Path
from unittest.mock import patch

import duckdb
import numpy as np
import pandas as pd

import analytics.rebuild_analytics as rebuild_analytics
from analytics.rebuild_analytics import (
    build_knn,
    claim_similarity_edges,
    cluster_stability_multi_seed_kmeans,
    combinational_novelty,
    compute_factor_loadings,
    drift_contribution,
    load_chunks,
    load_papers,
    load_user_events,
    paper_layout_quality_metrics,
    persist_duckdb,
    qa_gap_analytics,
    whiten_embeddings,
    write_embeddings_whitened_parquet,
    write_summary,
)

PAPER_ID_1 = "00000000-0000-0000-0000-000000000001"
PAPER_ID_2 = "00000000-0000-0000-0000-000000000002"
PAPER_ID_3 = "00000000-0000-0000-0000-000000000003"
PAPER_ID_4 = "00000000-0000-0000-0000-000000000004"


class RebuildAnalyticsUnitTests(unittest.TestCase):
    def test_claim_similarity_edges_bounds_neighbors_and_preserves_time_direction(self):
        claims = [
            {
                "statement": "robust portfolio optimization improves downside risk control",
                "year": 2000 + index,
                "paper_id": f"p{index}",
            }
            for index in range(20)
        ]

        edges = claim_similarity_edges(claims, threshold=0.0, max_neighbors=3)

        self.assertLessEqual(len(edges), len(claims) * 3)
        self.assertTrue(edges)
        self.assertTrue(all(edge["from_year"] < edge["to_year"] for edge in edges))

    def test_claim_similarity_edges_handles_empty_vocabulary(self):
        claims = [
            {"statement": "", "year": 2020, "paper_id": "p1"},
            {"statement": "", "year": 2021, "paper_id": "p2"},
        ]

        self.assertEqual(claim_similarity_edges(claims), [])

    def test_claim_similarity_edges_skips_non_text_statements(self):
        claims = [
            {"statement": ["not", "text"], "year": 2020, "paper_id": "p1"},
            {"statement": "valid claim text", "year": 2021, "paper_id": "p2"},
        ]

        self.assertEqual(claim_similarity_edges(claims), [])

    def test_claim_similarity_edges_sizes_neighbors_from_valid_claims(self):
        claims = [
            {
                "statement": "robust portfolio optimization improves downside risk control",
                "year": 2020,
                "paper_id": "p1",
            },
            {
                "statement": "portfolio optimization improves robust downside risk control",
                "year": 2021,
                "paper_id": "p2",
            },
            {"statement": ["not", "text"], "year": 2022, "paper_id": "p3"},
        ]

        edges = claim_similarity_edges(claims, threshold=0.0, max_neighbors=3)

        self.assertEqual(len(edges), 1)
        self.assertEqual(edges[0]["from_year"], 2020)
        self.assertEqual(edges[0]["to_year"], 2021)

    def test_compute_factor_loadings_single_sample_emits_no_runtime_warning(self):
        with warnings.catch_warnings(record=True) as captured:
            warnings.simplefilter("always")
            factors, loadings, _ = compute_factor_loadings(
                np.array([[1.0, 2.0, 3.0]], dtype=np.float32),
                ["p1"],
                ["analytics reliability"],
                n_factors=3,
            )

        self.assertFalse(captured)
        self.assertEqual(len(loadings), 1)
        self.assertTrue(np.isfinite(np.asarray(factors)).all())

    def test_compute_factor_loadings_rank_deficient_tags_emit_no_runtime_warning(self):
        embeddings = np.array(
            [[1.0 + index * 0.01, index * 0.02, 0.5] for index in range(12)],
            dtype=np.float32,
        )
        tag_texts = [
            f"topic-{index // 6} evaluation method-{index % 2} Stable evaluation protocol" for index in range(12)
        ]

        with warnings.catch_warnings(record=True) as captured:
            warnings.simplefilter("always")
            factors, loadings, _ = compute_factor_loadings(
                embeddings,
                [f"p{index}" for index in range(12)],
                tag_texts,
                n_factors=8,
            )

        self.assertFalse(captured)
        self.assertEqual(len(loadings), 12)
        self.assertTrue(np.isfinite(np.asarray(factors)).all())

    def test_qa_gap_analytics_uses_private_retrieval_events_without_raw_question(self):
        events = [
            {"event_type": "qa_question", "question_length": 18},
            {
                "event_type": "qa_retrieval",
                "top_scores": [0.8, 0.5],
                "margin": 0.3,
                "support_breadth": 0.7,
            },
            {"event_type": "qa_answer_ready", "question_length": 18},
        ]

        result = qa_gap_analytics(events, pd.DataFrame())

        self.assertTrue(result["available"])
        self.assertEqual(result["questions"][0]["question"], "Private question 1 (18 chars)")
        self.assertFalse(result["questions"][0]["unanswered"])
        self.assertEqual(result["questions"][0]["margin"], 0.3)

    def test_whiten_embeddings_handles_single_sample_without_non_finite_output(self):
        transformed, model = whiten_embeddings(np.array([[1.0, 2.0, 3.0]], dtype=np.float32))

        self.assertIsNone(model)
        np.testing.assert_array_equal(transformed, np.zeros((1, 1), dtype=np.float32))

    def test_whiten_embeddings_drops_components_outside_effective_rank(self):
        embeddings = np.array(
            [
                [1.0, 1.0, 1.0],
                [2.0, 2.0, 2.0],
                [3.0, 3.0, 3.0],
            ],
            dtype=np.float32,
        )

        transformed, _ = whiten_embeddings(embeddings)

        self.assertEqual(transformed.shape, (3, 1))
        self.assertTrue(np.isfinite(transformed).all())

    def test_whiten_embeddings_handles_zero_rank_without_warning_or_artificial_separation(self):
        embeddings = np.ones((4, 3), dtype=np.float32)

        with warnings.catch_warnings(record=True) as captured:
            warnings.simplefilter("always")
            transformed, model = whiten_embeddings(embeddings)

        self.assertFalse(captured)
        self.assertIsNone(model)
        self.assertTrue(np.isfinite(transformed).all())
        self.assertEqual(len(np.unique(transformed, axis=0)), 1)

    def test_drift_contribution_returns_json_serializable_floats(self):
        papers = pd.DataFrame(
            {
                "paper_id": ["p0", "p1"],
                "cluster_id": [0, 0],
                "year": [2020, 2020],
            }
        )
        embeddings = np.array([[0.0, 0.0], [1.0, 1.0]], dtype=np.float32)
        drift_vectors = {(0, 2020): np.array([1.0, 0.0], dtype=np.float32)}

        result = drift_contribution(papers, embeddings, drift_vectors, {})

        json.dumps(result, allow_nan=False)
        self.assertTrue(all(type(value) is float for value in result.values()))

    def test_build_knn_uses_bounded_neighbor_queries(self):
        real_nearest_neighbors = rebuild_analytics.NearestNeighbors
        observed: dict[str, object] = {}

        class RecordingNearestNeighbors:
            def __init__(self, *args, **kwargs):
                observed["n_neighbors"] = kwargs.get("n_neighbors")
                observed["metric"] = kwargs.get("metric")
                self._delegate = real_nearest_neighbors(*args, **kwargs)

            def fit(self, values):
                self._delegate.fit(values)
                return self

            def kneighbors(self, *args, **kwargs):
                observed["queried"] = True
                return self._delegate.kneighbors(*args, **kwargs)

        embeddings = np.array(
            [
                [1.0, 0.0],
                [0.9, 0.1],
                [0.0, 1.0],
                [0.1, 0.9],
            ],
            dtype=np.float32,
        )

        with patch.object(rebuild_analytics, "NearestNeighbors", RecordingNearestNeighbors):
            neighbors = build_knn(embeddings, ["p0", "p1", "p2", "p3"], k=2)

        self.assertEqual(observed["n_neighbors"], 3)
        self.assertEqual(observed["metric"], "cosine")
        self.assertTrue(observed["queried"])
        self.assertTrue(all(len(row["neighbors"]) == 2 for row in neighbors))

    def test_combinational_novelty_does_not_allocate_vocab_squared_matrix(self):
        df_papers = pd.DataFrame(
            [
                {
                    "paper_id": f"p{index}",
                    "tags": [f"tag-{index}", "shared"],
                    "assumptions": [f"assumption-{index}"],
                    "method_pipeline": None,
                }
                for index in range(20)
            ]
        )
        real_zeros = np.zeros

        def reject_dense_square(shape, *args, **kwargs):
            if isinstance(shape, tuple) and len(shape) == 2:
                raise AssertionError(f"unexpected dense matrix allocation: {shape}")
            return real_zeros(shape, *args, **kwargs)

        with patch.object(rebuild_analytics.np, "zeros", side_effect=reject_dense_square):
            scores = combinational_novelty(df_papers)

        self.assertEqual(set(scores), set(df_papers.paper_id))
        self.assertTrue(all(np.isfinite(score) for score in scores.values()))

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
                "id": PAPER_ID_1,
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
            self.assertEqual(rows[0].paper_id, PAPER_ID_1)

    def test_load_papers_skips_non_uuid_paper_ids(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            valid_id = PAPER_ID_1
            fixtures = {
                "valid.paper.json": {"id": valid_id, "embedding": [0.1, 0.2, 0.3]},
                "invalid.paper.json": {"id": "not-a-uuid", "embedding": [0.4, 0.5, 0.6]},
            }
            for filename, payload in fixtures.items():
                (papers_dir / filename).write_text(json.dumps(payload), encoding="utf-8")

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual([row.paper_id for row in rows], [valid_id])
            self.assertEqual(embeddings, [[0.1, 0.2, 0.3]])
            self.assertEqual([row["paper_id"] for row in trading_rows], [valid_id])

    def test_load_papers_deduplicates_paper_and_document_exports_by_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_root = Path(tmp)
            papers_dir = output_root / "papers"
            documents_dir = output_root / "documents"
            papers_dir.mkdir()
            documents_dir.mkdir()
            canonical = {
                "id": PAPER_ID_1,
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
            self.assertEqual(rows[0].paper_id, PAPER_ID_1)
            self.assertEqual(rows[0].title, "Canonical paper export")

    def test_load_papers_uses_freshest_canonical_export_for_duplicate_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            stale = {
                "id": PAPER_ID_1,
                "title": "Stale export",
                "embedding": [0.1, 0.2, 0.3],
            }
            fresh = {**stale, "title": "Fresh export"}
            stale_path = papers_dir / "A.paper.json"
            fresh_path = papers_dir / "Z.paper.json"
            stale_path.write_text(json.dumps(stale), encoding="utf-8")
            fresh_path.write_text(json.dumps(fresh), encoding="utf-8")
            os.utime(stale_path, ns=(1_000_000_000, 1_000_000_000))
            os.utime(fresh_path, ns=(2_000_000_000, 2_000_000_000))

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual(len(rows), 1)
            self.assertEqual(len(embeddings), 1)
            self.assertEqual(len(trading_rows), 1)
            self.assertEqual(rows[0].title, "Fresh export")

    def test_load_papers_rejects_non_numeric_and_non_finite_embeddings(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            fixtures = {
                "valid.paper.json": {
                    "id": PAPER_ID_1,
                    "title": "Valid",
                    "embedding": [0.1, 0.2, 0.3],
                },
                "text.paper.json": {
                    "id": PAPER_ID_2,
                    "title": "Text",
                    "embedding": [0.1, "not-a-number", 0.3],
                },
                "nan.paper.json": {
                    "id": PAPER_ID_3,
                    "title": "NaN",
                    "embedding": [0.1, float("nan"), 0.3],
                },
                "boolean.paper.json": {
                    "id": PAPER_ID_4,
                    "title": "Boolean",
                    "embedding": [0.1, True, 0.3],
                },
            }
            for filename, payload in fixtures.items():
                (papers_dir / filename).write_text(json.dumps(payload), encoding="utf-8")

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual([row.paper_id for row in rows], [PAPER_ID_1])
            self.assertEqual(embeddings, [[0.1, 0.2, 0.3]])
            self.assertEqual([row["paper_id"] for row in trading_rows], [PAPER_ID_1])

    def test_load_papers_uses_modal_embedding_dimension(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            fixtures = {
                "a-short.paper.json": {"id": PAPER_ID_1, "embedding": [0.1, 0.2]},
                "b-valid.paper.json": {"id": PAPER_ID_2, "embedding": [0.1, 0.2, 0.3]},
                "c-valid.paper.json": {"id": PAPER_ID_3, "embedding": [0.4, 0.5, 0.6]},
            }
            for filename, payload in fixtures.items():
                (papers_dir / filename).write_text(json.dumps(payload), encoding="utf-8")

            rows, embeddings, trading_rows = load_papers(papers_dir)

            self.assertEqual([row.paper_id for row in rows], [PAPER_ID_2, PAPER_ID_3])
            self.assertTrue(all(len(embedding) == 3 for embedding in embeddings))
            self.assertEqual(
                [row["paper_id"] for row in trading_rows],
                [PAPER_ID_2, PAPER_ID_3],
            )

    def test_load_papers_normalizes_invalid_optional_scalar_types(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            payload = {
                "id": PAPER_ID_1,
                "embedding": [0.1, 0.2, 0.3],
                "title": ["not", "text"],
                "year": "not-a-year",
                "clusterIndex": "not-a-cluster",
                "pageCount": [42],
            }
            (papers_dir / "invalid-optionals.paper.json").write_text(json.dumps(payload), encoding="utf-8")

            rows, _, trading_rows = load_papers(papers_dir)

            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0].title, "")
            self.assertIsNone(rows[0].year)
            self.assertIsNone(rows[0].cluster_id)
            self.assertIsNone(rows[0].page_count)
            self.assertIsNone(trading_rows[0]["cluster_id"])

    def test_load_papers_normalizes_nested_claim_fields(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            payload = {
                "id": PAPER_ID_1,
                "embedding": [0.1, 0.2, 0.3],
                "claims": [
                    {
                        "id": "valid",
                        "statement": "  A valid claim.  ",
                        "assumptions": ["stationarity", 42],
                        "year": 2024.0,
                        "strength": 0.8,
                    },
                    {"id": "invalid", "statement": ["not", "text"]},
                ],
            }
            (papers_dir / "claims.paper.json").write_text(json.dumps(payload), encoding="utf-8")

            rows, _, _ = load_papers(papers_dir)

            self.assertEqual(
                rows[0].claims,
                [
                    {
                        "id": "valid",
                        "statement": "A valid claim.",
                        "assumptions": ["stationarity"],
                        "year": 2024,
                        "strength": 0.8,
                    }
                ],
            )

    def test_load_papers_normalizes_malformed_method_pipeline_steps(self):
        with tempfile.TemporaryDirectory() as tmp:
            papers_dir = Path(tmp)
            malformed_steps = {
                "id": "00000000-0000-0000-0000-000000000001",
                "embedding": [0.1, 0.2, 0.3],
                "methodPipeline": {"steps": 7},
            }
            mixed_steps = {
                "id": "00000000-0000-0000-0000-000000000002",
                "embedding": [0.4, 0.5, 0.6],
                "methodPipeline": {
                    "steps": [
                        42,
                        {"stage": "model", "label": ["not", "text"]},
                        {"stage": "model", "label": "  Valid model  ", "detail": 9},
                    ]
                },
            }
            (papers_dir / "malformed.paper.json").write_text(json.dumps(malformed_steps), encoding="utf-8")
            (papers_dir / "mixed.paper.json").write_text(json.dumps(mixed_steps), encoding="utf-8")

            rows, _, _ = load_papers(papers_dir)

            self.assertIsNone(rows[0].method_pipeline)
            self.assertEqual(
                rows[1].method_pipeline,
                {"steps": [{"stage": "model", "label": "Valid model", "detail": None}]},
            )
            scores = combinational_novelty(pd.DataFrame([row.__dict__ for row in rows]))
            self.assertEqual(set(scores), {row.paper_id for row in rows})

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

    def test_load_chunks_rejects_invalid_nested_fields_and_normalizes_valid_values(self):
        with tempfile.TemporaryDirectory() as tmp:
            chunks_path = Path(tmp) / "chunks.json"
            chunks_path.write_text(
                json.dumps(
                    [
                        {
                            "id": "valid",
                            "paperID": "p1",
                            "embedding": [0.1, 2],
                            "order": 1.0,
                            "pageHint": 3.0,
                            "text": "chunk text",
                        },
                        {"paperID": "p2", "embedding": ["not-numeric"], "order": 0},
                        {"paperID": "p3", "embedding": [0.2], "order": "not-an-int"},
                        {"paperID": "", "embedding": [0.3], "order": 0},
                    ]
                ),
                encoding="utf-8",
            )

            chunks = load_chunks(chunks_path)

            self.assertEqual(len(chunks), 1)
            self.assertEqual(chunks[0]["embedding"], [0.1, 2.0])
            self.assertEqual(chunks[0]["order"], 1)
            self.assertEqual(chunks[0]["pageHint"], 3)

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

    def test_persist_duckdb_supports_apostrophe_in_output_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            quoted_root = Path(tmp) / "researcher's atlas"
            quoted_root.mkdir()
            db_path = quoted_root / "atlas.duckdb"
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

            self.assertTrue((quoted_root / "analytics" / "papers.parquet").is_file())

    def test_persist_duckdb_can_anchor_parquet_output_independently_of_db_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "custom" / "atlas.duckdb"
            analytics_dir = root / "Output" / "analytics"
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

            persist_duckdb(
                db_path,
                df_papers,
                embeddings,
                chunks=[],
                parquet_dir=analytics_dir,
            )

            self.assertTrue(db_path.is_file())
            self.assertTrue((analytics_dir / "papers.parquet").is_file())
            self.assertFalse((db_path.parent / "analytics" / "papers.parquet").exists())

    def test_write_summary_rejects_non_finite_numbers(self):
        with tempfile.TemporaryDirectory() as tmp:
            analytics_dir = Path(tmp)

            with self.assertRaises(ValueError):
                write_summary(analytics_dir, {"score": float("nan")})

            self.assertFalse((analytics_dir / "analytics.json").exists())


if __name__ == "__main__":
    unittest.main()
