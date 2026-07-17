#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/run_example_smoke.sh --source DIR [--count N] [--seed S] [--keep-workspace]

Runs an end-to-end smoke flow on a random sample of PDFs:
1) Select N random PDFs from an explicitly supplied authorized source folder
2) Run opt-in Swift ingestion smoke test against sampled folder
3) Rebuild analytics on sampled output
4) Build ANN edges
5) Run output artifact audit
6) Run topic reliability audit

Environment:
  LITERATURE_ATLAS_INGEST_SMOKE_TIMEOUT_SEC  Optional ingestion timeout (seconds, default: 1200)
EOF
}

COUNT=10
SEED=""
SOURCE_DIR=""
KEEP_WORKSPACE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count)
      COUNT="${2:-}"
      shift 2
      ;;
    --seed)
      SEED="${2:-}"
      shift 2
      ;;
    --source)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --keep-workspace)
      KEEP_WORKSPACE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${REPO_ROOT}/analytics/.venv/bin/python"

if [[ -z "${SOURCE_DIR}" ]]; then
  echo "--source DIR is required; supply a corpus you are authorized to use" >&2
  exit 2
fi

if [[ ! -x "${PYTHON}" ]]; then
  echo "Missing ${PYTHON}. Create .venv and install analytics deps first." >&2
  exit 2
fi

if [[ "${SOURCE_DIR}" = /* ]]; then
  SOURCE_PATH="${SOURCE_DIR}"
else
  SOURCE_PATH="${REPO_ROOT}/${SOURCE_DIR}"
fi
if [[ ! -d "${SOURCE_PATH}" ]]; then
  echo "Source directory not found: ${SOURCE_PATH}" >&2
  exit 2
fi

SMOKE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/literatureatlas_smoke.XXXXXX")"
cleanup() {
  if [[ "${KEEP_WORKSPACE}" = false ]]; then
    rm -rf "${SMOKE_ROOT}"
  fi
}
trap cleanup EXIT
SMOKE_BASE="${SMOKE_ROOT}/base"
SMOKE_INPUT="${SMOKE_ROOT}/input"
SMOKE_OUTPUT="${SMOKE_BASE}/Output"
mkdir -p "${SMOKE_BASE}" "${SMOKE_INPUT}" "${SMOKE_OUTPUT}"

echo "[smoke] workspace: ${SMOKE_ROOT}"
echo "[smoke] selecting ${COUNT} random PDFs from ${SOURCE_PATH}"

SMOKE_SOURCE_PATH="${SOURCE_PATH}" \
SMOKE_INPUT_PATH="${SMOKE_INPUT}" \
SMOKE_COUNT="${COUNT}" \
SMOKE_SEED="${SEED}" \
"${PYTHON}" - <<'PY'
import random
import shutil
import sys
import os
from pathlib import Path

source = Path(os.environ["SMOKE_SOURCE_PATH"])
dest = Path(os.environ["SMOKE_INPUT_PATH"])
count = int(os.environ["SMOKE_COUNT"])
seed_raw = os.environ.get("SMOKE_SEED", "")

pdfs = sorted(source.glob("*.pdf"))
if len(pdfs) < count:
    print(f"Need at least {count} PDFs in {source}, found {len(pdfs)}", file=sys.stderr)
    raise SystemExit(2)

rng = random.SystemRandom() if seed_raw == "" else random.Random(int(seed_raw))
picked = rng.sample(pdfs, count)
for idx, src in enumerate(picked, start=1):
    dst = dest / src.name
    shutil.copy2(src, dst)
    print(f"[sample {idx:02d}] {src.name}")
PY

echo "[smoke] running ingestion smoke test"
(
  cd "${REPO_ROOT}"
  LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR="${SMOKE_INPUT}" \
  LITERATURE_ATLAS_INGEST_SMOKE_OUTPUT_ROOT="${SMOKE_OUTPUT}" \
  LITERATURE_ATLAS_INGEST_SMOKE_EXPECTED_COUNT="${COUNT}" \
  LITERATURE_ATLAS_SMOKE_FAST="1" \
  LITERATURE_ATLAS_INGEST_SMOKE_TIMEOUT_SEC="${LITERATURE_ATLAS_INGEST_SMOKE_TIMEOUT_SEC:-1200}" \
  swift test --filter IngestionSmokeTests/testIngestsSampleFolderAndWritesArtifacts
)

echo "[smoke] rebuilding analytics"
(
  cd "${REPO_ROOT}"
  "${PYTHON}" analytics/rebuild_analytics.py --base "${SMOKE_BASE}"
)

if [[ -f "${REPO_ROOT}/analytics/rust/Cargo.toml" ]]; then
  echo "[smoke] building ANN edges"
  (
    cd "${REPO_ROOT}"
    cargo run --manifest-path analytics/rust/Cargo.toml --release -- \
      --emb "${SMOKE_OUTPUT}/analytics/paper_embeddings.parquet" \
      --out "${SMOKE_OUTPUT}/analytics/ann_edges.json" \
      --k 8
  )
else
  echo "[smoke] skipping ANN edge build; analytics/rust CLI is not present in this checkout"
fi

echo "[smoke] running output artifact audit"
(
  cd "${SMOKE_BASE}"
  "${PYTHON}" "${REPO_ROOT}/scripts/audit_output_artifacts.py"
)

echo "[smoke] running topic reliability audit"
MIN_TOPIC_SIZE=$(( COUNT / 3 ))
if (( MIN_TOPIC_SIZE < 3 )); then
  MIN_TOPIC_SIZE=3
fi

# Require a dominant topic, but keep this realistic for small random samples.
# ceil(0.4 * COUNT) avoids flaky failures where a coherent cluster has 4/10 papers.
MIN_PRIMARY_TOPIC_SIZE=$(( (COUNT * 2 + 4) / 5 ))
if (( MIN_PRIMARY_TOPIC_SIZE < 3 )); then
  MIN_PRIMARY_TOPIC_SIZE=3
fi

echo "[smoke] topic thresholds: min_topic_size=${MIN_TOPIC_SIZE}, min_primary_topic_size=${MIN_PRIMARY_TOPIC_SIZE}"

(
  cd "${REPO_ROOT}"
  "${PYTHON}" scripts/topic_focus_audit.py \
    --base "${SMOKE_BASE}" \
    --min-topic-size "${MIN_TOPIC_SIZE}" \
    --min-primary-topic-size "${MIN_PRIMARY_TOPIC_SIZE}"
)

echo "[smoke] complete"
if [[ "${KEEP_WORKSPACE}" = true ]]; then
  echo "[smoke] sampled input: ${SMOKE_INPUT}"
  echo "[smoke] output root: ${SMOKE_OUTPUT}"
  echo "[smoke] reports: ${SMOKE_OUTPUT}/reports"
else
  echo "[smoke] temporary sampled PDFs and outputs will be removed"
fi
