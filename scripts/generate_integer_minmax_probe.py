#!/usr/bin/env python3
"""Generate exact callers for all fixed-width integer Min/Max overloads."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "integer_minmax_codegen_probe.ads"
BODY = PROBES / "integer_minmax_codegen_probe.adb"
CASES = PROBES / "integer_minmax_codegen_cases.txt"

TYPES = (
    ("u8", "U8x16", "none", 8, 16, "unsigned"),
    ("i8", "I8x16", "2", 8, 16, "signed"),
    ("u16", "U16x8", "3", 16, 8, "unsigned"),
    ("i16", "I16x8", "4", 16, 8, "signed"),
    ("u32", "U32x4", "5", 32, 4, "unsigned"),
    ("i32", "I32x4", "6", 32, 4, "signed"),
    ("u64", "U64x2", "7", 64, 2, "unsigned"),
    ("i64", "I64x2", "8", 64, 2, "signed"),
)
OPERATIONS = ("min", "max")


def ada(name: str) -> str:
    return name.title()


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Integer_Minmax_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines += [
                f"   function {kind.upper()}_{ada(operation)}",
                f"     (Left, Right : Flyology_SIMD.{vector})",
                f"      return Flyology_SIMD.{vector};",
            ]
    return "\n".join((*lines, "end Integer_Minmax_Codegen_Probe;", ""))


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Backends.Native;",
        "",
        "package body Integer_Minmax_Codegen_Probe is",
    ]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines += [
                f"   function {kind.upper()}_{ada(operation)}",
                f"     (Left, Right : Flyology_SIMD.{vector})",
                f"      return Flyology_SIMD.{vector} is",
                f"     (Flyology_SIMD.Backends.Native.{ada(operation)} (Left, Right));",
                "",
            ]
    return "\n".join((*lines, "end Integer_Minmax_Codegen_Probe;", ""))


def cases_text() -> str:
    return "\n".join(
        [
            f"{kind} {operation} {suffix} {bits} {lanes} {signedness}"
            for kind, _, suffix, bits, lanes, signedness in TYPES
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
