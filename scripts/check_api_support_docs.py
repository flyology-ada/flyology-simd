#!/usr/bin/env python3
"""Require cross-platform support text on every public primitive overload."""

from __future__ import annotations

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SPECS = (
    ROOT / "src" / "flyology_simd.ads",
    ROOT / "src" / "flyology_simd-backends-scalar.ads",
    ROOT / "src" / "flyology_simd-backends-native.ads",
    ROOT / "src" / "flyology_simd-wide.ads",
    ROOT / "src" / "flyology_simd-wide-native.ads",
)
DECLARATION = re.compile(r"^   (?:function|procedure)\s+([A-Za-z0-9_]+)")


def declaration_end(lines: list[str], start: int) -> int:
    depth = 0
    for index in range(start, len(lines)):
        for character in lines[index]:
            if character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
            elif character == ";" and depth == 0:
                return index
    raise ValueError(f"unterminated declaration at line {start + 1}")


def missing_support(path: Path) -> list[str]:
    lines = path.read_text().splitlines()
    missing: list[str] = []
    index = 0
    while index < len(lines):
        match = DECLARATION.match(lines[index])
        if match is None:
            index += 1
            continue
        end = declaration_end(lines, index)
        comment = end + 1
        documented = False
        while comment < len(lines) and lines[comment].startswith("   --"):
            documented |= "Cross-platform support:" in lines[comment]
            comment += 1
        if not documented:
            missing.append(f"{path.relative_to(ROOT)}:{index + 1}: {match.group(1)}")
        index = end + 1
    return missing


def invalid_support(path: Path) -> list[str]:
    text = path.read_text()
    invalid: list[str] = []
    if "A target backend can use scalar composition" in text:
        invalid.append(f"{path.relative_to(ROOT)}: generic Native fallback wording")
    if path.name == "flyology_simd.ads":
        shared = (
            "Cross-platform support: this fixed-width Ada operation is available "
            "on every supported GNAT target and has no separate Backends.Native "
            "overload."
        )
        if text.count(shared) != 18:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected 18 operations without a "
                f"Native counterpart, found {text.count(shared)}"
            )
    if path.name == "flyology_simd-wide-native.ads":
        required = {
            "function Is_Aligned_32": "same portable Ada implementation",
            "function Interleave_Low": "four-register NEON tbl operation",
            "function Interleave_High": "four-register NEON tbl operation",
            "function Deinterleave_Even": "four-register NEON tbl operation",
            "function Deinterleave_Odd": "four-register NEON tbl operation",
            "function Reverse_Lanes": "two-register NEON tbl operation",
            "function Slide_Lanes_Toward_Low": "two-register NEON tbl operation",
            "function Slide_Lanes_Toward_High": "two-register NEON tbl operation",
            "function Load_Partial": "conditionally compose selected 128-bit full and partial memory operations",
            "procedure Store_Partial": "conditionally compose selected 128-bit full and partial memory operations",
            "function Add (": "run the selected 128-bit operation on both private parts",
            "function Subtract (": "run the selected 128-bit operation on both private parts",
            "function Multiply (": "run the selected 128-bit operation on both private parts",
            "function Divide (": "run the selected 128-bit operation on both private parts",
            "function Min_Number": "run the selected 128-bit operation on both private parts",
            "function Max_Number": "run the selected 128-bit operation on both private parts",
            "function Zero": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Splat": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function From_Lanes": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function To_Lanes": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Mask_From_Bit_Mask": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function To_Bit_Mask": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Mask_And": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Mask_Or": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Mask_Xor": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Mask_Not": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Any_True": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function All_True": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function None_True": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Population_Count": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function First_True": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Last_True": "call the selected 128-bit operation on each private part and combine the results in Ada",
            "function Extract": "only on the private part that contains the requested lane",
            "function Replace": "only on the private part that contains the requested lane",
            "function Test": "only on the private part that contains the requested lane",
            "function Reduce_Add_Wrap": "reduce each private part with the selected 128-bit Reduce_Add_Wrap operation",
            "function Reduce_Min": "reduce each private part with the selected 128-bit Reduce_Min operation",
            "function Reduce_Max": "reduce each private part with the selected 128-bit Reduce_Max operation",
            "function Table_Lookup": "x86-64 composed selection calls the Wide scalar implementation",
            "function Permute_Lanes": "optional AVX2 backend derives a 32-byte index map",
        }
        for declaration, phrase in required.items():
            count = sum(
                1
                for block in text.split(declaration)[1:]
                if phrase in block.split("function ", 1)[0].split("procedure ", 1)[0]
            )
            expected = {
                "function Add (": 2,
                "function Subtract (": 2,
                "function Multiply (": 2,
                "function Divide (": 2,
                "function Min_Number": 2,
                "function Max_Number": 2,
                "function Zero": 10,
                "function Splat": 10,
                "function From_Lanes": 10,
                "function To_Lanes": 10,
                "function Mask_From_Bit_Mask": 4,
                "function To_Bit_Mask": 4,
                "function Mask_And": 4,
                "function Mask_Or": 4,
                "function Mask_Xor": 4,
                "function Mask_Not": 4,
                "function Any_True": 4,
                "function All_True": 4,
                "function None_True": 4,
                "function Population_Count": 4,
                "function First_True": 4,
                "function Last_True": 4,
                "function Table_Lookup": 1,
                "function Permute_Lanes": 20,
                "function Test": 4,
                "function Reduce_Add_Wrap": 8,
                "function Reduce_Min": 8,
                "function Reduce_Max": 8,
            }.get(declaration, 10)
            if count != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: {declaration} classification "
                    f"appears {count} times, expected {expected}"
                )
    return invalid


def main() -> int:
    errors = [item for path in SPECS for item in missing_support(path)]
    errors += [item for path in SPECS for item in invalid_support(path)]
    if errors:
        print("invalid public primitive cross-platform support text:", file=sys.stderr)
        for item in errors:
            print(f"  {item}", file=sys.stderr)
        return 1
    counts = []
    for path in SPECS:
        count = sum(1 for line in path.read_text().splitlines() if DECLARATION.match(line))
        counts.append(f"{path.name}={count}")
    print("API cross-platform support documentation: PASS (" + ", ".join(counts) + ")")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
