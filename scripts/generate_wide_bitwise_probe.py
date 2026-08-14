#!/usr/bin/env python3
"""Generate exact public callers for all Wide integer bitwise overloads."""

from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "wide_bitwise_codegen_probe.ads"
BODY = PROBES / "wide_bitwise_codegen_probe.adb"
CASES = PROBES / "wide_bitwise_codegen_cases.txt"
TYPES = (
    ("u8", "U8x32", "none", "byte"), ("i8", "I8x32", "2", "byte"),
    ("u16", "U16x16", "3", "parts"), ("i16", "I16x16", "4", "parts"),
    ("u32", "U32x8", "5", "parts"), ("i32", "I32x8", "6", "parts"),
    ("u64", "U64x4", "7", "parts"), ("i64", "I64x4", "8", "parts"),
)
OPERATIONS = (("bitwise_and", 2), ("bitwise_or", 2), ("bitwise_xor", 2), ("bitwise_not", 1))


def ada(name: str) -> str:
    return "_".join(part.title() for part in name.split("_"))


def declaration(kind: str, vector: str, operation: str, arity: int) -> list[str]:
    parameters = "Value" if arity == 1 else "Left, Right"
    return [f"   function {kind.upper()}_{ada(operation)}",
            f"     ({parameters} : Flyology_SIMD.Wide.{vector})",
            f"      return Flyology_SIMD.Wide.{vector};"]


def spec_text() -> str:
    lines = ["with Flyology_SIMD.Wide;", "", "package Wide_Bitwise_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation, arity in OPERATIONS:
            lines.extend(declaration(kind, vector, operation, arity))
    lines.extend(["end Wide_Bitwise_Codegen_Probe;", ""])
    return "\n".join(lines)


def body_text() -> str:
    lines = ["with Flyology_SIMD.Wide.Native;", "", "package body Wide_Bitwise_Codegen_Probe is"]
    for kind, vector, *_ in TYPES:
        for operation, arity in OPERATIONS:
            lines.extend(declaration(kind, vector, operation, arity)[:-1])
            lines.append(f"      return Flyology_SIMD.Wide.{vector} is")
            arguments = "Value" if arity == 1 else "Left, Right"
            lines.extend([f"     (Flyology_SIMD.Wide.Native.{ada(operation)} ({arguments}));", ""])
    lines.extend(["end Wide_Bitwise_Codegen_Probe;", ""])
    return "\n".join(lines)


def cases_text() -> str:
    return "\n".join(
        [f"{kind} {operation} {suffix} {route} {arity}"
         for kind, _, suffix, route in TYPES for operation, arity in OPERATIONS] + [""])


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
