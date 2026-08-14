#!/usr/bin/env python3
"""Generate exact callers for all canonical fixed-width lane arrangements."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "lane_arrangement_codegen_probe.ads"
BODY = PROBES / "lane_arrangement_codegen_probe.adb"
CASES = PROBES / "lane_arrangement_codegen_cases.txt"
TYPES = (
    ("u8", "U8x16", "none", 8, 16),
    ("i8", "I8x16", "2", 8, 16),
    ("u16", "U16x8", "3", 16, 8),
    ("i16", "I16x8", "4", 16, 8),
    ("u32", "U32x4", "5", 32, 4),
    ("i32", "I32x4", "6", 32, 4),
    ("u64", "U64x2", "7", 64, 2),
    ("i64", "I64x2", "8", 64, 2),
    ("f32", "F32x4", "9", 32, 4),
    ("f64", "F64x2", "10", 64, 2),
)
OPERATIONS = (
    "reverse_lanes", "interleave_low", "interleave_high",
    "deinterleave_even", "deinterleave_odd",
)


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def declaration(kind: str, vector: str, operation: str) -> list[str]:
    if operation == "reverse_lanes":
        return [
            f"   function {kind.upper()}_{ada(operation)}",
            f"     (Value : Flyology_SIMD.{vector}) return Flyology_SIMD.{vector};",
        ]
    return [
        f"   function {kind.upper()}_{ada(operation)}",
        f"     (Left, Right : Flyology_SIMD.{vector})",
        f"      return Flyology_SIMD.{vector};",
    ]


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Lane_Arrangement_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines += declaration(kind, vector, operation)
    return "\n".join((*lines, "end Lane_Arrangement_Codegen_Probe;", ""))


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Backends.Native;",
        "",
        "package body Lane_Arrangement_Codegen_Probe is",
    ]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            name = ada(operation)
            if operation == "reverse_lanes":
                lines += [
                    f"   function {kind.upper()}_{name}",
                    f"     (Value : Flyology_SIMD.{vector})",
                    f"      return Flyology_SIMD.{vector} is",
                    f"     (Flyology_SIMD.Backends.Native.{name} (Value));",
                    "",
                ]
            else:
                lines += [
                    f"   function {kind.upper()}_{name}",
                    f"     (Left, Right : Flyology_SIMD.{vector})",
                    f"      return Flyology_SIMD.{vector} is",
                    f"     (Flyology_SIMD.Backends.Native.{name} (Left, Right));",
                    "",
                ]
    return "\n".join((*lines, "end Lane_Arrangement_Codegen_Probe;", ""))


def cases_text() -> str:
    return "\n".join(
        [
            f"{kind} {operation} {suffix} {bits} {lanes}"
            for kind, _, suffix, bits, lanes in TYPES
            for operation in OPERATIONS
        ]
        + [""]
    )


def write_or_check(path: Path, content: str, check: bool) -> None:
    if check:
        if not path.exists() or path.read_text() != content:
            raise SystemExit(f"generated file is stale: {path.relative_to(ROOT)}")
    else:
        path.write_text(content)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    write_or_check(SPEC, spec_text(), args.check)
    write_or_check(BODY, body_text(), args.check)
    write_or_check(CASES, cases_text(), args.check)


if __name__ == "__main__":
    main()
