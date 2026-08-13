#!/usr/bin/env python3
"""Generate exact public-caller probes for Wide construction and lane access."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "scripts" / "probes" / "wide_construction_codegen_probe.ads"
BODY = ROOT / "scripts" / "probes" / "wide_construction_codegen_probe.adb"
CASES = ROOT / "scripts" / "probes" / "wide_construction_codegen_cases.txt"

TYPES = (
    ("u8", "U8x32", "U8", "Lane_Values_U8x32", "Lane_Index_8x32", "none", 16),
    ("i8", "I8x32", "I8", "Lane_Values_I8x32", "Lane_Index_8x32", "2", 16),
    ("u16", "U16x16", "U16", "Lane_Values_U16x16", "Lane_Index_16x16", "3", 8),
    ("i16", "I16x16", "I16", "Lane_Values_I16x16", "Lane_Index_16x16", "4", 8),
    ("u32", "U32x8", "U32", "Lane_Values_U32x8", "Lane_Index_32x8", "5", 4),
    ("i32", "I32x8", "I32", "Lane_Values_I32x8", "Lane_Index_32x8", "6", 4),
    ("u64", "U64x4", "U64", "Lane_Values_U64x4", "Lane_Index_64x4", "7", 2),
    ("i64", "I64x4", "I64", "Lane_Values_I64x4", "Lane_Index_64x4", "8", 2),
    ("f32", "F32x8", "F32", "Lane_Values_F32x8", "Lane_Index_32x8", "9", 4),
    ("f64", "F64x4", "F64", "Lane_Values_F64x4", "Lane_Index_64x4", "10", 2),
)
OPERATIONS = ("zero", "splat", "from_lanes", "to_lanes", "extract", "replace")


def declarations(kind: str, vector: str, scalar: str, values: str, index: str) -> list[str]:
    prefix = kind.upper()
    wide = "Flyology_SIMD.Wide"
    root = "Flyology_SIMD"
    return [
        f"   function {prefix}_Zero return {wide}.{vector};",
        f"   function {prefix}_Splat (Value : {root}.{scalar}) return {wide}.{vector};",
        f"   function {prefix}_From_Lanes (Values : {wide}.{values}) return {wide}.{vector};",
        f"   function {prefix}_To_Lanes (Value : {wide}.{vector}) return {wide}.{values};",
        f"   function {prefix}_Extract (Value : {wide}.{vector}; Lane : {wide}.{index}) return {root}.{scalar};",
        f"   function {prefix}_Replace (Value : {wide}.{vector}; Lane : {wide}.{index}; With_Value : {root}.{scalar}) return {wide}.{vector};",
    ]


def spec_text() -> str:
    lines = ["with Flyology_SIMD.Wide;", "", "package Wide_Construction_Codegen_Probe is"]
    for kind, vector, scalar, values, index, _, _ in TYPES:
        lines.extend(declarations(kind, vector, scalar, values, index))
    lines.extend(["end Wide_Construction_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Wide.Native;",
        "",
        "package body Wide_Construction_Codegen_Probe is",
        "   package Native renames Flyology_SIMD.Wide.Native;",
        "",
    ]
    for kind, vector, scalar, values, index, _, _ in TYPES:
        prefix = kind.upper()
        lines.extend([
            f"   function {prefix}_Zero return Flyology_SIMD.Wide.{vector} is (Native.Zero);",
            f"   function {prefix}_Splat (Value : Flyology_SIMD.{scalar}) return Flyology_SIMD.Wide.{vector} is (Native.Splat (Value));",
            f"   function {prefix}_From_Lanes (Values : Flyology_SIMD.Wide.{values}) return Flyology_SIMD.Wide.{vector} is (Native.From_Lanes (Values));",
            f"   function {prefix}_To_Lanes (Value : Flyology_SIMD.Wide.{vector}) return Flyology_SIMD.Wide.{values} is (Native.To_Lanes (Value));",
            f"   function {prefix}_Extract (Value : Flyology_SIMD.Wide.{vector}; Lane : Flyology_SIMD.Wide.{index}) return Flyology_SIMD.{scalar} is (Native.Extract (Value, Lane));",
            f"   function {prefix}_Replace (Value : Flyology_SIMD.Wide.{vector}; Lane : Flyology_SIMD.Wide.{index}; With_Value : Flyology_SIMD.{scalar}) return Flyology_SIMD.Wide.{vector} is (Native.Replace (Value, Lane, With_Value));",
            "",
        ])
    lines.extend(["end Wide_Construction_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    return "\n".join(
        f"{kind} {operation} {suffix} {half_lanes}"
        for kind, _, _, _, _, suffix, half_lanes in TYPES
        for operation in OPERATIONS
    ) + "\n"


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
