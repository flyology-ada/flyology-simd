#!/usr/bin/env python3
"""Architecture-independent generated-code contracts."""

from __future__ import annotations

from pathlib import Path

from codegen_checker import Checker, CodegenError
from codegen_evidence import ROOT


def rows(name: str) -> list[list[str]]:
    return [
        line.split()
        for line in (ROOT / "scripts" / "probes" / name).read_text().splitlines()
        if line.strip()
    ]


def require_unique_manifest(
    name: str, expected: int, description: str
) -> list[list[str]]:
    manifest = rows(name)
    if len(manifest) != expected or len({tuple(row) for row in manifest}) != expected:
        raise CodegenError(description)
    return manifest


def check_floating_algorithms(checker: Checker) -> None:
    t = checker.temporary
    source = t / "floating-algorithm.txt"
    symbols = (
        ("scale", "f32-scale.txt"),
        ("scale__2", "f64-scale.txt"),
        ("clamp", "f32-clamp.txt"),
        ("clamp__2", "f64-clamp.txt"),
        ("axpy", "f32-axpy.txt"),
        ("axpy__2", "f64-axpy.txt"),
        ("sum", "f32-sum.txt"),
        ("sum__2", "f64-sum.txt"),
        ("min_number", "f32-min-number.txt"),
        ("max_number", "f32-max-number.txt"),
        ("min_number__2", "f64-min-number.txt"),
        ("max_number__2", "f64-max-number.txt"),
        ("dot_product", "f32-dot-product.txt"),
        ("dot_product__2", "f64-dot-product.txt"),
    )
    for symbol, output in symbols:
        checker.extract_symbol(
            f"flyology_simd__algorithms__native_floating__{symbol}",
            source,
            t / output,
        )

    profiles = {
        "f32": {
            "zero": "zero__9",
            "load": "load_partial__9",
            "store": "store_partial__9",
            "splat": "splat__9",
            "extract": "extract__9",
            "multiply": "multiply",
            "add": "add",
            "minimum": "min_number",
            "maximum": "max_number",
            "reduce": "reduce_add",
            "reduce_min": "reduce_min_number",
            "reduce_max": "reduce_max_number",
        },
        "f64": {
            "zero": "zero__10",
            "load": "load_partial__10",
            "store": "store_partial__10",
            "splat": "splat__10",
            "extract": "extract__10",
            "multiply": "multiply__2",
            "add": "add__2",
            "minimum": "min_number__2",
            "maximum": "max_number__2",
            "reduce": "reduce_add__2",
            "reduce_min": "reduce_min_number__2",
            "reduce_max": "reduce_max_number__2",
        },
    }
    for precision, route in profiles.items():
        files = {
            name: t / f"{precision}-{name.replace('_', '-')}.txt"
            for name in ("scale", "clamp", "axpy", "sum", "dot_product")
        }
        files["minimum"] = t / f"{precision}-min-number.txt"
        files["maximum"] = t / f"{precision}-max-number.txt"

        def at_most(key: str, limit: int, file: str, description: str) -> None:
            checker.require_at_most(
                f"flyology_simd__backends__native__{route[key]}([^_]|$)",
                limit,
                files[file],
                description.format(precision=precision),
            )

        for key, limit, description in (
            ("splat", 1, "one selected splat route in the native {precision} scale"),
            ("load", 1, "one selected partial load in the native {precision} scale"),
            (
                "multiply",
                1,
                "one selected multiply route in the native {precision} scale",
            ),
            ("store", 1, "one selected partial store in the native {precision} scale"),
        ):
            at_most(key, limit, "scale", description)
        checker.forbid_pattern(
            r"flyology_simd__backends__native__(add|reduce_add)",
            files["scale"],
            f"reduction operation in the native {precision} scale",
        )
        for key, limit, description in (
            ("splat", 2, "two selected bound splats in native {precision} clamp"),
            ("load", 1, "one selected partial load in native {precision} clamp"),
            ("maximum", 1, "one selected Max_Number in native {precision} clamp"),
            ("minimum", 1, "one selected Min_Number in native {precision} clamp"),
            ("store", 1, "one selected partial store in native {precision} clamp"),
        ):
            at_most(key, limit, "clamp", description)
        checker.forbid_pattern(
            r"flyology_simd__backends__native__(multiply|add|reduce_add)",
            files["clamp"],
            f"arithmetic or reduction operation in native {precision} clamp",
        )
        for key, limit, description in (
            ("splat", 1, "one selected factor splat in native {precision} AXPY"),
            ("load", 2, "two selected partial loads in native {precision} AXPY"),
            ("multiply", 1, "one selected multiply in native {precision} AXPY"),
            ("add", 1, "one selected add in native {precision} AXPY"),
            ("store", 1, "one selected partial store in native {precision} AXPY"),
        ):
            at_most(key, limit, "axpy", description)
        checker.forbid_pattern(
            r"flyology_simd__backends__native__(min_number|max_number|reduce_add)",
            files["axpy"],
            f"minimum or reduction operation in native {precision} AXPY",
        )
        for file in ("sum", "dot_product"):
            noun = "sum" if file == "sum" else "dot loop"
            for key, limit, description in (
                (
                    "zero",
                    1,
                    f"one selected zero route in the native {{precision}} {noun}",
                ),
                (
                    "load",
                    1 if file == "sum" else 2,
                    f"{'one' if file == 'sum' else 'two'} selected partial load{'s' if file != 'sum' else ''} in the native {{precision}} {noun}",
                ),
                (
                    "add",
                    1,
                    f"one selected add route in the native {{precision}} {noun}",
                ),
                (
                    "reduce",
                    1,
                    f"one selected reduction in the native {{precision}} {noun}",
                ),
            ):
                at_most(key, limit, file, description)
        checker.forbid_pattern(
            r"flyology_simd__backends__native__multiply",
            files["sum"],
            f"multiplication in the native {precision} sum",
        )
        for extremum, operation, reduction in (
            ("minimum", "minimum", "reduce_min"),
            ("maximum", "maximum", "reduce_max"),
        ):
            file = files[extremum]
            checker.require_route_or_inlined(
                f"flyology_simd__backends__native__{route['load']}([^_]|$)",
                file,
                f"selected partial load in native {precision} {extremum}",
            )
            at_most(
                operation,
                1,
                extremum,
                f"one selected {'Min' if extremum == 'minimum' else 'Max'}_Number in native {{precision}} {extremum}",
            )
            checker.require_route_or_inlined(
                f"flyology_simd__backends__native__{route[reduction]}([^_]|$)",
                file,
                f"selected reduction in native {precision} {extremum}",
            )
            checker.require_route_or_inlined(
                f"flyology_simd__backends__native__{route['extract']}([^_]|$)",
                file,
                f"selected tail extraction in native {precision} {extremum}",
            )

    checker.require_at_most(
        r"flyology_simd__backends__native__multiply([^_]|$)",
        1,
        t / "f32-dot-product.txt",
        "one selected multiply route in the native binary32 dot loop",
    )
    checker.require_at_most(
        r"flyology_simd__backends__native__multiply__2([^_]|$)",
        1,
        t / "f64-dot-product.txt",
        "one selected multiply route in the native binary64 dot loop",
    )
    checker.forbid_pattern(
        r"flyology_simd__algorithms__(scalar|runtime)|flyology_simd__(__algorithms)?__(scale|clamp|axpy|sum|dot_product|splat|multiply|add|min_number|max_number|reduce_add|load_partial|store_partial)",
        t / "floating-algorithm-undefined.txt",
        "portable, scalar, or runtime route in the native floating loops",
    )


def check_u8_value_callers(checker: Checker) -> None:
    t = checker.temporary
    operations = require_unique_manifest(
        "u8_value_codegen_cases.txt",
        26,
        "U8 value code-generation manifest must contain 26 unique operations",
    )
    forbidden = r"flyology_simd__wide__native__|flyology_simd__(wide__)?(add_wrap|subtract_wrap|multiply_wrap|add_saturate|subtract_saturate|bitwise_|equal|less_|greater_|select_value|min|max|reduce_|reverse_|interleave_|deinterleave_)|flyology_simd__backends__scalar__"
    for (operation,) in operations:
        caller = t / f"u8-value-{operation}.txt"
        checker.extract_symbol(
            f"u8_value_codegen_probe__{operation}", t / "u8-value-probe.txt", caller
        )
        checker.forbid_pattern(
            forbidden,
            caller,
            f"portable or public dispatcher call in U8 {operation} caller",
        )
    checker.forbid_pattern(
        r"flyology_simd__(wide__)?(add_wrap|subtract_wrap|multiply_wrap|add_saturate|subtract_saturate|bitwise_|equal|less_|greater_|select_value|min|max|reduce_|reverse_|interleave_|deinterleave_)|flyology_simd__wide__native__|flyology_simd__backends__scalar__",
        t / "u8-value-undefined.txt",
        "portable or public U8 operation in the exact caller probe",
    )


def check_byte_add_saturate(checker: Checker) -> None:
    t = checker.temporary
    caller = t / "byte-add-saturate.txt"
    checker.extract_symbol(
        "flyology_simd__algorithms__native__add_saturate",
        t / "algorithm.txt",
        caller,
    )
    checker.require_route_or_inlined(
        r"flyology_simd__backends__native__splat([^_]|$)|dup\.16b|pshufd",
        caller,
        "selected or inlined addend splat in Native byte Add_Saturate",
    )
    checker.require_route_or_inlined(
        r"flyology_simd__backends__native__load_unaligned([^_]|$)|ldr[[:space:]]+q[0-9]+|movdqu",
        caller,
        "selected or inlined load in Native byte Add_Saturate",
    )
    for pattern, description in (
        (
            r"flyology_simd__backends__native__add_saturate([^_]|$)",
            "one selected saturating add in Native byte Add_Saturate",
        ),
        (
            r"flyology_simd__backends__native__store_unaligned([^_]|$)",
            "one selected store in Native byte Add_Saturate",
        ),
    ):
        checker.require_at_most(pattern, 1, caller, description)
    checker.forbid_pattern(
        r"flyology_simd__algorithms__(scalar|runtime)|flyology_simd__add_saturate",
        caller,
        "portable, Scalar, or runtime route in Native byte Add_Saturate",
    )


def check_public_floating_and_numeric_conversions(checker: Checker) -> None:
    t = checker.temporary
    float_undefined = t / "float-reduction-undefined.txt"
    float_probe = t / "float-reduction-probe.txt"
    routes = (
        (
            "reduce_add",
            2,
            "two Native floating Reduce_Add calls in the public caller probe",
        ),
        (
            "min_number",
            2,
            "two Native floating Min_Number calls in the public caller probe",
        ),
        (
            "max_number",
            2,
            "two Native floating Max_Number calls in the public caller probe",
        ),
        (
            "reduce_min_number",
            2,
            "two Native floating Reduce_Min_Number calls in the public caller probe",
        ),
        (
            "reduce_max_number",
            2,
            "two Native floating Reduce_Max_Number calls in the public caller probe",
        ),
    )
    for route, limit, description in routes:
        checker.require_native_route(
            f"flyology_simd__backends__native__{route}",
            limit,
            float_undefined,
            float_probe,
            description,
        )
    checker.forbid_pattern(
        r"flyology_simd__reduce_add",
        float_undefined,
        "portable Reduce_Add call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__(min_number|max_number|reduce_min_number|reduce_max_number)",
        float_undefined,
        "portable floating min/max call in the Native caller probe",
    )
    conversion_undefined = t / "conversion64-undefined.txt"
    conversion_probe = t / "conversion64-probe.txt"
    for route, description in (
        (
            "convert_round",
            "I64x2-to-F64x2 and U64x2-to-F64x2 Native calls in the public caller probe",
        ),
        (
            "convert_truncate_saturate",
            "F64x2-to-I64x2 and F64x2-to-U64x2 Native calls in the public caller probe",
        ),
    ):
        checker.require_native_route(
            f"flyology_simd__backends__native__{route}",
            2,
            conversion_undefined,
            conversion_probe,
            description,
        )
    checker.forbid_pattern(
        r"flyology_simd__(convert_round|convert_truncate_saturate)",
        conversion_undefined,
        "portable 64-bit numeric conversion call in the Native caller probe",
    )

    selected = {
        "i32_to_f32": r"convert_round($|[^_])",
        "u32_to_f32": "convert_round__2",
        "i64_to_f64": "convert_round__3",
        "u64_to_f64": "convert_round__4",
        "f32_to_i32": r"convert_truncate_saturate($|[^_])",
        "f32_to_u32": "convert_truncate_saturate__2",
        "f64_to_i64": "convert_truncate_saturate__3",
        "f64_to_u64": "convert_truncate_saturate__4",
    }
    wide_probe = t / "wide-numeric-conversion-probe.txt"
    wide_undefined = t / "wide-numeric-conversion-undefined.txt"
    for conversion, route in selected.items():
        caller = t / f"wide_numeric_{conversion}.txt"
        checker.extract_symbol(
            f"wide_numeric_conversion_codegen_probe__{conversion}", wide_probe, caller
        )
        checker.require_at_most(
            f"flyology_simd__backends__native__{route}",
            2,
            caller,
            f"two matching selected 128-bit calls in Wide {conversion} conversion",
        )
        checker.require_at_most(
            r"flyology_simd__backends__native__convert_(round|truncate_saturate)",
            2,
            caller,
            f"no mismatched selected call in Wide {conversion} conversion",
        )
        checker.forbid_pattern(
            r"flyology_simd__(wide__)?(convert_round|convert_truncate_saturate)|flyology_simd__wide__native__",
            caller,
            f"portable or public dispatcher call in Wide {conversion} conversion",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__convert_(round|truncate_saturate)",
        8,
        wide_undefined,
        wide_probe,
        "all eight matching selected conversion symbols in the Wide conversion probe",
    )
    for caller_name, operation, overload_text in rows(
        "wide_non_numeric_conversion_codegen_cases.txt"
    ):
        caller = t / f"wide_non_numeric_{caller_name}.txt"
        checker.extract_symbol(
            f"wide_numeric_conversion_codegen_probe__{caller_name}", wide_probe, caller
        )
        overload = int(overload_text)
        suffix = r"($|[^_])" if overload == 1 else rf"__{overload}($|[^0-9])"
        if operation == "widen":
            for half in ("low", "high"):
                checker.require_at_most(
                    f"flyology_simd__backends__native__widen_{half}{suffix}",
                    1,
                    caller,
                    f"one matching selected {half}-half widening call in Wide {caller_name} conversion",
                )
            checker.require_at_most(
                r"flyology_simd__backends__native__widen_(low|high)",
                2,
                caller,
                f"no extra or mismatched selected call in Wide {caller_name} conversion",
            )
            portable = r"widen_(low|high)"
        else:
            checker.require_at_most(
                f"flyology_simd__backends__native__{operation}{suffix}",
                2,
                caller,
                f"two matching selected 128-bit calls in Wide {caller_name} conversion",
            )
            checker.require_at_most(
                f"flyology_simd__backends__native__{operation}",
                2,
                caller,
                f"no extra or mismatched selected call in Wide {caller_name} conversion",
            )
            portable = operation
        checker.forbid_pattern(
            f"flyology_simd__(wide__)?{portable}|flyology_simd__wide__native__",
            caller,
            f"portable or public dispatcher call in Wide {caller_name} conversion",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(widen_(low|high)|narrow_(truncate|saturate|round)|convert_saturate)",
        38,
        wide_undefined,
        wide_probe,
        "all 38 selected non-numeric conversion symbols in the Wide conversion probe",
    )
    checker.require_at_most(
        r"flyology_simd__",
        46,
        wide_undefined,
        "only the 38 non-numeric and eight numeric conversion symbols remain unresolved",
    )


def check_integer_conversion_callers(checker: Checker) -> None:
    t = checker.temporary
    cases = require_unique_manifest(
        "integer_conversion_codegen_cases.txt",
        35,
        "Integer conversion manifest must contain 35 unique operations",
    )
    branch = {
        "aarch64": r"(^|[[:space:]])(b|bl)[[:space:]]",
        "x86_64": r"(^|[[:space:]])(callq?|jmpq?)[[:space:]]",
    }[checker.architecture]
    symbol_end = r"([+-]0x[[:xdigit:]]+)?([[:space:]]|$)"
    forbidden = r"flyology_simd__(wide__(native__)?|backends__scalar__)?(widen_low|widen_high|narrow_truncate|narrow_saturate|convert_saturate)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)"
    for kind, operation, _source, _target, suffix, _arity in cases:
        caller = t / f"integer-conversion-{kind}-{operation}.txt"
        checker.extract_symbol(
            f"integer_conversion_codegen_probe__{kind}_{operation}",
            t / "integer-conversion-probe.txt",
            caller,
        )
        selected = operation if suffix == "none" else f"{operation}__{suffix}"
        checker.require_at_most(
            f"flyology_simd__backends__native__{selected}{symbol_end}",
            1,
            caller,
            f"one matching Native route in {kind} {operation}",
        )
        checker.require_at_most(
            r"flyology_simd__backends__native__",
            1,
            caller,
            f"only one Native route in {kind} {operation}",
        )
        checker.require_at_most(
            branch, 1, caller, f"only one out-of-line branch in {kind} {operation}"
        )
        checker.forbid_pattern(
            forbidden,
            caller,
            f"portable, Scalar, Wide, or dispatcher route in {kind} {operation}",
        )
    undefined = t / "integer-conversion-undefined.txt"
    probe = t / "integer-conversion-probe.txt"
    checker.require_native_route(
        r"flyology_simd__backends__native__(widen_low|widen_high|narrow_truncate|narrow_saturate|convert_saturate)(__[0-9]+)?([[:space:]]|$)",
        35,
        undefined,
        probe,
        "all 35 exact Native integer-conversion routes in the generated probe",
    )
    checker.require_at_most(
        r"flyology_simd__",
        35,
        undefined,
        "only the 35 Native integer-conversion symbols remain unresolved",
    )
    checker.forbid_pattern(
        r"flyology_simd__(wide__(native__)?|backends__scalar__)?(widen_low|widen_high|narrow_truncate|narrow_saturate|convert_saturate)",
        undefined,
        "portable, Scalar, Wide, or dispatcher conversion in generated probe",
    )


def check_wide_memory_callers(checker: Checker) -> None:
    t = checker.temporary
    probe = t / "wide-memory-probe.txt"
    undefined = t / "wide-memory-undefined.txt"
    symbol_end = r"([+-]0x[[:xdigit:]]+)?$"
    for caller_name, operation, overload_text in rows("wide_memory_codegen_cases.txt"):
        caller = t / f"wide_memory_{caller_name}.txt"
        checker.extract_symbol(
            f"wide_memory_codegen_probe__{caller_name}", probe, caller
        )
        overload = int(overload_text)
        suffix = r"($|[^_])" if overload == 1 else rf"__{overload}($|[^0-9])"
        if operation in {"load", "store"} or (
            operation
            in {"load_unaligned", "store_unaligned", "load_aligned", "store_aligned"}
            and caller_name != "u8_load_unaligned"
        ):
            checker.require_at_most(
                f"flyology_simd__backends__native__{operation}{suffix}",
                2,
                caller,
                f"two matching selected 128-bit {operation} calls in Wide {caller_name}",
            )
            checker.require_at_most(
                f"flyology_simd__backends__native__{operation}",
                2,
                caller,
                f"no extra or mismatched selected {operation} call in Wide {caller_name}",
            )
        elif operation in {
            "load_unaligned",
            "store_unaligned",
            "load_aligned",
            "store_aligned",
        }:
            if checker.architecture == "scalar":
                checker.require_count(
                    f"flyology_simd__load_unaligned{symbol_end}",
                    2,
                    caller,
                    f"two portable 128-bit unaligned loads in scalar Wide {caller_name}",
                )
                checker.require_at_most(
                    r"flyology_simd__backends__native__load_unaligned",
                    0,
                    caller,
                    f"scalar Wide {caller_name} resolves the selected rename directly",
                )
            elif checker.architecture == "aarch64":
                checker.require_at_most(
                    r"flyology_simd__backends__native__load_unaligned",
                    0,
                    caller,
                    f"selected unaligned load is fully inlined in Wide {caller_name}",
                )
                checker.require_count(
                    r"(^|[[:space:]])ldr[[:space:]]+q[0-9]+",
                    2,
                    caller,
                    f"two inlined 128-bit loads in Wide {caller_name}",
                )
                checker.require_count(
                    r"(^|[[:space:]])str[[:space:]]+q[0-9]+",
                    2,
                    caller,
                    f"two inlined 128-bit result stores in Wide {caller_name}",
                )
            else:
                checker.require_at_most(
                    f"flyology_simd__backends__native__{operation}",
                    0,
                    caller,
                    f"selected {operation} is fully inlined in Wide {caller_name}",
                )
                checker.require_at_least(
                    r"(^|[[:space:]])movdqu[[:space:]]",
                    2,
                    caller,
                    f"two inlined SSE2 unaligned transfers in Wide {caller_name}",
                )
        elif operation == "load_partial":
            for route, limit, description in (
                (
                    f"load_partial{suffix}",
                    2,
                    "both branches use the matching selected partial load",
                ),
                (f"load{suffix}", 1, "one matching selected full load"),
                (f"zero{suffix}", 1, "one matching selected zero"),
                ("load_partial", 2, "no mismatched partial load"),
                (f"load(__[0-9]+)?{symbol_end}", 1, "no mismatched full load"),
                (f"zero(__[0-9]+)?{symbol_end}", 1, "no mismatched zero"),
            ):
                checker.require_at_most(
                    f"flyology_simd__backends__native__{route}",
                    limit,
                    caller,
                    f"{description} in Wide {caller_name}",
                )
        elif operation == "store_partial":
            for route, limit, description in (
                (
                    f"store_partial{suffix}",
                    2,
                    "both branches use the matching selected partial store",
                ),
                (f"store{suffix}", 1, "one matching selected full store"),
                ("store_partial", 2, "no mismatched partial store"),
                (f"store(__[0-9]+)?{symbol_end}", 1, "no mismatched full store"),
            ):
                checker.require_at_most(
                    f"flyology_simd__backends__native__{route}",
                    limit,
                    caller,
                    f"{description} in Wide {caller_name}",
                )
        if checker.architecture == "scalar" and caller_name == "u8_load_unaligned":
            forbidden = (
                r"flyology_simd__wide__(load|store)|flyology_simd__wide__native__"
            )
            description = (
                f"Wide or public memory dispatcher call in scalar Wide {caller_name}"
            )
        else:
            forbidden = (
                r"flyology_simd__(wide__)?(load|store)|flyology_simd__wide__native__"
            )
            description = (
                f"portable or public memory dispatcher call in Wide {caller_name}"
            )
        checker.forbid_pattern(forbidden, caller, description)

    for operation in ("load", "store", "load_partial", "store_partial"):
        checker.require_native_route(
            f"flyology_simd__backends__native__{operation}($|__)",
            10,
            undefined,
            probe,
            f"all ten selected {operation} symbols in the Wide memory probe",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__load_unaligned($|__)",
        9,
        undefined,
        probe,
        "nine out-of-line selected unaligned loads plus the inlined U8 load path",
    )
    for operation in ("store_unaligned", "load_aligned", "store_aligned"):
        checker.require_native_route(
            f"flyology_simd__backends__native__{operation}($|__)",
            10,
            undefined,
            probe,
            f"all ten selected {operation} symbols in the Wide memory probe",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__zero($|__)",
        10,
        undefined,
        probe,
        "all ten selected zero symbols for Wide partial loads",
    )
    if checker.architecture == "scalar":
        checker.require_count(
            f"flyology_simd__load_unaligned{symbol_end}",
            1,
            undefined,
            "one portable U8 unaligned-load rename in the scalar Wide probe",
        )
        checker.require_at_most(
            r"flyology_simd__",
            90,
            undefined,
            "only the selected memory and zero symbols remain unresolved in the scalar probe",
        )
        checker.forbid_pattern(
            r"flyology_simd__wide__(load|store)|flyology_simd__wide__native__",
            undefined,
            "Wide or public memory symbols in the all-family scalar probe",
        )
    else:
        checker.require_at_most(
            r"flyology_simd__",
            89,
            undefined,
            "only the selected memory and zero symbols remain unresolved",
        )
        checker.forbid_pattern(
            r"flyology_simd__(wide__)?(load|store)|flyology_simd__wide__native__",
            undefined,
            "portable or public memory symbols in the all-family Wide probe",
        )


def check_public_routes(checker: Checker) -> None:
    t = checker.temporary

    def route(pattern: str, limit: int, stem: str, description: str) -> None:
        checker.require_native_route(
            pattern,
            limit,
            t / f"{stem}-undefined.txt",
            t / f"{stem}-probe.txt",
            description,
        )

    route(
        r"flyology_simd__backends__native__shift_right_arithmetic",
        4,
        "integer-shift",
        "all four Native arithmetic-right-shift calls in the public caller probe",
    )
    route(
        r"flyology_simd__backends__native__shift_left_logical",
        8,
        "integer-shift",
        "all eight Native logical-left-shift calls in the public caller probe",
    )
    route(
        r"flyology_simd__backends__native__shift_right_logical",
        8,
        "integer-shift",
        "all eight Native logical-right-shift calls in the public caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__shift_right_arithmetic",
        t / "integer-shift-undefined.txt",
        "portable arithmetic-right-shift call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__shift_(left|right)_logical",
        t / "integer-shift-undefined.txt",
        "portable logical-shift call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__shift_(left|right)_logical",
        t / "native-undefined.txt",
        "portable logical-shift call retained in the Native backend object",
    )
    checker.forbid_pattern(
        r"flyology_simd__shift_right_arithmetic",
        t / "native-undefined.txt",
        "portable arithmetic-right-shift call retained in the Native backend object",
    )
    route(
        r"flyology_simd__backends__native__table_lookup",
        1,
        "table-lookup",
        "one Native Table_Lookup call in the public caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__table_lookup",
        t / "table-lookup-undefined.txt",
        "portable Table_Lookup call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__table_lookup",
        t / "native-undefined.txt",
        "portable Table_Lookup call retained in the Native backend object",
    )
    checker.forbid_pattern(
        r"flyology_simd__wide__(compress|expand)|flyology_simd__wide__native__(compress|expand)",
        t / "wide-compact-undefined.txt",
        "portable or public Wide compact call in the all-family caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__wide__(compress|expand)",
        t / "wide-undefined.txt",
        "portable Wide compact call retained in the representative Wide caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__wide__(compress|expand)",
        t / "wide-compact-probe.txt",
        "portable Wide compact relocation in the all-family caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__wide__(permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)|flyology_simd__wide__native__(permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)",
        t / "wide-movement-undefined.txt",
        "portable or public Wide movement call in the all-family caller probe",
    )
    for direction in ("low", "high"):
        checker.require_count(
            rf"slide_codegen_probe__(u8|i8|u16|i16|u32|i32|u64|i64|f32|f64)_{direction}$",
            10,
            t / "slide-symbols.txt",
            f"all ten dynamic slide-toward-{direction} public caller probes",
        )
    checker.forbid_pattern(
        r"flyology_simd__slide_lanes_toward_(low|high)",
        t / "slide-undefined.txt",
        "portable lane-slide call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__(zero|slide_lanes_toward_(low|high))",
        t / "native-undefined.txt",
        "portable zero or lane-slide call retained in the Native backend object",
    )
    route(
        r"flyology_simd__backends__native__unordered",
        2,
        "unordered",
        "F32x4 and F64x2 Native Unordered calls in the public caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__unordered",
        t / "unordered-undefined.txt",
        "portable Unordered call in the Native caller probe",
    )
    for operation, limit, description in (
        ("first_true", 4, "four Native First_True calls in the public caller probe"),
        ("last_true", 4, "four Native Last_True calls in the public caller probe"),
        (
            "population_count",
            4,
            "four Native Population_Count calls in the public caller probe",
        ),
    ):
        route(
            f"flyology_simd__backends__native__{operation}",
            limit,
            "mask-position",
            description,
        )
    checker.forbid_pattern(
        r"flyology_simd__(first_true|last_true)",
        t / "mask-position-undefined.txt",
        "portable mask-position call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__population_count",
        t / "mask-position-undefined.txt",
        "portable population-count call in the Native caller probe",
    )
    for operation in (
        "mask_and",
        "mask_or",
        "mask_xor",
        "mask_not",
        "test",
        "any_true",
        "all_true",
        "none_true",
    ):
        route(
            f"flyology_simd__backends__native__{operation}",
            4,
            "mask-position",
            f"four Native {operation} calls in the public caller probe",
        )
    route(
        r"flyology_simd__backends__native__mask_from_bit_mask",
        3,
        "mask-position",
        "three out-of-line Native mask-construction calls in the public caller probe",
    )
    route(
        r"flyology_simd__backends__native__to_bit_mask",
        3,
        "mask-position",
        "three out-of-line Native mask-conversion calls in the public caller probe",
    )
    compact = r"flyology_simd__(mask_(from_bit_mask|and|or|xor|not)|to_bit_mask|test|any_true|all_true|none_true)"
    checker.forbid_pattern(
        compact,
        t / "mask-position-undefined.txt",
        "portable compact-mask call in the Native caller probe",
    )
    checker.forbid_pattern(
        compact,
        t / "native-undefined.txt",
        "portable compact-mask call retained in the Native backend object",
    )
    route(
        r"flyology_simd__backends__native__zero",
        10,
        "construction",
        "ten Native Zero calls in the public caller probe",
    )
    route(
        r"flyology_simd__backends__native__splat",
        9,
        "construction",
        "nine out-of-line Native Splat calls in the public caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__(zero|splat)",
        t / "construction-undefined.txt",
        "portable construction call in the Native caller probe",
    )
    for operation in ("from_lanes", "to_lanes", "extract", "replace"):
        route(
            f"flyology_simd__backends__native__{operation}",
            10,
            "construction",
            f"ten Native {operation} calls in the public caller probe",
        )
    access = r"flyology_simd__(from_lanes|to_lanes|extract|replace)"
    checker.forbid_pattern(
        access,
        t / "construction-undefined.txt",
        "portable lane-access call in the Native caller probe",
    )
    checker.forbid_pattern(
        access,
        t / "native-undefined.txt",
        "portable lane-access call retained in the Native backend object",
    )
    for operation in ("load_partial", "store_partial"):
        route(
            f"flyology_simd__backends__native__{operation}",
            10,
            "partial-memory",
            f"ten Native partial-{'load' if operation == 'load_partial' else 'store'} calls in the public caller probe",
        )
    partial = r"flyology_simd__(load_partial|store_partial)"
    checker.forbid_pattern(
        partial,
        t / "partial-memory-undefined.txt",
        "portable partial-memory call in the Native caller probe",
    )
    checker.forbid_pattern(
        partial,
        t / "native-undefined.txt",
        "portable partial-memory call retained in the Native backend object",
    )
    route(
        r"flyology_simd__backends__native__bit_cast",
        16,
        "bit-cast",
        "all sixteen Native Bit_Cast calls in the public caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__bit_cast",
        t / "bit-cast-undefined.txt",
        "portable Bit_Cast call in the Native caller probe",
    )
    checker.forbid_pattern(
        r"flyology_simd__bit_cast",
        t / "native-undefined.txt",
        "portable Bit_Cast call retained in the Native backend object",
    )
    checker.forbid_pattern(
        r"native_bit_cast",
        t / "native.txt",
        "out-of-line unchecked-conversion helper retained in the Native backend object",
    )
    checker.require_count(
        r"alignment_codegen_probe__.*_aligned_(16|32)",
        19,
        t / "alignment-symbols.txt",
        "all nineteen typed alignment-predicate callers",
    )
    checker.forbid_pattern(
        r"flyology_simd__(backends__native__is_aligned_16|wide__(native__)?is_aligned_32|is_aligned_16(__|$))",
        t / "alignment-undefined.txt",
        "out-of-line or portable alignment-predicate call in the caller probe",
    )
    checker.forbid_pattern(
        r"(^|[[:space:]])_?flyology_simd__(backends__native__)?is_aligned_16$",
        t / "native-undefined.txt",
        "undefined alignment predicate in the Native backend object",
    )
    checker.forbid_pattern(
        r"flyology_simd__is_aligned_16__",
        t / "native-undefined.txt",
        "typed portable alignment-predicate call retained in the Native backend object",
    )
    checker.forbid_pattern(
        r"flyology_simd__splat",
        t / "native-undefined.txt",
        "portable Splat call retained in the Native backend object",
    )


def check_fixed_width_callers(checker: Checker) -> None:
    t = checker.temporary
    branch = r"(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]"
    symbol_end = r"([+-]0x[[:xdigit:]]+)?([[:space:]]|$)"

    def ordinary_family(
        manifest: str,
        expected: int,
        stem: str,
        manifest_error: str,
        selected_description: str,
        forbidden: str,
        forbidden_description: str,
        route_pattern: str,
        route_description: str,
    ) -> None:
        cases = require_unique_manifest(manifest, expected, manifest_error)
        for row in cases:
            lane_kind, operation, suffix = row[:3]
            caller = t / f"{stem}-{lane_kind}-{operation}.txt"
            checker.extract_symbol(
                f"{stem.replace('-', '_')}_codegen_probe__{lane_kind}_{operation}",
                t / f"{stem}-probe.txt",
                caller,
            )
            symbol_suffix = "" if suffix == "none" else f"__{suffix}"
            checker.require_at_most(
                f"backends__native__{operation}{symbol_suffix}{symbol_end}",
                1,
                caller,
                f"matching selected {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                1,
                caller,
                f"only one selected {selected_description} in {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                branch,
                1,
                caller,
                f"only one out-of-line branch in {lane_kind} {operation} caller",
            )
            checker.forbid_pattern(
                forbidden,
                caller,
                f"{forbidden_description} in {lane_kind} {operation} caller",
            )
        undefined = t / f"{stem}-undefined.txt"
        probe = t / f"{stem}-probe.txt"
        checker.require_native_route(
            route_pattern, expected, undefined, probe, route_description
        )
        checker.require_at_most(
            r"flyology_simd__",
            expected,
            undefined,
            f"only the {expected} intended {selected_description}s remain unresolved",
        )
        checker.forbid_pattern(
            forbidden,
            undefined,
            f"{forbidden_description} retained in the caller probe",
        )

    # Integer reductions use the same one-route caller contract.
    ordinary_family(
        "integer_reduction_codegen_cases.txt",
        24,
        "integer-reduction",
        "128-bit integer-reduction manifest must contain 24 unique operations",
        "operation",
        r"flyology_simd__(backends__scalar__)?reduce_|flyology_simd__wide__",
        "portable, Scalar, or Wide reduction",
        r"flyology_simd__backends__native__reduce_(add_wrap|min|max)(__[2-8])?$",
        "all 24 selected 128-bit integer-reduction overloads",
    )
    ordinary_family(
        "wrapping_arithmetic_codegen_cases.txt",
        24,
        "wrapping-arithmetic",
        "fixed-width wrapping-arithmetic manifest must contain 24 unique operations",
        "operation",
        r"flyology_simd__(backends__scalar__)?(add_wrap|subtract_wrap|multiply_wrap)|flyology_simd__wide__",
        "portable, Scalar, or Wide arithmetic",
        r"flyology_simd__backends__native__(add_wrap|subtract_wrap|multiply_wrap)(__[2-8])?$",
        "all 24 selected fixed-width wrapping-arithmetic operations",
    )
    ordinary_family(
        "integer_minmax_codegen_cases.txt",
        16,
        "integer-minmax",
        "fixed-width integer Min/Max manifest must contain 16 unique operations",
        "integer Min/Max operation",
        r"flyology_simd__(backends__scalar__)?(min|max)(__[0-9]+)?|flyology_simd__wide__",
        "portable, Scalar, Wide, or mismatched Min/Max route",
        r"flyology_simd__backends__native__(min|max)(__[2-8])?$",
        "all 16 selected fixed-width integer Min/Max operations",
    )
    ordinary_family(
        "saturating_arithmetic_codegen_cases.txt",
        16,
        "saturating-arithmetic",
        "fixed-width saturating-arithmetic manifest must contain 16 unique operations",
        "saturating operation",
        r"flyology_simd__(backends__scalar__)?(add_saturate|subtract_saturate)(__[0-9]+)?|flyology_simd__wide__",
        "portable, Scalar, Wide, or mismatched saturation route",
        r"flyology_simd__backends__native__(add_saturate|subtract_saturate)(__[2-8])?$",
        "all 16 selected fixed-width saturating-arithmetic operations",
    )
    ordinary_family(
        "lane_arrangement_codegen_cases.txt",
        50,
        "lane-arrangement",
        "fixed-width lane-arrangement manifest must contain 50 unique operations",
        "arrangement",
        r"flyology_simd__(backends__scalar__)?(reverse_lanes|interleave_(low|high)|deinterleave_(even|odd))|flyology_simd__wide__",
        "portable, Scalar, or Wide arrangement",
        r"flyology_simd__backends__native__(reverse_lanes|interleave_(low|high)|deinterleave_(even|odd))(__([2-9]|10))?$",
        "all 50 selected fixed-width lane arrangements",
    )

    # Bitwise_And for U8 is the one fixed-width leaf that is always inlined.
    cases = require_unique_manifest(
        "bitwise_codegen_cases.txt",
        32,
        "fixed-width bitwise manifest must contain 32 unique operations",
    )
    forbidden = r"flyology_simd__(backends__scalar__)?bitwise_(and|or|xor|not)|flyology_simd__wide__"
    for lane_kind, operation, suffix, *_ in cases:
        caller = t / f"bitwise-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"bitwise_codegen_probe__{lane_kind}_{operation}",
            t / "bitwise-probe.txt",
            caller,
        )
        if lane_kind == "u8" and operation == "bitwise_and":
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                "inlined U8x16 Bitwise_And caller has no selected relocation",
            )
            checker.require_at_most(
                branch,
                0,
                caller,
                "inlined U8x16 Bitwise_And caller has no out-of-line branch",
            )
        else:
            suffix_text = "" if suffix == "none" else f"__{suffix}"
            checker.require_at_most(
                f"backends__native__{operation}{suffix_text}{symbol_end}",
                1,
                caller,
                f"matching selected {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                1,
                caller,
                f"only one selected bitwise operation in {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                branch,
                1,
                caller,
                f"only one out-of-line branch in {lane_kind} {operation} caller",
            )
        checker.forbid_pattern(
            forbidden,
            caller,
            f"portable, Scalar, or Wide bitwise route in {lane_kind} {operation} caller",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__bitwise_(and|or|xor|not)(__[2-8])?$",
        31,
        t / "bitwise-undefined.txt",
        t / "bitwise-probe.txt",
        "31 selected plus one inlined fixed-width bitwise operation",
    )
    checker.require_at_most(
        r"flyology_simd__",
        31,
        t / "bitwise-undefined.txt",
        "only the 31 intended out-of-line bitwise operations remain unresolved",
    )
    checker.forbid_pattern(
        forbidden,
        t / "bitwise-undefined.txt",
        "portable, Scalar, or Wide bitwise route retained in the caller probe",
    )

    cases = require_unique_manifest(
        "float_binary_codegen_cases.txt",
        12,
        "floating binary-operation manifest must contain 12 unique operations",
    )
    forbidden_float = r"flyology_simd__(backends__scalar__)?(add|subtract|multiply|divide|min_number|max_number)|flyology_simd__wide__"
    for lane_kind, operation, suffix, *_ in cases:
        caller = t / f"float-binary-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"float_binary_codegen_probe__{lane_kind}_{operation}",
            t / "float-binary-probe.txt",
            caller,
        )
        suffix_text = "" if suffix == "none" else f"__{suffix}"
        checker.require_at_most(
            f"backends__native__{operation}{suffix_text}{symbol_end}",
            1,
            caller,
            f"matching selected {lane_kind} {operation} caller",
        )
        checker.require_at_most(
            r"flyology_simd__backends__native__",
            1,
            caller,
            f"only one selected operation in {lane_kind} {operation} caller",
        )
        checker.require_at_most(
            r"flyology_simd__",
            1,
            caller,
            f"only the matching selected operation remains in {lane_kind} {operation} caller",
        )
        checker.require_at_most(
            branch,
            1,
            caller,
            f"only one out-of-line branch in {lane_kind} {operation} caller",
        )
        checker.forbid_pattern(
            forbidden_float,
            caller,
            f"portable, Scalar, or Wide floating operation in {lane_kind} {operation} caller",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(add|subtract|multiply|divide|min_number|max_number)(__2)?$",
        12,
        t / "float-binary-undefined.txt",
        t / "float-binary-probe.txt",
        "all 12 selected floating binary operations",
    )
    checker.require_at_most(
        r"flyology_simd__",
        12,
        t / "float-binary-undefined.txt",
        "only the 12 intended floating operations remain unresolved from the caller probe",
    )


def check_complete_memory_callers(checker: Checker) -> None:
    t = checker.temporary
    cases = require_unique_manifest(
        "complete_memory_codegen_cases.txt",
        60,
        "complete-memory manifest must contain 60 unique operations",
    )
    branch = r"(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]"
    symbol_end = r"([+-]0x[[:xdigit:]]+)?([[:space:]]|$)"
    forbidden = r"flyology_simd__(backends__scalar__)?(load|store)(_unaligned|_aligned)?|flyology_simd__wide__"
    for lane_kind, operation, suffix in cases:
        caller = t / f"complete-memory-{lane_kind}-{operation}.txt"
        checker.extract_symbol(
            f"complete_memory_codegen_probe__{lane_kind}_{operation}",
            t / "complete-memory-probe.txt",
            caller,
        )
        if (
            lane_kind == "u8"
            and operation == "load_unaligned"
            and checker.architecture == "aarch64"
        ):
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                "inlined selected U8 Load_Unaligned caller",
            )
            checker.require_count(
                r"(^|[[:space:]])ldr[[:space:]]+q[0-9]+,[[:space:]]*\[",
                1,
                caller,
                "inlined U8 Load_Unaligned target load",
            )
            checker.require_count(
                r"(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[",
                0,
                caller,
                "no inlined U8 Load_Unaligned result store",
            )
        elif (
            lane_kind == "u8"
            and operation == "load_unaligned"
            and checker.architecture == "x86_64"
        ):
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                0,
                caller,
                "inlined selected U8 Load_Unaligned caller",
            )
            checker.require_at_least(
                r"(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]",
                1,
                caller,
                "inlined U8 Load_Unaligned array-to-register transfer",
            )
            checker.require_count(
                r"(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)",
                0,
                caller,
                "no inlined U8 Load_Unaligned result store",
            )
        else:
            suffix_text = "" if suffix == "none" else f"__{suffix}"
            checker.require_at_most(
                f"backends__native__{operation}{suffix_text}{symbol_end}",
                1,
                caller,
                f"matching selected {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                r"flyology_simd__backends__native__",
                1,
                caller,
                f"only one selected memory operation in {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                r"flyology_simd__",
                1,
                caller,
                f"only the matching selected memory operation remains in {lane_kind} {operation} caller",
            )
            checker.require_at_most(
                branch,
                1,
                caller,
                f"only one out-of-line branch in {lane_kind} {operation} caller",
            )
        checker.forbid_pattern(
            forbidden,
            caller,
            f"portable, Scalar, or Wide memory call in {lane_kind} {operation} caller",
        )
    checker.require_native_route(
        r"flyology_simd__backends__native__(load|store)(_unaligned|_aligned)?(__([2-9]|10))?$",
        59,
        t / "complete-memory-undefined.txt",
        t / "complete-memory-probe.txt",
        "the 59 out-of-line selected complete-memory operations",
    )
    checker.require_at_most(
        r"flyology_simd__",
        59,
        t / "complete-memory-undefined.txt",
        "only the intended complete-memory operations remain unresolved",
    )
