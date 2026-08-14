#!/usr/bin/env python3
"""Generate exact public callers for all Wide wrapping arithmetic overloads."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "wide_wrapping_arithmetic_codegen_probe.ads"
BODY = PROBES / "wide_wrapping_arithmetic_codegen_probe.adb"
CASES = PROBES / "wide_wrapping_arithmetic_codegen_cases.txt"

TYPES = (
    ("u8", "U8x32", "none", "none", "byte"),
    ("i8", "I8x32", "2", "2", "byte"),
    ("u16", "U16x16", "3", "3", "parts"),
    ("i16", "I16x16", "4", "4", "parts"),
    ("u32", "U32x8", "5", "5", "parts"),
    ("i32", "I32x8", "6", "6", "parts"),
    ("u64", "U64x4", "7", "7", "parts"),
    ("i64", "I64x4", "8", "8", "parts"),
)
OPERATIONS = ("add_wrap", "subtract_wrap", "multiply_wrap")


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def spec_text() -> str:
    lines = [
        "with Flyology_SIMD.Wide;",
        "",
        "package Wide_Wrapping_Arithmetic_Codegen_Probe is",
    ]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines.extend([
                f"   function {kind.upper()}_{ada(operation)}",
                f"     (Left, Right : Flyology_SIMD.Wide.{vector})",
                f"      return Flyology_SIMD.Wide.{vector};",
            ])
    lines.extend(["end Wide_Wrapping_Arithmetic_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Wide.Native;",
        "",
        "package body Wide_Wrapping_Arithmetic_Codegen_Probe is",
    ]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines.extend([
                f"   function {kind.upper()}_{ada(operation)}",
                f"     (Left, Right : Flyology_SIMD.Wide.{vector})",
                f"      return Flyology_SIMD.Wide.{vector} is",
                f"     (Flyology_SIMD.Wide.Native.{ada(operation)} (Left, Right));",
                "",
            ])
    lines.extend(["end Wide_Wrapping_Arithmetic_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    return "\n".join(
        [
            f"{kind} {operation} {wide_suffix} {half_suffix} {route}"
            for kind, _, wide_suffix, half_suffix, route in TYPES
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
