#!/usr/bin/env python3
"""Generate exact callers for all fixed-width floating binary operations."""

from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "float_binary_codegen_probe.ads"
BODY = PROBES / "float_binary_codegen_probe.adb"
CASES = PROBES / "float_binary_codegen_cases.txt"
TYPES = (("f32", "F32x4", "none", "4s", "ps"), ("f64", "F64x2", "2", "2d", "pd"))
OPERATIONS = ("add", "subtract", "multiply", "divide", "min_number", "max_number")


def ada(operation: str) -> str:
    return "_".join(part.title() for part in operation.split("_"))


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Float_Binary_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines += [f"   function {kind.upper()}_{ada(operation)}", f"     (Left, Right : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{vector};"]
    return "\n".join((*lines, "end Float_Binary_Codegen_Probe;", ""))


def body_text() -> str:
    lines = ["with Flyology_SIMD.Backends.Native;", "", "package body Float_Binary_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation in OPERATIONS:
            lines += [f"   function {kind.upper()}_{ada(operation)}", f"     (Left, Right : Flyology_SIMD.{vector})", f"      return Flyology_SIMD.{vector} is", f"     (Flyology_SIMD.Backends.Native.{ada(operation)} (Left, Right));", ""]
    return "\n".join((*lines, "end Float_Binary_Codegen_Probe;", ""))


def cases_text() -> str:
    return "\n".join(f"{kind} {operation} {suffix} {shape} {x86}" for kind, _, suffix, shape, x86 in TYPES for operation in OPERATIONS) + "\n"


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
    for path, content in ((SPEC, spec_text()), (BODY, body_text()), (CASES, cases_text())):
        write_or_check(path, content, args.check)


if __name__ == "__main__":
    main()
