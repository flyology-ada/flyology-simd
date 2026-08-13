#!/usr/bin/env python3
"""Generate exact public-caller probes for all 128-bit integer reductions."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "scripts" / "probes" / "integer_reduction_codegen_probe.ads"
BODY = ROOT / "scripts" / "probes" / "integer_reduction_codegen_probe.adb"
CASES = ROOT / "scripts" / "probes" / "integer_reduction_codegen_cases.txt"

TYPES = (
    ("u8", "U8x16", "U8", "none", 8, 16, "unsigned"),
    ("i8", "I8x16", "I8", "2", 8, 16, "signed"),
    ("u16", "U16x8", "U16", "3", 16, 8, "unsigned"),
    ("i16", "I16x8", "I16", "4", 16, 8, "signed"),
    ("u32", "U32x4", "U32", "5", 32, 4, "unsigned"),
    ("i32", "I32x4", "I32", "6", 32, 4, "signed"),
    ("u64", "U64x2", "U64", "7", 64, 2, "unsigned"),
    ("i64", "I64x2", "I64", "8", 64, 2, "signed"),
)
OPERATIONS = ("reduce_add_wrap", "reduce_min", "reduce_max")


def ada_name(operation: str) -> str:
    return "_".join(part.title() for part in operation.split("_"))


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Integer_Reduction_Codegen_Probe is"]
    for kind, vector, scalar, *_ in TYPES:
        for operation in OPERATIONS:
            name = ada_name(operation)
            lines.extend(
                [
                    f"   function {kind.upper()}_{name}",
                    f"     (Value : Flyology_SIMD.{vector})",
                    f"      return Flyology_SIMD.{scalar};",
                ]
            )
    lines.extend(["end Integer_Reduction_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Backends.Native;",
        "",
        "package body Integer_Reduction_Codegen_Probe is",
    ]
    for kind, vector, scalar, *_ in TYPES:
        for operation in OPERATIONS:
            name = ada_name(operation)
            lines.extend(
                [
                    f"   function {kind.upper()}_{name}",
                    f"     (Value : Flyology_SIMD.{vector})",
                    f"      return Flyology_SIMD.{scalar} is",
                    f"     (Flyology_SIMD.Backends.Native.{name} (Value));",
                    "",
                ]
            )
    lines.extend(["end Integer_Reduction_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    lines = []
    for kind, _, _, suffix, bits, lanes, signedness in TYPES:
        for operation in OPERATIONS:
            lines.append(
                f"{kind} {operation} {suffix} {bits} {lanes} {signedness}"
            )
    return "\n".join((*lines, ""))


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
