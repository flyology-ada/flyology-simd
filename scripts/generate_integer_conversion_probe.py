#!/usr/bin/env python3
"""Generate exact callers for fixed-width integer conversion overloads."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "integer_conversion_codegen_probe.ads"
BODY = PROBES / "integer_conversion_codegen_probe.adb"
CASES = PROBES / "integer_conversion_codegen_cases.txt"

# Kind, source vector, target vector, selected-operation suffix.
WIDENINGS = (
    ("u8_u16", "U8x16", "U16x8", "none"),
    ("i8_i16", "I8x16", "I16x8", "2"),
    ("u16_u32", "U16x8", "U32x4", "3"),
    ("i16_i32", "I16x8", "I32x4", "4"),
    ("u32_u64", "U32x4", "U64x2", "5"),
    ("i32_i64", "I32x4", "I64x2", "6"),
)
NARROWINGS = (
    ("u16_u8", "U16x8", "U8x16", "none"),
    ("i16_i8", "I16x8", "I8x16", "2"),
    ("u32_u16", "U32x4", "U16x8", "3"),
    ("i32_i16", "I32x4", "I16x8", "4"),
    ("u64_u32", "U64x2", "U32x4", "5"),
    ("i64_i32", "I64x2", "I32x4", "6"),
)
SIGNED_NARROWINGS = (
    ("i16_u8", "I16x8", "U8x16", "7"),
    ("i32_u16", "I32x4", "U16x8", "8"),
    ("i64_u32", "I64x2", "U32x4", "9"),
)
SIGNEDNESS_CONVERSIONS = (
    ("i8_u8", "I8x16", "U8x16", "none"),
    ("u8_i8", "U8x16", "I8x16", "2"),
    ("i16_u16", "I16x8", "U16x8", "3"),
    ("u16_i16", "U16x8", "I16x8", "4"),
    ("i32_u32", "I32x4", "U32x4", "5"),
    ("u32_i32", "U32x4", "I32x4", "6"),
    ("i64_u64", "I64x2", "U64x2", "7"),
    ("u64_i64", "U64x2", "I64x2", "8"),
)


def ada(name: str) -> str:
    return "_".join(part.upper() if part[0].isdigit() else part.title()
                    for part in name.split("_"))


def cases() -> list[tuple[str, str, str, str, str, int]]:
    result = []
    for kind, source, target, suffix in WIDENINGS:
        for operation, arity in (("widen_low", 1), ("widen_high", 1)):
            result.append((kind, operation, source, target, suffix, arity))
    for kind, source, target, suffix in NARROWINGS:
        result.append((kind, "narrow_truncate", source, target, suffix, 2))
        result.append((kind, "narrow_saturate", source, target, suffix, 2))
    for kind, source, target, suffix in SIGNED_NARROWINGS:
        result.append((kind, "narrow_saturate", source, target, suffix, 2))
    for kind, source, target, suffix in SIGNEDNESS_CONVERSIONS:
        result.append((kind, "convert_saturate", source, target, suffix, 1))
    return result


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Integer_Conversion_Codegen_Probe is"]
    for kind, operation, source, target, _, arity in cases():
        name = f"{kind}_{operation}"
        parameters = "Value" if arity == 1 else "Low, High"
        lines += [
            f"   function {ada(name)}",
            f"     ({parameters} : Flyology_SIMD.{source})",
            f"      return Flyology_SIMD.{target};",
        ]
    return "\n".join((*lines, "end Integer_Conversion_Codegen_Probe;", ""))


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Backends.Native;",
        "",
        "package body Integer_Conversion_Codegen_Probe is",
    ]
    for kind, operation, source, target, _, arity in cases():
        name = f"{kind}_{operation}"
        parameters = "Value" if arity == 1 else "Low, High"
        arguments = parameters
        lines += [
            f"   function {ada(name)}",
            f"     ({parameters} : Flyology_SIMD.{source})",
            f"      return Flyology_SIMD.{target} is",
            f"     (Flyology_SIMD.Backends.Native.{ada(operation)} ({arguments}));",
            "",
        ]
    return "\n".join((*lines, "end Integer_Conversion_Codegen_Probe;", ""))


def cases_text() -> str:
    return "\n".join(
        " ".join((kind, operation, source.lower(), target.lower(), suffix, str(arity)))
        for kind, operation, source, target, suffix, arity in cases()
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
