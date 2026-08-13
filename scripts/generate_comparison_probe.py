#!/usr/bin/env python3
"""Generate exact callers for every fixed-width comparison and selection."""

from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "comparison_codegen_probe.ads"
BODY = PROBES / "comparison_codegen_probe.adb"
CASES = PROBES / "comparison_codegen_cases.txt"
TYPES = (
    ("u8", "U8x16", "Mask_8x16", "none", "none"),
    ("i8", "I8x16", "Mask_8x16", "2", "none"),
    ("u16", "U16x8", "Mask_16x8", "3", "none"),
    ("i16", "I16x8", "Mask_16x8", "4", "none"),
    ("u32", "U32x4", "Mask_32x4", "5", "none"),
    ("i32", "I32x4", "Mask_32x4", "6", "none"),
    ("u64", "U64x2", "Mask_64x2", "7", "none"),
    ("i64", "I64x2", "Mask_64x2", "8", "none"),
    ("f32", "F32x4", "Mask_32x4", "9", "none"),
    ("f64", "F64x2", "Mask_64x2", "10", "2"),
)
RELATIONS = ("equal", "less_than", "less_equal", "greater_than", "greater_equal")


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def operations(kind: str) -> tuple[str, ...]:
    return RELATIONS + (("unordered",) if kind in {"f32", "f64"} else ()) + ("select_value",)


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Comparison_Codegen_Probe is"]
    for kind, vector, mask, *_ in TYPES:
        for operation in operations(kind):
            if operation == "select_value":
                lines += [f"   function {kind.upper()}_{ada(operation)}", f"     (Mask : Flyology_SIMD.{mask};", f"      If_True, If_False : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{vector};"]
            else:
                lines += [f"   function {kind.upper()}_{ada(operation)}", f"     (Left, Right : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{mask};"]
    return "\n".join((*lines, "end Comparison_Codegen_Probe;", ""))


def body_text() -> str:
    lines = ["with Flyology_SIMD.Backends.Native;", "", "package body Comparison_Codegen_Probe is"]
    for kind, vector, mask, *_ in TYPES:
        for operation in operations(kind):
            selected_name = f"Selected_{kind.upper()}_{ada(operation)}"
            if operation == "select_value":
                lines += [f"   function {selected_name}", f"     (Mask : Flyology_SIMD.{mask};", f"      If_True, If_False : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{vector} is", f"     (Flyology_SIMD.Backends.Native.{ada(operation)}", "        (Mask, If_True, If_False));", f"   pragma No_Inline ({selected_name});", ""]
            else:
                lines += [f"   function {selected_name}", f"     (Left, Right : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{mask} is", f"     (Flyology_SIMD.Backends.Native.{ada(operation)} (Left, Right));", f"   pragma No_Inline ({selected_name});", ""]
            if operation == "select_value":
                lines += [f"   function {kind.upper()}_{ada(operation)}", f"     (Mask : Flyology_SIMD.{mask};", f"      If_True, If_False : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{vector} is", f"     ({selected_name} (Mask, If_True, If_False));", ""]
            else:
                lines += [f"   function {kind.upper()}_{ada(operation)}", f"     (Left, Right : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{mask} is", f"     ({selected_name} (Left, Right));", ""]
    return "\n".join((*lines, "end Comparison_Codegen_Probe;", ""))


def cases_text() -> str:
    lines = []
    for kind, _, _, suffix, unordered_suffix in TYPES:
        for operation in operations(kind):
            selected_suffix = unordered_suffix if operation == "unordered" else suffix
            lines.append(f"{kind} {operation} {selected_suffix}")
    return "\n".join((*lines, ""))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, content in ((SPEC, spec_text()), (BODY, body_text()), (CASES, cases_text())):
        if args.check:
            if not path.exists() or path.read_text() != content:
                raise SystemExit(f"generated file is stale: {path.relative_to(ROOT)}")
        else:
            path.write_text(content)


if __name__ == "__main__":
    main()
