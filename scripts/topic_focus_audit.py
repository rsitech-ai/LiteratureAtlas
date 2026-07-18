#!/usr/bin/env python3
"""
Topic reliability audit for LiteratureAtlas outputs.

Goal: verify that a corpus has at least one coherent, easy-to-search topic
you can rely on after ingestion, even when cluster metadata is sparse.

The script reads `Output/papers/*.paper.json`, checks Obsidian linkage,
builds topic groups (prefer existing clusters; fallback to KMeans over
embeddings), computes reliability metrics, and writes a report to:

  Output/reports/topic_focus_reliability_<timestamp>.md
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
from sklearn.cluster import KMeans
from sklearn.feature_extraction.text import ENGLISH_STOP_WORDS
from sklearn.metrics import silhouette_score


UUID_RE = re.compile(r"^[0-9A-Fa-f-]{36}$")
NOTE_ID_RE = re.compile(r"\[([0-9A-Fa-f-]{36})\]\.md$")
TOKEN_RE = re.compile(r"\b[a-z][a-z0-9+\-]{2,}\b")

# Compact stopword set + project-specific boilerplate terms.
PROJECT_STOPWORDS = {
    "the",
    "and",
    "for",
    "with",
    "from",
    "using",
    "via",
    "into",
    "under",
    "through",
    "based",
    "this",
    "that",
    "their",
    "our",
    "your",
    "paper",
    "study",
    "analysis",
    "approach",
    "method",
    "methods",
    "model",
    "models",
    "data",
    "results",
    "problem",
    "setup",
    "experimental",
    "evaluation",
    "summary",
    "details",
    "section",
    "specified",
    "unknown",
    "provided",
    "technical",
    "quant",
    "key",
    "include",
    "includes",
    "including",
    "constraints",
    "constraint",
    "horizon",
    "ideas",
    "idea",
    "introduces",
    "focusing",
    "focuses",
    "specific",
    "discusses",
    "type",
    "types",
    "text",
    "bullet",
    "concise",
    "not",
    "are",
    "use",
    "using",
    "used",
    "contributions",
    "predicting",
    "framing",
    "enables",
    "improved",
    "prediction",
    "baselines",
}
STOPWORDS = set(ENGLISH_STOP_WORDS).union(PROJECT_STOPWORDS)


@dataclass(frozen=True)
class PaperRecord:
    paper_id: str
    title: str
    tokens: set[str]
    year_present: bool
    note_present: bool
    embedding: np.ndarray | None
    explicit_cluster_id: int | None
    source_path: Path


@dataclass(frozen=True)
class TopicMetrics:
    topic_id: int
    size: int
    top_terms: tuple[str, ...]
    top_term_coverage: float
    year_coverage: float
    note_coverage: float
    embedding_coverage: float
    representative_titles: tuple[str, ...]
    query: str
    reliable: bool
    reliability_reasons: tuple[str, ...]


def _ratio(numerator: int, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return numerator / float(denominator)


def _normalize_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[\r\n\t]+", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def _normalize_uuid(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    raw = value.strip()
    if not raw or not UUID_RE.match(raw):
        return None
    return raw.upper()


def _safe_int(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        if not math.isfinite(value) or not value.is_integer():
            return None
        return int(value)
    if isinstance(value, str):
        stripped = value.strip()
        if not stripped:
            return None
        try:
            return int(stripped)
        except (ValueError, OverflowError):
            return None
    return None


def _stringify(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, (int, float, bool)):
        return str(value)
    return ""


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON number {value}")


def _extract_tokens_from_paper(data: dict[str, Any]) -> set[str]:
    parts: list[str] = []
    # Prefer fields that are less likely to include template boilerplate.
    parts.append(_stringify(data.get("title")))

    keywords = data.get("keywords")
    if isinstance(keywords, list):
        parts.extend(_stringify(x) for x in keywords)

    claims = data.get("claims")
    if isinstance(claims, list):
        for claim in claims:
            if isinstance(claim, dict):
                parts.append(_stringify(claim.get("statement")))

    joined = _normalize_text(" ".join(p for p in parts if p))
    tokens = {tok for tok in TOKEN_RE.findall(joined) if tok not in STOPWORDS}
    return tokens


def _load_note_ids(obsidian_papers_dir: Path) -> set[str]:
    ids: set[str] = set()
    if not obsidian_papers_dir.is_dir():
        return ids

    for path in obsidian_papers_dir.glob("*.md"):
        match = NOTE_ID_RE.search(path.name)
        if match:
            ids.add(match.group(1).upper())
    return ids


def _load_cluster_lookup_from_parquet(output_root: Path) -> dict[str, int]:
    parquet_path = output_root / "analytics" / "papers.parquet"
    if not parquet_path.exists():
        return {}

    try:
        import pandas as pd  # type: ignore
    except Exception:
        return {}

    columns = ["paper_id", "cluster_id", "primary_cluster_k10", "primary_cluster_k50"]
    try:
        df = pd.read_parquet(parquet_path, columns=columns)
    except Exception:
        return {}

    lookup: dict[str, int] = {}
    for _, row in df.iterrows():
        paper_id = _normalize_uuid(row.get("paper_id"))
        if not paper_id:
            continue
        cluster_val = None
        for key in ("cluster_id", "primary_cluster_k10", "primary_cluster_k50"):
            maybe = _safe_int(row.get(key))
            if maybe is not None:
                cluster_val = maybe
                break
        if cluster_val is not None:
            lookup[paper_id] = cluster_val
    return lookup


def load_papers(output_root: Path) -> list[PaperRecord]:
    papers_dir = output_root / "papers"
    obsidian_dir = output_root / "obsidian" / "papers"
    note_ids = _load_note_ids(obsidian_dir)
    parquet_lookup = _load_cluster_lookup_from_parquet(output_root)

    papers: list[PaperRecord] = []
    seen_ids: set[str] = set()
    embedding_dimension: int | None = None

    def candidate_rank(path: Path) -> tuple[int, str]:
        try:
            modified_ns = path.stat().st_mtime_ns
        except OSError:
            modified_ns = 0
        return (-modified_ns, path.as_posix())

    for path in sorted(papers_dir.glob("*.paper.json"), key=candidate_rank):
        try:
            data = json.loads(
                path.read_text(encoding="utf-8"),
                parse_constant=_reject_json_constant,
            )
        except Exception as exc:
            raise ValueError(f"Invalid paper JSON in {path}: {exc}") from exc
        if not isinstance(data, dict):
            raise ValueError(f"Paper JSON must be an object: {path}")

        paper_id = _normalize_uuid(data.get("id"))
        if not paper_id:
            raise ValueError(f"Paper JSON has an invalid id: {path}")
        if paper_id in seen_ids:
            # Title changes can leave a stale id-suffixed export beside the new one.
            # The app and analytics rebuild resolve the same state by freshness.
            continue
        seen_ids.add(paper_id)

        embedding_arr: np.ndarray | None = None
        embedding = data.get("embedding")
        if embedding is not None and not isinstance(embedding, list):
            raise ValueError(f"Paper embedding must be a list: {path}")
        if isinstance(embedding, list) and embedding:
            try:
                embedding_arr = np.asarray(embedding, dtype=np.float32)
            except Exception as exc:
                raise ValueError(f"Paper embedding is not numeric: {path}") from exc
            if embedding_arr.ndim != 1 or embedding_arr.size < 2:
                raise ValueError(
                    f"Paper embedding must be a one-dimensional vector with at least 2 values: {path}"
                )
            if not np.isfinite(embedding_arr).all():
                raise ValueError(f"Paper embedding contains a non-finite value: {path}")
            if embedding_dimension is None:
                embedding_dimension = int(embedding_arr.size)
            elif embedding_arr.size != embedding_dimension:
                raise ValueError(
                    f"Paper embedding dimension {embedding_arr.size} does not match {embedding_dimension}: {path}"
                )

        explicit_cluster = _safe_int(data.get("clusterIndex"))
        if explicit_cluster is None:
            explicit_cluster = parquet_lookup.get(paper_id)

        title = _stringify(data.get("title")).strip() or path.stem
        papers.append(
            PaperRecord(
                paper_id=paper_id,
                title=title,
                tokens=_extract_tokens_from_paper(data),
                year_present=_safe_int(data.get("year")) is not None,
                note_present=paper_id in note_ids,
                embedding=embedding_arr,
                explicit_cluster_id=explicit_cluster,
                source_path=path,
            )
        )
    return papers


def _auto_k(n: int, min_k: int, max_k: int) -> int:
    if n <= 2:
        return 1
    proposed = int(round(math.sqrt(max(4, n) / 2.0)))
    return max(min_k, min(max_k, proposed))


def assign_topics(
    papers: list[PaperRecord],
    min_cluster_coverage: float,
    min_k: int,
    max_k: int,
    seed: int,
) -> tuple[list[int], str, float | None]:
    n = len(papers)
    explicit = [p.explicit_cluster_id for p in papers]
    explicit_count = sum(1 for cid in explicit if cid is not None)
    coverage = _ratio(explicit_count, n)

    if coverage >= min_cluster_coverage:
        labels: list[int] = []
        next_unknown = -1
        for cid in explicit:
            if cid is None:
                labels.append(next_unknown)
                next_unknown -= 1
            else:
                labels.append(int(cid))
        return labels, "existing_clusters", None

    emb_idx = [i for i, p in enumerate(papers) if p.embedding is not None]
    if len(emb_idx) < 4:
        return list(range(n)), "singleton_fallback", None

    X = np.vstack(
        [papers[i].embedding for i in emb_idx if papers[i].embedding is not None]
    )
    k = _auto_k(len(emb_idx), min_k=min_k, max_k=max_k)
    if k <= 1 or len(emb_idx) <= k:
        return list(range(n)), "singleton_fallback", None

    km = KMeans(n_clusters=k, random_state=seed, n_init=10)
    emb_labels = km.fit_predict(X)

    labels = [-1] * n
    for pos, paper_idx in enumerate(emb_idx):
        labels[paper_idx] = int(emb_labels[pos])

    # Assign non-embedding papers to unique negative labels.
    next_unknown = -1
    for i, label in enumerate(labels):
        if label == -1:
            labels[i] = next_unknown
            next_unknown -= 1

    sil: float | None = None
    try:
        if k >= 2 and len(set(emb_labels.tolist())) >= 2:
            sil = float(silhouette_score(X, emb_labels, metric="cosine"))
    except Exception as exc:
        raise RuntimeError(f"Silhouette score computation failed: {exc}") from exc
    return labels, f"kmeans_k{k}", sil


def build_topic_metrics(
    papers: list[PaperRecord],
    labels: list[int],
    min_topic_size: int,
    min_top_term_coverage: float,
    min_year_coverage: float,
    min_note_coverage: float,
    min_embedding_coverage: float,
    max_global_term_ratio: float,
    max_terms: int = 6,
) -> list[TopicMetrics]:
    by_topic: dict[int, list[PaperRecord]] = defaultdict(list)
    for paper, label in zip(papers, labels, strict=True):
        by_topic[int(label)].append(paper)

    global_df: Counter[str] = Counter()
    for p in papers:
        global_df.update(p.tokens)
    total_docs = max(1, len(papers))

    topics: list[TopicMetrics] = []
    for topic_id in sorted(by_topic.keys()):
        members = by_topic[topic_id]
        size = len(members)
        term_presence: Counter[str] = Counter()
        for p in members:
            term_presence.update(p.tokens)

        scored_terms: list[tuple[float, str]] = []
        for term, count in term_presence.items():
            if count < 2:
                continue
            global_ratio = global_df[term] / float(total_docs)
            if global_ratio > max_global_term_ratio:
                continue
            topic_ratio = count / float(size)
            idf = math.log((total_docs + 1) / (global_df[term] + 1))
            score = topic_ratio * idf
            scored_terms.append((score, term))
        scored_terms.sort(key=lambda x: (-x[0], x[1]))

        filtered = [term for _, term in scored_terms]
        if not filtered:
            top_terms_raw = [t for t, _ in term_presence.most_common(30)]
            filtered = [t for t in top_terms_raw if term_presence[t] >= 2]
        if not filtered:
            filtered = [t for t, _ in term_presence.most_common(30)]
        top_terms = tuple(filtered[:max_terms])

        if top_terms:
            cov_values = [term_presence[t] / float(size) for t in top_terms[:3]]
            top_term_coverage = float(sum(cov_values) / len(cov_values))
        else:
            top_term_coverage = 0.0

        year_coverage = _ratio(sum(1 for p in members if p.year_present), size)
        note_coverage = _ratio(sum(1 for p in members if p.note_present), size)
        embedding_coverage = _ratio(
            sum(1 for p in members if p.embedding is not None), size
        )

        reps = tuple(sorted((p.title for p in members), key=len)[:3])
        query_terms = list(top_terms[:4])
        query = " OR ".join(f'"{t}"' for t in query_terms) if query_terms else ""

        reasons: list[str] = []
        if size < min_topic_size:
            reasons.append(f"size<{min_topic_size}")
        if len(top_terms) < 3:
            reasons.append("insufficient_terms")
        if top_term_coverage < min_top_term_coverage:
            reasons.append(f"cohesion<{min_top_term_coverage:.2f}")
        if year_coverage < min_year_coverage:
            reasons.append(f"year_cov<{min_year_coverage:.2f}")
        if note_coverage < min_note_coverage:
            reasons.append(f"note_cov<{min_note_coverage:.2f}")
        if embedding_coverage < min_embedding_coverage:
            reasons.append(f"emb_cov<{min_embedding_coverage:.2f}")

        topics.append(
            TopicMetrics(
                topic_id=topic_id,
                size=size,
                top_terms=top_terms,
                top_term_coverage=top_term_coverage,
                year_coverage=year_coverage,
                note_coverage=note_coverage,
                embedding_coverage=embedding_coverage,
                representative_titles=reps,
                query=query,
                reliable=(len(reasons) == 0),
                reliability_reasons=tuple(reasons),
            )
        )

    topics.sort(key=lambda t: (-t.size, -t.top_term_coverage, t.topic_id))
    return topics


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit whether corpus has reliable, searchable topics."
    )
    parser.add_argument(
        "--base", default=".", help="Repo root path (default: current directory)."
    )
    parser.add_argument(
        "--min-cluster-coverage",
        type=float,
        default=0.60,
        help="If explicit cluster id coverage is >= this threshold, use existing clusters instead of KMeans.",
    )
    parser.add_argument(
        "--kmeans-min-k", type=int, default=4, help="Minimum K for KMeans fallback."
    )
    parser.add_argument(
        "--kmeans-max-k", type=int, default=10, help="Maximum K for KMeans fallback."
    )
    parser.add_argument(
        "--seed", type=int, default=0, help="Random seed for deterministic KMeans."
    )
    parser.add_argument(
        "--min-reliable-topics",
        type=int,
        default=1,
        help="Minimum reliable topics required for PASS.",
    )
    parser.add_argument(
        "--min-primary-topic-size",
        type=int,
        default=8,
        help="Minimum size for largest topic.",
    )
    parser.add_argument(
        "--min-topic-size", type=int, default=6, help="Per-topic minimum papers."
    )
    parser.add_argument(
        "--min-top-term-coverage",
        type=float,
        default=0.15,
        help="Per-topic cohesion threshold.",
    )
    parser.add_argument(
        "--min-year-coverage",
        type=float,
        default=0.90,
        help="Per-topic year coverage threshold.",
    )
    parser.add_argument(
        "--min-note-coverage",
        type=float,
        default=0.90,
        help="Per-topic Obsidian note coverage threshold.",
    )
    parser.add_argument(
        "--min-embedding-coverage",
        type=float,
        default=0.95,
        help="Per-topic embedding coverage threshold.",
    )
    parser.add_argument(
        "--max-global-term-ratio",
        type=float,
        default=0.40,
        help="Drop candidate label terms that appear in more than this fraction of all papers.",
    )
    parser.add_argument(
        "--min-silhouette",
        type=float,
        default=0.05,
        help="Minimum silhouette score when KMeans is used (ignored if unavailable).",
    )
    parser.add_argument(
        "--max-topics",
        type=int,
        default=20,
        help="Maximum number of topics listed in report.",
    )
    return parser.parse_args()


def run_audit(args: argparse.Namespace) -> tuple[int, str]:
    repo_root = Path(args.base).expanduser().resolve()
    output_root = repo_root / "Output"
    papers_dir = output_root / "papers"
    if not papers_dir.is_dir():
        return 2, f"Missing papers directory: {papers_dir}"

    papers = load_papers(output_root)
    if not papers:
        return 2, "No readable papers found in Output/papers."

    try:
        labels, method, silhouette = assign_topics(
            papers=papers,
            min_cluster_coverage=float(args.min_cluster_coverage),
            min_k=int(args.kmeans_min_k),
            max_k=int(args.kmeans_max_k),
            seed=int(args.seed),
        )
    except RuntimeError as exc:
        return 2, f"Topic reliability audit error: {exc}"

    topics = build_topic_metrics(
        papers=papers,
        labels=labels,
        min_topic_size=int(args.min_topic_size),
        min_top_term_coverage=float(args.min_top_term_coverage),
        min_year_coverage=float(args.min_year_coverage),
        min_note_coverage=float(args.min_note_coverage),
        min_embedding_coverage=float(args.min_embedding_coverage),
        max_global_term_ratio=float(args.max_global_term_ratio),
    )

    reliable_topics = [t for t in topics if t.reliable]
    largest_topic_size = max((t.size for t in topics), default=0)

    checks: list[tuple[str, bool, str]] = []
    checks.append(
        (
            "reliable topic count",
            len(reliable_topics) >= int(args.min_reliable_topics),
            f"{len(reliable_topics)} reliable (required >= {int(args.min_reliable_topics)})",
        )
    )
    checks.append(
        (
            "primary topic size",
            largest_topic_size >= int(args.min_primary_topic_size),
            f"largest={largest_topic_size} (required >= {int(args.min_primary_topic_size)})",
        )
    )
    if silhouette is None:
        checks.append(
            ("topic separability", True, "silhouette unavailable; check skipped")
        )
    else:
        checks.append(
            (
                "topic separability",
                silhouette >= float(args.min_silhouette),
                f"silhouette={silhouette:.4f} (required >= {float(args.min_silhouette):.4f})",
            )
        )

    passed = all(ok for _, ok, _ in checks)
    status = "PASS" if passed else "FAIL"

    report_dir = output_root / "reports"
    report_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    report_path = report_dir / f"topic_focus_reliability_{stamp}.md"

    lines: list[str] = []
    lines.append("# Topic Reliability Audit")
    lines.append("")
    lines.append(f"- Status: **{status}**")
    lines.append(f"- Topic assignment method: `{method}`")
    lines.append(f"- Timestamp (UTC): `{stamp}`")
    lines.append(f"- Papers scanned: `{len(papers)}`")
    lines.append(f"- Topics found: `{len(topics)}`")
    lines.append(f"- Reliable topics: `{len(reliable_topics)}`")
    if silhouette is not None:
        lines.append(f"- Silhouette score: `{silhouette:.4f}`")
    lines.append("")

    lines.append("## Threshold checks")
    lines.append("")
    for name, ok, detail in checks:
        mark = "PASS" if ok else "FAIL"
        lines.append(f"- [{mark}] {name}: {detail}")
    lines.append("")

    lines.append("## Reliable Topics (Search-Ready)")
    lines.append("")
    if reliable_topics:
        for t in reliable_topics[: max(1, int(args.max_topics))]:
            terms = ", ".join(t.top_terms[:5]) if t.top_terms else "n/a"
            reps = (
                "; ".join(t.representative_titles) if t.representative_titles else "n/a"
            )
            lines.append(
                f"- Topic `{t.topic_id}` | size={t.size} | cohesion={t.top_term_coverage:.2f}"
            )
            lines.append(f"  terms: `{terms}`")
            lines.append(f"  query: `{t.query}`")
            lines.append(f"  examples: {reps}")
    else:
        lines.append("- No reliable topics found for current thresholds.")
    lines.append("")

    lines.append("## All Topics")
    lines.append("")
    for t in topics[: max(1, int(args.max_topics))]:
        terms = ", ".join(t.top_terms[:5]) if t.top_terms else "n/a"
        verdict = (
            "reliable"
            if t.reliable
            else f"not reliable ({', '.join(t.reliability_reasons)})"
        )
        lines.append(
            f"- Topic `{t.topic_id}` | size={t.size} | cohesion={t.top_term_coverage:.2f} | "
            f"year={t.year_coverage:.1%} | notes={t.note_coverage:.1%} | emb={t.embedding_coverage:.1%} | {verdict}"
        )
        lines.append(f"  terms: `{terms}`")
    lines.append("")

    report_path.write_text("\n".join(lines), encoding="utf-8")

    stdout_lines: list[str] = []
    stdout_lines.append(
        f"Topic reliability audit -> {status} "
        f"(method={method}, reliable_topics={len(reliable_topics)}, total_topics={len(topics)})"
    )
    for name, ok, detail in checks:
        stdout_lines.append(f"- {name}: {'ok' if ok else 'fail'} ({detail})")
    stdout_lines.append(f"Report written: {report_path}")
    return (0 if passed else 1), "\n".join(stdout_lines)


def main() -> int:
    args = _parse_args()
    code, message = run_audit(args)
    stream = sys.stdout if code in (0, 1) else sys.stderr
    print(message, file=stream)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
