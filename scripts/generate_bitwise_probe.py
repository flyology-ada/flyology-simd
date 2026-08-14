#!/usr/bin/env python3
"""Generate exact callers for all fixed-width integer bitwise overloads."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "bitwise_codegen_probe.ads"
BODY = PROBES / "bitwise_codegen_probe.adb"
CASES = PROBES / "bitwise_codegen_cases.txt"

TYPES = (
    ("u8", "U8x16", "none", 8, 16),
    ("i8", "I8x16", "2", 8, 16),
    ("u16", "U16x8", "3", 16, 8),
    ("i16", "I16x8", "4", 16, 8),
    ("u32", "U32x4", "5", 32, 4),
    ("i32", "I32x4", "6", 32, 4),
    ("u64", "U64x2", "7", 64, 2),
    ("i64", "I64x2", "8", 64, 2),
)
OPERATIONS = (
    ("bitwise_and", 2),
    ("bitwise_or", 2),
    ("bitwise_xor", 2),
    ("bitwise_not", 1),
)


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Bitwise_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation, arity in OPERATIONS:
            parameters = "Value" if arity == 1 else "Left, Right"
            lines += [
                f"   function {kind.upper()}_{ada(operation)}",
                f"     ({parameters} : Flyology_SIMD.{vector})",
                f"      return Flyology_SIMD.{vector};",
            ]
    return "\n".join((*lines, "end Bitwise_Codegen_Probe;", ""))


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Backends.Native;",
        "",
        "package body Bitwise_Codegen_Probe is",
    ]
    for kind, vector, *_ in TYPES:
        for operation, arity in OPERATIONS:
            parameters = "Value" if arity == 1 else "Left, Right"
            arguments = "Value" if arity == 1 else "Left, Right"
            lines += [
                f"   function {kind.upper()}_{ada(operation)}",
                f"     ({parameters} : Flyology_SIMD.{vector})",
                f"      return Flyology_SIMD.{vector} is",
                f"     (Flyology_SIMD.Backends.Native.{ada(operation)} ({arguments}));",
                "",
            ]
    return "\n".join((*lines, "end Bitwise_Codegen_Probe;", ""))


def cases_text() -> str:
    return "\n".join(
        [
            f"{kind} {operation} {suffix} {bits} {lanes} {arity}"
            for kind, _, suffix, bits, lanes in TYPES
            for operation, arity in OPERATIONS
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
