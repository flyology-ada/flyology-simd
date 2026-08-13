#!/usr/bin/env python3
"""Generate exact public-caller probes for Wide comparisons and selection."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "scripts" / "probes" / "wide_comparison_codegen_probe.ads"
BODY = ROOT / "scripts" / "probes" / "wide_comparison_codegen_probe.adb"
CASES = ROOT / "scripts" / "probes" / "wide_comparison_codegen_cases.txt"

TYPES = (
    ("u8", "U8x32", "Mask_8x32", "none", "none"),
    ("i8", "I8x32", "Mask_8x32", "2", "none"),
    ("u16", "U16x16", "Mask_16x16", "3", "none"),
    ("i16", "I16x16", "Mask_16x16", "4", "none"),
    ("u32", "U32x8", "Mask_32x8", "5", "none"),
    ("i32", "I32x8", "Mask_32x8", "6", "none"),
    ("u64", "U64x4", "Mask_64x4", "7", "none"),
    ("i64", "I64x4", "Mask_64x4", "8", "none"),
    ("f32", "F32x8", "Mask_32x8", "9", "none"),
    ("f64", "F64x4", "Mask_64x4", "10", "2"),
)
COMPARISONS = (
    ("equal", "Equal"),
    ("less_than", "Less_Than"),
    ("less_equal", "Less_Equal"),
    ("greater_than", "Greater_Than"),
    ("greater_equal", "Greater_Equal"),
)


def spec_text() -> str:
    lines = ["with Flyology_SIMD.Wide;", "", "package Wide_Comparison_Codegen_Probe is"]
    for kind, vector, mask, _, unordered_suffix in TYPES:
        prefix = kind.upper()
        float_operations = (("unordered", "Unordered"),) if kind in {"f32", "f64"} else ()
        for _, ada_operation in COMPARISONS + float_operations:
            lines.extend([
                f"   function {prefix}_{ada_operation}",
                f"     (Left, Right : Flyology_SIMD.Wide.{vector})",
                f"      return Flyology_SIMD.Wide.{mask};",
            ])
        lines.extend([
            f"   function {prefix}_Select_Value",
            f"     (Mask : Flyology_SIMD.Wide.{mask};",
            f"      If_True, If_False : Flyology_SIMD.Wide.{vector})",
            f"      return Flyology_SIMD.Wide.{vector};",
        ])
    lines.extend(["end Wide_Comparison_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Wide.Native;",
        "",
        "package body Wide_Comparison_Codegen_Probe is",
    ]
    for kind, vector, mask, _, unordered_suffix in TYPES:
        prefix = kind.upper()
        float_operations = (("unordered", "Unordered"),) if kind in {"f32", "f64"} else ()
        for _, ada_operation in COMPARISONS + float_operations:
            lines.extend([
                f"   function {prefix}_{ada_operation}",
                f"     (Left, Right : Flyology_SIMD.Wide.{vector})",
                f"      return Flyology_SIMD.Wide.{mask} is",
                f"     (Flyology_SIMD.Wide.Native.{ada_operation} (Left, Right));",
                "",
            ])
        lines.extend([
            f"   function {prefix}_Select_Value",
            f"     (Mask : Flyology_SIMD.Wide.{mask};",
            f"      If_True, If_False : Flyology_SIMD.Wide.{vector})",
            f"      return Flyology_SIMD.Wide.{vector} is",
            "     (Flyology_SIMD.Wide.Native.Select_Value",
            "        (Mask, If_True, If_False));",
            "",
        ])
    lines.extend(["end Wide_Comparison_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    lines = []
    for kind, _, _, suffix, unordered_suffix in TYPES:
        for operation, _ in COMPARISONS:
            lines.append(f"{kind} {operation} {suffix} comparison")
        if kind in {"f32", "f64"}:
            lines.append(f"{kind} unordered {unordered_suffix} comparison")
        lines.append(f"{kind} select_value {suffix} selection")
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
