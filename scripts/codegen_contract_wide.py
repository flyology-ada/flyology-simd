#!/usr/bin/env python3
"""Wide-family generated-code contracts shared by both native targets."""

from __future__ import annotations

from codegen_checker import Checker, CodegenError
from codegen_contract_common import require_unique_manifest


SYMBOL_END = r"([+-]0x[[:xdigit:]]+)?([[:space:]]|$)"


def check_wide_construction(checker: Checker) -> None:
    t = checker.temporary
    cases = require_unique_manifest(
        "wide_construction_codegen_cases.txt",
        60,
        "Wide construction code-generation manifest must contain 60 unique operations",
    )
    for lane_kind, operation, suffix, half_lanes_text in cases:
        caller = t / f"wide-construction-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_construction_codegen_probe__{lane_kind}_{operation}",
            t / "wide-construction-probe.txt",
            caller,
        )
        operation_symbol = operation if suffix == "none" else f"{operation}__{suffix}"
        pattern = f"backends__native__{operation_symbol}{SYMBOL_END}"
        if operation in {"zero", "splat"}:
            if checker.matches(pattern, caller):
                checker.require_at_most(
                    pattern,
                    2,
                    caller,
                    f"two matching selected {operation} calls in {lane_kind}",
                )
                selected_count = 2
            else:
                inline = {
                    ("aarch64", "splat"): r"dup(\.[0-9]+[bhsd])?[[:space:]]",
                    ("aarch64", "zero"): r"movi(\.[0-9]+[bhsd])?[[:space:]]",
                    (
                        "x86_64",
                        "splat",
                    ): r"punpcklbw|punpcklqdq|pshufd|shufps|unpcklpd|movd",
                    ("x86_64", "zero"): r"pxor",
                }.get((checker.architecture, operation))
                if inline is None:
                    raise CodegenError(
                        f"unexpected inline {operation} in {checker.architecture} {lane_kind}"
                    )
                checker.require_pattern(
                    inline,
                    caller,
                    f"inlined {'AArch64' if checker.architecture == 'aarch64' else 'x86-64'} {lane_kind} Wide {operation.title()}{' broadcast' if checker.architecture == 'x86_64' and operation == 'splat' else ''}",
                )
                selected_count = 0
        elif operation in {"from_lanes", "to_lanes", "replace"}:
            checker.require_at_most(
                pattern,
                2,
                caller,
                f"two matching selected {operation} calls in {lane_kind}",
            )
            selected_count = 2
        else:
            selected_count = checker.count_matches(pattern, caller)
            if selected_count not in {1, 2}:
                raise CodegenError(
                    f"code-generation count mismatch: one merged call or two branch calls for {lane_kind} extract ({selected_count})"
                )
        checker.require_count(
            r"backends__native__",
            selected_count,
            caller,
            f"only matching selected operations in {lane_kind} {operation}",
        )
        checker.forbid_pattern(
            r"flyology_simd__(wide__(native__)?|backends__scalar__)?(zero|splat|from_lanes|to_lanes|extract|replace)([+-]0x[[:xdigit:]]+)?([[:space:]]|$)",
            caller,
            f"portable or dispatcher construction call in {lane_kind} {operation}",
        )
        if operation in {"extract", "replace"}:
            half_lanes = int(half_lanes_text)
            half_hex = f"{half_lanes:x}"
            if checker.architecture == "aarch64":
                adjustment = rf"sub.*#(0x{half_hex}|{half_lanes})([^[:xdigit:]]|$)"
                branch = r"(^|[[:space:]])b\.[a-z]+"
            else:
                adjustment = rf"(sub.*\$(0x{half_hex}|{half_lanes})([^[:xdigit:]]|$)|lea[lq]?[[:space:]].*-(0x{half_hex}|{half_lanes})\([^)]*\),[[:space:]]*%[[:alnum:]]+)"
                branch = r"(^|[[:space:]])j(a|ae|b|be|c|e|g|ge|l|le|na|nae|nb|nbe|nc|ne|ng|nge|nl|nle|no|np|ns|nz|o|p|pe|po|s|z)[[:space:]]"
            checker.require_pattern(
                adjustment,
                caller,
                f"high-half lane adjustment in {lane_kind} {operation}",
            )
            checker.require_pattern(
                branch,
                caller,
                f"private-half conditional selection in {lane_kind} {operation}",
            )
            checker.forbid_pattern(
                r"cmov",
                caller,
                f"unchecked branchless private-half selection in {lane_kind} {operation}",
            )
    checker.forbid_pattern(
        r"flyology_simd__(wide__(native__)?|backends__scalar__)?(zero|splat|from_lanes|to_lanes|extract|replace)([[:space:]]|$)",
        t / "wide-native-construction-undefined.txt",
        "portable or dispatcher construction operation retained in Wide.Native",
    )


def check_wide_comparison(checker: Checker, wide_backend: str) -> None:
    t = checker.temporary
    cases = require_unique_manifest(
        "wide_comparison_codegen_cases.txt",
        62,
        "Wide comparison code-generation manifest must contain 62 unique operations",
    )
    selected_reloc = {
        "aarch64": r"(ARM64_RELOC_BRANCH26|R_AARCH64_(CALL26|JUMP26)).*flyology_simd__backends__native__",
        "x86_64": r"(X86_64_RELOC_BRANCH|R_X86_64_PLT32).*flyology_simd__backends__native__",
    }[checker.architecture]
    for lane_kind, operation, suffix, _operation_class in cases:
        caller = t / f"wide-comparison-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_comparison_codegen_probe__{lane_kind}_{operation}",
            t / "wide-comparison-probe.txt",
            caller,
        )
        operation_symbol = operation if suffix == "none" else f"{operation}__{suffix}"
        pattern = f"backends__native__{operation_symbol}{SYMBOL_END}"
        if wide_backend == "avx2" and lane_kind in {"u8", "i8"}:
            leaf_suffix = "__2" if lane_kind == "i8" else ""
            checker.require_count(
                f"wide__byte_avx2_leaf__{operation}{leaf_suffix}{SYMBOL_END}",
                1,
                caller,
                f"matching isolated AVX2 leaf in {lane_kind} {operation}",
            )
            checker.require_count(
                r"wide__byte_avx2_leaf__",
                1,
                caller,
                f"only one AVX2 byte leaf in {lane_kind} {operation}",
            )
            checker.require_at_most(
                r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
                1,
                caller,
                f"only one out-of-line helper in AVX2 {lane_kind} {operation}",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                f"no composed selected operation in AVX2 {lane_kind} {operation}",
            )
            checker.forbid_pattern(
                r"wide__byte_mechanism__",
                caller,
                f"out-of-line byte mechanism in AVX2 {lane_kind} {operation}",
            )
        else:
            selected_count = checker.count_matches(pattern, caller)
            if selected_count == 2:
                checker.require_count(
                    selected_reloc,
                    2,
                    caller,
                    f"only two matching selected operations in {lane_kind} {operation}",
                )
            elif lane_kind == "u8":
                if checker.architecture == "aarch64":
                    patterns = {
                        "equal": (
                            r"cmeq.*16b",
                            2,
                            "two inlined AArch64 U8 equality operations",
                        ),
                        "less_than": (
                            r"backends__native__greater_bits",
                            2,
                            f"two selected AArch64 U8 strict comparisons in {operation}",
                        ),
                        "greater_than": (
                            r"backends__native__greater_bits",
                            2,
                            f"two selected AArch64 U8 strict comparisons in {operation}",
                        ),
                        "less_equal": (
                            r"backends__native__greater_equal_bits",
                            2,
                            f"two selected AArch64 U8 inclusive comparisons in {operation}",
                        ),
                        "greater_equal": (
                            r"backends__native__greater_equal_bits",
                            2,
                            f"two selected AArch64 U8 inclusive comparisons in {operation}",
                        ),
                        "select_value": (
                            r"backends__native__select_value",
                            2,
                            "two selected AArch64 U8 selections",
                        ),
                    }
                    p, n, d = patterns[operation]
                    (
                        checker.require_count
                        if operation == "equal"
                        else checker.require_at_most
                    )(p, n, caller, d)
                else:
                    if operation == "equal":
                        checker.require_count(
                            r"pcmpeqb",
                            2,
                            caller,
                            "two inlined x86-64 U8 equality operations",
                        )
                        checker.require_count(
                            r"pmovmskb",
                            2,
                            caller,
                            "two inlined x86-64 U8 equality mask extractions",
                        )
                    else:
                        p = (
                            r"backends__native__select_value"
                            if operation == "select_value"
                            else r"backends__native__greater_mask"
                        )
                        checker.require_at_most(
                            p,
                            2,
                            caller,
                            f"two selected x86-64 U8 {'selections' if operation == 'select_value' else ('strict comparisons' if operation in {'less_than','greater_than'} else 'ordered comparisons')} in {operation}".replace(
                                " in select_value", ""
                            ),
                        )
                        if operation in {"less_equal", "greater_equal"}:
                            checker.require_count(
                                r"pcmpeqb",
                                2,
                                caller,
                                f"two inlined x86-64 U8 equality comparisons in {operation}",
                            )
                actual_native = checker.count_matches(selected_reloc, caller)
                if actual_native != 0:
                    raise CodegenError(
                        f"unexpected selected operation in {lane_kind} {operation}"
                    )
            elif lane_kind == "i8" and selected_count > 0:
                if checker.architecture == "aarch64":
                    leaf = {
                        "equal": "compare_i8x16",
                        "less_than": "compare_greater_i8x16",
                        "greater_than": "compare_greater_i8x16",
                        "less_equal": "compare_greater_equal_i8x16",
                        "greater_equal": "compare_greater_equal_i8x16",
                        "select_value": "native_select_i8x16",
                    }[operation]
                    expected = 2
                elif operation in {"less_equal", "greater_equal"}:
                    checker.require_at_most(
                        r"backends__native__compare_greater_i8x16",
                        2,
                        caller,
                        f"two x86-64 I8 greater comparisons in {operation}",
                    )
                    checker.require_at_most(
                        r"backends__native__compare_equal_i8x16",
                        2,
                        caller,
                        f"two x86-64 I8 equality comparisons in {operation}",
                    )
                    leaf, expected = r"compare_(greater|equal)_i8x16", 4
                else:
                    leaf = {
                        "equal": "compare_equal_i8x16",
                        "less_than": "compare_greater_i8x16",
                        "greater_than": "compare_greater_i8x16",
                        "select_value": "native_select_i8x16",
                    }[operation]
                    expected = 2
                checker.require_count(
                    f"backends__native__{leaf}",
                    expected,
                    caller,
                    f"matching selected I8 operations in {operation}",
                )
                checker.require_count(
                    selected_reloc,
                    expected,
                    caller,
                    f"only matching selected I8 operations in {operation}",
                )
            elif selected_count == 0:
                inline = (
                    r"(cmeq|cmhi|cmhs|cmgt|cmge|fcmeq|fcmgt|fcmge|cmtst|bsl|bit|bif)"
                    if checker.architecture == "aarch64"
                    else r"(pcmpeq|pcmpgt|pandn|pmovmskb|cmpps|cmppd)"
                )
                checker.require_at_least(
                    inline, 2, caller, f"two inlined {lane_kind} {operation} halves"
                )
            else:
                raise CodegenError(
                    f"missing two selected {operation} calls in {lane_kind}"
                )
        checker.forbid_pattern(
            r"flyology_simd__(wide__(native__)?|backends__scalar__)?(equal|less_than|less_equal|greater_than|greater_equal|unordered|select_value)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)",
            caller,
            f"portable or dispatcher comparison call in {lane_kind} {operation}",
        )


def check_wide_integer_arithmetic(checker: Checker, wide_backend: str) -> None:
    t = checker.temporary
    branch = (
        r"(^|[[:space:]])(b|bl)[[:space:]]"
        if checker.architecture == "aarch64"
        else r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]"
    )
    selected_reloc = {
        "aarch64": r"(ARM64_RELOC_BRANCH26|R_AARCH64_(CALL26|JUMP26)).*flyology_simd__backends__native__",
        "x86_64": r"(X86_64_RELOC_BRANCH|R_X86_64_PLT32).*flyology_simd__backends__native__",
    }[checker.architecture]

    def family(
        manifest: str,
        expected: int,
        stem: str,
        operations: str,
        nonbyte_count: int,
        byte_count: int,
        noun: str,
    ) -> None:
        cases = require_unique_manifest(
            manifest,
            expected,
            f"Wide {noun} manifest must contain {expected} unique operations",
        )
        probe = t / f"{stem}-probe.txt"
        undefined = t / f"{stem}-undefined.txt"
        for lane_kind, operation, _wide_suffix, half_suffix, route in cases:
            caller = t / f"{stem.replace('-arithmetic','')}-{lane_kind}-{operation}.txt"
            # Saturation historically abbreviates its output stem.
            if stem == "wide-saturating-arithmetic":
                caller = t / f"wide-saturation-{lane_kind}-{operation}.txt"
            elif stem == "wide-wrapping-arithmetic":
                caller = t / f"wide-wrapping-{lane_kind}-{operation}.txt"
            checker.extract_symbol(
                f"{stem.replace('-', '_')}_codegen_probe__{lane_kind}_{operation}",
                probe,
                caller,
            )
            if wide_backend == "avx2" and route == "byte":
                leaf_suffix = "__2" if lane_kind == "i8" else ""
                checker.require_count(
                    f"wide__byte_avx2_leaf__{operation}{leaf_suffix}{SYMBOL_END}",
                    1,
                    caller,
                    f"matching isolated AVX2 leaf in {lane_kind} {operation}",
                )
                checker.require_count(
                    r"wide__byte_avx2_leaf__",
                    1,
                    caller,
                    f"only one AVX2 byte leaf in {lane_kind} {operation}",
                )
                checker.require_route_branches_at_most(
                    branch,
                    1,
                    caller,
                    f"only one out-of-line branch in AVX2 {lane_kind} {operation}",
                )
                if stem == "wide-saturating-arithmetic":
                    checker.require_count(
                        selected_reloc,
                        0,
                        caller,
                        f"no composed selected operation in AVX2 {lane_kind} {operation}",
                    )
                else:
                    checker.require_at_most(
                        r"flyology_simd__backends__native__",
                        0,
                        caller,
                        f"no composed selected operation in AVX2 {lane_kind} {operation}",
                    )
            else:
                if route == "parts":
                    selected = f"{operation}__{half_suffix}"
                elif lane_kind == "u8":
                    selected = f"{'neon' if checker.architecture == 'aarch64' else 'u8'}_{operation}"
                else:
                    selected = f"native_{operation}_i8x16"
                checker.require_at_most(
                    f"backends__native__{selected}{SYMBOL_END}",
                    2,
                    caller,
                    f"two matching selected parts in {lane_kind} {operation}",
                )
                checker.require_at_most(
                    r"flyology_simd__backends__native__",
                    2,
                    caller,
                    f"only two matching selected operations in {lane_kind} {operation}",
                )
                checker.require_route_branches_at_most(
                    branch,
                    2,
                    caller,
                    f"only two out-of-line branches in {lane_kind} {operation}",
                )
            checker.forbid_pattern(
                rf"flyology_simd__(wide__(native__)?|backends__scalar__)?({operations})(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__",
                caller,
                f"portable, dispatcher, Scalar, or byte-mechanism route in {lane_kind} {operation}",
            )
        checker.require_native_route(
            rf"flyology_simd__backends__native__({operations})__(3|4|5|6|7|8)$",
            nonbyte_count,
            undefined,
            probe,
            f"{'twelve' if nonbyte_count == 12 else 'eighteen'} selected non-byte Wide {noun.split('-')[0]} operations",
        )
        if wide_backend == "avx2":
            checker.require_count(
                rf"flyology_simd__wide__byte_avx2_leaf__({operations})(__2)?$",
                byte_count,
                undefined,
                f"{'four' if byte_count == 4 else 'six'} isolated AVX2 byte {noun.split('-')[0]} operations",
            )
        else:
            prefix = "neon" if checker.architecture == "aarch64" else "u8"
            checker.require_native_route(
                rf"flyology_simd__backends__native__{prefix}_({operations})$",
                byte_count // 2,
                undefined,
                probe,
                f"{'two' if byte_count == 4 else 'three'} selected U8 Wide {noun.split('-')[0]} operations",
            )
            checker.require_native_route(
                rf"flyology_simd__backends__native__native_({operations})_i8x16$",
                byte_count // 2,
                undefined,
                probe,
                f"{'two' if byte_count == 4 else 'three'} selected I8 Wide {noun.split('-')[0]} operations",
            )
        checker.require_at_most(
            r"flyology_simd__",
            expected,
            undefined,
            f"only the {expected} intended Wide {noun.split('-')[0]} operations remain unresolved",
        )
        checker.forbid_pattern(
            rf"flyology_simd__(wide__(native__)?|backends__scalar__)?({operations})(__[0-9]+)?$|wide__byte_mechanism__",
            undefined,
            f"portable, dispatcher, Scalar, or byte-mechanism route retained in Wide {noun.split('-')[0]} probe",
        )

    family(
        "wide_saturating_arithmetic_codegen_cases.txt",
        16,
        "wide-saturating-arithmetic",
        "add_saturate|subtract_saturate",
        12,
        4,
        "saturating-arithmetic",
    )
    family(
        "wide_wrapping_arithmetic_codegen_cases.txt",
        24,
        "wide-wrapping-arithmetic",
        "add_wrap|subtract_wrap|multiply_wrap",
        18,
        6,
        "wrapping-arithmetic",
    )


def check_wide_bitwise_and_shifts(checker: Checker, wide_backend: str) -> None:
    t = checker.temporary
    branch = (
        r"(^|[[:space:]])(b|bl)[[:space:]]"
        if checker.architecture == "aarch64"
        else r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]"
    )
    cases = require_unique_manifest(
        "wide_bitwise_codegen_cases.txt",
        32,
        "Wide bitwise manifest must contain 32 unique operations",
    )
    probe, undefined = t / "wide-bitwise-probe.txt", t / "wide-bitwise-undefined.txt"
    for lane_kind, operation, half_suffix, route, _arity in cases:
        caller = t / f"wide-bitwise-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_bitwise_codegen_probe__{lane_kind}_{operation}", probe, caller
        )
        if wide_backend == "avx2" and route == "byte":
            suffix = "__2" if lane_kind == "i8" else ""
            checker.require_count(
                f"wide__byte_avx2_leaf__{operation}{suffix}{SYMBOL_END}",
                1,
                caller,
                f"matching isolated AVX2 leaf in {lane_kind} {operation}",
            )
            checker.require_count(
                r"wide__byte_avx2_leaf__",
                1,
                caller,
                f"only one AVX2 byte leaf in {lane_kind} {operation}",
            )
            checker.require_route_branches_at_most(
                branch,
                1,
                caller,
                f"one out-of-line AVX2 branch in {lane_kind} {operation}",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                f"no composed selected operation in AVX2 {lane_kind} {operation}",
            )
        elif lane_kind == "u8" and operation == "bitwise_and":
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                "inline U8 conjunction has no selected call",
            )
            checker.require_route_branches_at_most(
                branch, 0, caller, "inline U8 conjunction has no out-of-line branch"
            )
            checker.require_count(
                r"and.*16b" if checker.architecture == "aarch64" else r"pand",
                2,
                caller,
                f"two inline {'AArch64' if checker.architecture == 'aarch64' else 'SSE2'} U8 conjunctions",
            )
        else:
            if route == "parts":
                selected = f"{operation}__{half_suffix}"
            elif lane_kind == "u8":
                selected = (
                    f"neon_{operation}"
                    if checker.architecture == "aarch64"
                    else f"u8_{operation.removeprefix('bitwise_')}"
                )
            elif operation == "bitwise_not":
                selected = "native_not_i8x16"
            else:
                selected = f"native_{operation}_i8x16"
            checker.require_at_most(
                f"backends__native__{selected}{SYMBOL_END}",
                2,
                caller,
                f"two matching selected parts in {lane_kind} {operation}",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                2,
                caller,
                f"only two selected operations in {lane_kind} {operation}",
            )
            checker.require_route_branches_at_most(
                branch,
                2,
                caller,
                f"two out-of-line branches in {lane_kind} {operation}",
            )
        checker.forbid_pattern(
            r"flyology_simd__(wide__(native__)?|backends__scalar__)?bitwise_(and|or|xor|not)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__",
            caller,
            "portable, dispatcher, Scalar, or byte-mechanism bitwise route",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__bitwise_(and|or|xor|not)__(3|4|5|6|7|8)$",
        24,
        undefined,
        probe,
        "twenty-four selected non-byte Wide bitwise operations",
    )
    if wide_backend == "avx2":
        checker.require_count(
            r"flyology_simd__wide__byte_avx2_leaf__bitwise_(and|or|xor|not)(__2)?$",
            8,
            undefined,
            "eight isolated AVX2 byte bitwise operations",
        )
        expected_symbols = 32
    else:
        checker.require_native_route(
            r"flyology_simd__backends__native__native_(bitwise_(and|or|xor)|not)_i8x16$",
            4,
            undefined,
            probe,
            "four selected I8 Wide bitwise operations",
        )
        prefix = "neon_bitwise" if checker.architecture == "aarch64" else "u8"
        checker.require_native_route(
            f"flyology_simd__backends__native__{prefix}_(or|xor|not)$",
            3,
            undefined,
            probe,
            "three out-of-line U8 Wide bitwise operations",
        )
        expected_symbols = 31
    checker.require_at_most(
        r"flyology_simd__",
        expected_symbols,
        undefined,
        "only intended Wide bitwise operations remain unresolved",
    )
    checker.forbid_pattern(
        r"flyology_simd__(wide__(native__)?|backends__scalar__)?bitwise_(and|or|xor|not)(__[0-9]+)?$|wide__byte_mechanism__",
        undefined,
        "portable, dispatcher, Scalar, or byte-mechanism bitwise route retained",
    )

    shifts = require_unique_manifest(
        "wide_shift_codegen_cases.txt",
        20,
        "Wide shift manifest must contain 20 unique operations",
    )
    shift_probe, shift_undefined = (
        t / "wide-shift-probe.txt",
        t / "wide-shift-undefined.txt",
    )
    for lane_kind, operation, suffix in shifts:
        caller = t / f"wide-shift-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_shift_codegen_probe__{lane_kind}_{operation}", shift_probe, caller
        )
        suffix_text = "" if suffix == "none" else f"__{suffix}"
        checker.require_at_most(
            f"backends__native__{operation}{suffix_text}{SYMBOL_END}",
            2,
            caller,
            f"two matching selected shifts in {lane_kind} {operation}",
        )
        checker.require_at_most(
            r"flyology_simd__backends__native__",
            2,
            caller,
            f"only two selected operations in {lane_kind} {operation}",
        )
        checker.require_route_branches_at_most(
            branch, 2, caller, f"two out-of-line branches in {lane_kind} {operation}"
        )
        checker.forbid_pattern(
            r"flyology_simd__(wide__(native__)?|backends__scalar__)?shift_(left_logical|right_logical|right_arithmetic)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)",
            caller,
            "portable, dispatcher, Scalar, or mismatched Wide shift route",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__shift_(left_logical|right_logical|right_arithmetic)(__[0-9]+)?$",
        20,
        shift_undefined,
        shift_probe,
        "twenty selected Wide shift operations remain unresolved",
    )
    checker.require_at_most(
        r"flyology_simd__",
        20,
        shift_undefined,
        "only the twenty intended Wide shift operations remain unresolved",
    )
    checker.forbid_pattern(
        r"flyology_simd__(wide__(native__)?|backends__scalar__)?shift_(left_logical|right_logical|right_arithmetic)(__[0-9]+)?$",
        shift_undefined,
        "portable, dispatcher, Scalar, or mismatched Wide shift route retained",
    )


def check_wide_minmax(checker: Checker, wide_backend: str) -> None:
    t = checker.temporary
    branch = (
        r"(^|[[:space:]])(b|bl)[[:space:]]"
        if checker.architecture == "aarch64"
        else r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]"
    )
    cases = require_unique_manifest(
        "wide_minmax_codegen_cases.txt",
        16,
        "Wide integer Min/Max manifest must contain 16 unique operations",
    )
    probe, undefined = t / "wide-minmax-probe.txt", t / "wide-minmax-undefined.txt"
    for lane_kind, operation, suffix, route in cases:
        caller = t / f"wide-minmax-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_minmax_codegen_probe__{lane_kind}_{operation}", probe, caller
        )
        selected = None
        if wide_backend == "avx2" and route == "byte":
            leaf_suffix = "__2" if lane_kind == "i8" else ""
            checker.require_count(
                f"wide__byte_avx2_leaf__{operation}{leaf_suffix}{SYMBOL_END}",
                1,
                caller,
                f"matching isolated AVX2 leaf in {lane_kind} {operation}",
            )
            checker.require_count(
                r"wide__byte_avx2_leaf__",
                1,
                caller,
                f"only one AVX2 byte leaf in {lane_kind} {operation}",
            )
            checker.require_route_branches_at_most(
                branch,
                1,
                caller,
                f"one out-of-line AVX2 branch in {lane_kind} {operation}",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                f"no composed selected operation in AVX2 {lane_kind} {operation}",
            )
        else:
            if route == "parts":
                selected = f"{operation}__{suffix}"
            elif lane_kind == "u8":
                selected = (
                    f"neon_{operation}"
                    if checker.architecture == "aarch64"
                    else operation
                )
            elif checker.architecture == "aarch64":
                selected = f"native_{operation}_i8x16"
            else:
                for pattern, description in (
                    (
                        r"backends__native__compare_greater_i8x16",
                        "signed-byte comparisons",
                    ),
                    (
                        r"backends__native__native_select_i8x16",
                        "signed-byte selections",
                    ),
                    (r"backends__native__sign_8", "signed-byte comparison constants"),
                    (
                        r"backends__native__weights_x86_8",
                        "signed-byte selection constants",
                    ),
                ):
                    checker.require_at_most(
                        pattern,
                        2,
                        caller,
                        f"two {description} in {lane_kind} {operation}",
                    )
                checker.require_route_branches_at_most(
                    branch,
                    4,
                    caller,
                    f"four exact inlined selected branches in {lane_kind} {operation}",
                )
            if selected:
                checker.require_at_most(
                    f"backends__native__{selected}{SYMBOL_END}",
                    2,
                    caller,
                    f"two matching selected extrema in {lane_kind} {operation}",
                )
                checker.require_at_most(
                    r"flyology_simd__backends__native__",
                    2,
                    caller,
                    f"only two selected operations in {lane_kind} {operation}",
                )
                checker.require_route_branches_at_most(
                    branch,
                    2,
                    caller,
                    f"two out-of-line branches in {lane_kind} {operation}",
                )
        checker.forbid_pattern(
            r"flyology_simd__(wide__(native__)?|backends__scalar__)?(min|max)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__",
            caller,
            "portable, dispatcher, Scalar, or byte-mechanism extrema route",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(min|max)__(3|4|5|6|7|8)$",
        12,
        undefined,
        probe,
        "twelve selected non-byte Wide integer extrema operations",
    )
    if wide_backend == "avx2":
        checker.require_count(
            r"flyology_simd__wide__byte_avx2_leaf__(min|max)(__2)?$",
            4,
            undefined,
            "four isolated AVX2 byte extrema operations",
        )
        expected = 16
    elif checker.architecture == "aarch64":
        checker.require_native_route(
            r"flyology_simd__backends__native__neon_(min|max)$",
            2,
            undefined,
            probe,
            "two selected U8 Wide extrema operations",
        )
        checker.require_native_route(
            r"flyology_simd__backends__native__native_(min|max)_i8x16$",
            2,
            undefined,
            probe,
            "two selected I8 Wide extrema operations",
        )
        expected = 16
    else:
        checker.require_native_route(
            r"flyology_simd__backends__native__(min|max)$",
            2,
            undefined,
            probe,
            "two selected U8 Wide extrema operations",
        )
        checker.require_native_route(
            r"flyology_simd__backends__native__(compare_greater_i8x16|native_select_i8x16)$",
            2,
            undefined,
            probe,
            "two selected I8 extrema helpers",
        )
        checker.require_native_route(
            r"flyology_simd__backends__native__(sign_8|weights_x86_8)$",
            2,
            undefined,
            probe,
            "two selected I8 extrema constants",
        )
        expected = 18
    checker.require_at_most(
        r"flyology_simd__",
        expected,
        undefined,
        "only the intended Wide extrema routes remain unresolved",
    )
    checker.forbid_pattern(
        r"flyology_simd__(wide__(native__)?|backends__scalar__)?(min|max)(__[0-9]+)?$|wide__byte_mechanism__",
        undefined,
        "portable, dispatcher, Scalar, or byte-mechanism extrema route retained",
    )


def check_masks(checker: Checker) -> None:
    t = checker.temporary
    branch = (
        r"(^|[[:space:]])(b|bl)[[:space:]]"
        if checker.architecture == "aarch64"
        else r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]"
    )
    core_ops = r"(mask_from_bit_mask|to_bit_mask|mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true)"
    cases = require_unique_manifest(
        "mask_core_codegen_cases.txt",
        40,
        "fixed-width compact-mask manifest must contain 40 unique operations",
    )
    probe, undefined = t / "mask-core-probe.txt", t / "mask-core-undefined.txt"
    for mask_kind, operation, suffix in cases:
        caller = t / f"mask-core-{mask_kind}-{operation}.txt"
        checker.extract_symbol(
            f"mask_core_codegen_probe__{mask_kind}_{operation}", probe, caller
        )
        suffix_text = "" if suffix == "none" else f"__{suffix}"
        if mask_kind == "m8" and operation in {"mask_from_bit_mask", "to_bit_mask"}:
            checker.require_at_most(
                r"flyology_simd__",
                0,
                caller,
                f"inline fixed-width {operation} has no out-of-line operation",
            )
            checker.require_pattern(
                r"(^|[[:space:]])ret(q)?([[:space:]]|$)",
                caller,
                f"inline fixed-width {operation} returns directly",
            )
        else:
            checker.require_at_most(
                f"backends__native__{operation}{suffix_text}{SYMBOL_END}",
                1,
                caller,
                f"one matching fixed-width mask operation in {mask_kind} {operation}",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                1,
                caller,
                f"only one selected mask operation in {mask_kind} {operation}",
            )
            checker.require_at_most(
                branch, 1, caller, f"one out-of-line branch in {mask_kind} {operation}"
            )
        checker.forbid_pattern(
            rf"flyology_simd__{core_ops}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|flyology_simd__backends__scalar__{core_ops}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|flyology_simd__wide__(native__)?{core_ops}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)",
            caller,
            "root, Scalar, or Wide compact-mask route",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(mask_from_bit_mask|to_bit_mask)__(2|3|4)$",
        6,
        undefined,
        probe,
        "six out-of-line fixed-width mask conversion operations remain unresolved",
    )
    checker.require_native_route(
        r"flyology_simd__backends__native__(mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true)(__[234])?$",
        32,
        undefined,
        probe,
        "thirty-two fixed-width mask algebra and query operations remain unresolved",
    )
    checker.require_at_most(
        r"flyology_simd__",
        38,
        undefined,
        "only the thirty-eight intended fixed-width mask operations remain unresolved",
    )
    checker.forbid_pattern(
        rf"flyology_simd__{core_ops}(__[0-9]+)?$|flyology_simd__backends__scalar__{core_ops}(__[0-9]+)?$|flyology_simd__wide__(native__)?{core_ops}(__[0-9]+)?$",
        undefined,
        "root, Scalar, or Wide compact-mask route retained",
    )

    wide_ops = r"(mask_from_bit_mask|to_bit_mask|mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true|population_count|first_true|last_true)"
    wide_cases = require_unique_manifest(
        "wide_mask_codegen_cases.txt",
        52,
        "Wide compact-mask manifest must contain 52 unique operations",
    )
    probe, undefined = t / "wide-mask-probe.txt", t / "wide-mask-undefined.txt"
    for mask_kind, operation, suffix, half_lanes_text in wide_cases:
        caller = t / f"wide-mask-{mask_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_mask_codegen_probe__{mask_kind}_{operation}", probe, caller
        )
        suffix_text = "" if suffix == "none" else f"__{suffix}"
        if mask_kind == "m8" and operation in {"mask_from_bit_mask", "to_bit_mask"}:
            checker.require_at_most(
                r"flyology_simd__",
                0,
                caller,
                f"inline identity {operation} has no out-of-line operation",
            )
            checker.require_pattern(
                r"(^|[[:space:]])ret(q)?([[:space:]]|$)",
                caller,
                f"inline identity {operation} returns directly",
            )
        elif operation == "test":
            count = checker.count_matches(
                f"backends__native__{operation}{suffix_text}{SYMBOL_END}", caller
            )
            if count not in {1, 2}:
                raise CodegenError(
                    f"code-generation count mismatch: one merged or two branch Test calls in {mask_kind} ({count})"
                )
            checker.require_count(
                r"flyology_simd__backends__native__",
                count,
                caller,
                f"only matching selected Test operations in {mask_kind}",
            )
        else:
            checker.require_at_most(
                f"backends__native__{operation}{suffix_text}{SYMBOL_END}",
                2,
                caller,
                f"two matching selected mask operations in {mask_kind} {operation}",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                2,
                caller,
                f"only two selected mask operations in {mask_kind} {operation}",
            )
        if operation == "test":
            half_lanes = int(half_lanes_text)
            half_hex = f"{half_lanes:x}"
            if checker.architecture == "aarch64":
                adjustment = rf"sub.*#(0x{half_hex}|{half_lanes})([^[:xdigit:]]|$)"
                conditional = r"(^|[[:space:]])b\.[a-z]+"
            else:
                adjustment = rf"(sub.*\$(0x{half_hex}|{half_lanes})([^[:xdigit:]]|$)|lea[lq]?[[:space:]].*-(0x{half_hex}|{half_lanes})\([^)]*\),[[:space:]]*%[[:alnum:]]+)"
                conditional = r"(^|[[:space:]])j(a|ae|b|be|c|e|g|ge|l|le|na|nae|nb|nbe|nc|ne|ng|nge|nl|nle|no|np|ns|nz|o|p|pe|po|s|z)[[:space:]]"
            checker.require_pattern(
                adjustment, caller, f"high-half lane adjustment in {mask_kind} Test"
            )
            checker.require_pattern(
                conditional,
                caller,
                f"private-half conditional selection in {mask_kind} Test",
            )
        checker.forbid_pattern(
            rf"flyology_simd__(wide__(native__)?|backends__scalar__)?{wide_ops}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)",
            caller,
            "portable, dispatcher, Scalar, or mismatched compact-mask route",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(mask_from_bit_mask|to_bit_mask)__(2|3|4)$",
        6,
        undefined,
        probe,
        "six out-of-line Wide mask bit-conversion operations remain unresolved",
    )
    checker.require_native_route(
        r"flyology_simd__backends__native__(mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true|population_count|first_true|last_true)(__[234])?$",
        44,
        undefined,
        probe,
        "forty-four selected Wide mask algebra and query operations remain unresolved",
    )
    checker.require_at_most(
        r"flyology_simd__",
        50,
        undefined,
        "only the fifty intended out-of-line Wide mask operations remain unresolved",
    )
    checker.forbid_pattern(
        rf"flyology_simd__(wide__(native__)?|backends__scalar__)?{wide_ops}(__[0-9]+)?$",
        undefined,
        "portable, dispatcher, Scalar, or mismatched compact-mask route retained",
    )


def check_wide_reductions(checker: Checker) -> None:
    t = checker.temporary
    cases = require_unique_manifest(
        "wide_reduction_codegen_cases.txt",
        24,
        "Wide reduction code-generation manifest must contain 24 unique operations",
    )
    probe, undefined = (
        t / "wide-reduction-probe.txt",
        t / "wide-reduction-undefined.txt",
    )
    for lane_kind, operation, combine, suffix in cases:
        caller = t / f"wide-reduction-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"wide_reduction_codegen_probe__{lane_kind}_{operation}", probe, caller
        )
        if suffix == "none":
            operation_symbol, combine_symbol = operation, combine
            extract_symbol, splat_symbol = "extract", "splat"
        else:
            operation_symbol, combine_symbol = (
                f"{operation}__{suffix}",
                f"{combine}__{suffix}",
            )
            extract_symbol, splat_symbol = f"extract__{suffix}", f"splat__{suffix}"
        checker.require_at_most(
            f"backends__native__{operation_symbol}{SYMBOL_END}",
            2,
            caller,
            f"two matching selected reductions in {lane_kind} {operation}",
        )
        checker.require_at_most(
            f"backends__native__{combine_symbol}{SYMBOL_END}",
            1,
            caller,
            f"one matching selected combine in {lane_kind} {operation}",
        )
        checker.require_at_most(
            f"backends__native__{extract_symbol}{SYMBOL_END}",
            1,
            caller,
            f"one matching selected extraction in {lane_kind} {operation}",
        )
        splat_pattern = f"backends__native__{splat_symbol}{SYMBOL_END}"
        if checker.matches(splat_pattern, caller):
            checker.require_at_most(
                splat_pattern,
                2,
                caller,
                f"two matching selected splats in {lane_kind} {operation}",
            )
            selected_count = 6
        else:
            inline = (
                r"dup(\.[0-9]+[bhsd])?[[:space:]]"
                if checker.architecture == "aarch64"
                else r"pshufd|punpcklqdq|shufps|unpcklpd"
            )
            checker.require_at_least(
                inline,
                2,
                caller,
                f"two inlined {'splats' if checker.architecture == 'aarch64' else 'splat broadcasts'} in {lane_kind} {operation}",
            )
            selected_count = 4
        checker.require_at_most(
            r"flyology_simd__backends__native__",
            selected_count,
            caller,
            f"only the intended selected operations in {lane_kind} {operation}",
        )
        checker.forbid_pattern(
            r"flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_",
            caller,
            f"Wide dispatcher or portable scalar reduction in {lane_kind} {operation}",
        )
    checker.forbid_pattern(
        r"flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_",
        undefined,
        "Wide dispatcher or portable scalar reduction retained in caller probe",
    )
