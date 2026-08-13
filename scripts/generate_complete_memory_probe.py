#!/usr/bin/env python3
"""Generate exact public callers for all complete 128-bit memory operations."""

from pathlib import Path
import argparse


ROOT = Path(__file__).resolve().parents[1]
PROBES = ROOT / "scripts" / "probes"
SPEC = PROBES / "complete_memory_codegen_probe.ads"
BODY = PROBES / "complete_memory_codegen_probe.adb"
CASES = PROBES / "complete_memory_codegen_cases.txt"
TYPES = (
    ("u8", "U8x16", "Byte_Array", "none"),
    ("i8", "I8x16", "I8_Array", "2"),
    ("u16", "U16x8", "U16_Array", "3"),
    ("i16", "I16x8", "I16_Array", "4"),
    ("u32", "U32x4", "U32_Array", "5"),
    ("i32", "I32x4", "I32_Array", "6"),
    ("u64", "U64x2", "U64_Array", "7"),
    ("i64", "I64x2", "I64_Array", "8"),
    ("f32", "F32x4", "F32_Array", "9"),
    ("f64", "F64x2", "F64_Array", "10"),
)
OPERATIONS = (
    "load", "store", "load_unaligned", "store_unaligned",
    "load_aligned", "store_aligned",
)


def ada(operation: str) -> str:
    return "_".join(part.title() for part in operation.split("_"))


def spec_text() -> str:
    lines = ["with Flyology_SIMD;", "", "package Complete_Memory_Codegen_Probe is"]
    for kind, vector, array, _ in TYPES:
        for operation in OPERATIONS:
            name = f"{kind.upper()}_{ada(operation)}"
            if operation.startswith("load"):
                lines += [
                    f"   function {name}",
                    f"     (Data : Flyology_SIMD.{array}; Start : Natural)",
                    f"      return Flyology_SIMD.{vector};",
                ]
            else:
                lines += [
                    f"   procedure {name}",
                    f"     (Data : in out Flyology_SIMD.{array}; Start : Natural;",
                    f"      Value : Flyology_SIMD.{vector});",
                ]
    return "\n".join((*lines, "end Complete_Memory_Codegen_Probe;", ""))


def body_text() -> str:
    lines = [
        "with Flyology_SIMD.Backends.Native;", "",
        "package body Complete_Memory_Codegen_Probe is",
    ]
    for kind, vector, array, _ in TYPES:
        for operation in OPERATIONS:
            name = f"{kind.upper()}_{ada(operation)}"
            native = ada(operation)
            if operation.startswith("load"):
                lines += [
                    f"   function {name}",
                    f"     (Data : Flyology_SIMD.{array}; Start : Natural)",
                    f"      return Flyology_SIMD.{vector} is",
                    f"     (Flyology_SIMD.Backends.Native.{native} (Data, Start));", "",
                ]
            else:
                lines += [
                    f"   procedure {name}",
                    f"     (Data : in out Flyology_SIMD.{array}; Start : Natural;",
                    f"      Value : Flyology_SIMD.{vector}) is",
                    "   begin",
                    f"      Flyology_SIMD.Backends.Native.{native} (Data, Start, Value);",
                    f"   end {name};", "",
                ]
    return "\n".join((*lines, "end Complete_Memory_Codegen_Probe;", ""))


def cases_text() -> str:
    return "\n".join(
        f"{kind} {operation} {suffix}"
        for kind, _, _, suffix in TYPES
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
    for path, content in ((SPEC, spec_text()), (BODY, body_text()), (CASES, cases_text())):
        write_or_check(path, content, args.check)


if __name__ == "__main__":
    main()
