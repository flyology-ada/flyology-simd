#!/usr/bin/env python3
"""Verify that scalar and native packages expose identical subprograms."""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCALAR = ROOT / "src" / "flyology_simd-backends-scalar.ads"
NATIVE = ROOT / "src" / "flyology_simd-backends-native.ads"
WIDE = ROOT / "src" / "flyology_simd-wide.ads"
WIDE_NATIVE = ROOT / "src" / "flyology_simd-wide-native.ads"


def declarations(path: Path) -> Counter[str]:
    text = re.sub(r"--[^\n]*", "", path.read_text())
    text = text.split("\nprivate\n", 1)[0]
    found: Counter[str] = Counter()
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        match = re.match(
            r"\s*(function|procedure)\s+([A-Za-z0-9_]+)", lines[index]
        )
        if match is None:
            index += 1
            continue
        declaration = [lines[index]]
        depth = 0
        complete = False
        while not complete:
            for character in declaration[-1]:
                if character == "(":
                    depth += 1
                elif character == ")":
                    depth -= 1
                elif character == ";" and depth == 0:
                    complete = True
                    break
            if complete:
                break
            index += 1
            declaration.append(lines[index])
        profile = re.sub(r"\s+", " ", " ".join(declaration)).strip()
        profile = re.split(r"\s+(?:renames|with)\s+", profile, maxsplit=1)[0]
        profile = profile.removesuffix(";")
        found[profile] += 1
        index += 1
    return found


def report(label: str, difference: Counter[str]) -> None:
    if not difference:
        return
    print(label, file=sys.stderr)
    for declaration, count in sorted(difference.items()):
        print(f"  {count} x {declaration}", file=sys.stderr)


scalar = declarations(SCALAR)
native = declarations(NATIVE)
wide = declarations(WIDE)
wide_native = declarations(WIDE_NATIVE)
report("only in scalar backend:", scalar - native)
report("only in native backend:", native - scalar)
report("only in Wide scalar authority:", wide - wide_native)
report("only in Wide native backend:", wide_native - wide)
if scalar != native or wide != wide_native:
    raise SystemExit(1)
print(
    "backend contracts match: "
    f"{sum(scalar.values())} 128-bit and {sum(wide.values())} Wide declarations"
)
