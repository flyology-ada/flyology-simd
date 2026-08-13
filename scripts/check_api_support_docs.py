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
    if path.name == "flyology_simd-wide.ads":
        contextual_compact = (
            "In a scalar build, the matching Wide.Native overload uses the same "
            "two-part composition through the portable 128-bit implementation."
        )
        if text.count(contextual_compact) != 20:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected 20 contextualized portable "
                f"Compact support notes, found {text.count(contextual_compact)}"
            )
        movement_context = "In a scalar build, the matching Wide.Native overload uses"
        movement_operations = {
            "Reverse_Lanes": (10, "two selected 128-bit two-source Permute_Lanes operations"),
            "Permute_Lanes": (20, None),
            "Interleave_Low": (10, "four selected 128-bit two-source Permute_Lanes operations"),
            "Interleave_High": (10, "four selected 128-bit two-source Permute_Lanes operations"),
            "Deinterleave_Even": (10, "four selected 128-bit two-source Permute_Lanes operations"),
            "Deinterleave_Odd": (10, "four selected 128-bit two-source Permute_Lanes operations"),
            "Slide_Lanes_Toward_Low": (10, "two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero"),
            "Slide_Lanes_Toward_High": (10, "two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero"),
        }
        for operation, (expected, phrase) in movement_operations.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            contextual = sum(movement_context in block for block in blocks)
            classified = sum(phrase in block for block in blocks) if phrase else expected
            if len(blocks) != expected or contextual != expected or classified != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    f"movement classifications ({len(blocks)} declarations, "
                    f"{contextual} contextual, {classified} mechanism notes)"
                )
        permute_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Permute_Lanes")[1:]
        ]
        one_source = sum(
            "two selected 128-bit two-source Permute_Lanes operations" in block
            and "four selected 128-bit two-source Permute_Lanes operations" not in block
            for block in permute_blocks
        )
        two_source = sum(
            "four selected 128-bit two-source Permute_Lanes operations" in block
            and "two selected Select_Value operations" in block
            for block in permute_blocks
        )
        if one_source != 10 or two_source != 10:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected ten one-source and ten "
                f"two-source Permute_Lanes classifications, found "
                f"{one_source} and {two_source}"
            )
        floating_reductions = {
            "Reduce_Add": "dedicated SSE2 sequence with the same start value and lane order",
            "Reduce_Min_Number": "integer-only SSE2 classification and bit-selection sequence that applies minimum-number in the same order",
            "Reduce_Max_Number": "integer-only SSE2 classification and bit-selection sequence that applies maximum-number in the same order",
        }
        for operation, phrase in floating_reductions.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
                if re.match(r"\s*\(Value : F(?:32x8|64x4)\)", block)
            ]
            found = sum(
                phrase in block
                and "For the matching Wide.Native overload" in block
                for block in blocks
            )
            if len(blocks) != 2 or found != 2:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    f"ordered floating-reduction classifications ({found}/2)"
                )
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
        multiply_support = "dedicated NEON 32-bit partial-product sequence"
        if text.count(multiply_support) != 2:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected two portable 64-bit "
                f"Multiply_Wrap notes with exact Native lowering, found "
                f"{text.count(multiply_support)}"
            )
    if path.name == "flyology_simd-backends-native.ads":
        lane_access_support = {
            "From_Lanes": "copy the supplied lane array into private vector storage",
            "To_Lanes": "copy private vector storage into the result lane array",
            "Extract": "read the selected position from private vector storage",
            "Replace": "copy private vector storage and write the selected position",
        }
        for operation, phrase in lane_access_support.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            found = sum(
                phrase in block and "do not call the portable root operation" in block
                for block in blocks
            )
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact {operation} "
                    f"direct-lane-access classifications, found {found}"
                )
        partial_memory_support = {
            "Load_Partial": "read exactly Count elements and initialize every inactive result lane to positive zero",
            "Store_Partial": "write the first Count value lanes to exactly Count destination elements and leave every other array element unchanged",
        }
        for operation, phrase in partial_memory_support.items():
            declaration = "function" if operation == "Load_Partial" else "procedure"
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"{declaration} {operation}")[1:]
            ]
            found = sum(
                phrase in block
                and "A zero count does not evaluate an element address" in block
                and "do not call the portable root operation" in block
                for block in blocks
            )
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact {operation} "
                    f"direct-partial-memory classifications, found {found}"
                )
        bit_cast_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Bit_Cast")[1:]
        ]
        bit_cast_phrase = (
            "reinterpret the complete 128-bit private vector value directly "
            "with Ada.Unchecked_Conversion"
        )
        if (
            len(bit_cast_blocks) != 16
            or sum(bit_cast_phrase in block for block in bit_cast_blocks) != 16
            or sum(
                "do not call the portable root operation" in block
                for block in bit_cast_blocks
            ) != 16
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact Bit_Cast "
                "direct-reinterpretation classifications"
            )
        alignment_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Is_Aligned_16")[1:]
        ]
        if (
            len(alignment_blocks) != 9
            or sum(
                "first check that Start is in the array range" in block
                and "test the selected element address modulo 16 directly" in block
                and "do not call the portable root operation" in block
                for block in alignment_blocks
            ) != 9
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact Is_Aligned_16 "
                "direct-range-and-address classifications"
            )
        zero_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Zero")[1:]
        ]
        if (
            len(zero_blocks) != 10
            or sum("directly in result registers" in block for block in zero_blocks) != 1
            or sum("NEON movi instruction" in block and "SSE2 pxor instruction" in block for block in zero_blocks) != 9
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact Zero target classifications"
            )
        splat_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Splat")[1:]
        ]
        if (
            len(splat_blocks) != 10
            or sum("NEON dup instruction" in block for block in splat_blocks) != 10
            or sum("unpacks the input byte through word width" in block for block in splat_blocks) != 1
            or sum("replicates the input bits through 32-bit width" in block for block in splat_blocks) != 3
            or sum("broadcasts the input bits with the SSE2 pshufd instruction" in block for block in splat_blocks) != 3
            or sum("SSE2 punpcklqdq instruction" in block for block in splat_blocks) != 3
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact Splat target classifications"
            )
        direct_mask_support = (
            "The AArch64 and x86-64 backends apply this operation directly to "
            "the fixed-width compact integer mask."
        )
        for operation in (
            "Mask_From_Bit_Mask",
            "To_Bit_Mask",
            "Mask_And",
            "Mask_Or",
            "Mask_Xor",
            "Mask_Not",
            "Test",
            "Any_True",
            "All_True",
            "None_True",
        ):
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            found = sum(direct_mask_support in block for block in blocks)
            if found != 4:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected four exact {operation} "
                    f"direct-mask classifications, found {found}"
                )
        horizontal_sum_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Horizontal_Sum")[1:]
        ]
        if (
            len(horizontal_sum_blocks) != 1
            or "NEON uaddlv instruction" not in horizontal_sum_blocks[0]
            or "SSE2 psadbw" not in horizontal_sum_blocks[0]
            or "two 64-bit partial sums" not in horizontal_sum_blocks[0]
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact Horizontal_Sum "
                "backend classification"
            )
        for phrase, backend in (
            ("dedicated NEON 32-bit partial-product sequence", "AArch64"),
            ("dedicated SSE2 32-bit partial-product sequence", "x86-64"),
        ):
            if text.count(phrase) != 2:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected two exact 64-bit "
                    f"Multiply_Wrap {backend} notes, found {text.count(phrase)}"
                )
        select_support = (
            "Select_Value", "The AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence."
        )
        select_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split(f"function {select_support[0]}")[1:]
        ]
        selected = sum(select_support[1] in block for block in select_blocks)
        if selected != 10:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected ten exact Select_Value "
                f"NEON classifications, found {selected}"
            )
        reduction_support = {
            "Reduce_Add_Wrap": (
                "The x86-64 backend uses a dedicated SSE2 packed-add reduction tree.",
                8,
            ),
            "Reduce_Min": (
                "minimum reduction over fixed shuffles",
                8,
            ),
            "Reduce_Max": (
                "maximum reduction over fixed shuffles",
                8,
            ),
        }
        for operation, (phrase, expected) in reduction_support.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            found = sum(phrase in block for block in blocks)
            if found != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected {expected} exact "
                    f"{operation} SSE2 classifications, found {found}"
                )
        floating_add_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Reduce_Add")[1:]
            if not block.startswith("_Wrap")
        ]
        floating_add_phrase = (
            "dedicated SSE2 sequence that starts from positive zero and "
            "adds one binary"
        )
        if (
            len(floating_add_blocks) != 2
            or sum(floating_add_phrase in block for block in floating_add_blocks) != 2
            or sum("dedicated NEON sequence that starts from positive zero" in block for block in floating_add_blocks) != 2
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact floating "
                "Reduce_Add backend classifications"
            )
        floating_minmax_support = {
            "Min_Number": (
                "integer-only SSE2 classification and bit-selection sequence that preserves",
                2,
            ),
            "Max_Number": (
                "integer-only SSE2 classification and bit-selection sequence that preserves",
                2,
            ),
            "Reduce_Min_Number": (
                "integer-only SSE2 classification and bit-selection sequence that folds lanes in ascending order",
                2,
            ),
            "Reduce_Max_Number": (
                "integer-only SSE2 classification and bit-selection sequence that folds lanes in ascending order",
                2,
            ),
        }
        for operation, (phrase, expected) in floating_minmax_support.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            found = sum(phrase in block for block in blocks)
            if len(blocks) != expected or found != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    "SSE2 classifications"
                )
        conversion_support = {
            "Widen_Low": ("dedicated SSE2 sequence that unpacks and extends the selected lanes", 6),
            "Widen_High": ("dedicated SSE2 sequence that unpacks and extends the selected lanes", 6),
            "Narrow_Truncate": ("dedicated SSE2 sequence that selects the low bits and packs the result lanes", 6),
            "Narrow_Saturate": ("dedicated SSE2 sequence that clamps and packs the result lanes", 9),
        }
        for operation, (phrase, expected) in conversion_support.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            found = sum(phrase in block for block in blocks)
            if found != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected {expected} exact "
                    f"{operation} SSE2 classifications, found {found}"
                )
        conversion64_support = {
            "cvtsi2sdq and merges the two binary64 results": 1,
            "shifts each unsigned value above the signed maximum to the right": 1,
            "truncates each lane with cvttsd2siq and classifies the binary64 encoding": 1,
            "For a value that is at least 2 to the power of 63 and less than 2 to the power of 64": 1,
        }
        for phrase, expected in conversion64_support.items():
            found = text.count(phrase)
            if found != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected {expected} exact "
                    f"64-bit numeric conversion classification for {phrase!r}, "
                    f"found {found}"
                )
        logical_shift_blocks = {
            operation: [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
                if any(
                    f"Value : {vector}" in block.split(";", 1)[0]
                    for vector in (
                        "U8x16", "I8x16", "U16x8", "I16x8",
                        "U32x4", "I32x4", "U64x2", "I64x2",
                    )
                )
            ]
            for operation in ("Shift_Left_Logical", "Shift_Right_Logical")
        }
        for operation, direction, byte_action, instruction_stem in (
            ("Shift_Left_Logical", "positive", "shifts the 16-bit lanes left", "psll"),
            ("Shift_Right_Logical", "negative", "shifts the 16-bit lanes right", "psrl"),
        ):
            blocks = logical_shift_blocks[operation]
            requirements = (
                ("8-bit lanes with the NEON ushl", byte_action, "When Count exceeds 8"),
                ("8-bit lanes with the NEON ushl", byte_action, "When Count exceeds 8"),
                ("16-bit lanes with the NEON ushl", f"16-bit lanes with {instruction_stem}w", "When Count exceeds 16"),
                ("16-bit lanes with the NEON ushl", f"16-bit lanes with {instruction_stem}w", "When Count exceeds 16"),
                ("32-bit lanes with the NEON ushl", f"32-bit lanes with {instruction_stem}d", "When Count exceeds 32"),
                ("32-bit lanes with the NEON ushl", f"32-bit lanes with {instruction_stem}d", "When Count exceeds 32"),
                ("64-bit lanes with the NEON ushl", f"64-bit lanes with {instruction_stem}q", "When Count exceeds 64"),
                ("64-bit lanes with the NEON ushl", f"64-bit lanes with {instruction_stem}q", "When Count exceeds 64"),
            )
            if (
                len(blocks) != 8
                or any(
                    f"a {direction} count" not in block
                    or not all(phrase in block for phrase in expected)
                    for block, expected in zip(blocks, requirements)
                )
            ):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact all-family "
                    f"{operation} target classifications"
                )
        for operation, direction, x86_instruction in (
            ("Slide_Lanes_Toward_Low", "lower", "psrldq"),
            ("Slide_Lanes_Toward_High", "higher", "pslldq"),
        ):
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            if (
                len(blocks) != 10
                or any(
                    "AArch64 backend uses NEON ext" not in block
                    or f"toward {direction} indexes" not in block
                    or f"SSE2 {x86_instruction}" not in block
                    or "each backend calls its own target Zero" not in block
                    or "does not call the portable root operation" not in block
                    for block in blocks
                )
            ):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact all-family "
                    f"{operation} target classifications"
                )
        table_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Table_Lookup")[1:]
        ]
        if (
            len(table_blocks) != 1
            or "one NEON tbl instruction" not in table_blocks[0]
            or "compares each index with every valid table position" not in table_blocks[0]
            or "broadcasts the matching table byte" not in table_blocks[0]
            or "Indexes above 15 match no position and remain zero" not in table_blocks[0]
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact Table_Lookup "
                "target classification"
            )
        permute_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Permute_Lanes")[1:]
        ]
        if (
            len(permute_blocks) != 20
            or any(
                "NEON tbl sequence" not in block
                or "selects complete lane byte groups" not in block
                or "compares every byte selector with each valid source position" not in block
                or "broadcasts matching source bytes" not in block
                or "merges them into the result" not in block
                for block in permute_blocks
            )
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact all-family "
                "Permute_Lanes target classifications"
            )
        for operation, map_phrase in (
            ("Compress", "stable compression byte map from the mask"),
            ("Expand", "expansion byte map from the mask"),
        ):
            compact_blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            if (
                len(compact_blocks) != 10
                or any(
                    map_phrase not in block
                    or "dedicated NEON tbl sequence" not in block
                    or "compares every byte selector with each valid source position"
                    not in block
                    or "broadcasts matching source bytes" not in block
                    or "merges them into the result" not in block
                    for block in compact_blocks
                )
            ):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact all-family "
                    f"{operation} target classifications"
                )
        shift_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Shift_Right_Arithmetic")[1:]
            if any(
                f"Value : {vector}" in block.split(";", 1)[0]
                for vector in ("I8x16", "I16x8", "I32x4", "I64x2")
            )
        ]
        shift_requirements = (
            ("signed 8-bit lanes with the NEON sshl", "widens the signed bytes", "When Count exceeds 8, both backends clamp it to 8"),
            ("signed 16-bit lanes with the NEON sshl", "signed 16-bit lanes with psraw", "When Count exceeds 16, both backends clamp it to 16"),
            ("signed 32-bit lanes with the NEON sshl", "signed 32-bit lanes with psrad", "When Count exceeds 32, both backends clamp it to 32"),
            ("signed 64-bit lanes with the NEON sshl", "derives each lane's sign mask", "When Count exceeds 64, both backends clamp it to 64"),
        )
        if (
            len(shift_blocks) != 4
            or any(
                not all(phrase in block for phrase in requirements)
                for block, requirements in zip(shift_blocks, shift_requirements)
            )
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact all-family "
                "Shift_Right_Arithmetic target classifications"
            )
        unordered_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Unordered")[1:]
            if (
                "Left, Right : F32x4" in block.split(";", 1)[0]
                or "Left, Right : F64x2" in block.split(";", 1)[0]
            )
        ]
        unordered_phrase = (
            "The AArch64 backend uses a dedicated NEON sequence that "
            "compares each input with itself to mark lanes that are not NaN. "
            "It combines the masks with bitwise AND and inverts the result."
        )
        if (
            len(unordered_blocks) != 2
            or sum(unordered_phrase in block for block in unordered_blocks) != 2
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact floating "
                "Unordered AArch64 classifications"
            )
        floating_widening_support = {
            "Widen_Low": (
                "dedicated NEON instruction that converts the selected lanes with fcvtl",
                "dedicated SSE2 instruction that converts the selected lanes with cvtps2pd",
            ),
            "Widen_High": (
                "dedicated NEON instruction that converts the selected lanes with fcvtl2",
                "dedicated SSE2 sequence that shuffles the upper lanes and converts them with cvtps2pd",
            ),
        }
        for operation, (aarch_phrase, x86_phrase) in floating_widening_support.items():
            floating_blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
                if "Value : F32x4" in block.split(";", 1)[0]
            ]
            if len(floating_blocks) != 1:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected one exact floating "
                    f"{operation} classification"
                )
            elif aarch_phrase not in floating_blocks[0] or x86_phrase not in floating_blocks[0]:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact floating "
                    f"{operation} backend classification"
                )
        narrow_round_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Narrow_Round")[1:]
            if "Low, High : F64x2" in block.split(";", 1)[0]
        ]
        if (
            len(narrow_round_blocks) != 1
            or "dedicated NEON sequence that converts the lanes with fcvtn and fcvtn2"
            not in narrow_round_blocks[0]
            or "dedicated SSE2 sequence that converts with cvtpd2ps and merges the result lanes"
            not in narrow_round_blocks[0]
        ):
            invalid.append(
                f"{path.relative_to(ROOT)}: incorrect exact floating "
                "Narrow_Round backend classification"
            )
        convert_saturate_blocks = [
            block.split("function ", 1)[0].split("procedure ", 1)[0]
            for block in text.split("function Convert_Saturate")[1:]
        ]
        convert_saturate_phrase = (
            "dedicated SSE2 sequence that derives a sign mask and selects "
            "the clamped lanes"
        )
        found = sum(
            convert_saturate_phrase in block
            for block in convert_saturate_blocks
        )
        if found != 8:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected eight exact "
                f"Convert_Saturate SSE2 classifications, found {found}"
            )
        numeric_conversion_support = {
            ("Convert_Round", "Value : I32x4"): (
                "The x86-64 backend converts the lanes with the dedicated "
                "SSE2 cvtdq2ps instruction."
            ),
            ("Convert_Round", "Value : U32x4"): (
                "Under the required default round-to-nearest, ties-to-even "
                "mode, the x86-64 backend adjusts unsigned values above the "
                "signed maximum. It then converts the lanes with cvtdq2ps."
            ),
            ("Convert_Truncate_Saturate", "return I32x4"): (
                "The x86-64 backend truncates the lanes with cvttps2dq. It "
                "selects zero for NaN, the signed maximum for positive "
                "overflow, and the signed minimum for negative overflow."
            ),
            ("Convert_Truncate_Saturate", "return U32x4"): (
                "The x86-64 backend truncates the lanes with cvttps2dq. It "
                "selects zero for NaN or a negative input and the unsigned "
                "maximum for positive overflow."
            ),
        }
        for (operation, signature_part), phrase in numeric_conversion_support.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
                if signature_part in block.split(";", 1)[0]
            ]
            if len(blocks) != 1 or phrase not in blocks[0]:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    f"{signature_part} SSE2 classification"
                )
        saturation_support = {
            ("Add_Saturate", "U32x4"): "derives a carry mask and selects the unsigned maximum",
            ("Add_Saturate", "I32x4"): "derives a signed-overflow mask and selects the signed minimum or maximum",
            ("Add_Saturate", "U64x2"): "derives a carry mask and selects the unsigned maximum",
            ("Add_Saturate", "I64x2"): "derives a signed-overflow mask and selects the signed minimum or maximum",
            ("Subtract_Saturate", "U32x4"): "derives a borrow mask and selects zero",
            ("Subtract_Saturate", "I32x4"): "derives a signed-overflow mask and selects the signed minimum or maximum",
            ("Subtract_Saturate", "U64x2"): "derives a borrow mask and selects zero",
            ("Subtract_Saturate", "I64x2"): "derives a signed-overflow mask and selects the signed minimum or maximum",
        }
        for (operation, vector), phrase in saturation_support.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
                if vector in block.split(";", 1)[0]
            ]
            found = sum(phrase in block for block in blocks)
            if len(blocks) != 1 or found != 1:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {vector} "
                    f"{operation} SSE2 classification"
                )
    if path.name == "flyology_simd-wide-native.ads":
        required = {
            "function Is_Aligned_32": "test the selected element address modulo 32 directly",
            "function Interleave_Low": "four-register NEON tbl operation",
            "function Interleave_High": "four-register NEON tbl operation",
            "function Deinterleave_Even": "four-register NEON tbl operation",
            "function Deinterleave_Odd": "four-register NEON tbl operation",
            "function Reverse_Lanes": "two-register NEON tbl operation",
            "function Slide_Lanes_Toward_Low": "two-register NEON tbl operation",
            "function Slide_Lanes_Toward_High": "two-register NEON tbl operation",
            "function Load_Partial": "conditionally compose selected 128-bit full and partial memory operations",
            "procedure Store_Partial": "conditionally compose selected 128-bit full and partial memory operations",
            "function Add (": "optional AVX2 backend uses one isolated 256-bit vadd",
            "function Subtract (": "optional AVX2 backend uses one isolated 256-bit vsub",
            "function Multiply (": "optional AVX2 backend uses one isolated 256-bit vmul",
            "function Divide (": "optional AVX2 backend uses one isolated 256-bit vdiv",
            "function Min_Number": "isolated 256-bit integer-classification and bit-selection sequence",
            "function Max_Number": "isolated 256-bit integer-classification and bit-selection sequence",
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
            "function Population_Count": "selected 128-bit population-count operation on both private parts and add the two counts",
            "function First_True": "return a valid low-part result first",
            "function Last_True": "return a valid high-part result plus the private lane count first",
            "function Extract": "only on the private part that contains the requested lane",
            "function Replace": "only on the private part that contains the requested lane",
            "function Test": "only on the private part that contains the requested lane",
            "function Reduce_Add_Wrap": "reduce each private part with the selected 128-bit Reduce_Add_Wrap operation",
            "function Reduce_Min": "reduce each private part with the selected 128-bit Reduce_Min operation",
            "function Reduce_Max": "reduce each private part with the selected 128-bit Reduce_Max operation",
            "function Reduce_Add (": "dedicated SSE2 sequence with the same start value and lane order",
            "function Reduce_Min_Number": "integer-only SSE2 classification and bit-selection sequence that applies minimum-number in the same order",
            "function Reduce_Max_Number": "integer-only SSE2 classification and bit-selection sequence that applies maximum-number in the same order",
            "function Table_Lookup": "uses four selected 128-bit Table_Lookup operations",
            "function Permute_Lanes": "optional AVX2 backend derives a 32-byte index map",
            "function Reverse_Lanes": "composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations",
            "function Interleave_Low": "four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations",
            "function Interleave_High": "four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations",
            "function Deinterleave_Even": "four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations",
            "function Deinterleave_Odd": "four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations",
            "function Slide_Lanes_Toward_Low": "two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero",
            "function Slide_Lanes_Toward_High": "two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero",
            "function Compress": "derive two selected-128-bit compression maps",
            "function Expand": "derive two selected-128-bit expansion maps",
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
                "function Reverse_Lanes": 10,
                "function Interleave_Low": 10,
                "function Interleave_High": 10,
                "function Deinterleave_Even": 10,
                "function Deinterleave_Odd": 10,
                "function Slide_Lanes_Toward_Low": 10,
                "function Slide_Lanes_Toward_High": 10,
                "function Compress": 10,
                "function Expand": 10,
                "function Test": 4,
                "function Reduce_Add_Wrap": 8,
                "function Reduce_Min": 8,
                "function Reduce_Max": 8,
                "function Reduce_Add (": 2,
                "function Reduce_Min_Number": 2,
                "function Reduce_Max_Number": 2,
            }.get(declaration, 10)
            if count != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: {declaration} classification "
                    f"appears {count} times, expected {expected}"
                )
    if path.name in {"flyology_simd-wide.ads", "flyology_simd-wide-native.ads"}:
        wide_numeric_conversion_support = (
            ("Convert_Round", "Value : I32x8", "return F32x8"),
            ("Convert_Round", "Value : U32x8", "return F32x8"),
            ("Convert_Round", "Value : I64x4", "return F64x4"),
            ("Convert_Round", "Value : U64x4", "return F64x4"),
            ("Convert_Truncate_Saturate", "Value : F32x8", "return I32x8"),
            ("Convert_Truncate_Saturate", "Value : F32x8", "return U32x8"),
            ("Convert_Truncate_Saturate", "Value : F64x4", "return I64x4"),
            ("Convert_Truncate_Saturate", "Value : F64x4", "return U64x4"),
        )
        for operation, parameter, result in wide_numeric_conversion_support:
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
                if parameter in block.split(";", 1)[0]
                and result in block.split(";", 1)[0]
            ]
            phrase = (
                "AArch64 and x86-64 backends run the selected 128-bit "
                "operation on both private parts"
            )
            if len(blocks) != 1 or phrase not in blocks[0]:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    f"{parameter} {result} selected-two-part classification"
                )
        non_numeric_counts = {
            "Narrow_Truncate": 6,
            "Narrow_Saturate": 9,
            "Narrow_Round": 1,
            "Convert_Saturate": 8,
        }
        phrase = (
            "AArch64 and x86-64 backends run the selected 128-bit "
            "operation on both private parts"
        )
        for operation, expected in non_numeric_counts.items():
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            if len(blocks) != expected or sum(phrase in block for block in blocks) != expected:
                invalid.append(
                    f"{path.relative_to(ROOT)}: exact Wide {operation} "
                    f"selected-two-part classifications are incomplete"
                )
        for operation, part in (("Widen_Low", "low"), ("Widen_High", "high")):
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            phrases = (
                f"select the {part} private source part",
                "selected 128-bit Widen_Low operation forms the low result part",
                "selected 128-bit Widen_High operation forms the high result part",
            )
            if len(blocks) != 7 or any(
                sum(phrase in block for block in blocks) != 7 for phrase in phrases
            ):
                invalid.append(
                    f"{path.relative_to(ROOT)}: exact Wide {operation} "
                    "selected-source/two-result-part classifications are incomplete"
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
