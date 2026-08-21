#!/usr/bin/env python3
"""x86-64-specific generated-code contracts."""

from __future__ import annotations

from codegen_checker import Checker
from codegen_contract_common import rows


LOAD0 = r"(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0"
LOAD1 = r"(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1"
STORE = r"(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)"
BRANCH = r"(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]"


def _leaf(c: Checker, family: str, lane: str, operation: str, suffix: str):
    t = c.temporary
    output = t / f"{family.replace('_', '-')}-leaf-{lane}-{operation}.txt"
    symbol_suffix = "" if suffix == "none" else f"__{suffix}"
    c.extract_leaf_or_probe(
        f"flyology_simd__backends__native__{operation}{symbol_suffix}",
        t / "native.txt",
        f"{family}_codegen_probe__{lane}_{operation}",
        t / f"{family.replace('_', '-')}-probe.txt",
        output,
    )
    return output


def _binary_transfers(c: Checker, leaf, lane: str, operation: str) -> None:
    c.require_at_most(
        LOAD0, 1, leaf, f"left operand transfer in {lane} {operation} leaf"
    )
    c.require_at_most(
        LOAD1, 1, leaf, f"right operand transfer in {lane} {operation} leaf"
    )
    c.require_leaf_instruction(
        STORE, 0, leaf, f"no result store in register-operand {lane} {operation} leaf"
    )


def check_wrapping_and_bitwise(c: Checker) -> None:
    t = c.temporary
    for lane, operation, suffix, bits, _lanes in rows(
        "wrapping_arithmetic_codegen_cases.txt"
    ):
        leaf = _leaf(c, "wrapping_arithmetic", lane, operation, suffix)
        _binary_transfers(c, leaf, lane, operation)
        if operation in {"add_wrap", "subtract_wrap"}:
            mnemonic = ("padd" if operation == "add_wrap" else "psub") + {
                "8": "b",
                "16": "w",
                "32": "d",
                "64": "q",
            }[bits]
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                1,
                leaf,
                f"exact SSE2 {lane} {'add' if operation == 'add_wrap' else 'subtract'}",
            )
        elif bits == "8":
            checks = (
                ("punpcklbw", 2, "two low-byte widening steps"),
                ("punpckhbw", 2, "two high-byte widening steps"),
                ("pmullw", 2, "two widened products"),
                ("pand", 2, "two low-byte masks"),
                ("packuswb", 1, "byte repacking"),
                ("pxor", 1, "zero construction"),
                ("pcmpeqd", 1, "all-ones mask construction"),
            )
            for mnemonic, count, description in checks:
                c.require_leaf_instruction(
                    rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                    count,
                    leaf,
                    f"{description} in {lane} multiplication",
                )
            c.require_leaf_instruction(
                r"(^|[[:space:]])psrlw[[:space:]].*\$(0x0*8|8)([,[:space:]]|$)",
                1,
                leaf,
                f"low-byte mask derivation in {lane} multiplication",
            )
        elif bits == "16":
            c.require_leaf_instruction(
                r"(^|[[:space:]])pmullw[[:space:]]",
                1,
                leaf,
                f"exact SSE2 {lane} multiplication",
            )
        elif bits == "32":
            for pattern, count, description in (
                (r"(^|[[:space:]])pmuludq[[:space:]]", 2, "two even-dword products"),
                (
                    r"(^|[[:space:]])psrldq[[:space:]].*\$(0x0*4|4)([,[:space:]]|$)",
                    2,
                    "two four-byte odd-dword advances",
                ),
                (
                    r"(^|[[:space:]])pshufd[[:space:]].*\$(0x0*88|136)([,[:space:]]|$)",
                    2,
                    "two 0x88 dword product packings",
                ),
                (r"(^|[[:space:]])punpckldq[[:space:]]", 1, "dword product merge"),
            ):
                c.require_leaf_instruction(
                    pattern, count, leaf, f"{description} in {lane} multiplication"
                )
        else:
            for pattern, count, description in (
                (r"(^|[[:space:]])pmuludq[[:space:]]", 3, "three partial products"),
                (
                    r"(^|[[:space:]])pshufd[[:space:]].*\$(0x0*b1|177)([,[:space:]]|$)",
                    2,
                    "two 0xb1 cross-part broadcasts",
                ),
                (
                    r"(^|[[:space:]])paddq[[:space:]]",
                    2,
                    "two partial-product additions",
                ),
                (
                    r"(^|[[:space:]])psllq[[:space:]].*\$(0x20|32)",
                    1,
                    "32-bit cross-product shift",
                ),
            ):
                c.require_leaf_instruction(
                    pattern, count, leaf, f"{description} in {lane} multiplication"
                )
        c.forbid_pattern(
            r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in {lane} {operation} leaf",
        )

    for lane, operation, suffix, _bits, _lanes, arity in rows(
        "bitwise_codegen_cases.txt"
    ):
        if lane == "u8" and operation == "bitwise_and":
            leaf = t / f"bitwise-leaf-{lane}-{operation}.txt"
            c.extract_symbol(
                "bitwise_codegen_probe__u8_bitwise_and", t / "bitwise-probe.txt", leaf
            )
        else:
            leaf = _leaf(c, "bitwise", lane, operation, suffix)
        c.require_at_most(
            LOAD0, 1, leaf, f"left operand transfer in {lane} {operation} leaf"
        )
        if arity == "2":
            c.require_at_most(
                LOAD1, 1, leaf, f"right operand transfer in {lane} {operation} leaf"
            )
        else:
            c.require_leaf_instruction(
                LOAD1, 0, leaf, f"no second memory operand in {lane} {operation} leaf"
            )
        c.require_leaf_instruction(
            STORE,
            0,
            leaf,
            f"no result store in register-operand {lane} {operation} leaf",
        )
        if operation == "bitwise_not":
            c.require_leaf_instruction(
                r"(^|[[:space:]])pcmpeqd[[:space:]]+%xmm1,[[:space:]]*%xmm1",
                1,
                leaf,
                f"all-one construction in {lane} NOT",
            )
            mnemonic, label = "pxor", "NOT"
        else:
            mnemonic, label = {
                "bitwise_and": ("pand", "AND"),
                "bitwise_or": ("por", "OR"),
                "bitwise_xor": ("pxor", "XOR"),
            }[operation]
        c.require_leaf_instruction(
            rf"(^|[[:space:]]){mnemonic}[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+",
            1,
            leaf,
            f"exact SSE2 {lane} {label}",
        )
        c.forbid_pattern(
            BRANCH, leaf, f"branch or out-of-line helper in {lane} {operation} leaf"
        )


def check_minmax(c: Checker) -> None:
    for lane, operation, suffix, bits, _lanes, signedness in rows(
        "integer_minmax_codegen_cases.txt"
    ):
        leaf = _leaf(c, "integer_minmax", lane, operation, suffix)
        _binary_transfers(c, leaf, lane, operation)
        direct = {
            ("u8", "min"): "pminub",
            ("u8", "max"): "pmaxub",
            ("i16", "min"): "pminsw",
            ("i16", "max"): "pmaxsw",
        }.get((lane, operation))
        if direct:
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){direct}[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+",
                1,
                leaf,
                f"exact SSE2 {lane.upper()}x{16 if lane == 'u8' else 8} {operation.title()}",
            )
        else:
            compare = {
                "8": "pcmpgtb",
                "16": "pcmpgtw",
                "32": "pcmpgtd",
                "64": "pcmpgtd",
            }[bits]
            c.require_count(
                rf"(^|[[:space:]]){compare}[[:space:]]",
                2 if bits == "64" else 1,
                leaf,
                f"exact SSE2 comparison in {lane} {operation}",
            )
            c.require_leaf_instruction(
                r"(^|[[:space:]])pmovmskb[[:space:]]",
                1,
                leaf,
                f"compact comparison mask in {lane} {operation}",
            )
            c.require_leaf_instruction(
                r"(^|[[:space:]])pandn[[:space:]]",
                1,
                leaf,
                f"false selection arm in {lane} {operation}",
            )
            if bits == "64":
                counts = (
                    ("pcmpeqd", 3, "equality-gated dword comparison"),
                    ("pshufd", 4, "adjacent-dword broadcasts"),
                    ("pand", 3, "64-bit comparison and selection masks"),
                    ("por", 2, "64-bit comparison and selection merges"),
                )
                for mnemonic, count, description in counts:
                    c.require_leaf_instruction(
                        rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                        count,
                        leaf,
                        f"{description} in {lane} {operation}",
                    )
                c.require_count(
                    r"(^|[[:space:]])pxor[[:space:]]",
                    6 if signedness == "unsigned" else 4,
                    leaf,
                    f"signedness and mask transforms in {lane} {operation}",
                )
            else:
                c.require_leaf_instruction(
                    r"(^|[[:space:]])pand[[:space:]]",
                    2,
                    leaf,
                    f"comparison and true selection masks in {lane} {operation}",
                )
                c.require_leaf_instruction(
                    r"(^|[[:space:]])por[[:space:]]",
                    1,
                    leaf,
                    f"selection merge in {lane} {operation}",
                )
                c.require_count(
                    r"(^|[[:space:]])pxor[[:space:]]",
                    4 if signedness == "unsigned" else 2,
                    leaf,
                    f"signedness and mask transforms in {lane} {operation}",
                )
                details = {
                    "8": (
                        ("punpcklbw", 1, "byte mask expansion"),
                        ("punpcklwd", 1, "word mask expansion"),
                        ("punpckldq", 1, "dword mask expansion"),
                        ("pcmpeqb", 1, "byte mask materialization"),
                        ("pcmpeqd", 1, "byte mask inversion"),
                    ),
                    "16": (
                        ("pcmpeqw", 1, "word mask materialization"),
                        ("pcmpeqd", 1, "word mask inversion"),
                        ("pshufd", 1, "word mask broadcast"),
                    ),
                    "32": (
                        ("pcmpeqd", 2, "dword mask materialization"),
                        ("pshufd", 1, "dword mask broadcast"),
                    ),
                }[bits]
                for mnemonic, count, description in details:
                    c.require_leaf_instruction(
                        rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                        count,
                        leaf,
                        f"{description} in {lane} {operation}",
                    )
        c.forbid_pattern(
            BRANCH, leaf, f"branch or out-of-line helper in {lane} {operation} leaf"
        )


def check_saturating(c: Checker) -> None:
    for lane, operation, suffix, bits, _lanes, signedness in rows(
        "saturating_arithmetic_codegen_cases.txt"
    ):
        leaf = _leaf(c, "saturating_arithmetic", lane, operation, suffix)
        _binary_transfers(c, leaf, lane, operation)
        if int(bits) < 32:
            instruction = (
                ("padd" if operation == "add_saturate" else "psub")
                + ("s" if signedness == "signed" else "us")
                + ("b" if bits == "8" else "w")
            )
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){instruction}[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+",
                1,
                leaf,
                f"exact SSE2 {lane} {operation}",
            )
        else:
            arithmetic = ("padd" if operation == "add_saturate" else "psub") + (
                "d" if bits == "32" else "q"
            )
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){arithmetic}[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+",
                1,
                leaf,
                f"exact SSE2 {lane} {operation} arithmetic",
            )
            if bits == "64":
                c.require_count(
                    r"(^|[[:space:]])pshufd[[:space:]].*\$(0x0*f5|245)([,[:space:]]|$)",
                    2 if signedness == "signed" else 1,
                    leaf,
                    f"64-bit lane-mask replication in {lane} {operation}",
                )
            if signedness == "unsigned":
                if operation == "add_saturate":
                    counts = (
                        ("pand", 2, "unsigned carry masks"),
                        ("por", 3, "unsigned maximum selection"),
                        ("pxor", 1, "unsigned sum inversion"),
                        ("pandn", 0, "no subtract selection"),
                    )
                else:
                    counts = (
                        ("pand", 2, "unsigned borrow masks"),
                        ("por", 1, "unsigned borrow merge"),
                        ("pxor", 3, "unsigned borrow transforms"),
                        ("pandn", 1, "zero-clamped selection"),
                    )
                for mnemonic, count, description in counts:
                    c.require_leaf_instruction(
                        rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                        count,
                        leaf,
                        f"{description} in {lane} {operation}",
                    )
                c.require_leaf_instruction(
                    r"(^|[[:space:]])pcmpeqd[[:space:]]",
                    1,
                    leaf,
                    f"all-ones construction in {lane} {operation}",
                )
                c.require_leaf_instruction(
                    r"(^|[[:space:]])psrad[[:space:]].*\$(0x0*1f|31)([,[:space:]]|$)",
                    1,
                    leaf,
                    f"overflow or borrow lane expansion in {lane} {operation}",
                )
            else:
                for mnemonic, count, description in (
                    (
                        "pxor",
                        3 if operation == "add_saturate" else 2,
                        "signed overflow transforms",
                    ),
                    (
                        "pcmpeqd",
                        2 if operation == "add_saturate" else 1,
                        "signed limit construction",
                    ),
                    ("pand", 3, "signed overflow and limit masks"),
                    ("pandn", 2, "signed non-overflow selection arms"),
                    ("por", 2, "signed saturation merges"),
                ):
                    (
                        c.require_count
                        if mnemonic in {"pxor", "pcmpeqd"}
                        else c.require_leaf_instruction
                    )(
                        rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                        count,
                        leaf,
                        f"{description} in {lane} {operation}",
                    )
                c.require_leaf_instruction(
                    r"(^|[[:space:]])psrad[[:space:]].*\$(0x0*1f|31)([,[:space:]]|$)",
                    2,
                    leaf,
                    f"signed overflow and sign-mask expansion in {lane} {operation}",
                )
                shifts = (
                    (
                        ("pslld", "1f|31", "signed minimum construction"),
                        ("psrld", "1|1", "signed maximum construction"),
                    )
                    if bits == "32"
                    else (
                        ("psllq", "3f|63", "signed minimum construction"),
                        ("psrlq", "1|1", "signed maximum construction"),
                    )
                )
                for mnemonic, amount, description in shifts:
                    c.require_leaf_instruction(
                        rf"(^|[[:space:]]){mnemonic}[[:space:]].*\$(0x0*({amount}))([,[:space:]]|$)",
                        1,
                        leaf,
                        f"{description} in {lane} {operation}",
                    )
        c.forbid_pattern(
            BRANCH, leaf, f"branch or out-of-line helper in {lane} {operation} leaf"
        )


def check_arrangement_memory_float(c: Checker) -> None:
    t = c.temporary
    for lane, operation, suffix, bits, _lanes in rows(
        "lane_arrangement_codegen_cases.txt"
    ):
        leaf = _leaf(c, "lane_arrangement", lane, operation, suffix)
        c.require_at_most(
            LOAD0, 1, leaf, f"left operand transfer in {lane} {operation} leaf"
        )
        if operation != "reverse_lanes":
            c.require_at_most(
                LOAD1, 1, leaf, f"right operand transfer in {lane} {operation} leaf"
            )
        c.require_leaf_instruction(
            STORE,
            0,
            leaf,
            f"no result store in register-operand {lane} {operation} leaf",
        )
        instruction = {
            ("interleave_low", "8"): "punpcklbw",
            ("interleave_high", "8"): "punpckhbw",
            ("interleave_low", "16"): "punpcklwd",
            ("interleave_high", "16"): "punpckhwd",
            ("interleave_low", "32"): "unpcklps" if lane == "f32" else "punpckldq",
            ("interleave_high", "32"): "unpckhps" if lane == "f32" else "punpckhdq",
            ("interleave_low", "64"): "unpcklpd" if lane == "f64" else "punpcklqdq",
            ("interleave_high", "64"): "unpckhpd" if lane == "f64" else "punpckhqdq",
            ("deinterleave_even", "64"): "punpcklqdq",
            ("deinterleave_odd", "64"): "punpckhqdq",
        }.get((operation, bits))
        if instruction:
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){instruction}[[:space:]]",
                1,
                leaf,
                f"exact SSE2 {lane} {operation} leaf",
            )
        details = {
            ("reverse_lanes", "8"): (
                (r"psrlw[[:space:]].*\$(0x0*8|8)", 1, "byte reversal right shift"),
                (r"psllw[[:space:]].*\$(0x0*8|8)", 1, "byte reversal left shift"),
                ("por[[:space:]]", 1, "byte reversal merge"),
                (r"pshuflw[[:space:]].*\$(0x0*1[bB]|27)", 1, "low-word reversal"),
                (r"pshufhw[[:space:]].*\$(0x0*1[bB]|27)", 1, "high-word reversal"),
                (r"pshufd[[:space:]].*\$(0x0*4[eE]|78)", 1, "half reversal"),
            ),
            ("reverse_lanes", "16"): (
                (r"pshuflw[[:space:]].*\$(0x0*1[bB]|27)", 1, "low-word reversal"),
                (r"pshufhw[[:space:]].*\$(0x0*1[bB]|27)", 1, "high-word reversal"),
                (r"pshufd[[:space:]].*\$(0x0*4[eE]|78)", 1, "half reversal"),
            ),
            ("reverse_lanes", "32"): (
                (r"pshufd[[:space:]].*\$(0x0*1[bB]|27)", 1, "dword reversal"),
            ),
            ("reverse_lanes", "64"): (
                (r"pshufd[[:space:]].*\$(0x0*4[eE]|78)", 1, "qword reversal"),
            ),
            ("deinterleave_even", "8"): (
                ("pcmpeqd[[:space:]]", 1, "even-byte all-ones mask construction"),
                (r"psrlw[[:space:]].*\$(0x0*8|8)", 1, "even-byte low mask derivation"),
                ("pand[[:space:]]", 2, "two even-byte masks"),
                ("packuswb[[:space:]]", 1, "even-byte packing"),
            ),
            ("deinterleave_odd", "8"): (
                (r"psrlw[[:space:]].*\$(0x0*8|8)", 2, "two odd-byte shifts"),
                ("packuswb[[:space:]]", 1, "odd-byte packing"),
            ),
            ("deinterleave_even", "16"): (
                (
                    r"pshuflw[[:space:]].*\$(0x0*88|136)",
                    2,
                    "two even low-word selections",
                ),
                (
                    r"pshufhw[[:space:]].*\$(0x0*88|136)",
                    2,
                    "two even high-word selections",
                ),
                (r"pshufd[[:space:]].*\$(0x0*88|136)", 2, "two half packings"),
                ("punpcklqdq[[:space:]]", 1, "word result merge"),
            ),
            ("deinterleave_odd", "16"): (
                (
                    r"pshuflw[[:space:]].*\$(0x0*[dD][dD]|221)",
                    2,
                    "two odd low-word selections",
                ),
                (
                    r"pshufhw[[:space:]].*\$(0x0*[dD][dD]|221)",
                    2,
                    "two odd high-word selections",
                ),
                (r"pshufd[[:space:]].*\$(0x0*88|136)", 2, "two half packings"),
                ("punpcklqdq[[:space:]]", 1, "word result merge"),
            ),
            ("deinterleave_even", "32"): (
                (r"pshufd[[:space:]].*\$(0x0*88|136)", 2, "two even-dword selections"),
                ("punpcklqdq[[:space:]]", 1, "dword result merge"),
            ),
            ("deinterleave_odd", "32"): (
                (
                    r"pshufd[[:space:]].*\$(0x0*[dD][dD]|221)",
                    2,
                    "two odd-dword selections",
                ),
                ("punpcklqdq[[:space:]]", 1, "dword result merge"),
            ),
        }.get((operation, bits), ())
        for pattern, count, description in details:
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){pattern}", count, leaf, description
            )
        c.forbid_pattern(
            r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in {lane} {operation} leaf",
        )

    for lane, operation, suffix in rows("complete_memory_codegen_cases.txt"):
        if lane == "u8" and operation == "load_unaligned":
            continue
        leaf = _leaf(c, "complete_memory", lane, operation, suffix)
        if operation == "load_aligned":
            c.require_leaf_instruction(
                r"(^|[[:space:]])movdqa[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]+",
                1,
                leaf,
                f"x86 {lane} aligned array load into a register",
            )
        elif operation == "store_aligned":
            c.require_leaf_instruction(
                r"(^|[[:space:]])movdqa[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)",
                1,
                leaf,
                f"x86 {lane} aligned array store from a register",
            )
        elif operation in {"load", "load_unaligned"}:
            c.require_leaf_instruction(
                r"(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]+",
                1,
                leaf,
                f"x86 {lane} {operation} unaligned-safe array load",
            )
            c.forbid_pattern(
                r"(^|[[:space:]])movdqa[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]+",
                leaf,
                f"unexpected aligned array load in x86 {lane} {operation} leaf",
            )
        else:
            c.require_leaf_instruction(
                r"(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)",
                1,
                leaf,
                f"x86 {lane} {operation} unaligned-safe array store",
            )
            c.forbid_pattern(
                r"(^|[[:space:]])movdqa[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)",
                leaf,
                f"unexpected aligned array store in x86 {lane} {operation} leaf",
            )
        c.forbid_pattern(
            r"flyology_simd__(backends__scalar__|wide__)?(load|store)(_unaligned|_aligned)?",
            leaf,
            f"portable, Scalar, or Wide helper in x86 {lane} {operation} leaf",
        )

    for lane, operation, suffix, _shape, x86_shape in rows(
        "float_binary_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"float-binary-leaf-{lane}-{operation}.txt"
        if operation in {"add", "subtract", "multiply", "divide"}:
            c.extract_leaf_or_probe(
                f"flyology_simd__backends__native__{operation}{symbol_suffix}",
                t / "native.txt",
                f"float_binary_codegen_probe__{lane}_{operation}",
                t / "float-binary-probe.txt",
                leaf,
            )
            instruction = {
                "add": "add",
                "subtract": "sub",
                "multiply": "mul",
                "divide": "div",
            }[operation] + x86_shape
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){instruction}[[:space:]]",
                1,
                leaf,
                f"exact SSE2 {lane} {operation} leaf",
            )
        else:
            lanes = 4 if lane == "f32" else 2
            c.extract_symbol(
                f"flyology_simd__backends__native__native_{operation}_{lane}x{lanes}",
                t / "native.txt",
                leaf,
            )
            counts = (
                (
                    ("pcmpgtd", 5, "ordering"),
                    ("pcmpeqd", 10, "classification"),
                    ("pand", 11, "masks"),
                    ("pandn", 7, "masked selections"),
                    ("por", 7, "merges"),
                    ("pxor", 2, "keys"),
                )
                if lane == "f32"
                else (
                    ("pcmpgtd", 10, "ordering"),
                    ("pcmpeqd", 20, "classification"),
                    ("pand", 16, "masks"),
                    ("pandn", 7, "masked selections"),
                    ("por", 12, "merges"),
                    ("pxor", 12, "keys"),
                    ("pshufd", 21, "64-bit mask replication"),
                )
            )
            for mnemonic, count, description in counts:
                c.require_leaf_instruction(
                    rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                    count,
                    leaf,
                    f"exact SSE2 {description} in {lane} {operation} leaf",
                )
        c.forbid_pattern(
            r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in {lane} {operation} leaf",
        )


def check_construction_masks_float_reductions(c: Checker) -> None:
    t = c.temporary
    output = t / "construction-splat-u8.txt"
    c.extract_symbol(
        "construction_codegen_probe__splat_u8", t / "construction-probe.txt", output
    )
    c.require_pattern(
        r"imul[a-z]*[[:space:]]+\$0x1010101",
        output,
        "inlined x86 U8x16 general-register byte broadcast",
    )
    c.require_pattern("pshufd", output, "inlined x86 U8x16 lane broadcast")
    c.forbid_pattern(
        r"(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__(backends__native__)?splat",
        output,
        "out-of-line U8x16 broadcast in the x86 public caller probe",
    )
    output = t / "construction-zero-u8.txt"
    c.extract_symbol("flyology_simd__backends__native__zero", t / "native.txt", output)
    c.require_pattern(
        r"xor(l)?[[:space:]]+%e(ax|dx)", output, "x86 U8x16 zero construction"
    )
    for lane in ("i8", "u16", "i16", "u32", "i32", "u64", "i64", "f32", "f64"):
        output = t / f"construction-zero-{lane}.txt"
        c.extract_symbol(
            f"construction_codegen_probe__zero_{lane}",
            t / "construction-probe.txt",
            output,
        )
        c.require_pattern(
            r"pxor|xor(l|q)?[[:space:]]",
            output,
            f"x86 vector zero construction for {lane}",
        )
    for lane in ("i8", "u16", "i16", "u32", "i32"):
        output = t / f"construction-splat-{lane}.txt"
        c.extract_symbol(
            f"construction_codegen_probe__splat_{lane}",
            t / "construction-probe.txt",
            output,
        )
        c.require_pattern("pshufd", output, f"x86 packed lane broadcast for {lane}")
    for lane in ("u64", "i64", "f64"):
        output = t / f"construction-splat-{lane}.txt"
        c.extract_symbol(
            f"construction_codegen_probe__splat_{lane}",
            t / "construction-probe.txt",
            output,
        )
        c.require_pattern(
            r"punpcklqdq|unpcklpd", output, f"x86 64-bit lane broadcast for {lane}"
        )
    output = t / "construction-splat-f32.txt"
    c.extract_symbol(
        "construction_codegen_probe__splat_f32", t / "construction-probe.txt", output
    )
    c.require_pattern(r"shufps|pshufd", output, "x86 floating lane broadcast for f32")

    output = t / "horizontal-sum-u8x16.txt"
    c.extract_symbol(
        "flyology_simd__backends__native__horizontal_sum", t / "native.txt", output
    )
    for pattern, description in (
        (r"(^|[[:space:]])psadbw[[:space:]]", "SSE2 byte horizontal partial sums"),
        (r"(^|[[:space:]])movhlps[[:space:]]", "SSE2 upper partial-sum extraction"),
        (r"(^|[[:space:]])paddq[[:space:]]", "SSE2 exact partial-sum combination"),
    ):
        c.require_pattern(pattern, output, description)
    c.forbid_pattern(
        "flyology_simd__horizontal_sum", output, "portable x86 Horizontal_Sum call"
    )
    for suffix in ("", "__2", "__3", "__4"):
        pop, first, last = (
            t / f"population_count{suffix}.txt",
            t / f"first_true{suffix}.txt",
            t / f"last_true{suffix}.txt",
        )
        for symbol, out in (
            ("population_count", pop),
            ("first_true", first),
            ("last_true", last),
        ):
            c.extract_symbol(
                f"flyology_simd__backends__native__{symbol}{suffix}",
                t / "native.txt",
                out,
            )
        c.require_pattern(
            r"(^|[[:space:]])bsf(l)?([[:space:]]|$)", first, "x86 First_True bit scan"
        )
        c.require_pattern(
            r"(^|[[:space:]])bsr(l)?([[:space:]]|$)", last, "x86 Last_True bit scan"
        )
        for constant, description in (
            ("0x55555555", "x86 Population_Count alternating-bit mask"),
            ("0x33333333", "x86 Population_Count two-bit mask"),
            ("0x1010101", "x86 Population_Count byte-sum multiplier"),
        ):
            c.require_pattern(constant, pop, description)
        c.forbid_pattern(
            r"(^|[[:space:]])popcnt", pop, "POPCNT dependency in SSE2 Population_Count"
        )
        c.forbid_pattern(
            r"flyology_simd__first_true|flyology_simd__last_true",
            first,
            "portable x86 mask-position call",
        )
        c.forbid_pattern(
            r"flyology_simd__first_true|flyology_simd__last_true",
            last,
            "portable x86 mask-position call",
        )
        c.forbid_pattern(
            "flyology_simd__population_count", pop, "portable x86 population-count call"
        )
    for vector, mnemonic, count in (("f32x4", "addss", 4), ("f64x2", "addsd", 2)):
        output = t / f"reduce-add-{vector}.txt"
        c.extract_symbol(f"native_reduce_add_{vector}", t / "native.txt", output)
        c.require_count(
            mnemonic,
            count,
            output,
            f"{count} ordered scalar SSE2 additions in {vector.upper()} Reduce_Add",
        )
        c.require_pattern(
            r"pxor[[:space:]]+%xmm([0-9]+),[[:space:]]*%xmm\1",
            output,
            f"positive-zero accumulator in reduce-add-{vector}",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])call[[:space:]]|flyology_simd__reduce_add",
            output,
            f"out-of-line or portable reduction in reduce-add-{vector}",
        )

    extrema = (
        ("native_min_number_f32x4", "min-number-f32x4", "f32", 0),
        ("native_max_number_f32x4", "max-number-f32x4", "f32", 0),
        ("native_min_number_f64x2", "min-number-f64x2", "f64", 0),
        ("native_max_number_f64x2", "max-number-f64x2", "f64", 0),
        ("native_reduce_min_number_f32x4", "reduce-min-number-f32x4", "f32", 3),
        ("native_reduce_max_number_f32x4", "reduce-max-number-f32x4", "f32", 3),
        ("native_reduce_min_number_f64x2", "reduce-min-number-f64x2", "f64", 1),
        ("native_reduce_max_number_f64x2", "reduce-max-number-f64x2", "f64", 1),
    )
    for symbol, name, kind, steps in extrema:
        output = t / f"{name}.txt"
        c.extract_symbol(symbol, t / "native.txt", output)
        for pattern, description in (
            (r"(^|[[:space:]])pcmpgtd[[:space:]]", "integer SSE2 ordering"),
            (r"(^|[[:space:]])pcmpeqd[[:space:]]", "integer SSE2 NaN classification"),
            (r"(^|[[:space:]])pandn[[:space:]]", "SSE2 masked selection"),
            (r"(^|[[:space:]])por[[:space:]]", "SSE2 selected-value merge"),
            (
                r"(^|[[:space:]])pxor[[:space:]]",
                "SSE2 sortable-key or quiet-bit construction",
            ),
            (
                r"(^|[[:space:]])ps(ra|rl|ll)(d|q)[[:space:]]",
                "SSE2 classification and sortable-key shifts",
            ),
        ):
            c.require_pattern(pattern, output, f"{description} in {name}")
        c.forbid_pattern(
            r"(^|[[:space:]])call[[:space:]]|flyology_simd__(min_number|max_number|reduce_min_number|reduce_max_number)",
            output,
            f"portable or out-of-line helper in {name}",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])(min|max)(ps|pd|ss|sd)[[:space:]]|(^|[[:space:]])cmp(unord|lt|le|eq)(ps|pd|ss|sd)[[:space:]]",
            output,
            f"floating comparison or bare min/max in {name}",
        )
        if kind == "f64":
            c.require_pattern(
                r"(^|[[:space:]])pshufd[[:space:]]",
                output,
                f"64-bit dword-mask replication in {name}",
            )
        if steps:
            c.require_count(
                r"(^|[[:space:]])psrldq[[:space:]]",
                steps,
                output,
                f"ascending lane advances in {name}",
            )

    wide_leafs = (
        ("reduce_add", "wide-f32-reduce-add-leaf"),
        ("reduce_min_number", "wide-f32-reduce-min_number-leaf"),
        ("reduce_max_number", "wide-f32-reduce-max_number-leaf"),
        ("reduce_add__2", "wide-f64-reduce-add-leaf"),
        ("reduce_min_number__2", "wide-f64-reduce-min_number-leaf"),
        ("reduce_max_number__2", "wide-f64-reduce-max_number-leaf"),
    )
    for symbol, name in wide_leafs:
        output = t / f"{name}.txt"
        c.extract_symbol(
            f"flyology_simd__wide__float_reduce_selected_leaf__{symbol}",
            t / "wide-float-reduction-leaf.txt",
            output,
        )
        c.forbid_pattern(
            r"(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__wide__reduce_",
            output,
            f"portable or out-of-line helper in {name}",
        )
    c.require_count(
        r"(^|[[:space:]])addss[[:space:]]",
        8,
        t / "wide-f32-reduce-add-leaf.txt",
        "eight ordered SSE2 binary32 additions in Wide Reduce_Add",
    )
    c.require_count(
        r"(^|[[:space:]])addsd[[:space:]]",
        4,
        t / "wide-f64-reduce-add-leaf.txt",
        "four ordered SSE2 binary64 additions in Wide Reduce_Add",
    )
    c.require_count(
        r"(^|[[:space:]])pxor[[:space:]].*xmm0.*xmm0",
        1,
        t / "wide-f32-reduce-add-leaf.txt",
        "positive-zero binary32 accumulator in Wide Reduce_Add",
    )
    c.require_count(
        r"(^|[[:space:]])pxor[[:space:]].*xmm0.*xmm0",
        1,
        t / "wide-f64-reduce-add-leaf.txt",
        "positive-zero binary64 accumulator in Wide Reduce_Add",
    )
    for kind, operation, ordering, classes, masked, merges in (
        ("f32", "min_number", 35, 70, 49, 49),
        ("f32", "max_number", 35, 70, 49, 49),
        ("f64", "min_number", 30, 60, 21, 36),
        ("f64", "max_number", 30, 60, 21, 36),
    ):
        leaf = t / f"wide-{kind}-reduce-{operation}-leaf.txt"
        for mnemonic, count, description in (
            ("pcmpgtd", ordering, "integer SSE2 ordering for every step"),
            ("pcmpeqd", classes, "integer SSE2 NaN classification for every step"),
            ("pandn", masked, "SSE2 masked selection for every step"),
            ("por", merges, "SSE2 selected-value merge for every step"),
        ):
            c.require_count(
                rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                count,
                leaf,
                f"{description} in Wide {kind} {operation}",
            )
        c.forbid_pattern(
            r"(^|[[:space:]])(min|max)(ps|pd|ss|sd)[[:space:]]|(^|[[:space:]])cmp(unord|lt|le|eq)(ps|pd|ss|sd)[[:space:]]",
            leaf,
            f"floating compare or bare min/max in Wide {kind} {operation}",
        )
    for symbol, description in (
        ("reduce_add$", "F32-Reduce_Add"),
        ("reduce_min_number$", "F32-Reduce_Min_Number"),
        ("reduce_max_number$", "F32-Reduce_Max_Number"),
        ("reduce_add__2$", "F64-Reduce_Add"),
        ("reduce_min_number__2$", "F64-Reduce_Min_Number"),
        ("reduce_max_number__2$", "F64-Reduce_Max_Number"),
    ):
        c.require_count(
            f"flyology_simd__wide__float_reduce_selected_leaf__{symbol}",
            1,
            t / "wide-float-reduction-undefined.txt",
            f"one selected x86 floating-reduction leaf call for {description}",
        )
    c.forbid_pattern(
        r"flyology_simd__wide__reduce_|flyology_simd__wide__native__reduce_",
        t / "wide-float-reduction-undefined.txt",
        "portable or public Native Wide floating reduction retained on x86-64",
    )
    c.forbid_pattern(
        r"flyology_simd__wide__reduce_|flyology_simd__wide__native__reduce_",
        t / "wide-float-reduction-leaf-undefined.txt",
        "portable or public Native call retained in the x86 floating-reduction leaf",
    )
    c.forbid_pattern(
        "flyology_simd__wide__reduce_",
        t / "wide-float-reduction-undefined.txt",
        "portable Wide floating reduction retained on x86-64",
    )
    c.forbid_pattern(
        "flyology_simd__wide__native__reduce_",
        t / "wide-float-reduction-probe.txt",
        "Wide.Native floating-reduction dispatcher retained on x86-64",
    )


def check_u8_and_integer_reductions(c: Checker) -> None:
    t = c.temporary
    combined = c.native_and_probes()
    for pattern, description in (
        ("pcmpeqb", "SSE2 byte comparison"),
        ("pcmpeqw", "SSE2 16-bit comparison"),
        ("pcmpeqd", "SSE2 32/64-bit comparison composition"),
        ("pmovmskb", "SSE2 compact mask extraction"),
        ("paddb", "SSE2 wrapping byte add"),
        ("paddw", "SSE2 wrapping 16-bit add"),
        ("paddd", "SSE2 wrapping 32-bit add"),
        ("paddq", "SSE2 wrapping 64-bit add"),
    ):
        c.require_pattern(pattern, combined, description)
    operations = (
        ("add_wrap", "paddb", "add_wrap|u8_add_wrap"),
        ("subtract_wrap", "psubb", "subtract_wrap|u8_subtract_wrap"),
        ("multiply_wrap", "pmullw", "multiply_wrap|native_multiply_wrap_u8x16"),
        ("add_saturate", "paddusb", "add_saturate|u8_add_saturate"),
        ("subtract_saturate", "psubusb", "subtract_saturate|u8_subtract_saturate"),
        ("bitwise_and", "pand", "bitwise_and|u8_and"),
        ("bitwise_or", "por", "bitwise_or|u8_or"),
        ("bitwise_xor", "pxor", "bitwise_xor|u8_xor"),
        ("bitwise_not", "pcmpeqd", "bitwise_not|u8_not"),
        ("equal", "pcmpeqb", "equal|equal_mask"),
        ("less_than", "pcmpgtb", "less_than|greater_mask"),
        ("less_equal", "pcmpgtb", "less_equal|greater_mask"),
        ("greater_than", "pcmpgtb", "greater_than|greater_mask"),
        ("greater_equal", "pcmpgtb", "greater_equal|greater_mask"),
        ("select_value", "pandn", "select_value"),
        ("min", "pminub", "min"),
        ("max", "pmaxub", "max"),
        ("reduce_add_wrap", "paddb", "reduce_add_wrap|native_reduce_add_wrap_u8x16"),
        ("reduce_min", "pminub", "reduce_min|native_reduce_min_u8x16"),
        ("reduce_max", "pmaxub", "reduce_max|native_reduce_max_u8x16"),
        ("reverse_bytes", "pshufd", "reverse_bytes|u8_reverse"),
        ("reverse_lanes", "pshufd", "reverse_lanes|u8_reverse"),
        ("interleave_low", "punpcklbw", "interleave_low|u8_interleave_low"),
        ("interleave_high", "punpckhbw", "interleave_high|u8_interleave_high"),
        ("deinterleave_even", "packuswb", "deinterleave_even|u8_deinterleave_even"),
        ("deinterleave_odd", "packuswb", "deinterleave_odd|u8_deinterleave_odd"),
    )
    for operation, pattern, symbols in operations:
        caller, selected = (
            t / f"u8-value-{operation}.txt",
            t / f"u8-native-{operation}.txt",
        )
        c.bind_u8_selected_operation(
            caller,
            pattern,
            symbols,
            t / "native.txt",
            selected,
            f"x86-64 U8 {operation} caller",
        )
        c.require_exact_u8_operation(
            caller, selected, pattern, operation, f"x86-64 U8 {operation}"
        )
    c.require_count(
        r"(^|[[:space:]])pmullw[[:space:]]",
        2,
        t / "u8-native-multiply_wrap.txt",
        "two widened products in x86-64 U8 Multiply_Wrap",
    )
    c.require_count(
        r"(^|[[:space:]])pand[[:space:]]",
        2,
        t / "u8-native-multiply_wrap.txt",
        "two low-byte masks in x86-64 U8 Multiply_Wrap",
    )
    c.require_pattern(
        r"(^|[[:space:]])packuswb[[:space:]]",
        t / "u8-native-multiply_wrap.txt",
        "byte repacking in x86-64 U8 Multiply_Wrap",
    )
    for operation in (
        "equal",
        "less_than",
        "less_equal",
        "greater_than",
        "greater_equal",
    ):
        c.require_pattern(
            r"(^|[[:space:]])pmovmskb[[:space:]]",
            t / f"u8-native-{operation}.txt",
            f"compact mask extraction in x86-64 U8 {operation}",
        )
    for operation in ("less_than", "less_equal", "greater_than", "greater_equal"):
        c.require_pattern(
            r"(^|[[:space:]])pcmpgtb[[:space:]]",
            t / f"u8-native-{operation}.txt",
            f"unsigned ordering comparison in x86-64 U8 {operation}",
        )
    for mnemonic, description in (
        ("punpcklbw", "byte mask expansion"),
        ("punpcklwd", "word mask expansion"),
        ("punpckldq", "dword mask expansion"),
        ("pandn", "false-lane masking"),
        ("por", "selected-lane merge"),
    ):
        c.require_pattern(
            rf"(^|[[:space:]]){mnemonic}[[:space:]]",
            t / "u8-native-select_value.txt",
            f"{description} in x86-64 U8 Select_Value",
        )
    for operation in ("reverse_bytes", "reverse_lanes"):
        for mnemonic, description in (
            ("psrlw", "right byte shift"),
            ("psllw", "left byte shift"),
            ("pshufd", "dword reversal"),
        ):
            c.require_pattern(
                rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                t / f"u8-native-{operation}.txt",
                f"{description} in x86-64 U8 {operation}",
            )
    c.require_count(
        r"(^|[[:space:]])pand[[:space:]]",
        2,
        t / "u8-native-deinterleave_even.txt",
        "two even-byte masks in x86-64 U8 Deinterleave_Even",
    )
    c.require_count(
        r"(^|[[:space:]])psrlw[[:space:]]",
        2,
        t / "u8-native-deinterleave_odd.txt",
        "two odd-byte shifts in x86-64 U8 Deinterleave_Odd",
    )
    _check_integer_reductions(c)


def _check_integer_reductions(c: Checker) -> None:
    t = c.temporary
    cases = (
        ("u8", "", "paddb", 4, "byte_unsigned"),
        ("i8", "__2", "paddb", 4, "compare_select"),
        ("u16", "__3", "paddw", 3, "compare_select"),
        ("i16", "__4", "paddw", 3, "word_signed"),
        ("u32", "__5", "paddd", 2, "compare_select"),
        ("i32", "__6", "paddd", 2, "compare_select"),
        ("u64", "__7", "paddq", 1, "compare_select"),
        ("i64", "__8", "paddq", 1, "compare_select"),
    )
    for lane, suffix, add, stages, extreme in cases:
        outputs = {}
        for operation in ("reduce_add_wrap", "reduce_min", "reduce_max"):
            output = t / f"reduction_{lane}_{operation}.txt"
            outputs[operation] = output
            c.extract_symbol(
                f"flyology_simd__backends__native__{operation}{suffix}",
                t / "native.txt",
                output,
            )
            c.forbid_pattern(
                r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]|flyology_simd__reduce_",
                output,
                f"portable or out-of-line helper in {lane} {operation}",
            )
        c.require_count(
            rf"(^|[[:space:]]){add}[[:space:]]",
            stages,
            outputs["reduce_add_wrap"],
            f"complete SSE2 {lane} wrapping-add reduction tree",
        )
        if extreme == "byte_unsigned":
            c.require_count(
                r"(^|[[:space:]])pminub[[:space:]]",
                stages,
                outputs["reduce_min"],
                f"complete SSE2 {lane} minimum reduction tree",
            )
            c.require_count(
                r"(^|[[:space:]])pmaxub[[:space:]]",
                stages,
                outputs["reduce_max"],
                f"complete SSE2 {lane} maximum reduction tree",
            )
        elif extreme == "word_signed":
            c.require_count(
                r"(^|[[:space:]])pminsw[[:space:]]",
                stages,
                outputs["reduce_min"],
                f"complete SSE2 {lane} minimum reduction tree",
            )
            c.require_count(
                r"(^|[[:space:]])pmaxsw[[:space:]]",
                stages,
                outputs["reduce_max"],
                f"complete SSE2 {lane} maximum reduction tree",
            )
        else:
            for operation in ("reduce_min", "reduce_max"):
                output = outputs[operation]
                c.require_pattern(
                    r"(^|[[:space:]])pcmpgt(b|w|d)[[:space:]]",
                    output,
                    f"SSE2 comparison in {lane} {operation} reduction",
                )
                c.require_count(
                    r"(^|[[:space:]])pandn[[:space:]]",
                    stages,
                    output,
                    f"complete SSE2 {lane} {operation} selection tree",
                )
                if lane not in {"u64", "i64"}:
                    c.require_count(
                        r"(^|[[:space:]])pand[[:space:]]",
                        stages,
                        output,
                        f"complete SSE2 {lane} {operation} true-value selection tree",
                    )
                    c.require_count(
                        r"(^|[[:space:]])por[[:space:]]",
                        stages + 2 if lane == "i8" else stages,
                        output,
                        f"complete SSE2 {lane} {operation} shuffle and selected-value merge tree",
                    )
        for operation, output in outputs.items():
            if lane in {"u8", "i8", "u32", "i32"}:
                c.require_pattern(
                    r"(^|[[:space:]])movd[[:space:]]",
                    output,
                    f"SSE2 {lane} {operation} result extraction",
                )
                if lane in {"u8", "i8"}:
                    c.require_at_least(
                        r"(^|[[:space:]])(movd|mov(b|zbl)?)[[:space:]]",
                        1,
                        output,
                        f"SSE2 {lane} {operation} byte result transfer",
                    )
            elif lane in {"u16", "i16"}:
                c.require_pattern(
                    r"(^|[[:space:]])pextrw[[:space:]]",
                    output,
                    f"SSE2 {lane} {operation} result extraction",
                )
                c.forbid_pattern(
                    r"(^|[[:space:]])mov(w)?[[:space:]]+%(ax|bx|cx|dx|si|di|r(8|9|10|11|12|13|14|15)w),[[:space:]]*-?(0x)?[0-9a-f]*\(",
                    output,
                    f"SSE2 {lane} {operation} word result store",
                )
            else:
                c.require_pattern(
                    r"(^|[[:space:]])movq[[:space:]]",
                    output,
                    f"SSE2 {lane} {operation} result extraction",
                )
        for operation in ("reduce_min", "reduce_max"):
            output = outputs[operation]
            if lane == "i8":
                c.require_count(
                    r"(^|[[:space:]])pcmpgtb[[:space:]]",
                    stages,
                    output,
                    f"complete signed-byte comparison tree in {lane} {operation}",
                )
            elif lane == "u16":
                c.require_count(
                    r"(^|[[:space:]])pcmpgtw[[:space:]]",
                    stages,
                    output,
                    f"complete unsigned-word comparison tree in {lane} {operation}",
                )
                c.require_count(
                    r"(^|[[:space:]])pxor[[:space:]]",
                    2 * stages,
                    output,
                    f"sign-bit bias in every {lane} {operation} comparison stage",
                )
            elif lane in {"u32", "i32"}:
                c.require_count(
                    r"(^|[[:space:]])pcmpgtd[[:space:]]",
                    stages,
                    output,
                    f"complete dword comparison tree in {lane} {operation}",
                )
                if lane == "u32":
                    c.require_count(
                        r"(^|[[:space:]])pxor[[:space:]]",
                        2 * stages,
                        output,
                        f"sign-bit bias in every {lane} {operation} comparison stage",
                    )
            elif lane in {"u64", "i64"}:
                c.require_count(
                    r"(^|[[:space:]])pcmpgtd[[:space:]]",
                    2 * stages,
                    output,
                    f"high- and low-dword comparisons in {lane} {operation}",
                )
                c.require_count(
                    r"(^|[[:space:]])pcmpeqd[[:space:]]",
                    stages,
                    output,
                    f"high-dword equality gate in {lane} {operation}",
                )
                c.require_count(
                    r"(^|[[:space:]])pxor[[:space:]]",
                    (4 if lane == "u64" else 2) * stages,
                    output,
                    f"unsigned low-dword comparison bias in {lane} {operation}",
                )
                c.require_count(
                    r"(^|[[:space:]])pand[[:space:]]",
                    2 * stages,
                    output,
                    f"equality-gated low comparison and selected-value mask in {lane} {operation}",
                )
                c.require_count(
                    r"(^|[[:space:]])por[[:space:]]",
                    2 * stages,
                    output,
                    f"lexicographic comparison and selected-value merge in {lane} {operation}",
                )


def check_conversions(c: Checker) -> None:
    t = c.temporary
    basic = (
        ("widen_low", "u8x16", "u16x8", "punpcklbw"),
        ("widen_high", "u8x16", "u16x8", "punpckhbw"),
        ("widen_low__2", "i8x16", "i16x8", "pcmpgtb,punpcklbw"),
        ("widen_high__2", "i8x16", "i16x8", "pcmpgtb,punpckhbw"),
        ("widen_low__3", "u16x8", "u32x4", "punpcklwd"),
        ("widen_high__3", "u16x8", "u32x4", "punpckhwd"),
        ("widen_low__4", "i16x8", "i32x4", "pcmpgtw,punpcklwd"),
        ("widen_high__4", "i16x8", "i32x4", "pcmpgtw,punpckhwd"),
        ("widen_low__5", "u32x4", "u64x2", "punpckldq"),
        ("widen_high__5", "u32x4", "u64x2", "punpckhdq"),
        ("widen_low__6", "i32x4", "i64x2", "pcmpgtd,punpckldq"),
        ("widen_high__6", "i32x4", "i64x2", "pcmpgtd,punpckhdq"),
        ("widen_low__7", "f32x4", "f64x2", "cvtps2pd"),
        ("widen_high__7", "f32x4", "f64x2", "pshufd,cvtps2pd"),
        ("narrow_truncate", "u16x8", "u8x16", "packuswb"),
        ("narrow_saturate", "u16x8", "u8x16", "psrlw,pcmpeqw,pandn,packuswb"),
        ("narrow_truncate__2", "i16x8", "i8x16", "packuswb"),
        ("narrow_saturate__2", "i16x8", "i8x16", "packsswb"),
        ("narrow_truncate__3", "u32x4", "u16x8", "pshuflw,pshufhw,pshufd,punpcklqdq"),
        ("narrow_saturate__3", "u32x4", "u16x8", "psrld,pcmpeqd,pandn,punpcklqdq"),
        ("narrow_truncate__4", "i32x4", "i16x8", "pshuflw,pshufhw,pshufd,punpcklqdq"),
        ("narrow_saturate__4", "i32x4", "i16x8", "packssdw"),
        ("narrow_truncate__5", "u64x2", "u32x4", "pshufd,punpcklqdq"),
        (
            "narrow_saturate__5",
            "u64x2",
            "u32x4",
            "psrlq,pcmpeqd,pandn,pshufd,punpcklqdq",
        ),
        ("narrow_truncate__6", "i64x2", "i32x4", "pshufd,punpcklqdq"),
        (
            "narrow_saturate__6",
            "i64x2",
            "i32x4",
            "psrad,pcmpeqd,pandn,pshufd,punpcklqdq",
        ),
        ("narrow_saturate__7", "i16x8", "u8x16", "packuswb"),
        ("narrow_saturate__8", "i32x4", "u16x8", "pcmpgtd,pandn,pshufd,punpcklqdq"),
        (
            "narrow_saturate__9",
            "i64x2",
            "u32x4",
            "psrad,pcmpeqd,pandn,pshufd,punpcklqdq",
        ),
        ("narrow_round", "f64x2", "f32x4", "cvtpd2ps,movlhps"),
    )
    for operation, source, target, instructions in basic:
        output = t / f"conversion_{operation}_{source}_{target}.txt"
        c.extract_symbol(
            f"flyology_simd__backends__native__{operation}", t / "native.txt", output
        )
        for instruction in instructions.split(","):
            c.require_pattern(
                instruction, output, f"SSE2 {operation} {source} to {target} lowering"
            )
        c.forbid_pattern(
            r"(^|[[:space:]])call|flyology_simd__(widen|narrow)",
            output,
            f"scalar or out-of-line helper in {operation} {source} to {target}",
        )
    c.require_count(
        r"(^|[[:space:]])cvtpd2ps[[:space:]]",
        2,
        t / "conversion_narrow_round_f64x2_f32x4.txt",
        "two SSE2 binary64-to-binary32 conversions in Narrow_Round",
    )
    packed = (
        ("convert_round", "i32x4", "f32x4", "cvtdq2ps", 1, "cvtdq2ps"),
        (
            "convert_round__2",
            "u32x4",
            "f32x4",
            "cvtdq2ps",
            2,
            "pcmpgtd,psrld,addps,pandn",
        ),
        (
            "convert_truncate_saturate",
            "f32x4",
            "i32x4",
            "cvttps2dq",
            1,
            "cmpleps,cmpunordps,pandn",
        ),
        (
            "convert_truncate_saturate__2",
            "f32x4",
            "u32x4",
            "cvttps2dq",
            2,
            "cmpleps,cmpltps,subps,paddd,pandn",
        ),
    )
    for symbol, source, target, convert, count, required in packed:
        output = t / f"conversion_{symbol}_{source}_{target}.txt"
        c.extract_symbol(
            f"flyology_simd__backends__native__{symbol}", t / "native.txt", output
        )
        c.require_count(
            rf"(^|[[:space:]]){convert}[[:space:]]",
            count,
            output,
            f"complete packed conversion in {source} to {target} {symbol}",
        )
        for instruction in required.split(","):
            c.require_pattern(
                f"{instruction}[[:space:]]",
                output,
                f"SSE2 {instruction} in {source} to {target} {symbol}",
            )
        c.forbid_pattern(
            r"(^|[[:space:]])call[[:space:]]|flyology_simd__convert_|(ld|st)mxcsr",
            output,
            f"scalar helper or floating-control write in {source} to {target} {symbol}",
        )
    scalar = (
        ("convert_round__3", "i64x2", "f64x2", "cvtsi2sd", 2, "movq,psrldq,unpcklpd"),
        (
            "convert_round__4",
            "u64x2",
            "f64x2",
            "cvtsi2sd",
            4,
            r"test(q)?,shr(q)?,and(q)?,or(q)?,addsd,psrldq,unpcklpd",
        ),
        (
            "convert_truncate_saturate__3",
            "f64x2",
            "i64x2",
            "cvttsd2si",
            2,
            r"movabs(q)?,and(q)?,cmp(q)?,psrldq,punpcklqdq",
        ),
        (
            "convert_truncate_saturate__4",
            "f64x2",
            "u64x2",
            "cvttsd2si",
            4,
            r"test(q)?,cmp(q)?,subsd,or(q)?,psrldq,punpcklqdq",
        ),
    )
    for operation, source, target, convert, count, required in scalar:
        output = t / f"conversion_{operation}_{source}_{target}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}",
            t / "native.txt",
            c.conversion_probe_symbol(source, target, operation),
            t / "integer-conversion-probe.txt",
            output,
        )
        c.require_count(
            rf"(^|[[:space:]]){convert}[[:space:]]",
            count,
            output,
            f"{count} conversion instruction sites in {source} to {target} {operation}",
        )
        for instruction in required.split(","):
            c.require_pattern(
                f"{instruction}[[:space:]]",
                output,
                f"x86-64 {instruction} in {source} to {target} {operation}",
            )
        c.forbid_pattern(
            r"(^|[[:space:]])call[[:space:]]|flyology_simd__convert_|(ld|st)mxcsr",
            output,
            f"portable helper or floating-control write in {source} to {target} {operation}",
        )
    saturations = (
        ("", "i8x16", "u8x16", "pcmpgtb", "none"),
        ("__2", "u8x16", "i8x16", "pcmpgtb", "psrlw"),
        ("__3", "i16x8", "u16x8", "pcmpgtw", "none"),
        ("__4", "u16x8", "i16x8", "pcmpgtw", "psrlw"),
        ("__5", "i32x4", "u32x4", "pcmpgtd", "none"),
        ("__6", "u32x4", "i32x4", "pcmpgtd", "psrld"),
        ("__7", "i64x2", "u64x2", "psrad", "none"),
        ("__8", "u64x2", "i64x2", "psrad", "psrlq"),
    )
    for suffix, source, target, compare, shift in saturations:
        operation = f"convert_saturate{suffix}"
        output = t / f"conversion_{operation}_{source}_{target}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}",
            t / "native.txt",
            c.conversion_probe_symbol(source, target, "convert_saturate"),
            t / "integer-conversion-probe.txt",
            output,
        )
        c.require_pattern(
            compare,
            output,
            f"SSE2 sign-mask derivation in {source} to {target} Convert_Saturate",
        )
        c.require_pattern(
            r"(^|[[:space:]])pandn[[:space:]]",
            output,
            f"SSE2 clamped selection in {source} to {target} Convert_Saturate",
        )
        if shift != "none":
            c.require_pattern(
                shift,
                output,
                f"SSE2 signed-maximum construction in {source} to {target} Convert_Saturate",
            )
            c.require_pattern(
                r"(^|[[:space:]])por[[:space:]]",
                output,
                f"SSE2 signed-maximum selection in {source} to {target} Convert_Saturate",
            )
        c.forbid_pattern(
            r"(^|[[:space:]])call|flyology_simd__convert_saturate",
            output,
            f"scalar or out-of-line helper in {source} to {target} Convert_Saturate",
        )
    for kind, operation, _source, _target, suffix, _arity in rows(
        "integer_conversion_codegen_cases.txt"
    ):
        selected = operation if suffix == "none" else f"{operation}__{suffix}"
        leaf = t / f"x86_integer_conversion_{kind}_{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{selected}",
            t / "native.txt",
            f"integer_conversion_codegen_probe__{kind}_{operation}",
            t / "integer-conversion-probe.txt",
            leaf,
        )
        c.require_count(
            STORE, 0, leaf, f"no result store in register-operand {kind} {operation}"
        )
        c.forbid_pattern(
            r"(^|[[:space:]])(callq?|jmpq?|j(a|ae|b|be|c|e|g|ge|l|le|na|nae|nb|nbe|nc|ne|ng|nge|nl|nle|no|np|ns|nz|o|p|pe|po|s|z))[[:space:]]",
            leaf,
            f"branch or helper in {kind} {operation} leaf",
        )


def check_table_permute_and_shifts(c: Checker) -> None:
    t = c.temporary
    combined = c.native_and_probes()
    for pattern, description in (
        (r"psub(b|w|d|q)", "SSE2 wrapping subtraction family"),
        ("paddusb", "SSE2 saturating byte add"),
        ("paddusw", "SSE2 unsigned saturating 16-bit add"),
        ("paddsw", "SSE2 signed saturating 16-bit add"),
        ("psubusb", "SSE2 saturating byte subtract"),
        ("pmullw", "SSE2 8/16-bit multiplication composition"),
        ("pmuludq", "SSE2 32/64-bit multiplication composition"),
        (r"pcmpgt(b|w|d)", "SSE2 ordered integer comparisons"),
        (r"psll(w|d|q)", "SSE2 logical left shifts"),
        (r"psrl(w|d|q)", "SSE2 logical right shifts"),
        (r"psra(w|d)", "SSE2 arithmetic right shifts"),
    ):
        c.require_pattern(pattern, combined, description)
    output = t / "table_lookup.txt"
    c.extract_leaf_or_probe(
        "native_table_lookup_u8x16",
        t / "native.txt",
        "table_lookup_codegen_probe__lookup",
        t / "table-lookup-probe.txt",
        output,
    )
    table_counts = (
        ("pcmpeqb", 16, "sixteen SSE2 table-index comparisons"),
        ("punpcklbw", 16, "sixteen SSE2 table-byte broadcasts"),
        ("punpcklwd", 16, "sixteen SSE2 table-byte word broadcasts"),
        ("pshufd", 16, "sixteen SSE2 table-byte dword broadcasts"),
        ("pand", 16, "sixteen SSE2 lookup masks"),
        ("por", 16, "sixteen SSE2 lookup merges"),
        ("paddb", 16, "sixteen SSE2 selector increments"),
        ("pxor", 2, "SSE2 result and selector zero initialization"),
        ("pcmpeqd", 1, "SSE2 all-ones increment construction"),
        ("psrlw", 1, "SSE2 one-bit increment construction"),
        ("packuswb", 1, "SSE2 byte increment construction"),
    )
    for mnemonic, count, description in table_counts:
        c.require_count(
            rf"(^|[[:space:]]){mnemonic}[[:space:]]", count, output, description
        )
    c.forbid_pattern(
        r"(^|[[:space:]])call[[:space:]]|flyology_simd__table_lookup",
        output,
        "portable or out-of-line x86-64 Table_Lookup helper",
    )
    shapes = (
        "u8x16",
        "i8x16",
        "u16x8",
        "i16x8",
        "u32x4",
        "i32x4",
        "f32x4",
        "u64x2",
        "i64x2",
        "f64x2",
    )
    for shape in shapes:
        lane = shape.split("x", 1)[0]
        for two, count in ((False, 16), (True, 32)):
            name = f"permute_{'2_' if two else ''}{lane}"
            output = t / f"{name}.txt"
            c.extract_symbol(
                f"native_permute_{'2_' if two else ''}{shape}", t / "native.txt", output
            )
            word = "thirty-two" if two else "sixteen"
            source = "two-source" if two else "one-source"
            for mnemonic, description in (
                ("pcmpeqb", "selector comparisons"),
                ("paddb", "selector increments"),
                ("punpcklbw", "punpcklbw stages"),
                ("punpcklwd", "punpcklwd stages"),
                ("pshufd", "pshufd stages"),
                ("pand", "pand stages"),
                ("por", "por stages"),
            ):
                c.require_count(
                    rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                    count,
                    output,
                    f"{word} SSE2 {description} in {lane} {source} permutation",
                )
            c.require_count(
                r"(^|[[:space:]])pxor[[:space:]]",
                2,
                output,
                f"SSE2 result and selector zero initialization in {lane} {source} permutation",
            )
            for mnemonic in ("pcmpeqd", "psrlw", "packuswb"):
                c.require_count(
                    rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                    1,
                    output,
                    f"SSE2 selector increment construction in {lane} {source} permutation",
                )
            c.forbid_pattern(
                r"(^|[[:space:]])call[[:space:]]|flyology_simd__permute_lanes",
                output,
                f"portable or out-of-line {lane} {source} permutation",
            )
    c.require_native_route(
        r"flyology_simd__backends__native__native_permute_[a-z0-9]+$",
        10,
        t / "permute-undefined.txt",
        t / "permute-probe.txt",
        "all ten one-source Native permutation leaves in caller probes",
    )
    c.require_native_route(
        r"flyology_simd__backends__native__native_permute_2_[a-z0-9]+$",
        10,
        t / "permute-undefined.txt",
        t / "permute-probe.txt",
        "all ten two-source Native permutation leaves in caller probes",
    )
    c.forbid_pattern(
        r"flyology_simd__backends__native__permute_lanes|flyology_simd__permute_lanes",
        t / "permute-undefined.txt",
        "Native dispatcher or portable permutation retained in x86 caller probes",
    )
    for shape in shapes:
        lane = shape.split("x", 1)[0]
        for operation in ("compress", "expand"):
            output = t / f"{lane}_{operation}.txt"
            c.extract_symbol(
                f"permute_codegen_probe__{lane}_{operation}",
                t / "permute-probe.txt",
                output,
            )
            c.require_route_or_inlined(
                f"flyology_simd__backends__native__native_permute_{shape}",
                output,
                f"matching SSE2 permutation leaf in {lane} {operation} caller",
            )
            c.forbid_pattern(
                r"flyology_simd__backends__native__(compress|expand)|flyology_simd__(compress|expand)",
                output,
                f"public Native or portable compact operation in {lane} {operation} caller",
            )
    c.forbid_pattern(
        r"flyology_simd__(compress|expand)",
        t / "native-undefined.txt",
        "portable compact operation retained in x86 Native object",
    )
    for direction, instruction in (("low", "psrldq"), ("high", "pslldq")):
        for lane in (
            "u8",
            "i8",
            "u16",
            "i16",
            "u32",
            "i32",
            "u64",
            "i64",
            "f32",
            "f64",
        ):
            output = t / f"slide-{lane}-{direction}.txt"
            c.extract_symbol(
                f"slide_codegen_probe__{lane}_{direction}",
                t / "slide-probe.txt",
                output,
            )
            c.require_pattern(
                rf"(^|[[:space:]]){instruction}[[:space:]]",
                output,
                f"SSE2 immediate lane movement in {lane} {direction} caller",
            )
            c.forbid_pattern(
                r"flyology_simd__(zero|slide_lanes_toward_(low|high))",
                output,
                f"portable zero or lane-slide call in {lane} {direction} caller",
            )
    logical = (
        ("shl", "u8x16", "psllw", "packuswb"),
        ("shr", "u8x16", "psrlw", "packuswb"),
        ("shl", "i8x16", "psllw", "packuswb"),
        ("shr", "i8x16", "psrlw", "packuswb"),
        ("shl", "u16x8", "psllw", None),
        ("shr", "u16x8", "psrlw", None),
        ("shl", "i16x8", "psllw", None),
        ("shr", "i16x8", "psrlw", None),
        ("shl", "u32x4", "pslld", None),
        ("shr", "u32x4", "psrld", None),
        ("shl", "i32x4", "pslld", None),
        ("shr", "i32x4", "psrld", None),
        ("shl", "u64x2", "psllq", None),
        ("shr", "u64x2", "psrlq", None),
        ("shl", "i64x2", "psllq", None),
        ("shr", "i64x2", "psrlq", None),
    )
    for operation, lane, instruction, secondary in logical:
        symbol = f"native_{operation}_{lane}"
        forbidden = r"(^|[[:space:]])call[[:space:]]|flyology_simd__(zero|shift_(left|right)_logical)"
        if lane == "u8x16":
            symbol = f"flyology_simd__backends__native__shift_{'left' if operation=='shl' else 'right'}_logical"
            forbidden = r"flyology_simd__(zero|shift_(left|right)_logical)"
        output = t / f"{operation}-{lane}.txt"
        c.extract_symbol(symbol, t / "native.txt", output)
        c.require_pattern(
            rf"(^|[[:space:]]){instruction}[[:space:]]",
            output,
            f"SSE2 {instruction} in {lane} logical shift",
        )
        if secondary:
            c.require_pattern(
                rf"(^|[[:space:]]){secondary}[[:space:]]",
                output,
                f"SSE2 byte repacking in {lane} logical shift",
            )
            for widening in ("pxor", "punpcklbw", "punpckhbw"):
                c.require_pattern(
                    rf"(^|[[:space:]]){widening}[[:space:]]",
                    output,
                    f"SSE2 byte widening step {widening} in {lane} logical shift",
                )
        c.forbid_pattern(
            forbidden, output, f"portable or out-of-line helper in {lane} logical shift"
        )
    for lane, instruction, secondary in (
        ("i8x16", "psraw", "packsswb"),
        ("i16x8", "psraw", None),
        ("i32x4", "psrad", None),
    ):
        output = t / f"{lane}-sar.txt"
        c.extract_symbol(f"native_sar_{lane}", t / "native.txt", output)
        c.require_pattern(
            rf"(^|[[:space:]]){instruction}[[:space:]]",
            output,
            f"inlined SSE2 arithmetic right shift for {lane}",
        )
        if secondary:
            c.require_pattern(
                rf"(^|[[:space:]]){secondary}[[:space:]]",
                output,
                f"SSE2 signed-byte repacking for {lane}",
            )
        c.forbid_pattern(
            r"(^|[[:space:]])call[[:space:]]|flyology_simd__shift_right_arithmetic",
            output,
            f"portable or out-of-line arithmetic right shift for {lane}",
        )
    for instruction in ("pxor", "punpcklbw", "punpckhbw", "psllw"):
        c.require_pattern(
            rf"(^|[[:space:]]){instruction}[[:space:]]",
            t / "i8x16-sar.txt",
            f"SSE2 signed-byte widening step {instruction} in I8x16 arithmetic right shift",
        )
    output = t / "sar-i64x2.txt"
    c.extract_symbol("native_sar_i64x2", t / "native.txt", output)
    for instruction in ("pshufd", "psrad", "psrlq", "pxor", "por"):
        c.require_pattern(
            rf"(^|[[:space:]]){instruction}[[:space:]]",
            output,
            f"SSE2 {instruction} in I64x2 Shift_Right_Arithmetic",
        )
    c.forbid_pattern(
        r"(^|[[:space:]])call[[:space:]]|flyology_simd__shift_right_arithmetic",
        output,
        "portable or out-of-line helper in I64x2 Shift_Right_Arithmetic",
    )
    for pattern, description in (
        ("pandn", "SSE2 mask selection"),
        (r"punpckl(bw|wd|dq|qdq)", "SSE2 interleave family"),
        (r"pshuf(d|lw|hw)", "SSE2 reverse/shuffle family"),
    ):
        c.require_pattern(pattern, combined, description)
    constants = (
        ("u8", "low", "psrldq", 1, "constant U8 slide toward low in caller"),
        ("u8", "high", "pslldq", 1, "constant U8 slide toward high in caller"),
        ("u16", "low", "psrldq", 2, "constant U16 lane scaling in caller"),
        ("u32", "low", "psrldq", 4, "constant U32 lane scaling in caller"),
        ("f32", "low", "psrldq", 4, "constant F32 slide toward low in caller"),
        ("f32", "high", "pslldq", 4, "constant F32 slide toward high in caller"),
        ("f64", "high", "pslldq", 8, "constant F64 lane scaling in caller"),
    )
    for lane, direction, mnemonic, amount, description in constants:
        output = t / f"probe_{lane}_{direction}.txt"
        c.extract_symbol(
            f"slide_codegen_probe__{lane}_toward_{direction}",
            t / "slide-probe.txt",
            output,
        )
        c.require_pattern(
            rf"{mnemonic}.*[$](0x)?0*{amount}([^[:xdigit:]]|$)", output, description
        )
    c.forbid_pattern(
        "flyology_simd__backends__native__slide_lanes",
        t / "slide-probe.txt",
        "lane-slide dispatcher call in constant-count probe",
    )
    for pattern, description in (
        ("addps", "SSE floating32 addition"),
        ("addpd", "SSE2 floating64 addition"),
        (r"mul(ps|pd)", "SSE/SSE2 floating multiplication"),
        (r"div(ps|pd)", "SSE/SSE2 floating division"),
        (r"cmp(unord|eq|lt|le)(ps|pd)", "SSE/SSE2 floating comparisons"),
        ("movdqu", "unaligned SSE2 load/store"),
        ("movdqa", "aligned SSE2 load/store"),
    ):
        c.require_pattern(pattern, combined, description)


def _collect_wide_outputs(c: Checker) -> None:
    t = c.temporary
    simple = (
        "u8_add",
        "f32_multiply",
        "f32_to_u32_bits",
        "u8_widen_low",
        "u16_narrow_saturate",
        "i32_to_f32",
        "u8_table_lookup",
        "u8_horizontal_sum",
        "u8_permute",
        "u16_permute_2",
        "f32_permute",
        "f64_permute_2",
        "u8_reverse",
        "u16_interleave_low",
        "f32_deinterleave_odd",
        "f64_slide_low_one",
    )
    renamed = {
        "f32_to_u32_bits": "wide_f32_to_u32",
        "u8_widen_low": "wide_u8_widen",
        "u16_narrow_saturate": "wide_u16_narrow",
        "u16_interleave_low": "wide_u16_interleave",
        "f32_deinterleave_odd": "wide_f32_deinterleave",
        "f64_slide_low_one": "wide_f64_slide",
    }
    for name in simple:
        c.extract_symbol(
            f"wide_codegen_probe__{name}",
            t / "wide-probe.txt",
            t / f"{renamed.get(name,'wide_'+name)}.txt",
        )
    for precision in ("f32", "f64"):
        for operation in (
            "add",
            "subtract",
            "multiply",
            "divide",
            "min_number",
            "max_number",
        ):
            c.extract_symbol(
                f"wide_codegen_probe__{precision}_{operation}",
                t / "wide-probe.txt",
                t / f"wide_{precision}_{operation}.txt",
            )
    for lane in ("u8", "i8"):
        for operation in (
            "equal",
            "less",
            "less_equal",
            "greater",
            "greater_equal",
            "select",
        ):
            c.extract_symbol(
                f"wide_codegen_probe__{lane}_{operation}",
                t / "wide-probe.txt",
                t / f"wide_{lane}_{operation}.txt",
            )


def _wide_kind(vector: str):
    return {
        "u8x32": ("u8x16", "backends__native__select_value", None),
        "i8x32": (
            "i8x16",
            "backends__native__native_select_i8x16",
            "backends__native__native_zero_i8x16",
        ),
        "u16x16": (
            "u16x8",
            "backends__native__native_select_u16x8",
            "backends__native__native_zero_u16x8",
        ),
        "i16x16": (
            "i16x8",
            "backends__native__native_select_i16x8",
            "backends__native__native_zero_i16x8",
        ),
        "u32x8": (
            "u32x4",
            "backends__native__native_select_u32x4",
            "backends__native__native_zero_u32x4",
        ),
        "i32x8": (
            "i32x4",
            "backends__native__native_select_i32x4",
            "backends__native__native_zero_i32x4",
        ),
        "u64x4": (
            "u64x2",
            "backends__native__native_select_u64x2",
            "backends__native__native_zero_u64x2",
        ),
        "i64x4": (
            "i64x2",
            "backends__native__native_select_i64x2",
            "backends__native__native_zero_i64x2",
        ),
        "f32x8": (
            "f32x4",
            "backends__native__native_select_f32x4",
            "backends__native__native_zero_f32x4",
        ),
        "f64x4": (
            "f64x2",
            "backends__native__native_select_f64x2",
            "backends__native__native_zero_f64x2",
        ),
    }[vector]


def check_wide(c: Checker, wide_backend: str) -> None:
    t = c.temporary
    _collect_wide_outputs(c)
    vectors = (
        "u8x32",
        "i8x32",
        "u16x16",
        "i16x16",
        "u32x8",
        "i32x8",
        "u64x4",
        "i64x4",
        "f32x8",
        "f64x4",
    )
    if wide_backend == "composed":
        for vector in vectors:
            half, select, zero = _wide_kind(vector)
            for operation in ("permute_1", "reverse"):
                output = _extract_movement(c, vector, operation)
                c.require_at_most(
                    f"backends__native__native_permute_2_{half}",
                    2,
                    output,
                    f"two exact selected permutations in {vector} {operation} caller",
                )
                c.require_at_most(
                    "backends__native__native_permute_2_",
                    2,
                    output,
                    f"no mismatched permutation in {vector} {operation} caller",
                )
            for operation in (
                "permute_2",
                "interleave_low",
                "interleave_high",
                "deinterleave_even",
                "deinterleave_odd",
            ):
                output = _extract_movement(c, vector, operation)
                c.require_at_most(
                    f"backends__native__native_permute_2_{half}",
                    4,
                    output,
                    f"four exact selected permutations in {vector} {operation} caller",
                )
                c.require_at_most(
                    select,
                    2,
                    output,
                    f"two exact selected source choices in {vector} {operation} caller",
                )
                c.require_at_most(
                    "backends__native__native_permute_2_",
                    4,
                    output,
                    f"no mismatched permutation in {vector} {operation} caller",
                )
                c.require_at_most(
                    r"backends__native(__select_value|__native_select_)",
                    2,
                    output,
                    f"no mismatched source choice in {vector} {operation} caller",
                )
            for operation in ("slide_low", "slide_high"):
                output = _extract_movement(c, vector, operation)
                c.require_at_most(
                    f"backends__native__native_permute_2_{half}",
                    2,
                    output,
                    f"two exact selected permutations in {vector} {operation} caller",
                )
                c.require_at_most(
                    select,
                    2,
                    output,
                    f"two exact selected zero-fill choices in {vector} {operation} caller",
                )
                c.require_at_most(
                    "backends__native__native_permute_2_",
                    2,
                    output,
                    f"no mismatched permutation in {vector} {operation} caller",
                )
                c.require_at_most(
                    r"backends__native(__select_value|__native_select_)",
                    2,
                    output,
                    f"no mismatched zero-fill choice in {vector} {operation} caller",
                )
                if zero:
                    c.require_at_most(
                        zero,
                        1,
                        output,
                        f"one exact selected zero in {vector} {operation} caller",
                    )
                    c.require_at_most(
                        "backends__native__native_zero_",
                        1,
                        output,
                        f"no mismatched zero constructor in {vector} {operation} caller",
                    )
                else:
                    c.require_at_least(
                        r"(^|[[:space:]])pxor[[:space:]]+%?xmm([0-9]+),[[:space:]]*%?xmm\2",
                        3,
                        output,
                        f"exact map, selector, and value zeroing in {vector} {operation} caller",
                    )
                    c.require_at_most(
                        "backends__native__native_zero_",
                        0,
                        output,
                        f"no out-of-line zero constructor in {vector} {operation} caller",
                    )
    else:
        for vector in vectors:
            for operation in ("permute_1", "reverse", "slide_low", "slide_high"):
                _check_avx_movement(c, vector, operation, 2, 1, 1, 1)
            for operation in (
                "permute_2",
                "interleave_low",
                "interleave_high",
                "deinterleave_even",
                "deinterleave_odd",
            ):
                _check_avx_movement(c, vector, operation, 4, 2, 3, 3)
    _check_wide_callers_and_compact(c, wide_backend)
    _check_wide_routes(c, wide_backend)


def _extract_movement(c: Checker, vector: str, operation: str):
    output = c.temporary / f"wide_movement_{vector}_{operation}.txt"
    c.extract_symbol(
        f"wide_movement_codegen_probe__{vector}_{operation}",
        c.temporary / "wide-movement-probe.txt",
        output,
    )
    return output


def _check_avx_movement(
    c: Checker,
    vector: str,
    operation: str,
    shuffles: int,
    crosses: int,
    selects: int,
    merges: int,
) -> None:
    output = _extract_movement(c, vector, operation)
    for mnemonic, count, description in (
        ("vpshufb", shuffles, f"{'four' if shuffles==4 else 'two'} byte shuffles"),
        (
            "vperm2i128",
            crosses,
            f"{'two' if crosses==2 else 'one'} cross-half selection{'s' if crosses==2 else ''}",
        ),
        ("vpcmpeqb", 2, "two mask comparisons"),
        (
            "vpandn",
            selects,
            f"{'three' if selects==3 else 'one'} false-side mask selection{'s' if selects==3 else ''}",
        ),
        (
            "vpor",
            merges,
            f"{'three' if merges==3 else 'one'} mask merge{'s' if merges==3 else ''}",
        ),
        ("vzeroupper", 1, "one vzeroupper"),
    ):
        c.require_count(
            rf"(^|[[:space:]]){mnemonic}{'([[:space:]]|$)' if mnemonic=='vzeroupper' else '[[:space:]]'}",
            count,
            output,
            f"{description} in AVX2 {vector} {operation} caller",
        )
    c.forbid_pattern(
        r"flyology_simd__wide__(extract|from_lanes|permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)",
        output,
        f"call or portable helper in AVX2 {vector} {operation} caller",
    )


def _check_wide_callers_and_compact(c: Checker, backend: str) -> None:
    t = c.temporary
    if backend == "avx2":
        c.require_at_most(
            r"(^|[[:space:]])call",
            1,
            t / "wide_u8_add.txt",
            "one isolated AVX2 byte-operation mechanism in wide caller",
        )
        for precision in ("f32", "f64"):
            for operation in (
                "add",
                "subtract",
                "multiply",
                "divide",
                "min_number",
                "max_number",
            ):
                output = t / f"wide_{precision}_{operation}.txt"
                c.require_at_most(
                    r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
                    1,
                    output,
                    f"one isolated AVX2 {precision} {operation} leaf in wide caller",
                )
                c.forbid_pattern(
                    r"(^|[[:space:]])(call|jmp).*backends__native|(^|[[:space:]])(call|jmp).*flyology_simd__wide__(native|float_arithmetic_mechanism)",
                    output,
                    f"composed or public helper in AVX2 {precision} {operation} caller",
                )
        for names, shuffles, crosses, source in (
            (("wide_u8_permute", "wide_f32_permute"), 2, 1, "one-source"),
            (("wide_u16_permute_2", "wide_f64_permute_2"), 4, 2, "two-source"),
        ):
            for name in names:
                c.require_count(
                    "vpshufb",
                    shuffles,
                    t / f"{name}.txt",
                    f"{'two' if shuffles==2 else 'four'} AVX2 byte shuffles in {source} {name} caller",
                )
                c.require_count(
                    "vperm2i128",
                    crosses,
                    t / f"{name}.txt",
                    f"{'one' if crosses==1 else 'two'} AVX2 cross-half selection{'s' if crosses==2 else ''} in {source} {name} caller",
                )
                c.require_count(
                    "vzeroupper",
                    1,
                    t / f"{name}.txt",
                    f"AVX2 boundary cleanup in {source} {name} caller",
                )
                c.forbid_pattern(
                    r"flyology_simd__(__wide)?__(extract|from_lanes|permute_lanes)|flyology_simd__wide__native__permute_lanes",
                    t / f"{name}.txt",
                    f"scalar, per-lane, or public permutation helper in {name} caller",
                )
        for names, shuffles, crosses, source in (
            (("wide_u8_reverse", "wide_f64_slide"), 2, 1, "one-source"),
            (("wide_u16_interleave", "wide_f32_deinterleave"), 4, 2, "two-source"),
        ):
            for name in names:
                output = t / f"{name}.txt"
                c.require_count(
                    "vpshufb",
                    shuffles,
                    output,
                    f"{'two' if shuffles==2 else 'four'} AVX2 byte shuffles in {source} {name} caller",
                )
                c.require_count(
                    "vperm2i128",
                    crosses,
                    output,
                    f"{'one' if crosses==1 else 'two'} AVX2 cross-half selection{'s' if crosses==2 else ''} in {source} {name} caller",
                )
                c.require_count(
                    "vzeroupper",
                    1,
                    output,
                    f"AVX2 boundary cleanup in {source} {name} caller",
                )
                for pattern, description in (
                    (
                        "vpcmpeqb",
                        (
                            "source-half mask"
                            if source == "one-source"
                            else "source masks"
                        ),
                    ),
                    ("vpandn", "complementary source selection"),
                    ("vpor", "source merge"),
                ):
                    c.require_pattern(
                        pattern, output, f"AVX2 {description} in {source} {name} caller"
                    )
                c.forbid_pattern(
                    r"flyology_simd__(__wide)?__(extract|from_lanes|reverse_lanes|interleave|deinterleave|slide_lanes)|flyology_simd__wide__native__",
                    output,
                    f"scalar, per-lane, or public movement helper in {name} caller",
                )
    else:
        c.require_at_most(
            r"(^|[[:space:]])call",
            2,
            t / "wide_u8_add.txt",
            "two inlined SSE2 byte-add leaves in wide caller",
        )
    if backend == "composed":
        for precision in ("f32", "f64"):
            for operation in (
                "add",
                "subtract",
                "multiply",
                "divide",
                "min_number",
                "max_number",
            ):
                c.require_at_most(
                    r"(^|[[:space:]])call",
                    2,
                    t / f"wide_{precision}_{operation}.txt",
                    f"two selected SSE {precision} {operation} leaves in wide caller",
                )
    for name, description in (
        ("wide_f32_to_u32", "two SSE F32-to-U32 bit-cast leaves"),
        ("wide_u8_widen", "two selected byte-widen operations"),
        ("wide_u16_narrow", "two selected U16-narrow operations"),
        ("wide_i32_to_f32", "two selected I32-to-F32 conversion operations"),
        ("wide_u8_table_lookup", "one target-selected 32-lane table-lookup mechanism"),
        ("wide_u8_horizontal_sum", "two exact byte-sum operations"),
    ):
        c.require_at_most(
            r"(^|[[:space:]])call",
            1 if name == "wide_u8_table_lookup" else 2,
            t / f"{name}.txt",
            f"{description} in wide caller",
        )
    lane_info = {
        "u8": ("u8x16", "backends__native__select_value", None),
        "i8": (
            "i8x16",
            "backends__native__native_select_i8x16",
            "backends__native__native_zero_i8x16",
        ),
        "u16": (
            "u16x8",
            "backends__native__native_select_u16x8",
            "backends__native__native_zero_u16x8",
        ),
        "i16": (
            "i16x8",
            "backends__native__native_select_i16x8",
            "backends__native__native_zero_i16x8",
        ),
        "u32": (
            "u32x4",
            "backends__native__native_select_u32x4",
            "backends__native__native_zero_u32x4",
        ),
        "i32": (
            "i32x4",
            "backends__native__native_select_i32x4",
            "backends__native__native_zero_i32x4",
        ),
        "u64": (
            "u64x2",
            "backends__native__native_select_u64x2",
            "backends__native__native_zero_u64x2",
        ),
        "i64": (
            "i64x2",
            "backends__native__native_select_i64x2",
            "backends__native__native_zero_i64x2",
        ),
        "f32": (
            "f32x4",
            "backends__native__native_select_f32x4",
            "backends__native__native_zero_f32x4",
        ),
        "f64": (
            "f64x2",
            "backends__native__native_select_f64x2",
            "backends__native__native_zero_f64x2",
        ),
    }
    for lane, (half, select, zero) in lane_info.items():
        for operation in ("compress", "expand"):
            output = t / f"wide_compact_{lane}_{operation}.txt"
            c.extract_symbol(
                f"wide_compact_codegen_probe__{lane}_{operation}",
                t / "wide-compact-probe.txt",
                output,
            )
            c.require_at_most(
                f"backends__native__native_permute_2_{half}",
                2,
                output,
                f"two selected SSE2 permutations in Wide {lane} {operation} caller",
            )
            c.require_at_most(
                "backends__native__native_permute_2_",
                2,
                output,
                f"no mismatched selected permutation leaf in Wide {lane} {operation} caller",
            )
            c.require_at_most(
                select,
                2,
                output,
                f"two selected SSE2 zero-fill selections in Wide {lane} {operation} caller",
            )
            c.require_at_most(
                r"backends__native(__select_value|__native_select_)",
                2,
                output,
                f"no mismatched selected zero-fill leaf in Wide {lane} {operation} caller",
            )
            if zero:
                c.require_at_most(
                    zero,
                    1,
                    output,
                    f"one selected SSE2 zero construction in Wide {lane} {operation} caller",
                )
            else:
                c.require_pattern(
                    r"(^|[[:space:]])pxor[[:space:]]",
                    output,
                    f"inline selected SSE2 zero construction in Wide {lane} {operation} caller",
                )
            c.forbid_pattern(
                r"flyology_simd__(__wide)?__(to_bit_mask|mask_from_bit_mask|zero)|flyology_simd__backends__native__(to_bit_mask|mask_from_bit_mask|zero)",
                output,
                f"portable mask or zero helper in {lane} {operation} caller",
            )
            c.forbid_pattern(
                r"(^|[[:space:]])(call|jmp).*flyology_simd__wide__(compress|expand|native__)|flyology_simd__(__wide)?__(extract|from_lanes|test)",
                output,
                f"portable or public Wide compact helper in {lane} {operation} caller",
            )
    if backend == "avx2":
        for lane in ("u8", "i8"):
            for operation in (
                "equal",
                "less",
                "less_equal",
                "greater",
                "greater_equal",
                "select",
            ):
                output = t / f"wide_{lane}_{operation}.txt"
                c.require_at_most(
                    r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
                    1,
                    output,
                    f"one isolated AVX2 {lane} {operation} mechanism in wide caller",
                )
                c.forbid_pattern(
                    r"(^|[[:space:]])(callq?|jmpq?).*backends__native|(^|[[:space:]])(callq?|jmpq?).*flyology_simd__(wide__)?(equal|less|greater|select_value)",
                    output,
                    f"scalar, composed, or public helper in AVX2 {lane} {operation} caller",
                )
    else:
        c.require_count(
            "pcmpeqb",
            2,
            t / "wide_u8_equal.txt",
            "two inlined SSE2 U8 equality operations in the composed Wide caller",
        )
        c.require_count(
            "pmovmskb",
            2,
            t / "wide_u8_equal.txt",
            "two inlined SSE2 U8 compact-mask extractions in the composed Wide caller",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])call",
            t / "wide_u8_equal.txt",
            "out-of-line helper retained in composed Wide U8 equality caller",
        )
        for operation in ("less", "greater", "select"):
            c.require_at_most(
                r"(^|[[:space:]])call",
                2,
                t / f"wide_u8_{operation}.txt",
                f"two selected SSE2 U8 {operation} operations in composed Wide caller",
            )
        for operation in ("less_equal", "greater_equal"):
            c.require_at_most(
                r"(^|[[:space:]])call",
                2,
                t / f"wide_u8_{operation}.txt",
                f"two selected SSE2 U8 ordered operations in composed Wide {operation} caller",
            )
            c.require_count(
                "pcmpeqb",
                2,
                t / f"wide_u8_{operation}.txt",
                f"two inlined SSE2 U8 equality operations in composed Wide {operation} caller",
            )
        for operation in ("equal", "less", "greater", "select"):
            c.require_at_most(
                r"(^|[[:space:]])call",
                2,
                t / f"wide_i8_{operation}.txt",
                f"two selected SSE2 I8 {operation} operations in composed Wide caller",
            )
        for operation in ("less_equal", "greater_equal"):
            c.require_at_most(
                r"(^|[[:space:]])call",
                4,
                t / f"wide_i8_{operation}.txt",
                f"four selected SSE2 I8 compare operations in composed Wide {operation} caller",
            )


def _check_wide_routes(c: Checker, backend: str) -> None:
    t = c.temporary
    if backend == "avx2":
        c.require_pattern(
            "flyology_simd__wide__byte_avx2_leaf__add_wrap",
            t / "wide-undefined.txt",
            "wide U8 addition calls the isolated AVX2 byte implementation",
        )
        c.require_pattern(
            r"flyology_simd__wide__float_avx2_leaf__(add|subtract|multiply|divide|min_number|max_number)",
            t / "wide-undefined.txt",
            "wide floating arithmetic and extrema call isolated AVX2 implementations",
        )
        c.require_pattern(
            r"flyology_simd__wide__byte_avx2_leaf__(equal|less_than|less_equal|greater_than|greater_equal|select_value)",
            t / "wide-undefined.txt",
            "wide byte predicates call relation-specific isolated AVX2 implementations",
        )
        c.forbid_pattern(
            "flyology_simd__wide__byte_mechanism__",
            t / "wide-undefined.txt",
            "non-AVX2 byte mechanism call retained in the public Wide caller",
        )
    else:
        c.require_route_or_inlined(
            r"flyology_simd__backends__native__(u8_)?add_wrap",
            t / "wide-undefined.txt",
            "wide U8 addition calls selected 128-bit native leaves after mechanism inlining",
        )
        c.require_route_or_inlined(
            r"flyology_simd__backends__native__native_(add|subtract|multiply|divide|min_number|max_number)_(f32x4|f64x2)",
            t / "wide-undefined.txt",
            "wide floating arithmetic and extrema call selected 128-bit native leaves",
        )
        reloc = t / "wide-lookup-relocs.txt"
        for pattern, limit, description in (
            (
                r"flyology_simd__backends__native__table_lookup([+-]0x[[:xdigit:]]+)?$",
                4,
                "four selected 128-bit table lookups",
            ),
            (
                r"flyology_simd__backends__native__subtract_wrap([+-]0x[[:xdigit:]]+)?$",
                2,
                "two selected 128-bit index adjustments",
            ),
            (
                r"flyology_simd__backends__native__bitwise_or([+-]0x[[:xdigit:]]+)?$",
                2,
                "two selected 128-bit result merges",
            ),
        ):
            c.require_at_most(
                pattern,
                limit,
                reloc,
                f"{description} in the composed Wide lookup mechanism",
            )
        if c.matches(
            r"flyology_simd__(backends__native__)?splat([+-]0x[[:xdigit:]]+)?$", reloc
        ):
            c.require_at_most(
                r"flyology_simd__(backends__native__)?splat([+-]0x[[:xdigit:]]+)?$",
                1,
                reloc,
                "one selected 128-bit 16-filled vector construction in the composed Wide lookup mechanism",
            )
            expected = 4
        else:
            for pattern, description in (
                (
                    r"(^|[[:space:]])imul[a-z]*[[:space:]]+\$0x1010101",
                    "one inlined 16-byte repeated constant",
                ),
                (
                    r"(^|[[:space:]])movd[[:space:]]+%?e[a-z0-9]+,[[:space:]]*%?xmm[0-9]+",
                    "one inlined 16-filled vector scalar transfer",
                ),
                (
                    r"(^|[[:space:]])pshufd[[:space:]]+\$(0x0*0|0),[[:space:]]*%?xmm[0-9]+,[[:space:]]*%?xmm[0-9]+",
                    "one inlined 16-filled vector broadcast",
                ),
            ):
                c.require_count(
                    pattern,
                    1,
                    t / "wide-lookup.txt",
                    f"{description} in the composed Wide lookup mechanism",
                )
            expected = 3
        c.require_at_most(
            r"flyology_simd__backends__native__(table_lookup|subtract_wrap|bitwise_or)$|flyology_simd__(backends__native__)?splat$",
            expected,
            t / "wide-lookup-undefined.txt",
            "only the intended selected 128-bit operations remain unresolved from the composed Wide lookup mechanism",
        )
        c.require_at_most(
            "flyology_simd__",
            expected,
            t / "wide-lookup-undefined.txt",
            "only the intended library operations remain unresolved from the composed Wide lookup mechanism",
        )
        c.forbid_pattern(
            r"flyology_simd__(wide__)?table_lookup|flyology_simd__wide__native__table_lookup",
            t / "wide-lookup-undefined.txt",
            "portable or public Wide table lookup call from the composed lookup mechanism",
        )
    for pattern, description in (
        (
            "flyology_simd__backends__native__bit_cast",
            "wide F32 bit cast calls the selected 128-bit native leaf",
        ),
        (
            r"flyology_simd__backends__native__widen_(low|high)",
            "wide byte widening calls selected 128-bit native leaves",
        ),
        (
            "flyology_simd__backends__native__narrow_saturate",
            "wide U16 narrowing calls selected 128-bit native leaves",
        ),
        (
            "flyology_simd__backends__native__convert_round",
            "wide integer conversion calls selected 128-bit native leaves",
        ),
        (
            "flyology_simd__backends__native__horizontal_sum",
            "wide exact byte sum calls the selected 128-bit native leaf",
        ),
    ):
        c.require_route_or_inlined(pattern, t / "wide-undefined.txt", description)
    c.require_pattern(
        "flyology_simd__wide__lookup_mechanism__table_lookup_32",
        t / "wide-undefined.txt",
        "wide lookup calls the target-selected lookup mechanism",
    )
    route_avx = r"flyology_simd__backends__native__(bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum)|flyology_simd__wide__((byte|float)_avx2_leaf__(add_wrap|equal|equal__2|less_than|less_than__2|less_equal|less_equal__2|greater_than|greater_than__2|greater_equal|greater_equal__2|select_value|select_value__2|add|add__2|subtract|subtract__2|multiply|multiply__2|divide|divide__2|min_number|min_number__2|max_number|max_number__2)|lookup_mechanism__table_lookup_32)"
    route_composed = r"flyology_simd__backends__native__((u8_)?add_wrap|native_(add|subtract|multiply|divide|min_number|max_number)_(f32x4|f64x2)|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|compare_(equal|greater)(_i8x16)?|native_select_(u8|i8)x16)|flyology_simd__wide__lookup_mechanism__table_lookup_32"
    c.require_native_route(
        route_avx if backend == "avx2" else route_composed,
        32 if backend == "avx2" else 23,
        t / "wide-undefined.txt",
        t / "wide-probe.txt",
        f"only the intended native primitive classes remain unresolved from the {'AVX2' if backend=='avx2' else 'composed'} wide probe",
    )
    c.forbid_pattern(
        r"flyology_simd__(wide__)?(add_wrap|add|subtract|multiply|divide|min_number|max_number|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)",
        t / "wide-undefined.txt",
        "scalar or Wide primitive call from the native wide probe",
    )
    c.forbid_pattern(
        r"flyology_simd__wide__native__(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)",
        t / "wide-probe.txt",
        "wide native dispatcher call in caller probe",
    )


def check_algorithms(c: Checker, avx2: str) -> None:
    t = c.temporary
    for pattern, description in (
        ("pcmpeqb", "inlined SSE2 comparison in representative loop"),
        ("pmovmskb", "inlined mask extraction in representative loop"),
        ("movdqu", "inlined vector load in representative loop"),
    ):
        c.require_pattern(pattern, t / "algorithm.txt", description)
    output = t / "find-first-of.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__native__find_first_of", t / "algorithm.txt", output
    )
    for pattern, description in (
        ("pcmpeqb", "fused small-set SSE2 comparisons"),
        ("pmovmskb", "fused small-set SSE2 mask extraction"),
        ("movdqu", "fused small-set SSE2 vector load"),
    ):
        c.require_pattern(pattern, output, description)
    output = t / "find-first-difference.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__native__find_first_difference",
        t / "algorithm.txt",
        output,
    )
    for pattern, description in (
        ("movdqu", "fused two-buffer SSE2 vector loads"),
        ("pcmpeqb", "fused two-buffer SSE2 byte comparison"),
        ("pmovmskb", "fused two-buffer SSE2 mask extraction"),
        (
            r"(^|[[:space:]])(not(l|q)?[[:space:]]|xor(w|l|q)?[[:space:]]+\$(0x(ffff|ffffffff)|-1)(,|[[:space:]]))",
            "complemented SSE2 equality mask",
        ),
    ):
        c.require_pattern(pattern, output, description)
    c.forbid_pattern(
        r"call.*flyology_simd__backends__native__(load_unaligned|equal|to_bit_mask)",
        output,
        "out-of-line primitive in the Native difference loop",
    )
    output = t / "count-in-range.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__native__count_in_range", t / "algorithm.txt", output
    )
    c.require_pattern("movdqu", output, "Native range-count SSE2 vector load")
    for route, description in (
        ("greater_equal", "one selected lower-bound comparison in Native range count"),
        ("less_equal", "one selected upper-bound comparison in Native range count"),
        ("mask_and", "one selected mask intersection in Native range count"),
    ):
        c.require_at_most(
            f"flyology_simd__backends__native__{route}", 1, output, description
        )
    avx_instruction = r"(^|[[:space:]])v[a-z0-9]+([[:space:]]|$)|(^|[^[:alnum:]_])%?ymm[0-9]+([^[:alnum:]_]|$)"
    c.forbid_pattern(
        avx_instruction,
        t / "native.txt",
        "AVX instructions in the SSE2 baseline object",
    )
    c.forbid_pattern(
        avx_instruction, t / "features.txt", "AVX instructions in feature detection"
    )
    c.forbid_pattern(
        avx_instruction,
        t / "baseline.txt",
        "AVX instructions outside the AVX2-only object",
    )
    if avx2 == "enabled":
        _check_avx2_algorithms(c)


def _check_avx2_algorithms(c: Checker) -> None:
    t = c.temporary
    source = t / "avx2.txt"
    broad = (
        (r"ymm[0-9]+|vp[a-z]+", "AVX2 vectorization in the AVX2-only algorithm object"),
        ("bsf", "constant-time first-set-bit extraction in the AVX2 algorithm"),
        ("vpcmpeqb", "fused AVX2 small-set comparisons"),
        ("vpor", "fused AVX2 small-set comparison merge"),
        ("vpmovmskb", "fused AVX2 small-set mask extraction"),
        ("vzeroupper", "AVX-SSE transition cleanup in the small-set algorithm"),
        ("vmulps", "AVX2-width binary32 dot-product multiplication"),
        ("vaddps", "ordered binary32 dot-product accumulation"),
        ("vmulpd", "AVX2-width binary64 dot-product multiplication"),
        ("vaddpd", "ordered binary64 dot-product accumulation"),
        ("vextractf128", "ordered AVX2 dot-product half extraction"),
    )
    for pattern, description in broad:
        c.require_pattern(pattern, source, description)
    for precision, suffix, broadcast, mov, mul, add in (
        ("f32", "", "vbroadcastss", "vmovups", "vmulps", "vaddps"),
        ("f64", "__2", "vbroadcastsd", "vmovupd", "vmulpd", "vaddpd"),
    ):
        scale = t / f"avx2-{precision}-scale.txt"
        c.extract_symbol(
            f"flyology_simd__algorithms__avx2_implementation__scale{suffix}",
            source,
            scale,
        )
        c.require_pattern(
            broadcast,
            scale,
            f"AVX2-width binary{'32' if precision=='f32' else '64'} scale-factor broadcast",
        )
        c.require_count(
            mov,
            2,
            scale,
            f"one AVX2-width binary{'32' if precision=='f32' else '64'} scale load and store",
        )
        c.require_pattern(
            mul, scale, f"AVX2-width binary{'32' if precision=='f32' else '64'} scaling"
        )
        c.require_pattern(
            "vzeroupper",
            scale,
            f"AVX-SSE transition cleanup in binary{'32' if precision=='f32' else '64'} scaling",
        )
        c.forbid_pattern(
            add,
            scale,
            f"addition in binary{'32' if precision=='f32' else '64'} scaling",
        )
        axpy = t / f"avx2-{precision}-axpy.txt"
        c.extract_symbol(
            f"flyology_simd__algorithms__avx2_implementation__axpy{suffix}",
            source,
            axpy,
        )
        c.require_pattern(
            broadcast,
            axpy,
            f"AVX2-width binary{'32' if precision=='f32' else '64'} AXPY factor broadcast",
        )
        c.require_count(
            mov,
            3,
            axpy,
            f"two AVX2-width binary{'32' if precision=='f32' else '64'} AXPY loads and one store",
        )
        c.require_pattern(
            mul,
            axpy,
            f"separate AVX2-width binary{'32' if precision=='f32' else '64'} AXPY multiplication",
        )
        c.require_pattern(
            add,
            axpy,
            f"separate AVX2-width binary{'32' if precision=='f32' else '64'} AXPY addition",
        )
        c.require_pattern(
            "vzeroupper",
            axpy,
            f"AVX-SSE transition cleanup in binary{'32' if precision=='f32' else '64'} AXPY",
        )
        c.forbid_pattern(
            "vfmadd",
            axpy,
            f"fused multiply-add in exact binary{'32' if precision=='f32' else '64'} AXPY",
        )
        summation = t / f"avx2-{precision}-sum.txt"
        c.extract_symbol(
            f"flyology_simd__algorithms__avx2_implementation__sum{suffix}",
            source,
            summation,
        )
        c.require_pattern(
            mov,
            summation,
            f"AVX2-width binary{'32' if precision=='f32' else '64'} sum load",
        )
        c.require_pattern(
            add,
            summation,
            f"ordered binary{'32' if precision=='f32' else '64'} sum accumulation",
        )
        c.require_pattern(
            "vextractf128",
            summation,
            f"ordered binary{'32' if precision=='f32' else '64'} sum half extraction",
        )
        c.require_pattern(
            "vzeroupper",
            summation,
            f"AVX-SSE transition cleanup in the binary{'32' if precision=='f32' else '64'} sum",
        )
        c.forbid_pattern(
            mul,
            summation,
            f"multiplication in the binary{'32' if precision=='f32' else '64'} sum",
        )
    undefined = t / "avx2-undefined.txt"
    for symbol, description in (
        ("clamp$", "binary32 clamp"),
        ("clamp__2$", "binary64 clamp"),
        ("min_number$", "binary32-minimum"),
        ("max_number$", "binary32-maximum"),
        ("min_number__2$", "binary64-minimum"),
        ("max_number__2$", "binary64-maximum"),
    ):
        c.require_count(
            f"flyology_simd__algorithms__native_floating__{symbol}",
            1,
            undefined,
            f"one exact selected {description} route in the AVX2 object",
        )
    count = t / "avx2-count-in-range.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__avx2_implementation__count_in_range", source, count
    )
    for pattern, description in (
        ("vpmaxub", "AVX2 inclusive byte lower-bound classification"),
        ("vpminub", "AVX2 inclusive byte upper-bound classification"),
        ("vpcmpeqb", "AVX2 range-bound equality classification"),
        ("vpand", "AVX2 range-mask intersection"),
        ("vpmovmskb", "AVX2 range-mask extraction"),
        ("vzeroupper", "AVX-SSE transition cleanup in range count"),
    ):
        c.require_pattern(pattern, count, description)
    add = t / "avx2-add-saturate.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__avx2_implementation__add_saturate", source, add
    )
    for pattern, count_value, description in (
        ("vpbroadcastb", None, "AVX2-width byte Add_Saturate addend broadcast"),
        ("vmovdqu", 2, "one AVX2-width byte Add_Saturate load and store"),
        ("vpaddusb", None, "AVX2 unsigned saturating byte addition"),
        ("vzeroupper", None, "AVX-SSE transition cleanup in byte Add_Saturate"),
    ):
        (
            c.require_count(pattern, count_value, add, description)
            if count_value
            else c.require_pattern(pattern, add, description)
        )
    difference = t / "avx2-find-first-difference.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__avx2_implementation__find_first_difference",
        source,
        difference,
    )
    for pattern, description in (
        ("vmovdqu", "two-buffer AVX2 vector loads"),
        ("vpcmpeqb", "two-buffer AVX2 byte comparison"),
        ("vpmovmskb", "two-buffer AVX2 mask extraction"),
        (
            r"(^|[[:space:]])(not(l|q)?[[:space:]]|xor(w|l|q)?[[:space:]]+\$(0x(ffff|ffffffff)|-1)(,|[[:space:]]))",
            "complemented AVX2 equality mask",
        ),
        ("vzeroupper", "AVX-SSE transition cleanup in the difference loop"),
    ):
        c.require_pattern(pattern, difference, description)
    c.forbid_pattern(
        r"flyology_simd(__backends__native)?__(splat|load_unaligned|equal|bitwise_(and|or)|shift_right_logical|table_lookup|to_bit_mask|first_true)$",
        undefined,
        "per-vector primitive relocation in the AVX2 small-set algorithm object",
    )


def check_avx2_wide_leaves(c: Checker, backend: str) -> None:
    if backend != "avx2":
        return
    t = c.temporary
    c.forbid_pattern(
        r"flyology_simd__(__wide)?__(extract|from_lanes|permute_lanes)",
        t / "wide-permute.txt",
        "scalar or per-lane helper in AVX2 permutation object",
    )
    float_instructions = {
        "add": ("vaddps", "vaddpd"),
        "subtract": ("vsubps", "vsubpd"),
        "multiply": ("vmulps", "vmulpd"),
        "divide": ("vdivps", "vdivpd"),
    }
    float_leafs = []
    for operation in (
        "add",
        "subtract",
        "multiply",
        "divide",
        "min_number",
        "max_number",
    ):
        for precision, suffix in (("f32", ""), ("f64", "__2")):
            output = t / f"wide_float_{precision}_{operation}.txt"
            float_leafs.append(output)
            c.extract_symbol(
                f"float_avx2_leaf__{operation}{suffix}", t / "wide-float.txt", output
            )
            if operation in float_instructions:
                c.require_pattern(
                    float_instructions[operation][0 if precision == "f32" else 1],
                    output,
                    f"AVX2-width binary{'32' if precision=='f32' else '64'} {operation if operation!='subtract' else 'subtraction'}",
                )
            else:
                for pattern, description in (
                    (r"vpcmpgtd|vpcmpeqd", "AVX2 integer classification"),
                    ("vpandn", "AVX2 bit selection"),
                    ("vpor", "AVX2 result merge"),
                ):
                    c.require_pattern(
                        pattern, output, f"{description} in {precision} {operation}"
                    )
                c.forbid_pattern(
                    r"v(min|max)(ps|pd)|vcmp(ps|pd)",
                    output,
                    f"floating compare or min/max in exact {precision} {operation}",
                )
    for leaf in float_leafs:
        c.require_leaf_instruction(
            "vzeroupper",
            1,
            leaf,
            "one AVX-SSE transition cleanup in each Wide floating leaf",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__backends__native|flyology_simd__wide__(native|add|subtract|multiply|divide|min_number|max_number)",
            leaf,
            "scalar, composed, or out-of-line call in AVX2 floating leaf",
        )
    c.forbid_pattern(
        r"flyology_simd__backends__native|flyology_simd__wide__(native|add|subtract|multiply|divide|min_number|max_number)",
        t / "wide-float-undefined.txt",
        "scalar, composed, or public dispatcher call from AVX2 floating implementation",
    )

    byte_names = {
        "add_wrap": "add",
        "subtract_wrap": "subtract",
        "multiply_wrap": "multiply",
        "add_saturate": "add_sat",
        "subtract_saturate": "sub_sat",
        "bitwise_and": "and",
        "bitwise_or": "or",
        "bitwise_xor": "xor",
        "bitwise_not": "not",
        "min": "min",
        "max": "max",
        "equal": "equal",
        "greater_than": "greater",
        "less_than": "less",
        "less_equal": "less_equal",
        "greater_equal": "greater_equal",
        "select_value": "select",
    }
    byte_leafs = []
    for operation, name in byte_names.items():
        for lane, suffix in (("u8", ""), ("i8", "__2")):
            output = t / f"wide_byte_{lane}_{name}.txt"
            byte_leafs.append(output)
            c.extract_symbol(
                f"byte_avx2_leaf__{operation}{suffix}", t / "wide-byte.txt", output
            )
    for lane in ("u8", "i8"):
        for name in ("add", "subtract", "multiply"):
            leaf = t / f"wide_byte_{lane}_{name}.txt"
            _avx_binary_abi(c, leaf, lane, f"wrapping leaf")
        add, sub, mul = (
            t / f"wide_byte_{lane}_{name}.txt"
            for name in ("add", "subtract", "multiply")
        )
        c.require_count(
            r"vpaddb[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0",
            1,
            add,
            f"one exact AVX2 {lane} wrapping byte addition",
        )
        c.forbid_pattern(
            r"vpsubb|vpmullw",
            add,
            f"unrelated wrapping operation in AVX2 {lane} addition leaf",
        )
        c.require_count(
            r"vpsubb[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0",
            1,
            sub,
            f"one exact AVX2 {lane} wrapping byte subtraction",
        )
        c.forbid_pattern(
            r"vpaddb|vpmullw",
            sub,
            f"unrelated wrapping operation in AVX2 {lane} subtraction leaf",
        )
        for pattern, count, description in (
            ("vpcmpeqd", 1, "one low-byte mask source"),
            (r"vpsrlw[[:space:]]+\$(0x0*8|8),", 3, "three shift-by-eight extractions"),
            ("vpand", 3, "three low-byte masks"),
            ("vpmullw", 2, "two even/odd word products"),
            (r"vpsllw[[:space:]]+\$(0x0*8|8),", 1, "one shift-by-eight placement"),
            ("vpor", 1, "one even/odd product merge"),
        ):
            c.require_count(
                pattern, count, mul, f"{description} in AVX2 {lane} multiplication"
            )
        c.forbid_pattern(
            r"vpaddb|vpsubb",
            mul,
            f"unrelated wrapping operation in AVX2 {lane} multiplication leaf",
        )
    for name, pattern, description in (
        ("u8_add_sat", "vpaddusb", "AVX2 unsigned saturating byte addition"),
        ("i8_add_sat", "vpaddsb", "AVX2 signed saturating byte addition"),
        ("u8_sub_sat", "vpsubusb", "AVX2 unsigned saturating byte subtraction"),
        ("i8_sub_sat", "vpsubsb", "AVX2 signed saturating byte subtraction"),
    ):
        c.require_pattern(pattern, t / f"wide_byte_{name}.txt", description)
    for lane in ("u8", "i8"):
        for operation, mnemonic, label in (
            ("and", "vpand", "conjunction"),
            ("or", "vpor", "disjunction"),
            ("xor", "vpxor", "exclusive disjunction"),
        ):
            leaf = t / f"wide_byte_{lane}_{operation}.txt"
            _avx_binary_abi(c, leaf, lane, f"bitwise {operation} leaf")
            c.require_count(
                rf"{mnemonic}[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0",
                1,
                leaf,
                f"one exact AVX2 {lane} bitwise {label}",
            )
            c.require_count(
                rf"(^|[[:space:]]){mnemonic}[[:space:]]",
                1,
                leaf,
                f"only one AVX2 {lane} {label} instruction",
            )
            unrelated = {
                "and": r"vpandn|vpor|vpxor|vpcmpeqd",
                "or": r"vpand|vpxor|vpcmpeqd",
                "xor": r"vpand|vpor|vpcmpeqd",
            }[operation]
            c.forbid_pattern(
                unrelated,
                leaf,
                f"unrelated bitwise operation in AVX2 {lane} {label} leaf",
            )
        leaf = t / f"wide_byte_{lane}_not.txt"
        c.require_leaf_instruction(
            r"vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm0",
            2,
            leaf,
            f"operand and return-copy loads in AVX2 {lane} complement leaf",
        )
        c.require_leaf_instruction(
            r"vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm1",
            0,
            leaf,
            f"no second memory operand in AVX2 {lane} complement leaf",
        )
        c.require_leaf_instruction(
            r"vmovdqu[[:space:]]+%ymm0,[[:space:]]*[^,]*\([^)]*\)",
            2,
            leaf,
            f"assembly-result and return-value stores in AVX2 {lane} complement leaf",
        )
        for pattern, description in (
            (r"vmovdqu[[:space:]]+\(%rsi\),[[:space:]]*%ymm0", "ABI operand"),
            (
                r"vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdx\)",
                "assembly result destination",
            ),
            (
                r"vpcmpeqd[[:space:]]+%ymm1,[[:space:]]*%ymm1,[[:space:]]*%ymm1",
                "one all-one mask construction",
            ),
            (
                r"vpxor[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0",
                "one exact bitwise complement",
            ),
        ):
            c.require_leaf_instruction(
                pattern, 1, leaf, f"{description} in AVX2 {lane} complement leaf"
            )
        c.require_leaf_instruction(
            r"(^|[[:space:]])vpcmpeqd[[:space:]]",
            1,
            leaf,
            f"only one all-one mask construction in AVX2 {lane} complement leaf",
        )
        c.require_leaf_instruction(
            r"(^|[[:space:]])vpxor[[:space:]]",
            1,
            leaf,
            f"only one AVX2 {lane} complement instruction",
        )
        c.forbid_pattern(
            r"vpand|vpor|(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]",
            leaf,
            f"unrelated bitwise operation, branch, or helper in AVX2 {lane} complement leaf",
        )
        for operation in ("min", "max"):
            leaf = t / f"wide_byte_{lane}_{operation}.txt"
            _avx_extrema_abi(c, leaf, lane, operation)
            instruction = {
                ("u8", "min"): "vpminub",
                ("i8", "min"): "vpminsb",
                ("u8", "max"): "vpmaxub",
                ("i8", "max"): "vpmaxsb",
            }[(lane, operation)]
            c.require_leaf_instruction(
                rf"{instruction}[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0",
                1,
                leaf,
                f"one exact AVX2 {lane} {operation}",
            )
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){instruction}[[:space:]]",
                1,
                leaf,
                f"only one AVX2 {lane} {operation} instruction",
            )
            c.require_leaf_instruction(
                "vzeroupper",
                2,
                leaf,
                f"two AVX-SSE transition cleanups in AVX2 {lane} {operation} leaf",
            )
            unrelated = "|".join(
                x
                for x in ("vpminub", "vpminsb", "vpmaxub", "vpmaxsb")
                if x != instruction
            )
            c.forbid_pattern(
                rf"{unrelated}|(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]",
                leaf,
                f"unrelated extrema operation, branch, or helper in AVX2 {lane} {operation} leaf",
            )
    _check_avx_byte_relations(c)
    for leaf in byte_leafs:
        c.require_pattern(
            "vzeroupper", leaf, "AVX-SSE transition cleanup in each Wide byte leaf"
        )
        c.require_final_avx_instruction(
            "vzeroupper",
            leaf,
            "vzeroupper is the final AVX instruction in each Wide byte leaf",
        )
    c.forbid_pattern(
        r"flyology_simd__backends__native|flyology_simd__wide__(native|add_wrap|subtract_wrap|multiply_wrap|add_saturate|subtract_saturate|bitwise_|min|max|equal|less|greater|select_value)",
        t / "wide-byte-undefined.txt",
        "scalar, composed, or public dispatcher call from the AVX2 byte implementation",
    )
    output = t / "wide_lookup_leaf.txt"
    c.extract_symbol("table_lookup_32", t / "wide-lookup.txt", output)
    for pattern, description in (
        ("vpshufb", "AVX2 lane-local byte selection"),
        ("vperm2i128", "AVX2 cross-half table selection"),
        ("vpsubusb", "AVX2 out-of-range index rejection"),
        ("vzeroupper", "AVX-SSE transition cleanup"),
    ):
        c.require_pattern(pattern, output, f"{description} in the Wide lookup leaf")
    c.require_final_avx_instruction(
        "vzeroupper",
        output,
        "vzeroupper is the final AVX instruction in the Wide lookup leaf",
    )


def _avx_binary_abi(c: Checker, leaf, lane: str, kind: str) -> None:
    for pattern, count, description in (
        (
            r"vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm0",
            2,
            "left-operand and return-copy loads",
        ),
        (
            r"vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm1",
            1,
            "one right-operand load",
        ),
        (
            r"vmovdqu[[:space:]]+%ymm0,[[:space:]]*[^,]*\([^)]*\)",
            2,
            "assembly-result and return-value stores",
        ),
        (r"vmovdqu[[:space:]]+\(%rsi\),[[:space:]]*%ymm0", 1, "left ABI operand"),
        (r"vmovdqu[[:space:]]+\(%rcx\),[[:space:]]*%ymm1", 1, "right ABI operand"),
        (
            r"vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdx\)",
            1,
            "assembly result destination",
        ),
    ):
        c.require_leaf_instruction(
            pattern, count, leaf, f"{description} in AVX2 {lane} {kind}"
        )
    c.forbid_pattern(BRANCH, leaf, f"branch or helper in AVX2 {lane} {kind}")


def _avx_extrema_abi(c: Checker, leaf, lane: str, operation: str) -> None:
    _avx_binary_abi(c, leaf, lane, f"{operation} leaf")
    for pattern, description in (
        (
            r"vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdi\)",
            "hidden-result return store",
        ),
        (r"movq?[[:space:]]+%rdi,[[:space:]]*%rax", "hidden-result return address"),
        (r"movq?[[:space:]]+%rdx,[[:space:]]*%rcx", "right-operand ABI routing"),
    ):
        c.require_leaf_instruction(
            pattern, 1, leaf, f"{description} in AVX2 {lane} {operation} leaf"
        )


def _check_avx_byte_relations(c: Checker) -> None:
    t = c.temporary
    for lane, label in (("u8", "unsigned"), ("i8", "signed")):
        c.require_pattern(
            "vpcmpeqb", t / f"wide_byte_{lane}_equal.txt", f"AVX2 {label} byte equality"
        )
        c.require_pattern(
            "vpmovmskb",
            t / f"wide_byte_{lane}_equal.txt",
            f"AVX2 {label} compact equality mask",
        )
        c.require_pattern(
            "vpcmpgtb",
            t / f"wide_byte_{lane}_greater.txt",
            f"AVX2 {label} byte ordering compare",
        )
        c.require_pattern(
            "vpmovmskb",
            t / f"wide_byte_{lane}_greater.txt",
            f"AVX2 {label} compact ordered mask",
        )
    c.require_count(
        "vpxor",
        2,
        t / "wide_byte_u8_greater.txt",
        "two AVX2 unsigned sign-bit bias transforms",
    )
    for relation in ("less", "less_equal", "greater_equal"):
        for lane, label in (("u8", "unsigned"), ("i8", "signed")):
            output = t / f"wide_byte_{lane}_{relation}.txt"
            c.require_pattern(
                "vpcmpgtb",
                output,
                f"AVX2 {label} byte compare in {relation} relation leaf",
            )
            c.require_pattern(
                "vpmovmskb",
                output,
                f"AVX2 {label} compact mask in {relation} relation leaf",
            )
        c.require_count(
            "vpxor",
            2,
            t / f"wide_byte_u8_{relation}.txt",
            f"two AVX2 unsigned sign-bit bias transforms in {relation} relation leaf",
        )
    for relation in ("less_equal", "greater_equal"):
        for lane, label in (("u8", "unsigned"), ("i8", "signed")):
            c.require_pattern(
                r"(^|[[:space:]])not(l|q)?[[:space:]]",
                t / f"wide_byte_{lane}_{relation}.txt",
                f"compact-mask complement in {label} {relation} relation leaf",
            )
    for lane in ("u8", "i8"):
        output = t / f"wide_byte_{lane}_select.txt"
        for pattern, description in (
            ("vpbroadcastd", "compact-mask broadcast"),
            ("vpshufb", "compact-mask byte expansion"),
            ("vpcmpeqb", "all-bits lane mask construction"),
            ("vpandn", "false-lane selection"),
            ("vpor", "selected-lane merge"),
        ):
            c.require_pattern(pattern, output, f"AVX2 {description} for selection")


def check_x86_64(c: Checker, avx2: str, wide_backend: str) -> None:
    check_wrapping_and_bitwise(c)
    check_minmax(c)
    check_saturating(c)
    check_arrangement_memory_float(c)
    check_construction_masks_float_reductions(c)
    check_u8_and_integer_reductions(c)
    check_conversions(c)
    check_table_permute_and_shifts(c)
    check_wide(c, wide_backend)
    check_algorithms(c, avx2)
    check_avx2_wide_leaves(c, wide_backend)
