#!/usr/bin/env python3
"""AArch64-specific generated-code contracts."""

from __future__ import annotations

from codegen_checker import Checker
from codegen_contract_common import rows


BRANCH = r"(^|[[:space:]])(b(\.[a-z]+)?|bl|br|blr|cbz|cbnz|tbz|tbnz)[[:space:]]"


def _shape(bits: str) -> str:
    return {"8": "16b", "16": "8h", "32": "4s", "64": "2d"}[bits]


def check_exact_leaf_families(c: Checker) -> None:
    t = c.temporary
    native = t / "native.txt"

    for lane, operation, suffix, bits, _lanes in rows(
        "wrapping_arithmetic_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"wrapping-arithmetic-leaf-{lane}-{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}{symbol_suffix}",
            native,
            f"wrapping_arithmetic_codegen_probe__{lane}_{operation}",
            t / "wrapping-arithmetic-probe.txt",
            leaf,
        )
        c.require_vector_operand_transfers(leaf, lane, operation, 2)
        shape = _shape(bits)
        if operation == "add_wrap":
            c.require_leaf_instruction(
                rf"(^|[[:space:]])(add\.{shape}[[:space:]]|add[[:space:]].*\.{shape}([^[:alnum:]]|$))",
                1,
                leaf,
                f"exact NEON {shape} {operation} leaf",
            )
        elif operation == "subtract_wrap":
            c.require_leaf_instruction(
                rf"(^|[[:space:]])(sub\.{shape}[[:space:]]|sub[[:space:]].*\.{shape}([^[:alnum:]]|$))",
                1,
                leaf,
                f"exact NEON {shape} {operation} leaf",
            )
        elif bits != "64":
            c.require_leaf_instruction(
                rf"(^|[[:space:]])(mul\.{shape}[[:space:]]|mul[[:space:]].*\.{shape}([^[:alnum:]]|$))",
                1,
                leaf,
                f"exact NEON {shape} {operation} leaf",
            )
        else:
            checks = (
                (
                    r"(^|[[:space:]])uzp1(\.4s)?[[:space:]]",
                    2,
                    "two low-word deinterleaves",
                ),
                (
                    r"(^|[[:space:]])uzp2(\.4s)?[[:space:]]",
                    2,
                    "two high-word deinterleaves",
                ),
                (
                    r"(^|[[:space:]])umull(\.2d)?[[:space:]]",
                    1,
                    "one low-word full product",
                ),
                (r"(^|[[:space:]])mul(\.2s)?[[:space:]]", 1, "one first cross product"),
                (
                    r"(^|[[:space:]])mla(\.2s)?[[:space:]]",
                    1,
                    "one second cross product",
                ),
                (
                    r"(^|[[:space:]])shll(\.2d)?[[:space:]].*#(32|0x20)([^[:xdigit:]]|$)",
                    1,
                    "32-bit cross-product shift",
                ),
                (
                    r"(^|[[:space:]])add(\.2d)?[[:space:]]+v[0-9]+",
                    1,
                    "one modulo-64 product combination",
                ),
            )
            for pattern, count, description in checks:
                c.require_leaf_instruction(
                    pattern, count, leaf, f"{description} in {lane} multiplication"
                )
        c.forbid_pattern(
            r"(^|[[:space:]])(b(\.[a-z]+)?|bl)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in {lane} {operation} leaf",
        )

    for lane, operation, suffix, _bits, _lanes, arity in rows(
        "bitwise_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"bitwise-leaf-{lane}-{operation}.txt"
        if lane == "u8" and operation == "bitwise_and":
            c.extract_symbol(
                "bitwise_codegen_probe__u8_bitwise_and", t / "bitwise-probe.txt", leaf
            )
        else:
            c.extract_leaf_or_probe(
                f"flyology_simd__backends__native__{operation}{symbol_suffix}",
                native,
                f"bitwise_codegen_probe__{lane}_{operation}",
                t / "bitwise-probe.txt",
                leaf,
            )
        c.require_vector_operand_transfers(leaf, lane, operation, int(arity))
        instruction = {
            "bitwise_and": "and",
            "bitwise_or": "orr",
            "bitwise_xor": "eor",
            "bitwise_not": "mvn",
        }[operation]
        c.require_exact_neon_shaped(
            leaf,
            instruction,
            "16b",
            lane,
            int(arity),
            f"exact NEON {lane} {operation} operation",
        )
        c.forbid_pattern(
            BRANCH, leaf, f"branch or out-of-line helper in {lane} {operation} leaf"
        )

    for lane, operation, suffix, bits, _lanes, signedness in rows(
        "integer_minmax_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"integer-minmax-leaf-{lane}-{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}{symbol_suffix}",
            native,
            f"integer_minmax_codegen_probe__{lane}_{operation}",
            t / "integer-minmax-probe.txt",
            leaf,
        )
        c.require_vector_operand_transfers(leaf, lane, operation, 2)
        shape = _shape(bits)
        if bits != "64":
            prefix = "s" if signedness == "signed" else "u"
            c.require_exact_neon_shaped(
                leaf,
                f"{prefix}{operation}",
                shape,
                lane,
                2,
                f"exact NEON {shape} {lane} {operation}",
            )
        else:
            compare = "cmgt" if signedness == "signed" else "cmhi"
            select = "bit" if operation == "min" else "bif"
            c.require_exact_neon_shaped(
                leaf,
                compare,
                "2d",
                lane,
                2,
                f"exact NEON 64-bit comparison in {lane} {operation}",
            )
            c.require_exact_neon_shaped(
                leaf,
                select,
                "16b",
                lane,
                2,
                f"exact NEON 64-bit selection in {lane} {operation}",
            )
        c.forbid_pattern(
            BRANCH, leaf, f"branch or out-of-line helper in {lane} {operation} leaf"
        )

    for lane, operation, suffix, bits, _lanes, signedness in rows(
        "saturating_arithmetic_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"saturating-arithmetic-leaf-{lane}-{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}{symbol_suffix}",
            native,
            f"saturating_arithmetic_codegen_probe__{lane}_{operation}",
            t / "saturating-arithmetic-probe.txt",
            leaf,
        )
        c.require_vector_operand_transfers(leaf, lane, operation, 2)
        prefix = "sq" if signedness == "signed" else "uq"
        instruction = f"{prefix}{'add' if operation == 'add_saturate' else 'sub'}"
        shape = _shape(bits)
        c.require_exact_neon_shaped(
            leaf, instruction, shape, lane, 2, f"exact NEON {shape} {lane} {operation}"
        )
        c.forbid_pattern(
            BRANCH, leaf, f"branch or out-of-line helper in {lane} {operation} leaf"
        )

    for lane, operation, suffix, bits, _lanes in rows(
        "lane_arrangement_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"lane-arrangement-leaf-{lane}-{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}{symbol_suffix}",
            native,
            f"lane_arrangement_codegen_probe__{lane}_{operation}",
            t / "lane-arrangement-probe.txt",
            leaf,
        )
        shape = _shape(bits)
        c.require_vector_operand_transfers(
            leaf, lane, operation, 1 if operation == "reverse_lanes" else 2
        )
        if operation == "reverse_lanes":
            if bits != "64":
                c.require_leaf_instruction(
                    rf"(^|[[:space:]])rev64(\.{shape}[[:space:]]|[[:space:]].*\.{shape})",
                    1,
                    leaf,
                    f"NEON {shape} lane reversal in {lane}",
                )
            c.require_leaf_instruction(
                r"(^|[[:space:]])ext(\.16b[[:space:]]|[[:space:]].*\.16b).*#(0x)?8([^[:xdigit:]]|$)",
                1,
                leaf,
                f"eight-byte half exchange in {lane} reverse",
            )
        else:
            instruction = {
                "interleave_low": "zip1",
                "interleave_high": "zip2",
                "deinterleave_even": "uzp1",
                "deinterleave_odd": "uzp2",
            }[operation]
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){instruction}(\.{shape}[[:space:]]|[[:space:]].*\.{shape}([^[:alnum:]]|$))",
                1,
                leaf,
                f"exact NEON {shape} {operation} leaf",
            )
        c.forbid_pattern(
            r"(^|[[:space:]])(b(\.[a-z]+)?|bl)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in {lane} {operation} leaf",
        )

    float_instructions = {
        "add": "fadd",
        "subtract": "fsub",
        "multiply": "fmul",
        "divide": "fdiv",
        "min_number": "fminnm",
        "max_number": "fmaxnm",
    }
    for lane, operation, suffix, shape, _x86_shape in rows(
        "float_binary_codegen_cases.txt"
    ):
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"float-binary-leaf-{lane}-{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}{symbol_suffix}",
            native,
            f"float_binary_codegen_probe__{lane}_{operation}",
            t / "float-binary-probe.txt",
            leaf,
        )
        instruction = float_instructions[operation]
        c.require_leaf_instruction(
            rf"(^|[[:space:]])({instruction}\.{shape}[[:space:]]|{instruction}[[:space:]].*\.{shape}([^[:alnum:]]|$))",
            1,
            leaf,
            f"exact NEON {shape} {operation} leaf",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])(b(\.[a-z]+)?|bl)[[:space:]]",
            leaf,
            f"branch or out-of-line helper in {lane} {operation} leaf",
        )


def check_memory_slides_shifts_construction(c: Checker) -> None:
    t = c.temporary
    for lane, operation, suffix in rows("complete_memory_codegen_cases.txt"):
        if lane == "u8" and operation == "load_unaligned":
            continue
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        leaf = t / f"complete-memory-leaf-{lane}-{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{operation}{symbol_suffix}",
            t / "native.txt",
            f"complete_memory_codegen_probe__{lane}_{operation}",
            t / "complete-memory-probe.txt",
            leaf,
        )
        if c.register_operand_memory_family(lane):
            if operation in {"load", "load_unaligned", "load_aligned"}:
                c.require_leaf_instruction(
                    r"(^|[[:space:]])ldr[[:space:]]+q[0-9]+,[[:space:]]*\[",
                    1,
                    leaf,
                    f"AArch64 {lane} {operation} vector load transfer",
                )
                c.require_leaf_instruction(
                    r"(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[",
                    0,
                    leaf,
                    f"no result store in register-operand {lane} {operation} leaf",
                )
            else:
                c.require_leaf_instruction(
                    r"(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[",
                    1,
                    leaf,
                    f"AArch64 {lane} {operation} vector store transfer",
                )
        else:
            c.require_leaf_instruction(
                r"(^|[[:space:]])ldr[[:space:]]+q0,[[:space:]]*\[",
                1,
                leaf,
                f"AArch64 {lane} {operation} vector load transfer",
            )
            c.require_leaf_instruction(
                r"(^|[[:space:]])str[[:space:]]+q0,[[:space:]]*\[",
                1,
                leaf,
                f"AArch64 {lane} {operation} vector store transfer",
            )
        c.forbid_pattern(
            r"flyology_simd__(backends__scalar__|wide__)?(load|store)(_unaligned|_aligned)?",
            leaf,
            f"portable, Scalar, or Wide helper in AArch64 {lane} {operation} leaf",
        )

    for direction in ("low", "high"):
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
                r"ext.*16b",
                output,
                f"AArch64 immediate lane movement in {lane} {direction} caller",
            )
            c.forbid_pattern(
                r"flyology_simd__(zero|slide_lanes_toward_(low|high))",
                output,
                f"portable zero or lane-slide call in {lane} {direction} caller",
            )

    for direction in ("left", "right"):
        output = t / f"u8-shift-{direction}.txt"
        c.extract_symbol(
            f"flyology_simd__backends__native__shift_{direction}_logical",
            t / "native.txt",
            output,
        )
        c.require_pattern(
            r"ushl.*16b", output, f"AArch64 ushl in the byte {direction}-shift leaf"
        )
    for lane, shape in (
        ("i8", "16b"),
        ("u16", "8h"),
        ("i16", "8h"),
        ("u32", "4s"),
        ("i32", "4s"),
        ("u64", "2d"),
        ("i64", "2d"),
    ):
        for direction in ("left", "right"):
            output = t / f"integer-shift-{lane}-{direction}.txt"
            c.extract_symbol(
                f"integer_shift_codegen_probe__{lane}_{direction}",
                t / "integer-shift-probe.txt",
                output,
            )
            c.require_pattern(
                rf"ushl.*{shape}",
                output,
                f"AArch64 ushl in the inlined {lane} {direction} shift",
            )
            c.forbid_pattern(
                r"flyology_simd__(zero|shift_(left|right)_logical)",
                output,
                f"portable helper in the inlined {lane} {direction} shift",
            )
    for lane, shape in (("i8", "16b"), ("i16", "8h"), ("i32", "4s"), ("i64", "2d")):
        output = t / f"{lane}-sar.txt"
        c.extract_symbol(
            f"integer_shift_codegen_probe__{lane}_arithmetic_right",
            t / "integer-shift-probe.txt",
            output,
        )
        c.require_pattern(
            rf"sshl.*{shape}",
            output,
            f"inlined AArch64 arithmetic right shift for {lane}",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])bl[[:space:]]|flyology_simd__shift_right_arithmetic",
            output,
            f"portable or out-of-line arithmetic right shift for {lane}",
        )

    output = t / "construction-splat-u8.txt"
    c.extract_symbol(
        "construction_codegen_probe__splat_u8", t / "construction-probe.txt", output
    )
    c.require_pattern(
        r"(^|[[:space:]])dup(\.16b)?[[:space:]]+v[0-9]+(\.16b)?",
        output,
        "inlined AArch64 U8x16 broadcast in the public caller probe",
    )
    c.forbid_pattern(
        r"(^|[[:space:]])bl[[:space:]]|flyology_simd__(backends__native__)?splat",
        output,
        "out-of-line U8x16 broadcast in the AArch64 public caller probe",
    )
    output = t / "construction-zero-u8.txt"
    c.extract_symbol("flyology_simd__backends__native__zero", t / "native.txt", output)
    c.require_count(
        r"mov[[:space:]]+x(0|1),[[:space:]]*#0x?0",
        2,
        output,
        "two zero result registers in AArch64 U8x16 Zero",
    )
    for lane in ("i8", "u16", "i16", "u32", "i32", "u64", "i64", "f32", "f64"):
        output = t / f"construction-zero-{lane}.txt"
        c.extract_symbol(
            f"construction_codegen_probe__zero_{lane}",
            t / "construction-probe.txt",
            output,
        )
        c.require_pattern(
            r"movi(\.[0-9]+[bhsd])?.*#0x?0|mov[[:space:]]+x[0-9]+,[[:space:]]*#0x?0",
            output,
            f"AArch64 vector zero construction for {lane}",
        )
    for lane, shape in (
        ("i8", "16b"),
        ("u16", "8h"),
        ("i16", "8h"),
        ("u32", "4s"),
        ("i32", "4s"),
        ("u64", "2d"),
        ("i64", "2d"),
        ("f32", "4s"),
        ("f64", "2d"),
    ):
        output = t / f"construction-splat-{lane}.txt"
        c.extract_symbol(
            f"construction_codegen_probe__splat_{lane}",
            t / "construction-probe.txt",
            output,
        )
        c.require_pattern(
            rf"(^|[[:space:]])dup(\.{shape})?[[:space:]]+v[0-9]+(\.{shape})?",
            output,
            f"AArch64 {shape} lane broadcast for {lane}",
        )


def check_masks_and_float_reductions(c: Checker) -> None:
    t = c.temporary
    output = t / "horizontal-sum-u8x16.txt"
    c.extract_symbol(
        "flyology_simd__backends__native__horizontal_sum", t / "native.txt", output
    )
    c.require_pattern(r"uaddlv.*16b", output, "AArch64 U8x16 exact horizontal sum")
    c.require_pattern("umov", output, "AArch64 U8x16 exact-sum result transfer")
    c.forbid_pattern(
        "flyology_simd__horizontal_sum", output, "portable AArch64 Horizontal_Sum call"
    )
    for suffix in ("", "__2", "__3", "__4"):
        population = t / f"population_count{suffix}.txt"
        first = t / f"first_true{suffix}.txt"
        last = t / f"last_true{suffix}.txt"
        c.extract_symbol(
            f"flyology_simd__backends__native__population_count{suffix}",
            t / "native.txt",
            population,
        )
        c.extract_symbol(
            f"flyology_simd__backends__native__first_true{suffix}",
            t / "native.txt",
            first,
        )
        c.extract_symbol(
            f"flyology_simd__backends__native__last_true{suffix}",
            t / "native.txt",
            last,
        )
        c.require_pattern("rbit", first, "AArch64 First_True bit reversal")
        c.require_pattern("clz", first, "AArch64 First_True leading-zero count")
        c.require_pattern("clz", last, "AArch64 Last_True leading-zero count")
        c.require_pattern(
            r"(^|[[:space:]])cnt(\.8b)?[[:space:]]",
            population,
            "AArch64 Population_Count byte population count",
        )
        c.require_pattern(
            "uaddlv", population, "AArch64 Population_Count horizontal sum"
        )
        c.forbid_pattern(
            r"flyology_simd__first_true|flyology_simd__last_true",
            first,
            "portable AArch64 mask-position call",
        )
        c.forbid_pattern(
            r"flyology_simd__first_true|flyology_simd__last_true",
            last,
            "portable AArch64 mask-position call",
        )
        c.forbid_pattern(
            "flyology_simd__population_count",
            population,
            "portable AArch64 population-count call",
        )

    for precision, shape in (("f32", "4"), ("f64", "2")):
        output = t / f"unordered-{precision}x{shape}.txt"
        c.extract_symbol(
            f"unordered_codegen_probe__{precision}_unordered",
            t / "unordered-probe.txt",
            output,
        )
        c.require_count(
            "fcmeq", 2, output, f"two self-comparisons in unordered-{precision}x{shape}"
        )
        c.require_pattern(
            r"and.*16b",
            output,
            f"ordered-mask conjunction in unordered-{precision}x{shape}",
        )
        c.require_pattern(
            r"mvn.*16b",
            output,
            f"unordered-mask inversion in unordered-{precision}x{shape}",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])bl[[:space:]]|flyology_simd__unordered",
            output,
            f"portable or out-of-line helper in unordered-{precision}x{shape}",
        )

    reductions = (("f32x4", "s", 4), ("f64x2", "d", 2))
    for vector, scalar, count in reductions:
        output = t / f"reduce-add-{vector}.txt"
        c.extract_symbol(f"native_reduce_add_{vector}", t / "native.txt", output)
        c.require_count(
            rf"fadd[[:space:]]+{scalar}[0-9]+",
            count,
            output,
            f"{count_word(count)} ascending scalar NEON additions in {vector.upper()} Reduce_Add",
        )
        c.require_pattern(
            r"movi.*v[0-9]+.*#(0x)?0+([^[:xdigit:]]|$)",
            output,
            f"positive-zero accumulator in reduce-add-{vector}",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])bl[[:space:]]|flyology_simd__reduce_add",
            output,
            f"out-of-line or portable reduction in reduce-add-{vector}",
        )

    wide = (
        ("f32", "add", "add", "s", 8, "eight ordered scalar F32 additions"),
        (
            "f32",
            "min_number",
            "min",
            "s",
            7,
            "seven ordered scalar F32 minimum-number steps",
        ),
        (
            "f32",
            "max_number",
            "max",
            "s",
            7,
            "seven ordered scalar F32 maximum-number steps",
        ),
        ("f64", "add", "add", "d", 4, "four ordered scalar F64 additions"),
        (
            "f64",
            "min_number",
            "min",
            "d",
            3,
            "three ordered scalar F64 minimum-number steps",
        ),
        (
            "f64",
            "max_number",
            "max",
            "d",
            3,
            "three ordered scalar F64 maximum-number steps",
        ),
    )
    for precision, operation, short, scalar, count, description in wide:
        name = f"wide-{precision}-reduce-{short}"
        output = t / f"{name}.txt"
        c.extract_symbol(
            f"wide_float_reduction_codegen_probe__{precision}_reduce_{operation}",
            t / "wide-float-reduction-probe.txt",
            output,
        )
        c.require_count(
            (
                rf"f{short if short != 'add' else 'add'}nm[[:space:]]+{scalar}"
                if short in {"min", "max"}
                else rf"fadd[[:space:]]+{scalar}"
            ),
            count,
            output,
            f"{description} in the Wide reduction caller",
        )
    c.require_count(
        r"fmov[[:space:]]+s2,[[:space:]]*wzr",
        1,
        t / "wide-f32-reduce-add.txt",
        "positive-zero start in the Wide F32 Reduce_Add caller",
    )
    c.require_count(
        r"fmov[[:space:]]+d2,[[:space:]]*xzr",
        1,
        t / "wide-f64-reduce-add.txt",
        "positive-zero start in the Wide F64 Reduce_Add caller",
    )
    for precision, scalar in (("f32", "s"), ("f64", "d")):
        for extrema in ("min", "max"):
            name = f"wide-{precision}-reduce-{extrema}"
            c.require_count(
                rf"fmov[[:space:]]+{scalar}2,[[:space:]]*{scalar}0",
                1,
                t / f"{name}.txt",
                f"lane-zero start in {name}",
            )
    for name in (
        "wide-f32-reduce-add",
        "wide-f32-reduce-min",
        "wide-f32-reduce-max",
        "wide-f64-reduce-add",
        "wide-f64-reduce-min",
        "wide-f64-reduce-max",
    ):
        output = t / f"{name}.txt"
        c.require_count(
            r"ldr[[:space:]]+q", 2, output, f"two Wide input-half loads in {name}"
        )
        c.forbid_pattern(
            r"(^|[[:space:]])bl[[:space:]]|flyology_simd__(wide__)?reduce_",
            output,
            f"out-of-line or portable reduction in {name}",
        )


def count_word(count: int) -> str:
    return {2: "two", 4: "four"}[count]


def check_u8_and_integer_reductions(c: Checker) -> None:
    t = c.temporary
    combined = c.native_and_probes()
    broad = (
        ("cmeq", "NEON byte comparison"),
        (r"add.*16b", "NEON wrapping byte add"),
        (r"sub.*16b", "NEON wrapping byte subtract"),
        ("uqadd", "NEON saturating byte add"),
        ("uqsub", "NEON saturating byte subtract"),
        (r"orr.*16b", "NEON byte OR"),
        (r"eor.*16b", "NEON byte XOR"),
        (r"mvn.*16b", "NEON byte complement"),
        (r"ushl.*16b", "NEON defined byte shifts"),
        (r"cmhi.*16b", "NEON unsigned ordered comparison"),
        (r"cmhs.*16b", "NEON unsigned inclusive comparison"),
        (r"bsl.*16b", "NEON masked selection"),
        (r"rev64.*16b", "NEON byte reversal"),
        (r"zip1.*16b", "NEON low interleave"),
        (r"zip2.*16b", "NEON high interleave"),
        (r"uzp1.*16b", "NEON even deinterleave"),
        (r"uzp2.*16b", "NEON odd deinterleave"),
        (r"uminv.*16b", "NEON unsigned byte minimum reduction"),
        (r"umaxv.*16b", "NEON unsigned byte maximum reduction"),
    )
    for pattern, description in broad:
        c.require_pattern(pattern, combined, description)

    u8_operations = (
        ("add_wrap", r"add.*16b", "add_wrap|neon_add_wrap"),
        ("subtract_wrap", r"sub.*16b", "subtract_wrap|neon_subtract_wrap"),
        ("multiply_wrap", r"mul.*16b", "multiply_wrap|neon_multiply_wrap"),
        ("add_saturate", r"uqadd.*16b", "add_saturate|neon_add_saturate"),
        (
            "subtract_saturate",
            r"uqsub.*16b",
            "subtract_saturate|neon_subtract_saturate",
        ),
        ("bitwise_and", r"and.*16b", "bitwise_and|neon_bitwise_and"),
        ("bitwise_or", r"orr.*16b", "bitwise_or|neon_bitwise_or"),
        ("bitwise_xor", r"eor.*16b", "bitwise_xor|neon_bitwise_xor"),
        ("bitwise_not", r"mvn.*16b", "bitwise_not|neon_bitwise_not"),
        ("equal", r"cmeq.*16b", "equal|equal_bits"),
        ("less_than", r"cmhi.*16b", "less_than|greater_bits"),
        ("less_equal", r"cmhs.*16b", "less_equal|greater_equal_bits"),
        ("greater_than", r"cmhi.*16b", "greater_than|greater_bits"),
        ("greater_equal", r"cmhs.*16b", "greater_equal|greater_equal_bits"),
        ("select_value", r"bsl.*16b", "select_value"),
        ("min", r"umin.*16b", "min|neon_min"),
        ("max", r"umax.*16b", "max|neon_max"),
        (
            "reduce_add_wrap",
            r"addv.*16b",
            "reduce_add_wrap|native_reduce_add_wrap_u8x16",
        ),
        ("reduce_min", r"uminv.*16b", "reduce_min|native_reduce_min_u8x16"),
        ("reduce_max", r"umaxv.*16b", "reduce_max|native_reduce_max_u8x16"),
        ("reverse_bytes", r"rev64.*16b", "reverse_bytes|neon_reverse_bytes"),
        ("reverse_lanes", r"rev64.*16b", "reverse_lanes|neon_reverse_bytes"),
        ("interleave_low", r"zip1.*16b", "interleave_low|neon_interleave_low"),
        ("interleave_high", r"zip2.*16b", "interleave_high|neon_interleave_high"),
        ("deinterleave_even", r"uzp1.*16b", "deinterleave_even|neon_deinterleave_even"),
        ("deinterleave_odd", r"uzp2.*16b", "deinterleave_odd|neon_deinterleave_odd"),
    )
    for operation, pattern, symbols in u8_operations:
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
            f"AArch64 U8 {operation} caller",
        )
        c.require_exact_u8_operation(
            caller, selected, pattern, operation, f"AArch64 U8 {operation}"
        )
    for operation in (
        "equal",
        "less_than",
        "less_equal",
        "greater_than",
        "greater_equal",
    ):
        output = t / f"u8-native-{operation}.txt"
        c.require_count(
            r"uaddlv.*8b",
            2,
            output,
            f"two byte-half mask sums in AArch64 U8 {operation}",
        )
        c.require_count(
            "umov", 2, output, f"two mask-half transfers in AArch64 U8 {operation}"
        )
        c.require_pattern(
            r"ext.*16b.*#(0x)?8",
            output,
            f"high mask-half extraction in AArch64 U8 {operation}",
        )
    c.require_pattern(
        r"cmtst.*16b",
        t / "u8-native-select_value.txt",
        "compact-mask expansion in AArch64 U8 Select_Value",
    )
    c.require_pattern(
        r"bsl.*16b",
        t / "u8-native-select_value.txt",
        "bit selection in AArch64 U8 Select_Value",
    )
    for operation in ("reverse_bytes", "reverse_lanes"):
        c.require_pattern(
            r"ext.*16b.*#(0x)?8",
            t / f"u8-native-{operation}.txt",
            f"byte-half exchange in AArch64 U8 {operation}",
        )
    c.require_pattern(
        "umov",
        t / "u8-native-reduce_add_wrap.txt",
        "result transfer in AArch64 U8 Reduce_Add_Wrap",
    )

    selected = (
        (
            "native_reduce_add_wrap_i32x4",
            "reduce_add_i32",
            r"addv.*4s",
            "NEON signed-32 wrapping reduction",
        ),
        (
            "native_reduce_min_u16x8",
            "reduce_min_u16",
            r"uminv.*8h",
            "NEON unsigned-16 minimum reduction",
        ),
        (
            "native_reduce_max_i8x16",
            "reduce_max_i8",
            r"smaxv.*16b",
            "NEON signed-byte maximum reduction",
        ),
        (
            "native_reduce_add_wrap_u64x2",
            "reduce_add_u64",
            r"addp.*2d",
            "NEON unsigned-64 wrapping reduction",
        ),
    )
    for symbol, name, pattern, description in selected:
        output = t / f"{name}.txt"
        c.extract_symbol(symbol, t / "native.txt", output)
        c.require_pattern(pattern, output, description)
    for symbol, name, checks in (
        (
            "native_reduce_min_i64x2",
            "reduce_min_i64",
            (
                (r"dup.*2d.*v[0-9]+.*\[1\]", "NEON signed-64 reduction lane broadcast"),
                (r"cmgt.*2d", "NEON signed-64 minimum comparison"),
                (r"bit.*16b", "NEON signed-64 minimum selection"),
            ),
        ),
        (
            "native_reduce_max_u64x2",
            "reduce_max_u64",
            (
                (
                    r"dup.*2d.*v[0-9]+.*\[1\]",
                    "NEON unsigned-64 reduction lane broadcast",
                ),
                (r"cmhi.*2d", "NEON unsigned-64 maximum comparison"),
                (r"bif.*16b", "NEON unsigned-64 maximum selection"),
            ),
        ),
    ):
        output = t / f"{name}.txt"
        c.extract_symbol(symbol, t / "native.txt", output)
        for pattern, description in checks:
            c.require_pattern(pattern, output, description)

    reduction_rows = (
        ("u8", "none", "16b", "b", "u"),
        ("i8", "2", "16b", "b", "s"),
        ("u16", "3", "8h", "h", "u"),
        ("i16", "4", "8h", "h", "s"),
        ("u32", "5", "4s", "s", "u"),
        ("i32", "6", "4s", "s", "s"),
        ("u64", "7", "2d", "d", "u"),
        ("i64", "8", "2d", "d", "s"),
    )
    for lane, suffix, shape, letter, prefix in reduction_rows:
        symbol_suffix = "" if suffix == "none" else f"__{suffix}"
        outputs = {}
        for operation in ("reduce_add_wrap", "reduce_min", "reduce_max"):
            output = t / f"integer_reduction_leaf_{lane}_{operation}.txt"
            outputs[operation] = output
            c.extract_symbol(
                f"flyology_simd__backends__native__{operation}{symbol_suffix}",
                t / "native.txt",
                output,
            )
            c.forbid_pattern(
                r"flyology_simd__(backends__scalar__)?reduce_|flyology_simd__wide__",
                output,
                f"portable, Scalar, or Wide helper in {lane} {operation} leaf",
            )
            c.forbid_pattern(
                r"(^|[[:space:]])(b|bl)[[:space:]].*flyology_simd__",
                output,
                f"out-of-line Flyology helper in {lane} {operation} leaf",
            )
        if lane == "u8":
            c.require_pattern(
                r"(^|[[:space:]])(addv\.16b[[:space:]]|addv[[:space:]].*16b([^[:alnum:]]|$))",
                combined,
                "unsigned-byte wrapping sum in U8 Reduce_Add_Wrap",
            )
        elif shape == "2d":
            c.require_count(
                r"(^|[[:space:]])(addp\.2d[[:space:]]|addp[[:space:]].*2d([^[:alnum:]]|$))",
                1,
                outputs["reduce_add_wrap"],
                f"one exact 64-bit pairwise sum in {lane} Reduce_Add_Wrap",
            )
        else:
            c.require_count(
                rf"(^|[[:space:]])(addv\.{shape}[[:space:]]|addv[[:space:]].*{shape}([^[:alnum:]]|$))",
                1,
                outputs["reduce_add_wrap"],
                f"one exact packed sum in {lane} Reduce_Add_Wrap",
            )
        if shape == "2d":
            compare = "cmgt" if prefix == "s" else "cmhi"
            for operation in ("reduce_min", "reduce_max"):
                c.require_count(
                    r"(^|[[:space:]])(dup\.2d[[:space:]].*\[1\]|dup[[:space:]].*2d.*\[1\])",
                    1,
                    outputs[operation],
                    f"one high-lane broadcast in {lane} {operation}",
                )
                c.require_count(
                    rf"(^|[[:space:]])({compare}\.2d[[:space:]]|{compare}[[:space:]].*2d([^[:alnum:]]|$))",
                    1,
                    outputs[operation],
                    f"one 64-bit comparison in {lane} {operation}",
                )
            c.require_at_most(
                r"(^|[[:space:]])(bit\.16b[[:space:]]|bit[[:space:]].*16b([^[:alnum:]]|$))",
                1,
                outputs["reduce_min"],
                f"one minimum selection in {lane} Reduce_Min",
            )
            c.require_at_most(
                r"(^|[[:space:]])(bif\.16b[[:space:]]|bif[[:space:]].*16b([^[:alnum:]]|$))",
                1,
                outputs["reduce_max"],
                f"one maximum selection in {lane} Reduce_Max",
            )
        else:
            c.require_count(
                rf"(^|[[:space:]])({prefix}minv\.{shape}[[:space:]]|{prefix}minv[[:space:]].*{shape}([^[:alnum:]]|$))",
                1,
                outputs["reduce_min"],
                f"one exact packed minimum in {lane} Reduce_Min",
            )
            c.require_count(
                rf"(^|[[:space:]])({prefix}maxv\.{shape}[[:space:]]|{prefix}maxv[[:space:]].*{shape}([^[:alnum:]]|$))",
                1,
                outputs["reduce_max"],
                f"one exact packed maximum in {lane} Reduce_Max",
            )
        for operation, output in outputs.items():
            if lane == "u8" and operation == "reduce_add_wrap":
                c.require_pattern(
                    r"(^|[[:space:]])umov(\.h)?[[:space:]]",
                    output,
                    "widened sum transfer in U8 Reduce_Add_Wrap",
                )
            else:
                c.require_pattern(
                    rf"(^|[[:space:]])(str[[:space:]]+{letter}0|u?mov\.{letter}[[:space:]]|umov[[:space:]])",
                    output,
                    f"result transfer in {lane} {operation}",
                )


def check_multiply_select_and_permute(c: Checker) -> None:
    t = c.temporary
    for vector in ("u64", "i64"):
        output = t / f"multiply_{vector}.txt"
        c.extract_symbol(f"native_multiply_wrap_{vector}x2", t / "native.txt", output)
        checks = (
            (
                r"(^|[[:space:]])uzp1(\.4s)?[[:space:]]+v[0-9]+",
                2,
                "two low-word deinterleaves",
            ),
            (
                r"(^|[[:space:]])uzp2(\.4s)?[[:space:]]+v[0-9]+",
                2,
                "two high-word deinterleaves",
            ),
            (
                r"(^|[[:space:]])umull(\.2d)?[[:space:]]+v[0-9]+",
                1,
                "one low-word full product",
            ),
            (
                r"(^|[[:space:]])mul(\.2s)?[[:space:]]+v[0-9]+",
                1,
                "one first cross product",
            ),
            (
                r"(^|[[:space:]])mla(\.2s)?[[:space:]]+v[0-9]+",
                1,
                "one second cross product",
            ),
            (
                r"(^|[[:space:]])shll(\.2d)?[[:space:]]+v[0-9]+.*#(32|0x20)([^[:xdigit:]]|$)",
                1,
                "32-bit cross-product shift",
            ),
            (
                r"(^|[[:space:]])add(\.2d)?[[:space:]]+v[0-9]+",
                1,
                "one modulo-64 product combination",
            ),
        )
        for pattern, count, description in checks:
            c.require_count(
                pattern, count, output, f"{description} in multiply_{vector}"
            )
        c.forbid_pattern(
            r"(^|[[:space:]])bl[[:space:]]|flyology_simd__multiply_wrap",
            output,
            f"out-of-line or portable multiplication in multiply_{vector}",
        )

    for lane, vector in (
        ("i8", "i8x16"),
        ("u16", "u16x8"),
        ("i16", "i16x8"),
        ("u32", "u32x4"),
        ("i32", "i32x4"),
        ("u64", "u64x2"),
        ("i64", "i64x2"),
        ("f32", "f32x4"),
        ("f64", "f64x2"),
    ):
        output = t / f"select_{lane}.txt"
        c.extract_leaf_or_probe(
            f"native_select_{vector}",
            t / "native.txt",
            f"comparison_codegen_probe__selected_{lane}_select_value",
            t / "comparison-probe.txt",
            output,
        )
        c.require_count(
            r"(^|[[:space:]])cmtst(\.(16b|8h|4s|2d))?[[:space:]]+v[0-9]+",
            1,
            output,
            f"one lane-mask expansion in select_{lane}",
        )
        c.require_at_most(
            r"(^|[[:space:]])bsl(\.16b)?[[:space:]]+v[0-9]+",
            1,
            output,
            f"one NEON bit selection in select_{lane}",
        )
        c.forbid_pattern(
            r"(^|[[:space:]])bl[[:space:]]|flyology_simd__select_value",
            output,
            f"out-of-line or portable selection in select_{lane}",
        )

    output = t / "table_lookup.txt"
    c.extract_leaf_or_probe(
        "native_table_lookup_u8x16",
        t / "native.txt",
        "table_lookup_codegen_probe__lookup",
        t / "table-lookup-probe.txt",
        output,
    )
    c.require_pattern(r"tbl.*16b", output, "NEON byte-table lookup")
    c.forbid_pattern(
        r"(^|[[:space:]])bl[[:space:]]|flyology_simd__table_lookup",
        output,
        "portable or out-of-line AArch64 Table_Lookup helper",
    )
    lanes = ("u8", "i8", "u16", "i16", "u32", "i32", "f32", "u64", "i64", "f64")
    for lane in lanes:
        for operation in ("compress", "expand"):
            output = t / f"{lane}_{operation}.txt"
            c.extract_symbol(
                f"permute_codegen_probe__{lane}_{operation}",
                t / "permute-probe.txt",
                output,
            )
            c.require_pattern(
                r"tbl.*16b", output, f"inlined NEON {lane} {operation} caller"
            )
    c.forbid_pattern(
        r"flyology_simd__backends__native__(compress|expand)",
        t / "permute-probe.txt",
        "compression backend call in caller probe",
    )
    table_1 = r"tbl(\.16b)?[[:space:]]+v[0-9]+(\.16b)?,.*\{[[:space:]]*v[0-9]+(\.16b)?[[:space:]]*\},[[:space:]]*v[0-9]+(\.16b)?"
    table_2 = r"tbx(\.16b)?[[:space:]]+v[0-9]+(\.16b)?,.*\{[[:space:]]*v[0-9]+(\.16b)?[[:space:]]*\},[[:space:]]*v[0-9]+(\.16b)?"
    for lane in lanes:
        output = t / f"permute_{lane}.txt"
        c.extract_symbol(
            f"permute_codegen_probe__{lane}_permute", t / "permute-probe.txt", output
        )
        c.require_pattern(r"tbl.*16b", output, f"NEON {lane} public lane permutation")
        output = t / f"permute_2_{lane}.txt"
        c.extract_symbol(
            f"permute_codegen_probe__{lane}_permute_2", t / "permute-probe.txt", output
        )
        c.require_count(table_1, 1, output, f"one NEON {lane} left-source table lookup")
        c.require_count(
            table_2, 1, output, f"one NEON {lane} right-source table extension"
        )
    c.forbid_pattern(
        "flyology_simd__backends__native__permute_lanes",
        t / "permute-probe.txt",
        "lane-permutation backend call in caller probe",
    )


def _wide_outputs(c: Checker) -> None:
    t = c.temporary
    names = (
        "f32_to_u32_bits",
        "u8_widen_low",
        "u16_narrow_saturate",
        "i32_to_f32",
        "u8_table_lookup",
        "u8_horizontal_sum",
        "u8_compress",
        "u16_expand",
        "f32_compress",
        "f64_expand",
        "u8_permute",
        "u16_permute_2",
        "f32_permute",
        "f64_permute_2",
        "u8_reverse",
        "u16_interleave_low",
        "f32_deinterleave_odd",
        "f64_slide_low_one",
    )
    output_names = {
        "f32_to_u32_bits": "wide_f32_to_u32",
        "u8_widen_low": "wide_u8_widen",
        "u16_narrow_saturate": "wide_u16_narrow",
        "i32_to_f32": "wide_i32_to_f32",
        "u16_interleave_low": "wide_u16_interleave",
        "f32_deinterleave_odd": "wide_f32_deinterleave",
        "f64_slide_low_one": "wide_f64_slide",
    }
    c.extract_symbol(
        "wide_codegen_probe__u8_add", t / "wide-probe.txt", t / "wide_u8_add.txt"
    )
    c.extract_symbol(
        "wide_codegen_probe__f32_multiply",
        t / "wide-probe.txt",
        t / "wide_f32_multiply.txt",
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
    for name in names:
        c.extract_symbol(
            f"wide_codegen_probe__{name}",
            t / "wide-probe.txt",
            t / f"{output_names.get(name, 'wide_' + name)}.txt",
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


def check_wide_mechanisms(c: Checker) -> None:
    t = c.temporary
    _wide_outputs(c)
    register = r"v[0-9]+(\.16b)?"
    two = rf"({register},[[:space:]]*{register}|{register}-[[:space:]]*{register})"
    four = rf"({register},[[:space:]]*{register},[[:space:]]*{register},[[:space:]]*{register}|{register}-[[:space:]]*{register})"
    tbl_two = rf"tbl(\.16b)?[[:space:]]+{register},.*\{{[[:space:]]*{two}[[:space:]]*\}},[[:space:]]*{register}"
    tbl_four = rf"tbl(\.16b)?[[:space:]]+{register},.*\{{[[:space:]]*{four}[[:space:]]*\}},[[:space:]]*{register}"
    for name in ("wide_u8_permute", "wide_f32_permute"):
        c.require_count(
            tbl_two,
            2,
            t / f"{name}.txt",
            f"two-register TBL operations in AArch64 {name} caller",
        )
        c.forbid_pattern(
            r"flyology_simd__wide__(permute_mechanism|native)__permute_lanes|flyology_simd__(__wide)?__(extract|from_lanes)",
            t / f"{name}.txt",
            f"per-lane or dispatcher call in AArch64 {name} caller",
        )
    for name in ("wide_u16_permute_2", "wide_f64_permute_2"):
        c.require_count(
            tbl_four,
            2,
            t / f"{name}.txt",
            f"four-register TBL operations in AArch64 {name} caller",
        )
        c.forbid_pattern(
            r"flyology_simd__wide__(permute_mechanism|native)__permute_lanes|flyology_simd__(__wide)?__(extract|from_lanes)",
            t / f"{name}.txt",
            f"per-lane or dispatcher call in AArch64 {name} caller",
        )
    for name in ("wide_u8_reverse", "wide_f64_slide"):
        c.require_count(
            tbl_two,
            2,
            t / f"{name}.txt",
            f"two-register TBL operations in AArch64 {name} caller",
        )
    for name in ("wide_u16_interleave", "wide_f32_deinterleave"):
        c.require_count(
            tbl_four,
            2,
            t / f"{name}.txt",
            f"four-register TBL operations in AArch64 {name} caller",
        )
    for name in (
        "wide_u8_reverse",
        "wide_u16_interleave",
        "wide_f32_deinterleave",
        "wide_f64_slide",
    ):
        c.forbid_pattern(
            r"flyology_simd__wide__(permute_mechanism|native)__(reverse_lanes|interleave|deinterleave|slide_lanes)|flyology_simd__(__wide)?__(extract|from_lanes)",
            t / f"{name}.txt",
            f"per-lane or dispatcher call in AArch64 {name} caller",
        )
    limits = (
        ("wide_u8_add", 2, "two inlined NEON byte-add leaves"),
        ("wide_f32_multiply", 2, "two NEON F32-multiply leaves"),
        ("wide_f32_to_u32", 2, "two NEON F32-to-U32 bit-cast leaves"),
        ("wide_u8_widen", 2, "two NEON byte-widen leaves"),
        ("wide_u16_narrow", 2, "two NEON U16-narrow leaves"),
        ("wide_i32_to_f32", 2, "two NEON I32-to-F32 conversion leaves"),
        (
            "wide_u8_table_lookup",
            1,
            "one target-selected 32-lane table-lookup mechanism",
        ),
        ("wide_u8_horizontal_sum", 2, "two exact byte-sum leaves"),
    )
    for name, limit, description in limits:
        c.require_at_most(
            r"(^|[[:space:]])bl[[:space:]]",
            limit,
            t / f"{name}.txt",
            f"{description} in wide caller",
        )
    for name in (
        "wide_u8_compress",
        "wide_u16_expand",
        "wide_f32_compress",
        "wide_f64_expand",
    ):
        c.require_count(
            tbl_two,
            2,
            t / f"{name}.txt",
            f"two-register TBL operations in AArch64 {name} caller",
        )
        c.forbid_pattern(
            r"flyology_simd__wide__(compact_mechanism|native)__(compress|expand)|flyology_simd__(__wide)?__(extract|from_lanes|test)",
            t / f"{name}.txt",
            f"per-lane or dispatcher call in AArch64 {name} caller",
        )
    for lane in ("u8", "i8", "u16", "i16", "u32", "i32", "u64", "i64", "f32", "f64"):
        for operation in ("compress", "expand"):
            name = f"wide_compact_{lane}_{operation}"
            output = t / f"{name}.txt"
            c.extract_symbol(
                f"wide_compact_codegen_probe__{lane}_{operation}",
                t / "wide-compact-probe.txt",
                output,
            )
            c.require_count(
                tbl_two,
                2,
                output,
                f"two-register TBL operations in AArch64 {lane} {operation} caller",
            )
            c.forbid_pattern(
                r"flyology_simd__(__wide)?__to_bit_mask|flyology_simd__backends__native__to_bit_mask",
                output,
                f"out-of-line mask extraction in AArch64 {lane} {operation} caller",
            )
            c.forbid_pattern(
                r"flyology_simd__wide__(compact_mechanism|native)__(compress|expand)|flyology_simd__(__wide)?__(extract|from_lanes|test)",
                output,
                f"per-lane or dispatcher call in AArch64 {lane} {operation} caller",
            )
    c.require_at_most(
        "flyology_simd__",
        0,
        t / "wide-compact-object-undefined.txt",
        "no Flyology operation remains unresolved in the AArch64 Wide compact object",
    )
    c.forbid_pattern(
        r"flyology_simd__wide__to_bit_mask|flyology_simd__wide__(compress|expand)|flyology_simd__wide__native__",
        t / "wide-compact-object-undefined.txt",
        "portable or public Wide helper retained in the AArch64 Wide compact object",
    )
    for vector in (
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
    ):
        for operation in ("permute_1", "reverse", "slide_low", "slide_high"):
            _check_wide_movement(c, vector, operation, tbl_two, "two two-register")
        for operation in (
            "permute_2",
            "interleave_low",
            "interleave_high",
            "deinterleave_even",
            "deinterleave_odd",
        ):
            _check_wide_movement(c, vector, operation, tbl_four, "two four-register")

    c.require_count(
        r"cmeq.*16b",
        2,
        t / "wide_u8_equal.txt",
        "two NEON equality operations in the composed Wide U8 caller",
    )
    c.forbid_pattern(
        r"(^|[[:space:]])bl[[:space:]]",
        t / "wide_u8_equal.txt",
        "out-of-line helper retained in the composed Wide U8 equality caller",
    )
    for operation in ("less", "less_equal", "greater", "greater_equal"):
        c.require_at_most(
            r"(^|[[:space:]])bl[[:space:]]",
            2,
            t / f"wide_u8_{operation}.txt",
            f"two selected NEON operations in composed Wide U8 {operation} caller",
        )
        c.require_at_most(
            r"(^|[[:space:]])bl[[:space:]]",
            2,
            t / f"wide_i8_{operation}.txt",
            f"two selected NEON operations in composed Wide I8 {operation} caller",
        )
    for name, description in (
        (
            "wide_i8_equal",
            "two selected NEON operations in composed Wide I8 equality caller",
        ),
        (
            "wide_u8_select",
            "two selected NEON operations in composed Wide U8 selection caller",
        ),
        (
            "wide_i8_select",
            "two selected operations in composed Wide I8 selection caller",
        ),
    ):
        c.require_at_most(
            r"(^|[[:space:]])bl[[:space:]]", 2, t / f"{name}.txt", description
        )

    output = t / "wide_lookup_leaf.txt"
    c.extract_symbol("table_lookup_half", t / "wide-lookup.txt", output)
    c.require_pattern(tbl_two, output, "AArch64 32-entry byte-table lookup leaf")
    routes = (
        (
            r"flyology_simd__backends__native__(neon_)?add_wrap",
            "wide U8 addition calls selected 128-bit native leaves after mechanism inlining",
        ),
        (
            r"flyology_simd__backends__native__native_(add|subtract|multiply|divide)_(f32x4|f64x2)",
            "wide floating arithmetic calls selected 128-bit native leaves",
        ),
        (
            r"flyology_simd__backends__native__bit_cast",
            "wide F32 bit cast calls the selected 128-bit native leaf",
        ),
        (
            r"flyology_simd__backends__native__widen_(low|high)",
            "wide byte widening calls selected 128-bit native leaves",
        ),
        (
            r"flyology_simd__backends__native__narrow_saturate",
            "wide U16 narrowing calls selected 128-bit native leaves",
        ),
        (
            r"flyology_simd__backends__native__convert_round",
            "wide integer conversion calls selected 128-bit native leaves",
        ),
        (
            r"flyology_simd__backends__native__horizontal_sum",
            "wide exact byte sum calls the selected 128-bit native leaf",
        ),
        (
            r"flyology_simd__backends__native__(greater|greater_equal|compare_|select_value)",
            "wide byte predicates call selected 128-bit native operations",
        ),
    )
    for pattern, description in routes:
        c.require_route_or_inlined(pattern, t / "wide-undefined.txt", description)
    c.require_pattern(
        "flyology_simd__wide__lookup_mechanism__table_lookup_32",
        t / "wide-undefined.txt",
        "wide lookup calls the target-selected lookup mechanism",
    )
    c.require_native_route(
        r"flyology_simd__backends__native__((neon_)?add_wrap|native_(add|subtract|multiply|divide)_(f32x4|f64x2)|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|greater_bits|greater_equal_bits|compare_(greater(_equal)?_)?i8x16|select_value)|flyology_simd__wide__lookup_mechanism__table_lookup_32",
        22,
        t / "wide-undefined.txt",
        t / "wide-probe.txt",
        "only the intended native primitive classes remain unresolved from the wide probe",
    )
    c.forbid_pattern(
        r"flyology_simd__(wide__)?(add_wrap|add|subtract|multiply|divide|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)",
        t / "wide-undefined.txt",
        "scalar or Wide primitive call from the native wide probe",
    )
    c.forbid_pattern(
        r"flyology_simd__wide__native__(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)",
        t / "wide-probe.txt",
        "wide native dispatcher call in caller probe",
    )


def _check_wide_movement(
    c: Checker, vector: str, operation: str, pattern: str, phrase: str
) -> None:
    t = c.temporary
    output = t / f"wide_movement_{vector}_{operation}.txt"
    c.extract_symbol(
        f"wide_movement_codegen_probe__{vector}_{operation}",
        t / "wide-movement-probe.txt",
        output,
    )
    c.require_count(
        pattern,
        2,
        output,
        f"{phrase} TBL operations in AArch64 {vector} {operation} caller",
    )
    c.forbid_pattern(
        r"flyology_simd__wide__(extract|from_lanes|permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)",
        output,
        f"call or per-lane helper in AArch64 {vector} {operation} caller",
    )


def check_instruction_classes_and_conversions(c: Checker) -> None:
    t = c.temporary
    slide_outputs = (
        (
            "u8",
            "low",
            r"ext.*#(0x)?0*1([^[:xdigit:]]|$)",
            "constant U8 slide toward low in caller",
        ),
        (
            "u8",
            "high",
            r"ext.*#(0x0*f|0*15)([^[:xdigit:]]|$)",
            "constant U8 slide toward high in caller",
        ),
        (
            "u16",
            "low",
            r"ext.*#(0x)?0*2([^[:xdigit:]]|$)",
            "constant U16 lane scaling in caller",
        ),
        (
            "u32",
            "low",
            r"ext.*#(0x)?0*4([^[:xdigit:]]|$)",
            "constant U32 lane scaling in caller",
        ),
        (
            "f32",
            "low",
            r"ext.*#(0x)?0*4([^[:xdigit:]]|$)",
            "constant F32 slide toward low in caller",
        ),
        (
            "f32",
            "high",
            r"ext.*#(0x0*c|0*12)([^[:xdigit:]]|$)",
            "constant F32 slide toward high in caller",
        ),
        (
            "f64",
            "high",
            r"ext.*#(0x)?0*8([^[:xdigit:]]|$)",
            "constant F64 lane scaling in caller",
        ),
    )
    for lane, direction, pattern, description in slide_outputs:
        output = t / f"probe_{lane}_{direction}.txt"
        c.extract_symbol(
            f"slide_codegen_probe__{lane}_toward_{direction}",
            t / "slide-probe.txt",
            output,
        )
        c.require_pattern(pattern, output, description)
    c.forbid_pattern(
        "flyology_simd__backends__native__slide_lanes",
        t / "slide-probe.txt",
        "lane-slide dispatcher call in constant-count probe",
    )

    combined = c.native_and_probes()
    classes = (
        (r"ldr[[:space:]]+q[0-9]+", "128-bit unaligned load"),
        ("uaddlv", "vector mask/sum reduction"),
        (r"sqadd.*(16b|8h|4s|2d)", "signed saturating arithmetic"),
        (r"mul.*(16b|8h|4s)", "wrapping integer multiplication"),
        (r"add.*8h", "16-bit lane arithmetic"),
        (r"add.*4s", "32-bit lane arithmetic"),
        (r"add.*2d", "64-bit lane arithmetic"),
        (r"cmgt.*(16b|8h|4s|2d)", "signed ordered comparison"),
        (r"sshl.*(16b|8h|4s|2d)", "arithmetic right shift"),
        (r"fadd.*(4s|2d)", "floating addition"),
        (r"fmul.*(4s|2d)", "floating multiplication"),
        (r"fdiv.*(4s|2d)", "floating division"),
        (r"fminnm.*(4s|2d)", "IEEE minimum-number operation"),
        (r"fmaxnm.*(4s|2d)", "IEEE maximum-number operation"),
        (r"fminnm[[:space:]]+s[0-9]+,", "ordered F32 minimum-number reduction"),
        (r"fmaxnm[[:space:]]+s[0-9]+,", "ordered F32 maximum-number reduction"),
        (r"fminnm[[:space:]]+d[0-9]+,", "ordered F64 minimum-number reduction"),
        (r"fmaxnm[[:space:]]+d[0-9]+,", "ordered F64 maximum-number reduction"),
        (r"fcmeq.*(4s|2d)", "floating comparison"),
        (r"(uxtl|ushll)2?.*(8h|4s|2d)", "unsigned integer widening"),
        (r"(sxtl|sshll)2?.*(8h|4s|2d)", "signed integer widening"),
        (r"fcvtl2?.*2d", "floating-point widening"),
        (r"fcvtn2?.*(2s|4s)", "floating-point narrowing"),
        (r"scvtf.*4s", "signed 32-bit integer-to-floating conversion"),
        (r"scvtf.*2d", "signed 64-bit integer-to-floating conversion"),
        (r"ucvtf.*4s", "unsigned 32-bit integer-to-floating conversion"),
        (r"ucvtf.*2d", "unsigned 64-bit integer-to-floating conversion"),
        (r"fcvtzs.*4s", "binary32-to-signed-32 truncating saturating conversion"),
        (r"fcvtzs.*2d", "binary64-to-signed-64 truncating saturating conversion"),
        (r"fcvtzu.*4s", "binary32-to-unsigned-32 truncating saturating conversion"),
        (r"fcvtzu.*2d", "binary64-to-unsigned-64 truncating saturating conversion"),
    )
    for pattern, description in classes:
        c.require_pattern(pattern, combined, description)

    saturation = (
        (
            "i8",
            "u8",
            (
                (
                    r"movi.*v[0-9]+.*#(0x)?0+([,[:space:]]|$)",
                    "signed-byte conversion zero construction",
                ),
                (r"smax.*16b", "signed-byte to unsigned-byte saturation"),
            ),
        ),
        (
            "u8",
            "i8",
            (
                (
                    r"movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)",
                    "signed-byte maximum all-ones construction",
                ),
                (
                    r"ushr.*16b.*#(0x)?1([,[:space:]]|$)",
                    "signed-byte maximum construction",
                ),
                (r"umin.*16b", "unsigned-byte to signed-byte saturation"),
            ),
        ),
        (
            "i16",
            "u16",
            (
                (
                    r"movi.*v[0-9]+.*#(0x)?0+([,[:space:]]|$)",
                    "signed-16 conversion zero construction",
                ),
                (r"smax.*8h", "signed-16 to unsigned-16 saturation"),
            ),
        ),
        (
            "u16",
            "i16",
            (
                (
                    r"movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)",
                    "signed-16 maximum all-ones construction",
                ),
                (
                    r"ushr.*8h.*#(0x)?1([,[:space:]]|$)",
                    "signed-16 maximum construction",
                ),
                (r"umin.*8h", "unsigned-16 to signed-16 saturation"),
            ),
        ),
        (
            "i32",
            "u32",
            (
                (
                    r"movi.*v[0-9]+.*#(0x)?0+([,[:space:]]|$)",
                    "signed-32 conversion zero construction",
                ),
                (r"smax.*4s", "signed-32 to unsigned-32 saturation"),
            ),
        ),
        (
            "u32",
            "i32",
            (
                (
                    r"movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)",
                    "signed-32 maximum all-ones construction",
                ),
                (
                    r"ushr.*4s.*#(0x)?1([,[:space:]]|$)",
                    "signed-32 maximum construction",
                ),
                (r"umin.*4s", "unsigned-32 to signed-32 saturation"),
            ),
        ),
        (
            "i64",
            "u64",
            (
                (r"cmge.*2d.*#(0x)?0+([,[:space:]]|$)", "signed-64 nonnegative mask"),
                (r"and.*16b", "signed-64 to unsigned-64 saturation"),
            ),
        ),
        (
            "u64",
            "i64",
            (
                (
                    r"movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)",
                    "signed-64 maximum all-ones construction",
                ),
                (
                    r"ushr.*2d.*#(0x)?1([,[:space:]]|$)",
                    "signed-64 maximum construction",
                ),
                (r"cmhi.*2d", "unsigned-64 clamp mask"),
                (r"bsl.*16b", "unsigned-64 clamp selection"),
                (
                    r"mov(\.16b)?[[:space:]]+v[0-9]+(\.16b)?,[[:space:]]*v[0-9]+(\.16b)?",
                    "unsigned-64 conversion result move",
                ),
            ),
        ),
    )
    for source, target, checks in saturation:
        output = t / f"{source}_to_{target}.txt"
        c.extract_symbol(
            f"integer_conversion_codegen_probe__{source}_{target}_convert_saturate",
            t / "integer-conversion-probe.txt",
            output,
        )
        for pattern, description in checks:
            c.require_pattern(pattern, output, description)
    for pattern, description in (
        (
            r"(^|[[:space:]])(xtn2?\..*(16b|8h|4s)|xtn2?[[:space:]]+v[0-9]+\.(16b|8h|4s))",
            "truncating integer narrowing",
        ),
        (
            r"(^|[[:space:]])(uqxtn2?\..*(16b|8h|4s)|uqxtn2?[[:space:]]+v[0-9]+\.(16b|8h|4s))",
            "unsigned saturating narrowing",
        ),
        (
            r"(^|[[:space:]])(sqxtn2?\..*(16b|8h|4s)|sqxtn2?[[:space:]]+v[0-9]+\.(16b|8h|4s))",
            "signed saturating narrowing",
        ),
        (
            r"(^|[[:space:]])(sqxtun2?\..*(16b|8h|4s)|sqxtun2?[[:space:]]+v[0-9]+\.(16b|8h|4s))",
            "signed-to-unsigned saturating narrowing",
        ),
    ):
        c.require_pattern(pattern, combined, description)
    _check_exact_integer_conversions(c)


def _check_exact_integer_conversions(c: Checker) -> None:
    t = c.temporary
    widening = {
        "u8x16": ("ushll", "8h"),
        "i8x16": ("sshll", "8h"),
        "u16x8": ("ushll", "4s"),
        "i16x8": ("sshll", "4s"),
        "u32x4": ("ushll", "2d"),
        "i32x4": ("sshll", "2d"),
    }
    narrow_shapes = {
        "u8x16": ("8b", "16b"),
        "i8x16": ("8b", "16b"),
        "u16x8": ("4h", "8h"),
        "i16x8": ("4h", "8h"),
        "u32x4": ("2s", "4s"),
        "i32x4": ("2s", "4s"),
    }
    saturation = {
        "i8x16:u8x16": r"movi.*v[0-9]+.*#(0x)?0+|smax.*16b",
        "u8x16:i8x16": r"movi.*v[0-9]+.*#(0xff|255)|ushr.*16b.*#(0x)?1|umin.*16b",
        "i16x8:u16x8": r"movi.*v[0-9]+.*#(0x)?0+|smax.*8h",
        "u16x8:i16x8": r"movi.*v[0-9]+.*#(0xff|255)|ushr.*8h.*#(0x)?1|umin.*8h",
        "i32x4:u32x4": r"movi.*v[0-9]+.*#(0x)?0+|smax.*4s",
        "u32x4:i32x4": r"movi.*v[0-9]+.*#(0xff|255)|ushr.*4s.*#(0x)?1|umin.*4s",
        "i64x2:u64x2": r"cmge.*2d.*#(0x)?0+|and.*16b",
        "u64x2:i64x2": r"movi.*v[0-9]+.*#(0xff|255)|ushr.*2d.*#(0x)?1|cmhi.*2d|bsl.*16b|mov(\.16b)?[[:space:]]+v[0-9]+(\.16b)?,[[:space:]]*v[0-9]+(\.16b)?",
    }
    for kind, operation, source, target, suffix, _arity in rows(
        "integer_conversion_codegen_cases.txt"
    ):
        selected = operation if suffix == "none" else f"{operation}__{suffix}"
        leaf = t / f"aarch_integer_conversion_{kind}_{operation}.txt"
        c.extract_leaf_or_probe(
            f"flyology_simd__backends__native__{selected}",
            t / "native.txt",
            f"integer_conversion_codegen_probe__{kind}_{operation}",
            t / "integer-conversion-probe.txt",
            leaf,
        )
        c.forbid_pattern(BRANCH, leaf, f"branch or helper in {kind} {operation} leaf")
        if operation in {"widen_low", "widen_high"}:
            mnemonic, shape = widening[source]
            if operation == "widen_high":
                mnemonic += "2"
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){mnemonic}\.{shape}[[:space:]]",
                1,
                leaf,
                f"exact {mnemonic}.{shape} in {kind} {operation}",
            )
        elif operation in {"narrow_truncate", "narrow_saturate"}:
            low, high = narrow_shapes[target]
            if operation == "narrow_truncate":
                mnemonic = "xtn"
            elif source.startswith("i") and target.startswith("u"):
                mnemonic = "sqxtun"
            elif source.startswith("i"):
                mnemonic = "sqxtn"
            else:
                mnemonic = "uqxtn"
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){mnemonic}\.{low}[[:space:]]",
                1,
                leaf,
                f"exact {mnemonic}.{low} low half in {kind} {operation}",
            )
            c.require_leaf_instruction(
                rf"(^|[[:space:]]){mnemonic}2\.{high}[[:space:]]",
                1,
                leaf,
                f"exact {mnemonic}2.{high} high half in {kind} {operation}",
            )
        elif operation == "convert_saturate":
            for instruction in saturation[f"{source}:{target}"].split("|"):
                c.require_at_least(
                    rf"(^|[[:space:]]){instruction}",
                    1,
                    leaf,
                    f"exact conversion step {instruction} in {kind} {operation}",
                )


def check_algorithms(c: Checker) -> None:
    t = c.temporary
    for pattern, description in (
        (r"ldr[[:space:]]+q[0-9]+", "inlined vector load in representative loop"),
        (r"cmeq.*16b", "inlined NEON comparison in representative loop"),
        ("uaddlv", "inlined compact-mask extraction in representative loop"),
    ):
        c.require_pattern(pattern, t / "algorithm.txt", description)
    algorithms = (
        (
            "find_first_of",
            (
                (r"ldr[[:space:]]+q[0-9]+", "fused small-set NEON vector load"),
                (r"cmeq.*16b", "fused small-set NEON comparisons"),
                ("uaddlv", "fused small-set NEON mask extraction"),
            ),
        ),
        (
            "find_first_difference",
            (
                (r"ldr[[:space:]]+q[0-9]+", "fused two-buffer NEON vector loads"),
                (r"cmeq.*16b", "fused two-buffer NEON byte comparison"),
                ("uaddlv", "fused two-buffer NEON mask extraction"),
                (r"(^|[[:space:]])mvn[[:space:]]", "complemented NEON equality mask"),
            ),
        ),
    )
    for name, checks in algorithms:
        output = t / f"{name.replace('_', '-')}.txt"
        c.extract_symbol(
            f"flyology_simd__algorithms__native__{name}", t / "algorithm.txt", output
        )
        for pattern, description in checks:
            c.require_pattern(pattern, output, description)
    c.forbid_pattern(
        r"bl.*flyology_simd__backends__native__(load_unaligned|equal|to_bit_mask)",
        t / "find-first-difference.txt",
        "out-of-line primitive in the Native difference loop",
    )
    output = t / "count-in-range.txt"
    c.extract_symbol(
        "flyology_simd__algorithms__native__count_in_range", t / "algorithm.txt", output
    )
    c.require_pattern(
        r"ldr[[:space:]]+q[0-9]+", output, "Native range-count NEON vector load"
    )
    for route, description in (
        ("greater_equal", "one selected lower-bound comparison in Native range count"),
        ("less_equal", "one selected upper-bound comparison in Native range count"),
        ("mask_and", "one selected mask intersection in Native range count"),
    ):
        c.require_at_most(
            f"flyology_simd__backends__native__{route}", 1, output, description
        )
    c.require_pattern(r"cnt.*8b", output, "NEON population count in Native range count")
    c.forbid_pattern(
        r"bl.*equal_mask", t / "native.txt", "out-of-line mask helper call"
    )


def check_aarch64(c: Checker) -> None:
    check_exact_leaf_families(c)
    check_memory_slides_shifts_construction(c)
    check_masks_and_float_reductions(c)
    check_u8_and_integer_reductions(c)
    check_multiply_select_and_permute(c)
    check_wide_mechanisms(c)
    check_instruction_classes_and_conversions(c)
    check_algorithms(c)
