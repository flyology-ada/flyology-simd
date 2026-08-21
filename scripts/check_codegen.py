#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.11"
# dependencies = ["regex==2026.7.19"]
# ///
"""Build SIMD probes and enforce their generated-code contracts."""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
from pathlib import Path

from codegen_checker import Checker, CodegenError
from codegen_contract_aarch64 import check_aarch64
from codegen_contract_common import (
    check_byte_add_saturate,
    check_complete_memory_callers,
    check_fixed_width_callers,
    check_floating_algorithms,
    check_integer_conversion_callers,
    check_public_floating_and_numeric_conversions,
    check_public_routes,
    check_u8_value_callers,
    check_wide_memory_callers,
)
from codegen_contract_comparison import check_comparisons
from codegen_contract_wide import (
    check_masks,
    check_wide_bitwise_and_shifts,
    check_wide_comparison,
    check_wide_construction,
    check_wide_integer_arithmetic,
    check_wide_minmax,
    check_wide_reductions,
)
from codegen_contract_x86_64 import check_x86_64
from codegen_evidence import Evidence


def temporary_directory() -> tuple[Path, bool]:
    configured = os.environ.get("FLYOLOGY_CODEGEN_EVIDENCE_DIR")
    if configured:
        path = Path(configured)
        path.mkdir(parents=True, exist_ok=True)
        if next(path.iterdir(), None) is not None:
            raise CodegenError(
                f"code-generation evidence directory is not empty: {path}"
            )
        return path, True
    return Path(tempfile.mkdtemp(prefix="flyology-simd-codegen.")), False


def check_common(checker: Checker, wide_backend: str) -> None:
    check_floating_algorithms(checker)
    check_u8_value_callers(checker)
    check_byte_add_saturate(checker)
    check_public_floating_and_numeric_conversions(checker)
    check_integer_conversion_callers(checker)
    check_wide_memory_callers(checker)
    check_public_routes(checker)
    check_fixed_width_callers(checker)
    check_complete_memory_callers(checker)
    check_wide_construction(checker)
    check_wide_comparison(checker, wide_backend)
    check_wide_integer_arithmetic(checker, wide_backend)
    check_wide_bitwise_and_shifts(checker, wide_backend)
    check_wide_minmax(checker, wide_backend)
    check_masks(checker)
    check_wide_reductions(checker)
    check_comparisons(checker)


def check_algorithm_undefined(checker: Checker) -> None:
    undefined = checker.temporary / "algorithm-undefined.txt"
    if checker.matches(r"[_ ]flyology_simd__equal$", undefined):
        raise CodegenError(
            "representative native algorithm calls the scalar equality helper"
        )
    if checker.matches(
        r"flyology_simd__backends__native__(splat|load_unaligned|equal|bitwise_and|bitwise_or|shift_right_logical|table_lookup|to_bit_mask|equal_bits|neon_bitwise_and|u8_and)$",
        undefined,
    ):
        raise CodegenError(
            "representative native algorithm retains an out-of-line backend primitive"
        )


def run(architecture: str, avx2: str, wide_backend: str) -> None:
    temporary, preserve = temporary_directory()
    try:
        evidence = Evidence(architecture, avx2, wide_backend, temporary)
        evidence.build()
        evidence.collect()
        checker = Checker(architecture, temporary)
        check_common(checker, wide_backend)
        if architecture == "aarch64":
            check_aarch64(checker)
        elif architecture == "x86_64":
            check_x86_64(checker, avx2, wide_backend)
        else:
            raise CodegenError(
                f"unsupported code-generation architecture: {architecture}"
            )
        check_algorithm_undefined(checker)
        print(
            f"code-generation checks passed: architecture={architecture} avx2={avx2} wide_backend={wide_backend}"
        )
    finally:
        if not preserve:
            shutil.rmtree(temporary)


def main(arguments: list[str]) -> int:
    architecture = arguments[0] if arguments else "aarch64"
    avx2 = arguments[1] if len(arguments) > 1 else "disabled"
    wide_backend = arguments[2] if len(arguments) > 2 else "composed"
    try:
        run(architecture, avx2, wide_backend)
    except (CodegenError, OSError) as error:
        print(error, file=sys.stderr)
        if str(error).startswith(
            (
                "unsupported code-generation architecture:",
                "code-generation evidence directory is not empty:",
            )
        ):
            return 2
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
