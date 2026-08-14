#!/usr/bin/env python3
"""Generate exact public callers for all Wide integer shift overloads."""

from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "wide_shift_codegen_probe.ads"
BODY = PROBES / "wide_shift_codegen_probe.adb"
CASES = PROBES / "wide_shift_codegen_cases.txt"
TYPES = (
    ("u8", "U8x32", "none", None), ("i8", "I8x32", "2", "none"),
    ("u16", "U16x16", "3", None), ("i16", "I16x16", "4", "2"),
    ("u32", "U32x8", "5", None), ("i32", "I32x8", "6", "3"),
    ("u64", "U64x4", "7", None), ("i64", "I64x4", "8", "4"),
)


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def operations(signed: bool) -> tuple[str, ...]:
    base = ("shift_left_logical", "shift_right_logical")
    return base + (("shift_right_arithmetic",) if signed else ())


def declaration(kind: str, vector: str, operation: str) -> list[str]:
    return [f"   function {kind.upper()}_{ada(operation)}",
            f"     (Value : Flyology_SIMD.Wide.{vector}; Count : Natural)",
            f"      return Flyology_SIMD.Wide.{vector};"]


def spec_text() -> str:
    lines = ["with Flyology_SIMD.Wide;", "", "package Wide_Shift_Codegen_Probe is"]
    for kind, vector, _, arithmetic_suffix in TYPES:
        for operation in operations(arithmetic_suffix is not None):
            lines.extend(declaration(kind, vector, operation))
    lines.extend(["end Wide_Shift_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = ["with Flyology_SIMD.Wide.Native;", "", "package body Wide_Shift_Codegen_Probe is"]
    for kind, vector, _, arithmetic_suffix in TYPES:
        for operation in operations(arithmetic_suffix is not None):
            lines.extend(declaration(kind, vector, operation)[:-1])
            lines.append(f"      return Flyology_SIMD.Wide.{vector} is")
            lines.extend([
                f"     (Flyology_SIMD.Wide.Native.{ada(operation)} (Value, Count));",
                "",
            ])
    lines.extend(["end Wide_Shift_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    return "\n".join(
        [f"{kind} {operation} "
         f"{arithmetic_suffix if operation == 'shift_right_arithmetic' else logical_suffix}"
         for kind, _, logical_suffix, arithmetic_suffix in TYPES
         for operation in operations(arithmetic_suffix is not None)]
        + [""])


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
