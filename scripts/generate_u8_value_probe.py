#!/usr/bin/env python3
"""Generate exact public-caller probes for the U8x16 value-operation family."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "scripts" / "probes" / "u8_value_codegen_probe.ads"
BODY = ROOT / "scripts" / "probes" / "u8_value_codegen_probe.adb"
CASES = ROOT / "scripts" / "probes" / "u8_value_codegen_cases.txt"

BINARY = (
    "add_wrap",
    "subtract_wrap",
    "multiply_wrap",
    "add_saturate",
    "subtract_saturate",
    "bitwise_and",
    "bitwise_or",
    "bitwise_xor",
    "equal",
    "less_than",
    "less_equal",
    "greater_than",
    "greater_equal",
    "min",
    "max",
    "interleave_low",
    "interleave_high",
    "deinterleave_even",
    "deinterleave_odd",
)
UNARY = (
    "bitwise_not",
    "reduce_add_wrap",
    "reduce_min",
    "reduce_max",
    "reverse_bytes",
    "reverse_lanes",
)
SELECT = "select_value"


def ada_name(name: str) -> str:
    return "_".join(part.capitalize() for part in name.split("_"))


def result_type(name: str) -> str:
    if name in {"equal", "less_than", "less_equal", "greater_than", "greater_equal"}:
        return "Flyology_SIMD.Mask_8x16"
    if name in {"reduce_add_wrap", "reduce_min", "reduce_max"}:
        return "Flyology_SIMD.U8"
    return "Flyology_SIMD.U8x16"


def spec_text() -> str:
    declarations: list[str] = [
        "with Flyology_SIMD;",
        "",
        "package U8_Value_Codegen_Probe is",
    ]
    for name in BINARY:
        declarations.extend(
            [
                f"   function {ada_name(name)}",
                "     (Left, Right : Flyology_SIMD.U8x16)",
                f"      return {result_type(name)};",
            ]
        )
    for name in UNARY:
        declarations.extend(
            [
                f"   function {ada_name(name)}",
                "     (Value : Flyology_SIMD.U8x16)",
                f"      return {result_type(name)};",
            ]
        )
    declarations.extend(
        [
            "   function Select_Value",
            "     (Mask : Flyology_SIMD.Mask_8x16;",
            "      If_True, If_False : Flyology_SIMD.U8x16)",
            "      return Flyology_SIMD.U8x16;",
            "end U8_Value_Codegen_Probe;",
            "",
        ]
    )
    return "\n".join(declarations)


def body_text() -> str:
    declarations: list[str] = [
        "with Flyology_SIMD.Backends.Native;",
        "",
        "package body U8_Value_Codegen_Probe is",
    ]
    for name in BINARY:
        declarations.extend(
            [
                f"   function {ada_name(name)}",
                "     (Left, Right : Flyology_SIMD.U8x16)",
                f"      return {result_type(name)} is",
                "     (Flyology_SIMD.Backends.Native."
                f"{ada_name(name)} (Left, Right));",
                "",
            ]
        )
    for name in UNARY:
        declarations.extend(
            [
                f"   function {ada_name(name)}",
                "     (Value : Flyology_SIMD.U8x16)",
                f"      return {result_type(name)} is",
                f"     (Flyology_SIMD.Backends.Native.{ada_name(name)} (Value));",
                "",
            ]
        )
    declarations.extend(
        [
            "   function Select_Value",
            "     (Mask : Flyology_SIMD.Mask_8x16;",
            "      If_True, If_False : Flyology_SIMD.U8x16)",
            "      return Flyology_SIMD.U8x16 is",
            "     (Flyology_SIMD.Backends.Native.Select_Value",
            "        (Mask, If_True, If_False));",
            "end U8_Value_Codegen_Probe;",
            "",
        ]
    )
    return "\n".join(declarations)


def cases_text() -> str:
    return "\n".join((*BINARY, *UNARY, SELECT, ""))


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
