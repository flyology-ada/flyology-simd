#!/usr/bin/env python3
"""Generate exact public-caller probes for all Wide integer reductions."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "scripts" / "probes" / "wide_reduction_codegen_probe.ads"
BODY = ROOT / "scripts" / "probes" / "wide_reduction_codegen_probe.adb"
CASES = ROOT / "scripts" / "probes" / "wide_reduction_codegen_cases.txt"

TYPES = (
    ("u8", "U8x32", "U8", "none"),
    ("i8", "I8x32", "I8", "2"),
    ("u16", "U16x16", "U16", "3"),
    ("i16", "I16x16", "I16", "4"),
    ("u32", "U32x8", "U32", "5"),
    ("i32", "I32x8", "I32", "6"),
    ("u64", "U64x4", "U64", "7"),
    ("i64", "I64x4", "I64", "8"),
)
OPERATIONS = (
    ("reduce_add_wrap", "Reduce_Add_Wrap", "add_wrap"),
    ("reduce_min", "Reduce_Min", "min"),
    ("reduce_max", "Reduce_Max", "max"),
)


def spec_text() -> str:
    lines = ["with Flyology_SIMD.Wide;", "", "package Wide_Reduction_Codegen_Probe is"]
    for kind, vector, scalar, _ in TYPES:
        for operation, ada_operation, _ in OPERATIONS:
            lines.extend(
                [
                    f"   function {kind.upper()}_{ada_operation}",
                    f"     (Value : Flyology_SIMD.Wide.{vector})",
                    f"      return Flyology_SIMD.{scalar};",
                ]
            )
    lines.extend(["end Wide_Reduction_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Wide.Native;",
        "",
        "package body Wide_Reduction_Codegen_Probe is",
    ]
    for kind, vector, scalar, _ in TYPES:
        for operation, ada_operation, _ in OPERATIONS:
            lines.extend(
                [
                    f"   function {kind.upper()}_{ada_operation}",
                    f"     (Value : Flyology_SIMD.Wide.{vector})",
                    f"      return Flyology_SIMD.{scalar} is",
                    f"     (Flyology_SIMD.Wide.Native.{ada_operation} (Value));",
                    "",
                ]
            )
    lines.extend(["end Wide_Reduction_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    lines = []
    for kind, _, _, suffix in TYPES:
        for operation, _, combine in OPERATIONS:
            lines.append(f"{kind} {operation} {combine} {suffix}")
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
