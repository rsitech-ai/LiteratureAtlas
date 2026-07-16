#!/usr/bin/env python3
"""Generate deterministic SPDX evidence for tracked source or an exact app bundle."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import pathlib
import subprocess
import tempfile
from typing import Any, Iterable


REPOSITORY = "https://github.com/s1korrrr/LiteratureAtlas"
GENERATOR = "Tool: LiteratureAtlas generate_spdx_sbom.py"


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def file_entry(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    relative = path.relative_to(root).as_posix()
    identifier = hashlib.sha256(relative.encode("utf-8")).hexdigest()[:20]
    return {
        "fileName": relative,
        "SPDXID": f"SPDXRef-File-{identifier}",
        "checksums": [{"algorithm": "SHA256", "checksumValue": sha256(path)}],
        "licenseConcluded": "NOASSERTION",
        "licenseInfoInFiles": ["NOASSERTION"],
        "copyrightText": "NOASSERTION",
    }


def base_document(name: str, namespace: str, created: str) -> dict[str, Any]:
    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": name,
        "documentNamespace": namespace,
        "creationInfo": {"creators": [GENERATOR], "created": created},
    }


def add_package_and_relationships(
    document: dict[str, Any],
    *,
    package_name: str,
    version: str,
    files: list[dict[str, Any]],
) -> None:
    package_id = "SPDXRef-Package-LiteratureAtlas"
    document["packages"] = [
        {
            "name": package_name,
            "SPDXID": package_id,
            "versionInfo": version,
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": True,
            "licenseConcluded": "MIT",
            "licenseDeclared": "MIT",
            "copyrightText": "NOASSERTION",
        }
    ]
    document["files"] = files
    document["relationships"] = [
        {
            "spdxElementId": "SPDXRef-DOCUMENT",
            "relatedSpdxElement": package_id,
            "relationshipType": "DESCRIBES",
        },
        *[
            {
                "spdxElementId": package_id,
                "relatedSpdxElement": item["SPDXID"],
                "relationshipType": "CONTAINS",
            }
            for item in files
        ],
    ]


def build_source_document(
    *, root: pathlib.Path, paths: Iterable[pathlib.Path], revision: str, created: str
) -> dict[str, Any]:
    root = root.resolve()
    resolved_files = sorted(
        (root / path for path in paths if (root / path).is_file()),
        key=lambda path: path.relative_to(root).as_posix(),
    )
    files = [file_entry(root, path) for path in resolved_files]
    document = base_document(
        "LiteratureAtlas-source",
        f"{REPOSITORY}/sbom/source/{revision}",
        created,
    )
    add_package_and_relationships(
        document,
        package_name="LiteratureAtlas source",
        version=revision,
        files=files,
    )
    return document


def build_artifact_document(
    app: pathlib.Path, *, version: str, created: str
) -> dict[str, Any]:
    app = app.resolve()
    files = [
        file_entry(app, path)
        for path in sorted(
            (
                candidate
                for candidate in app.rglob("*")
                if candidate.is_file() and not candidate.is_symlink()
            ),
            key=lambda path: path.relative_to(app).as_posix(),
        )
    ]
    artifact_digest = hashlib.sha256(
        "".join(item["checksums"][0]["checksumValue"] for item in files).encode("ascii")
    ).hexdigest()
    document = base_document(
        app.name,
        f"{REPOSITORY}/sbom/artifact/{artifact_digest}",
        created,
    )
    add_package_and_relationships(
        document,
        package_name=app.name,
        version=version,
        files=files,
    )
    return document


def sanitize_cyclonedx(payload: Any, workspace_root: pathlib.Path) -> Any:
    old_root = workspace_root.resolve().as_posix()
    replacement = "/workspace/LiteratureAtlas"
    if isinstance(payload, dict):
        return {
            key: sanitize_cyclonedx(value, workspace_root)
            for key, value in payload.items()
        }
    if isinstance(payload, list):
        return [sanitize_cyclonedx(value, workspace_root) for value in payload]
    if isinstance(payload, str):
        return payload.replace(old_root, replacement)
    return payload


def tracked_source_paths(root: pathlib.Path) -> list[pathlib.Path]:
    result = subprocess.run(
        [
            "git",
            "-C",
            str(root),
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
        ],
        check=True,
        capture_output=True,
    )
    excluded_prefix = "docs/open-source/sbom/"
    return [
        pathlib.Path(raw.decode("utf-8"))
        for raw in result.stdout.split(b"\0")
        if raw and not raw.decode("utf-8").startswith(excluded_prefix)
    ]


def source_inventory_revision(root: pathlib.Path, paths: Iterable[pathlib.Path]) -> str:
    digest = hashlib.sha256()
    for relative in sorted(paths, key=lambda path: path.as_posix()):
        absolute = root / relative
        if not absolute.is_file():
            continue
        digest.update(relative.as_posix().encode("utf-8"))
        digest.update(b"\0")
        digest.update(sha256(absolute).encode("ascii"))
        digest.update(b"\0")
    return f"tracked-source-sha256-{digest.hexdigest()}"


def reproducible_created_at() -> str:
    raw_epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if raw_epoch is None:
        return "2026-07-16T00:00:00Z"
    try:
        epoch = int(raw_epoch)
    except ValueError as error:
        raise ValueError(
            "SOURCE_DATE_EPOCH must be an integer Unix timestamp"
        ) from error
    return (
        datetime.datetime.fromtimestamp(epoch, tz=datetime.timezone.utc)
        .isoformat(timespec="seconds")
        .replace("+00:00", "Z")
    )


def write_json_atomic(payload: Any, output: pathlib.Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=output.parent,
        prefix=f".{output.name}.",
        delete=False,
    ) as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
        temporary = pathlib.Path(handle.name)
    os.replace(temporary, output)


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--source-root", type=pathlib.Path)
    mode.add_argument("--app", type=pathlib.Path)
    mode.add_argument("--sanitize-cyclonedx", type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--version")
    parser.add_argument("--workspace-root", type=pathlib.Path)
    args = parser.parse_args()

    if args.source_root:
        root = args.source_root.resolve()
        paths = tracked_source_paths(root)
        revision = source_inventory_revision(root, paths)
        created = reproducible_created_at()
        payload = build_source_document(
            root=root,
            paths=paths,
            revision=revision,
            created=created,
        )
    elif args.app:
        if not args.version:
            parser.error("--app requires --version")
        created = reproducible_created_at()
        payload = build_artifact_document(
            args.app, version=args.version, created=created
        )
    else:
        if not args.workspace_root:
            parser.error("--sanitize-cyclonedx requires --workspace-root")
        payload = sanitize_cyclonedx(
            json.loads(args.sanitize_cyclonedx.read_text(encoding="utf-8")),
            args.workspace_root,
        )

    write_json_atomic(payload, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
