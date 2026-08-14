#!/usr/bin/env python3
"""Generate exact public callers for all Wide compact-mask operations."""

from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "wide_mask_codegen_probe.ads"
BODY = PROBES / "wide_mask_codegen_probe.adb"
CASES = PROBES / "wide_mask_codegen_cases.txt"

SHAPES = (
    ("m8", "8x32", "none", 16),
    ("m16", "16x16", "2", 8),
    ("m32", "32x8", "3", 4),
    ("m64", "64x4", "4", 2),
)

OPERATIONS = (
    "mask_from_bit_mask",
    "to_bit_mask",
    "mask_and",
    "mask_or",
    "mask_xor",
    "mask_not",
    "test",
    "any_true",
    "all_true",
    "none_true",
    "population_count",
    "first_true",
    "last_true",
)


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def declaration(kind: str, shape: str, operation: str) -> list[str]:
    mask = f"Flyology_SIMD.Wide.Mask_{shape}"
    bits = f"Flyology_SIMD.Wide.Mask_Bits_{shape}"
    index = f"Flyology_SIMD.Wide.Lane_Index_{shape}"
    count = f"Flyology_SIMD.Wide.Lane_Count_{shape}"
    name = f"{kind.upper()}_{ada(operation)}"
    if operation == "mask_from_bit_mask":
        return [f"   function {name} (Bits : {bits}) return {mask};"]
    if operation == "to_bit_mask":
        return [f"   function {name} (Mask : {mask}) return {bits};"]
    if operation in ("mask_and", "mask_or", "mask_xor"):
        return [f"   function {name} (Left, Right : {mask}) return {mask};"]
    if operation == "mask_not":
        return [f"   function {name} (Value : {mask}) return {mask};"]
    if operation == "test":
        return [f"   function {name} (Mask : {mask}; Lane : {index}) return Boolean;"]
    if operation in ("any_true", "all_true", "none_true"):
        return [f"   function {name} (Mask : {mask}) return Boolean;"]
    return [f"   function {name} (Mask : {mask}) return {count};"]


def call_arguments(operation: str) -> str:
    if operation == "mask_from_bit_mask":
        return "Bits"
    if operation in ("mask_and", "mask_or", "mask_xor"):
        return "Left, Right"
    if operation == "mask_not":
        return "Value"
    if operation == "test":
        return "Mask, Lane"
    return "Mask"


def spec_text() -> str:
    lines = ["with Flyology_SIMD.Wide;", "", "package Wide_Mask_Codegen_Probe is"]
    for kind, shape, *_ in SHAPES:
        for operation in OPERATIONS:
            lines.extend(declaration(kind, shape, operation))
    lines.extend(["end Wide_Mask_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = ["with Flyology_SIMD.Wide.Native;", "", "package body Wide_Mask_Codegen_Probe is"]
    for kind, shape, *_ in SHAPES:
        for operation in OPERATIONS:
            declaration_line = declaration(kind, shape, operation)[0]
            signature, result = declaration_line[:-1].rsplit(" return ", 1)
            lines.extend([
                signature,
                f"      return {result} is",
                f"     (Flyology_SIMD.Wide.Native.{ada(operation)} ({call_arguments(operation)}));",
                "",
            ])
    lines.extend(["end Wide_Mask_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    return "\n".join(
        [f"{kind} {operation} {suffix} {half_lanes}"
         for kind, _, suffix, half_lanes in SHAPES
         for operation in OPERATIONS]
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
