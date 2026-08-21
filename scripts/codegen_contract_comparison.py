#!/usr/bin/env python3
"""Fixed-width comparison caller and isolated-leaf contracts."""

from __future__ import annotations

from codegen_checker import Checker
from codegen_contract_common import ROOT, require_unique_manifest


SYMBOL_END = r"([+-]0x[[:xdigit:]]+)?([[:space:]]|$)"
ORDERED = {"less_than", "less_equal", "greater_than", "greater_equal"}
INCLUSIVE = {"less_equal", "greater_equal"}


def check_comparisons(checker: Checker) -> None:
    t = checker.temporary
    cases = require_unique_manifest(
        "comparison_codegen_cases.txt",
        62,
        "fixed-width comparison manifest must contain 62 unique operations",
    )
    checker.require_count(
        r"Left => Right, Right => Left",
        20,
        ROOT
        / "src"
        / "backends"
        / checker.architecture
        / "flyology_simd-backends-native.adb",
        f"the ten less-than and ten less-equal reversed-operand definitions on {checker.architecture}",
    )
    probe, undefined = t / "comparison-probe.txt", t / "comparison-undefined.txt"
    for lane_kind, operation, _suffix in cases:
        caller = t / f"comparison-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"comparison_codegen_probe__{lane_kind}_{operation}", probe, caller
        )
        checker.require_count(
            f"comparison_codegen_probe__selected_{lane_kind}_{operation}",
            1,
            caller,
            f"matching isolated {lane_kind} {operation} leaf",
        )
        checker.require_at_most(
            r"(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]",
            1,
            caller,
            f"only one out-of-line branch in {lane_kind} {operation} caller",
        )
        checker.forbid_pattern(
            r"flyology_simd__(backends__scalar__)?(equal|less_than|less_equal|greater_than|greater_equal|unordered|select_value)|flyology_simd__wide__",
            caller,
            f"portable, Scalar, or Wide comparison in {lane_kind} {operation} caller",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(equal|less_than|less_equal|greater_than|greater_equal|select_value)(__([2-9]|10))?$|flyology_simd__backends__native__unordered(__2)?$",
        61,
        undefined,
        probe,
        "the 61 out-of-line selected comparison and selection overloads",
    )
    checker.require_native_route(
        r"flyology_simd__backends__native__weights_8x16$",
        0,
        undefined,
        probe,
        "no external U8 compact-mask weight table reference",
    )
    checker.require_at_most(
        r"flyology_simd__",
        61,
        undefined,
        "only the intended fixed-width comparison routes remain unresolved",
    )

    shapes = {
        "u8": ("16b", "pcmpgtb", "pcmpeqb"),
        "i8": ("16b", "pcmpgtb", "pcmpeqb"),
        "u16": ("8h", "pcmpgtw", "pcmpeqw"),
        "i16": ("8h", "pcmpgtw", "pcmpeqw"),
        "u32": ("4s", "pcmpgtd", "pcmpeqd"),
        "i32": ("4s", "pcmpgtd", "pcmpeqd"),
        "u64": ("2d", "pcmpgtd", "pcmpeqd"),
        "i64": ("2d", "pcmpgtd", "pcmpeqd"),
        "f32": ("4s", "", "pcmpeqd"),
        "f64": ("2d", "", "pcmpeqd"),
    }
    for lane_kind, operation, suffix in cases:
        leaf = t / f"comparison-leaf-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"comparison_codegen_probe__selected_{lane_kind}_{operation}", probe, leaf
        )
        suffix_text = "" if suffix == "none" else f"__{suffix}"
        native_pattern = f"backends__native__{operation}{suffix_text}{SYMBOL_END}"
        if checker.matches(native_pattern, leaf):
            checker.extract_symbol(
                f"flyology_simd__backends__native__{operation}{suffix_text}",
                t / "native.txt",
                leaf,
            )
        shape, x86_compare, x86_equal = shapes[lane_kind]
        if checker.architecture == "aarch64":
            _check_aarch64(checker, leaf, lane_kind, operation, shape)
        else:
            _check_x86(checker, leaf, lane_kind, operation, x86_compare, x86_equal)
        checker.forbid_pattern(
            r"(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in isolated {lane_kind} {operation} leaf",
        )


def _check_aarch64(
    checker: Checker, leaf, lane: str, operation: str, shape: str
) -> None:
    if operation == "select_value":
        checker.require_leaf_instruction(
            f"cmtst.*{shape}",
            1,
            leaf,
            f"NEON {shape} mask expansion in {lane} selection",
        )
        checker.require_leaf_instruction(
            r"bsl.*16b", 1, leaf, f"NEON 128-bit selection in {lane} selection"
        )
    elif lane in {"f32", "f64"} and operation == "unordered":
        checker.require_leaf_instruction(
            f"fcm(e|g)[a-z]*.*{shape}",
            2,
            leaf,
            f"two NEON {shape} self comparisons in {lane} unordered",
        )
        checker.require_pattern(
            r"(^|[[:space:]])and", leaf, f"ordered-mask conjunction in {lane} unordered"
        )
        checker.require_leaf_instruction(
            r"(^|[[:space:]])mvn",
            1,
            leaf,
            f"ordered-mask inversion in {lane} unordered",
        )
    elif lane in {"f32", "f64"}:
        mnemonic = (
            "fcmeq"
            if operation == "equal"
            else ("fcmge" if operation in INCLUSIVE else "fcmgt")
        )
        kind = (
            "equality"
            if operation == "equal"
            else (
                "inclusive comparison"
                if operation in INCLUSIVE
                else "strict comparison"
            )
        )
        checker.require_leaf_instruction(
            f"{mnemonic}.*{shape}",
            1,
            leaf,
            f"NEON floating {kind} in {lane}"
            + (f" {operation}" if operation != "equal" else ""),
        )
    elif operation == "equal":
        checker.require_leaf_instruction(
            f"cmeq.*{shape}", 1, leaf, f"NEON {shape} integer equality in {lane}"
        )
    elif operation in ORDERED:
        if lane.startswith("u"):
            mnemonic = "cmhs" if operation in INCLUSIVE else "cmhi"
            signed = "unsigned"
        else:
            mnemonic = "cmge" if operation in INCLUSIVE else "cmgt"
            signed = "signed"
        checker.require_leaf_instruction(
            f"{mnemonic}.*{shape}",
            1,
            leaf,
            f"NEON {signed} {shape} {'inclusive' if operation in INCLUSIVE else 'strict'} comparison in {lane} {operation}",
        )
    if (
        lane in {"u8", "i8"}
        and operation != "select_value"
        and operation != "unordered"
    ):
        for pattern, count, description in (
            (r"and.*16b", 1, "byte comparison weight mask"),
            (r"ext.*16b", 1, "byte comparison half advance"),
            (r"uaddlv.*8b", 2, "byte comparison half sums"),
            (r"umov.*h", 2, "byte compact-mask transfers"),
        ):
            checker.require_leaf_instruction(
                pattern, count, leaf, f"{description} in {lane} {operation}"
            )
    elif lane in {"u16", "i16"} and operation not in {"select_value", "unordered"}:
        for pattern, description in (
            (r"ushr.*8h", "16-bit comparison normalization"),
            (r"mul.*8h", "16-bit compact-mask weighting"),
            (r"addv.*8h", "16-bit compact-mask reduction"),
        ):
            checker.require_leaf_instruction(
                pattern, 1, leaf, f"{description} in {lane} {operation}"
            )
    elif lane in {"u32", "i32", "f32"} and operation not in {
        "select_value",
        "unordered",
    }:
        for pattern, description in (
            (r"ushr.*4s", "32-bit comparison normalization"),
            (r"mul.*4s", "32-bit compact-mask weighting"),
            (r"addv.*4s", "32-bit compact-mask reduction"),
        ):
            checker.require_leaf_instruction(
                pattern, 1, leaf, f"{description} in {lane} {operation}"
            )
    elif lane in {"u64", "i64", "f64"} and operation not in {
        "select_value",
        "unordered",
    }:
        checker.require_leaf_instruction(
            r"ushr.*2d",
            1,
            leaf,
            f"64-bit comparison normalization in {lane} {operation}",
        )
        checker.require_leaf_instruction(
            r"(^|[[:space:]])and",
            1,
            leaf,
            f"64-bit compact-mask merge in {lane} {operation}",
        )


def _check_x86(
    checker: Checker, leaf, lane: str, operation: str, compare: str, equal: str
) -> None:
    compact = r"pmovmskb"
    if operation == "select_value":
        checker.require_pattern(
            equal, leaf, f"SSE2 lane-width mask expansion in {lane} selection"
        )
        checker.require_pattern(
            r"(^|[[:space:]])pand",
            leaf,
            f"SSE2 true-lane selection in {lane} selection",
        )
        checker.require_leaf_instruction(
            r"(^|[[:space:]])pandn",
            1,
            leaf,
            f"SSE2 false-lane selection in {lane} selection",
        )
        checker.require_leaf_instruction(
            r"(^|[[:space:]])por",
            1,
            leaf,
            f"SSE2 selected-lane merge in {lane} selection",
        )
        return
    if lane in {"f32", "f64"}:
        suffix = "ps" if lane == "f32" else "pd"
        mnemonic = (
            "cmpunord"
            if operation == "unordered"
            else (
                "cmpeq"
                if operation == "equal"
                else ("cmple" if operation in INCLUSIVE else "cmplt")
            )
        )
        description = f"SSE2 {lane.upper()} " + (
            "unordered comparison"
            if operation == "unordered"
            else (
                "equality"
                if operation == "equal"
                else f"{'inclusive' if operation in INCLUSIVE else 'strict'} comparison in {operation}"
            )
        )
        checker.require_leaf_instruction(f"{mnemonic}{suffix}", 1, leaf, description)
    elif operation == "equal":
        checker.require_leaf_instruction(
            equal, 1, leaf, f"SSE2 lane-width integer equality in {lane}"
        )
        checker.require_leaf_instruction(
            compact, 1, leaf, f"SSE2 compact-mask extraction in {lane} equality"
        )
    elif operation in ORDERED:
        if lane.startswith("u"):
            checker.require_pattern(
                r"pxor", leaf, f"unsigned sign-bit bias in {lane} {operation}"
            )
            checker.require_pattern(
                compare, leaf, f"SSE2 unsigned ordered comparison in {lane} {operation}"
            )
        else:
            checker.require_pattern(
                compare, leaf, f"SSE2 signed ordered comparison in {lane} {operation}"
            )
    if operation in INCLUSIVE and lane in {"u8", "i8", "u16", "i16", "u32", "i32"}:
        checker.require_leaf_instruction(
            equal, 1, leaf, f"SSE2 equality component in {lane} {operation}"
        )
        checker.require_leaf_instruction(
            compact,
            2,
            leaf,
            f"SSE2 strict and equality mask extraction in {lane} {operation}",
        )
        checker.require_count(
            r"(^|[[:space:]])orl?",
            {"u8": 1, "i8": 1, "u16": 7, "i16": 7, "u32": 5, "i32": 5}[lane],
            leaf,
            f"compact-mask construction and strict/equality merge in {lane} {operation}",
        )
    if operation in {"equal", *ORDERED}:
        checker.require_pattern(
            compact, leaf, f"lane-width compact-mask extraction in {lane} {operation}"
        )
    if lane in {"u8", "u16", "u32"} and operation in ORDERED:
        checker.require_leaf_instruction(
            r"(^|[[:space:]])pxor",
            2,
            leaf,
            f"two unsigned sign-bit transforms in {lane} {operation}",
        )
    if lane in {"u64", "i64"} and operation in ORDERED:
        checker.require_leaf_instruction(
            r"pcmpgtd", 2, leaf, f"high/low dword comparisons in {lane} {operation}"
        )
        for pattern, description in (
            (r"pcmpeqd", "high-dword equality gate"),
            (r"pshufd", "dword-to-lane replication"),
            (r"(^|[[:space:]])pand", "equality-gated low comparison"),
            (r"(^|[[:space:]])por", "lexicographic comparison merge"),
        ):
            checker.require_pattern(
                pattern, leaf, f"{description} in {lane} {operation}"
            )
        checker.require_leaf_instruction(
            r"(^|[[:space:]])pxor",
            4 if lane == "u64" else 2,
            leaf,
            f"{'unsigned high/low dword' if lane == 'u64' else 'signed low-dword'} sign transforms in {lane} {operation}",
        )
    elif lane in {"u64", "i64"} and operation == "equal":
        checker.require_leaf_instruction(
            r"pcmpeqd", 1, leaf, f"dword equality in {lane} equality"
        )
        checker.require_leaf_instruction(
            r"pshufd",
            2,
            leaf,
            f"adjacent-dword equality replication in {lane} equality",
        )
        checker.require_leaf_instruction(
            r"(^|[[:space:]])pand",
            1,
            leaf,
            f"adjacent-dword equality conjunction in {lane} equality",
        )
