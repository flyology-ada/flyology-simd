#!/usr/bin/env python3
"""Validate and report the finite evidence inventory for every public SIMD overload."""

from __future__ import annotations

import argparse
from collections import Counter
from copy import deepcopy
from pathlib import Path
import re
import sys
import tomllib


ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "scripts" / "simd_coverage.toml"
REPORT = ROOT / "docs" / "coverage.md"
LAYERS = {
    "fixed": ROOT / "src" / "flyology_simd.ads",
    "wide": ROOT / "src" / "flyology_simd-wide.ads",
}
DIMENSIONS = ("semantic", "codegen", "docs", "teaching")
STATUSES = {"complete", "gap", "not_applicable"}
TEXT_EVIDENCE_SUFFIXES = {".adb", ".ads", ".py", ".sh", ".txt"}
EVIDENCE_ALIASES = {
    "Slide_Lanes_Toward_Low": ("slide_lanes_toward_low", "slide_low"),
    "Slide_Lanes_Toward_High": ("slide_lanes_toward_high", "slide_high"),
}


def declarations(path: Path) -> Counter[str]:
    """Return public subprogram declaration counts grouped by operation name."""
    text = re.sub(r"--[^\n]*", "", path.read_text())
    text = text.split("\nprivate\n", 1)[0]
    result: Counter[str] = Counter()
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        match = re.match(
            r"\s*(?:function|procedure)\s+([A-Za-z0-9_]+)", lines[index]
        )
        if match is None:
            index += 1
            continue
        depth = 0
        while True:
            for character in lines[index]:
                if character == "(":
                    depth += 1
                elif character == ")":
                    depth -= 1
                elif character == ";" and depth == 0:
                    result[match.group(1)] += 1
                    break
            else:
                index += 1
                if index >= len(lines):
                    raise ValueError(f"unterminated declaration in {path}")
                continue
            break
        index += 1
    return result


def relative(path: str) -> Path:
    candidate = ROOT / path
    if candidate.is_absolute() and ROOT not in candidate.parents:
        raise ValueError(f"evidence path escapes repository: {path}")
    return candidate


def coverage_entry(family: dict, dimension: str) -> dict:
    entry = family.get(dimension)
    if not isinstance(entry, dict):
        raise ValueError(
            f"{family.get('id', '<unnamed>')}: {dimension} must be a table"
        )
    status = entry.get("status")
    if status not in STATUSES:
        raise ValueError(
            f"{family['id']}: {dimension}.status must be one of "
            f"{', '.join(sorted(STATUSES))}"
        )
    evidence = entry.get("evidence", [])
    reason = entry.get("reason", "")
    if status == "complete" and not evidence:
        raise ValueError(f"{family['id']}: complete {dimension} lacks evidence")
    if status != "complete" and not reason:
        raise ValueError(f"{family['id']}: {status} {dimension} lacks a reason")
    if status == "gap" and not entry.get("closure"):
        raise ValueError(f"{family['id']}: {dimension} gap lacks a closure action")
    for item in evidence:
        if not relative(item).exists():
            raise ValueError(
                f"{family['id']}: {dimension} evidence does not exist: {item}"
            )
    return entry


def load_inventory() -> tuple[dict, list[dict]]:
    data = tomllib.loads(INVENTORY.read_text())
    if data.get("schema") != 1:
        raise ValueError("unsupported SIMD coverage inventory schema")
    families = data.get("family")
    if not isinstance(families, list) or not families:
        raise ValueError("inventory has no families")
    profiles = data.get("profile", {})
    for family in families:
        for dimension in DIMENSIONS:
            value = family.get(dimension)
            if isinstance(value, str):
                if value not in profiles:
                    raise ValueError(
                        f"{family.get('id', '<unnamed>')}: unknown profile {value!r}"
                    )
                family[dimension] = deepcopy(profiles[value])
    return data, families


def validate(data: dict, families: list[dict]) -> dict:
    errors: list[str] = []
    ids: set[str] = set()
    assigned: dict[str, Counter[str]] = {
        layer: Counter() for layer in LAYERS
    }
    operation_owner: dict[str, dict[str, str]] = {
        layer: {} for layer in LAYERS
    }
    parsed = {layer: declarations(path) for layer, path in LAYERS.items()}
    split_operations = set(data.get("split_operations", []))

    for family in families:
        family_id = family.get("id")
        layer = family.get("layer")
        operations = family.get("operations")
        if not isinstance(family_id, str) or not family_id:
            errors.append("family without a nonempty id")
            continue
        if family_id in ids:
            errors.append(f"duplicate family id: {family_id}")
        ids.add(family_id)
        if layer not in LAYERS:
            errors.append(f"{family_id}: unknown layer {layer!r}")
            continue
        if not isinstance(operations, dict) or not operations:
            errors.append(f"{family_id}: operations must be a nonempty table")
            continue
        for operation, count in operations.items():
            if not isinstance(count, int) or count <= 0:
                errors.append(f"{family_id}: invalid count for {operation}: {count!r}")
                continue
            previous = operation_owner[layer].get(operation)
            if previous is not None and operation not in split_operations:
                errors.append(
                    f"{layer} operation {operation} is assigned to both "
                    f"{previous} and {family_id}"
                )
            operation_owner[layer][operation] = family_id
            assigned[layer][operation] += count
        for dimension in DIMENSIONS:
            try:
                coverage_entry(family, dimension)
            except ValueError as exc:
                errors.append(str(exc))

        for dimension in ("semantic", "codegen"):
            entry = family.get(dimension)
            if not isinstance(entry, dict) or entry.get("status") != "complete":
                continue
            evidence_text = "\n".join(
                relative(item).read_text().lower()
                for item in entry.get("evidence", [])
                if relative(item).suffix in TEXT_EVIDENCE_SUFFIXES
            )
            for operation in operations:
                tokens = EVIDENCE_ALIASES.get(operation, (operation.lower(),))
                if not any(token in evidence_text for token in tokens):
                    errors.append(
                        f"{family_id}: complete {dimension} evidence does not "
                        f"name operation {operation}"
                    )

    for layer in LAYERS:
        missing = parsed[layer] - assigned[layer]
        extra = assigned[layer] - parsed[layer]
        if missing:
            errors.append(f"{layer} unclassified declarations: {dict(sorted(missing.items()))}")
        if extra:
            errors.append(f"{layer} nonexistent inventory entries: {dict(sorted(extra.items()))}")
        expected = data.get("expected_overloads", {}).get(layer)
        actual = sum(parsed[layer].values())
        if expected != actual:
            errors.append(
                f"{layer} expected_overloads is {expected!r}, parsed public total is {actual}"
            )

    declared_gaps = sorted(
        (family["id"], dimension)
        for family in families
        for dimension in DIMENSIONS
        if family[dimension]["status"] == "gap"
    )
    expected_gaps = sorted(
        (entry["family"], entry["dimension"])
        for entry in data.get("expected_gap", [])
    )
    if declared_gaps != expected_gaps:
        errors.append(
            "declared gaps differ from expected_gap ledger: "
            f"declared={declared_gaps}, expected={expected_gaps}"
        )

    if errors:
        raise ValueError("\n".join(errors))

    family_counts = {
        family["id"]: sum(family["operations"].values()) for family in families
    }
    gap_overloads = {
        dimension: sum(
            family_counts[family["id"]]
            for family in families
            if family[dimension]["status"] == "gap"
        )
        for dimension in DIMENSIONS
    }
    incomplete = {
        family["id"]
        for family in families
        if any(family[dimension]["status"] == "gap" for dimension in DIMENSIONS)
    }
    total = sum(sum(counter.values()) for counter in parsed.values())
    incomplete_overloads = sum(family_counts[family_id] for family_id in incomplete)
    return {
        "parsed": parsed,
        "family_counts": family_counts,
        "gap_overloads": gap_overloads,
        "incomplete": incomplete,
        "total": total,
        "incomplete_overloads": incomplete_overloads,
    }


def render_report(families: list[dict], state: dict) -> str:
    complete = state["total"] - state["incomplete_overloads"]
    lines = [
        "# SIMD coverage",
        "",
        "This file is generated by `scripts/check_simd_coverage.py --write-report`",
        "from `scripts/simd_coverage.toml`. Do not edit it by hand.",
        "",
        "## Summary",
        "",
        f"- Public overloads: **{state['total']}** "
        f"({sum(state['parsed']['fixed'].values())} fixed-width + "
        f"{sum(state['parsed']['wide'].values())} Wide)",
        f"- Fully evidenced overloads: **{complete}**",
        f"- Overloads in families with a declared gap: **{state['incomplete_overloads']}**",
    ]
    for dimension in DIMENSIONS:
        lines.append(
            f"- {dimension.capitalize()} gap surface: "
            f"**{state['gap_overloads'][dimension]} overloads**"
        )
    lines.extend([
        "",
        "A family is fully evidenced only when semantic, code-generation, API-documentation,",
        "and teaching coverage are all complete or explicitly not applicable.",
        "",
        "## Declared gaps",
        "",
    ])
    gap_rows: list[str] = []
    for family in families:
        for dimension in DIMENSIONS:
            entry = family[dimension]
            if entry["status"] != "gap":
                continue
            gap_rows.append(
                f"| {family['layer']} | `{family['id']}` | "
                f"{state['family_counts'][family['id']]} | {dimension} | "
                f"{entry['reason']} | {entry['closure']} |"
            )
    if gap_rows:
        lines.extend([
            "| Layer | Family | Overloads | Dimension | Gap | Deterministic closure |",
            "| --- | --- | ---: | --- | --- | --- |",
            *gap_rows,
        ])
    else:
        lines.append("None.")
    lines.extend([
        "",
        "## Family ledger",
        "",
        "| Layer | Family | Overloads | Semantic | Codegen | Docs | Teaching |",
        "| --- | --- | ---: | --- | --- | --- | --- |",
    ])
    for family in families:
        statuses = [family[dimension]["status"] for dimension in DIMENSIONS]
        lines.append(
            f"| {family['layer']} | `{family['id']}` | "
            f"{state['family_counts'][family['id']]} | " + " | ".join(statuses) + " |"
        )
    lines.extend([
        "",
        "## Enforcement",
        "",
        "The default checker accepts only the explicitly declared gap set above. It fails on",
        "an added, removed, duplicated, or miscounted public overload; missing evidence files;",
        "or an undeclared status change. Run the zero-gap completion gate with:",
        "",
        "```sh",
        "python3 scripts/check_simd_coverage.py --require-complete",
        "```",
        "",
    ])
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-report", action="store_true")
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    try:
        data, families = load_inventory()
        state = validate(data, families)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as exc:
        print(f"SIMD coverage inventory error:\n{exc}", file=sys.stderr)
        raise SystemExit(1) from exc

    report = render_report(families, state)
    if args.write_report:
        REPORT.write_text(report)
    elif REPORT.exists() and REPORT.read_text() != report:
        print(
            "docs/coverage.md is stale; run "
            "scripts/check_simd_coverage.py --write-report",
            file=sys.stderr,
        )
        raise SystemExit(1)

    print(
        "SIMD coverage inventory: "
        f"{state['total']} public overloads, "
        f"{state['total'] - state['incomplete_overloads']} fully evidenced, "
        f"{state['incomplete_overloads']} in {len(state['incomplete'])} gap families"
    )
    if args.require_complete and state["incomplete"]:
        print("remaining coverage gaps:", file=sys.stderr)
        for family in families:
            gaps = [
                dimension for dimension in DIMENSIONS
                if family[dimension]["status"] == "gap"
            ]
            if gaps:
                print(f"  {family['id']}: {', '.join(gaps)}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
