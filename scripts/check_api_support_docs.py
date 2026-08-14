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


def declaration_blocks(text: str, name: str) -> list[str]:
    """Return exact declaration-plus-documentation blocks for one public name."""
    lines = text.splitlines()
    blocks: list[str] = []
    index = 0
    while index < len(lines):
        match = DECLARATION.match(lines[index])
        if match is None:
            index += 1
            continue
        end = declaration_end(lines, index)
        comment = end + 1
        while comment < len(lines) and lines[comment].startswith("   --"):
            comment += 1
        if match.group(1) == name:
            blocks.append("\n".join(lines[index:comment]))
        index = comment
    return blocks


def comparison_phrases(operation: str, vector: str) -> tuple[str, str]:
    """Return exact AArch64/x86 phrases for one fixed-width predicate."""
    if vector.startswith("F"):
        shape = "4s" if vector == "F32x4" else "2d"
        x86_shape = "ps" if vector == "F32x4" else "pd"
        neon = {
            "Equal": "fcmeq", "Less_Than": "fcmgt with reversed operands",
            "Less_Equal": "fcmge with reversed operands",
            "Greater_Than": "fcmgt", "Greater_Equal": "fcmge",
        }[operation]
        sse2 = {
            "Equal": f"cmpeq{x86_shape}", "Less_Than": f"cmplt{x86_shape}",
            "Less_Equal": f"cmple{x86_shape}",
            "Greater_Than": f"cmplt{x86_shape} with reversed operands",
            "Greater_Equal": f"cmple{x86_shape} with reversed operands",
        }[operation]
        return (f"NEON {neon} comparison over {shape} lanes", f"SSE2 {sse2} comparison")
    signed = vector.startswith("I")
    width = re.search(r"(8|16|32|64)x", vector).group(1)
    shape = {"8": "16b", "16": "8h", "32": "4s", "64": "2d"}[width]
    pcmpeq = {"8": "pcmpeqb", "16": "pcmpeqw", "32": "pcmpeqd", "64": "pcmpeqd"}[width]
    pcmpgt = {"8": "pcmpgtb", "16": "pcmpgtw", "32": "pcmpgtd", "64": "pcmpgtd"}[width]
    if operation == "Equal":
        x86 = f"SSE2 {pcmpeq} comparison"
        if width == "64":
            x86 += " with adjacent dword results combined per 64-bit lane"
        return (f"NEON cmeq comparison over {shape} lanes", x86)
    neon = (("cmgt" if signed else "cmhi") if "Than" in operation
            else ("cmge" if signed else "cmhs"))
    direction = " with reversed operands" if operation.startswith("Less") else ""
    aarch = f"NEON {neon} comparison over {shape} lanes{direction}"
    if width == "64":
        bias = " with an unsigned sign-bit bias" if not signed else ""
        x86 = f"SSE2 equality-gated two-dword lexicographic comparison using {pcmpgt}{bias}"
    else:
        bias = " with an unsigned sign-bit bias" if not signed else ""
        x86 = f"SSE2 {pcmpgt} comparison{bias}"
        if "Equal" in operation:
            x86 += f" merged with {pcmpeq} equality"
        if operation.startswith("Less"):
            x86 += " using reversed operands"
    return aarch, x86


def wrapping_arithmetic_phrases(operation: str, vector: str) -> tuple[str, str]:
    """Return exact AArch64/x86 phrases for wrapping integer arithmetic."""
    width = int(re.search(r"(8|16|32|64)x", vector).group(1))
    shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[width]
    if operation == "Add_Wrap":
        return (
            f"NEON add instruction over {shape} lanes",
            f"SSE2 padd{ {8: 'b', 16: 'w', 32: 'd', 64: 'q'}[width] } instruction",
        )
    if operation == "Subtract_Wrap":
        return (
            f"NEON sub instruction over {shape} lanes",
            f"SSE2 psub{ {8: 'b', 16: 'w', 32: 'd', 64: 'q'}[width] } instruction",
        )
    if width < 64:
        return (
            f"NEON mul instruction over {shape} lanes",
            {
                8: "widens bytes, uses two pmullw instructions, and packs the low product bytes",
                16: "SSE2 pmullw instruction",
                32: "uses two pmuludq instructions and repacks the dword products",
            }[width],
        )
    return (
        "NEON 32-bit partial-product sequence",
        "SSE2 three-pmuludq partial-product sequence",
    )


def lane_arrangement_phrases(operation: str, vector: str) -> tuple[str, str]:
    """Return exact AArch64/x86 phrases for one canonical arrangement."""
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[bits]
    if operation == "Reverse_Lanes":
        aarch = (
            "NEON ext instruction with an eight-byte offset"
            if bits == 64 else
            f"NEON rev64 over {shape} lanes followed by ext with an eight-byte offset"
        )
        x86 = {
            8: "SSE2 byte shifts and OR followed by pshuflw, pshufhw, and pshufd",
            16: "SSE2 pshuflw, pshufhw, and pshufd",
            32: "SSE2 pshufd with control 0x1B",
            64: "SSE2 pshufd with control 0x4E",
        }[bits]
    elif operation in {"Interleave_Low", "Interleave_High"}:
        high = operation.endswith("High")
        aarch = f"NEON {'zip2' if high else 'zip1'} instruction over {shape} lanes"
        if vector.startswith("F"):
            x86 = f"SSE2 unpck{'h' if high else 'l'}{'ps' if bits == 32 else 'pd'} instruction"
        else:
            suffix = {8: "bw", 16: "wd", 32: "dq", 64: "qdq"}[bits]
            x86 = f"SSE2 punpck{'h' if high else 'l'}{suffix} instruction"
    else:
        odd = operation.endswith("Odd")
        aarch = f"NEON {'uzp2' if odd else 'uzp1'} instruction over {shape} lanes"
        if bits == 8:
            x86 = "SSE2 word shifts and packuswb" if odd else "SSE2 low-byte masking and packuswb"
        elif bits == 16:
            control = "0xDD" if odd else "0x88"
            x86 = f"SSE2 pshuflw and pshufhw with control {control}, followed by pshufd and punpcklqdq"
        elif bits == 32:
            control = "0xDD" if odd else "0x88"
            x86 = f"SSE2 pshufd with control {control}, followed by punpcklqdq"
        else:
            x86 = f"SSE2 punpck{'h' if odd else 'l'}qdq instruction"
    return aarch, x86


def bitwise_phrases(operation: str) -> tuple[str, str]:
    """Return exact AArch64/x86 phrases for one integer bitwise operation."""
    return {
        "Bitwise_And": ("one NEON and instruction over 16b", "one SSE2 pand instruction"),
        "Bitwise_Or": ("one NEON orr instruction over 16b", "one SSE2 por instruction"),
        "Bitwise_Xor": ("one NEON eor instruction over 16b", "one SSE2 pxor instruction"),
        "Bitwise_Not": (
            "one NEON mvn instruction over 16b",
            "one SSE2 pcmpeqd instruction to construct all-one bits, followed by one pxor instruction",
        ),
    }[operation]


def integer_minmax_phrases(operation: str, vector: str) -> tuple[str, str]:
    """Return exact AArch64/x86 phrases for pairwise integer Min/Max."""
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    signed = vector.startswith("I")
    maximum = operation == "Max"
    if bits < 64:
        shape = {8: "16b", 16: "8h", 32: "4s"}[bits]
        aarch = f"one NEON {'s' if signed else 'u'}{'max' if maximum else 'min'} instruction over {shape} lanes"
    else:
        aarch = f"NEON {'cmgt' if signed else 'cmhi'} comparison followed by {'bif' if maximum else 'bit'} selection over 2d lanes"
    if vector == "U8x16":
        x86 = f"one SSE2 p{'max' if maximum else 'min'}ub instruction"
    elif vector == "I16x8":
        x86 = f"one SSE2 p{'max' if maximum else 'min'}sw instruction"
    elif bits == 64:
        x86 = f"SSE2 equality-gated two-dword {'signed' if signed else 'unsigned'} lexicographic comparison followed by compact-mask expansion and pand, pandn, and por selection"
    else:
        compare = {8: "pcmpgtb", 16: "pcmpgtw", 32: "pcmpgtd"}[bits]
        bias = " with unsigned sign-bit bias" if not signed else ""
        x86 = f"SSE2 {compare} comparison{bias} followed by compact-mask expansion and pand, pandn, and por selection"
    return aarch, x86


def saturating_arithmetic_phrases(operation: str, vector: str) -> tuple[str, str]:
    """Return exact AArch64/x86 phrases for saturating integer arithmetic."""
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    signed = vector.startswith("I")
    adding = operation == "Add_Saturate"
    shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[bits]
    aarch = f"one NEON {'sq' if signed else 'uq'}{'add' if adding else 'sub'} instruction over {shape} lanes"
    if bits < 32:
        x86 = f"one SSE2 p{'add' if adding else 'sub'}{'s' if signed else 'us'}{'b' if bits == 8 else 'w'} instruction"
    elif signed:
        x86 = "SSE2 sequence that derives a signed-overflow mask and selects the signed minimum or maximum"
    elif adding:
        x86 = "SSE2 sequence that derives a carry mask and selects the unsigned maximum"
    else:
        x86 = "SSE2 sequence that derives a borrow mask and selects zero"
    return aarch, x86


def integer_reduction_aarch_phrase(operation: str, vector: str) -> str:
    """Return the exact operation/type-specific AArch64 reduction phrase."""
    if operation == "Reduce_Add_Wrap":
        return {
            "U8x16": "NEON uaddlv instruction to form a widening sum and retains its low eight bits",
            "I8x16": "NEON addv instruction over 16 byte lanes",
            "U16x8": "NEON addv instruction over eight 16-bit lanes",
            "I16x8": "NEON addv instruction over eight 16-bit lanes",
            "U32x4": "NEON addv instruction over four 32-bit lanes",
            "I32x4": "NEON addv instruction over four 32-bit lanes",
            "U64x2": "NEON addp instruction over two 64-bit lanes",
            "I64x2": "NEON addp instruction over two 64-bit lanes",
        }[vector]
    extreme = "minimum" if operation == "Reduce_Min" else "maximum"
    if vector in {"U64x2", "I64x2"}:
        compare = "cmhi" if vector == "U64x2" else "cmgt"
        select = "bit" if operation == "Reduce_Min" else "bif"
        return (
            "broadcasts the high lane, compares with " + compare
            + ", and selects the " + extreme + " with " + select
        )
    prefix = "s" if vector.startswith("I") else "u"
    instruction = prefix + ("minv" if operation == "Reduce_Min" else "maxv")
    shape = (
        "16 byte lanes" if "8x16" in vector
        else "eight 16-bit lanes" if "16x8" in vector
        else "four 32-bit lanes"
    )
    return f"NEON {instruction} instruction over {shape}"


def integer_reduction_x86_phrase(operation: str, vector: str) -> str:
    """Return the exact operation/type-specific x86 reduction phrase."""
    if operation == "Reduce_Add_Wrap":
        instruction, stages = {
            "U8x16": ("paddb", "four"), "I8x16": ("paddb", "four"),
            "U16x8": ("paddw", "three"), "I16x8": ("paddw", "three"),
            "U32x4": ("paddd", "two"), "I32x4": ("paddd", "two"),
            "U64x2": ("paddq", "one"), "I64x2": ("paddq", "one"),
        }[vector]
        return f"SSE2 {instruction} instruction in a {stages}-stage fixed-shuffle tree"
    extreme = "minimum" if operation == "Reduce_Min" else "maximum"
    if vector == "U8x16":
        instruction = "pminub" if operation == "Reduce_Min" else "pmaxub"
        return f"SSE2 {instruction} instruction in a four-stage fixed-shuffle tree"
    if vector == "I16x8":
        instruction = "pminsw" if operation == "Reduce_Min" else "pmaxsw"
        return f"SSE2 {instruction} instruction in a three-stage fixed-shuffle tree"
    if vector in {"I8x16", "U16x8", "U32x4", "I32x4"}:
        instruction = {
            "I8x16": "pcmpgtb",
            "U16x8": "pcmpgtw with a sign-bit bias",
            "U32x4": "pcmpgtd with a sign-bit bias",
            "I32x4": "pcmpgtd",
        }[vector]
        stages = {"I8x16": 4, "U16x8": 3, "U32x4": 2, "I32x4": 2}[vector]
        return (
            f"SSE2 {instruction} comparison-and-selection {extreme} reduction "
            f"in a {stages}-stage fixed-shuffle tree"
        )
    bias = " with a sign-bit bias" if vector == "U64x2" else ""
    return (
        "SSE2 equality-gated two-dword lexicographic comparison"
        f"{bias} that selects the {extreme}"
    )


def invalid_support(path: Path) -> list[str]:
    text = path.read_text()
    invalid: list[str] = []
    complete_memory_names = (
        "Load", "Store", "Load_Unaligned", "Store_Unaligned",
        "Load_Aligned", "Store_Aligned",
    )
    if path.name == "flyology_simd-backends-scalar.ads":
        for operation in complete_memory_names:
            blocks = declaration_blocks(text, operation)
            found = sum(
                "this scalar implementation is available on every supported GNAT target"
                in block
                for block in blocks
            )
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact scalar "
                    f"{operation} classifications, found {found}"
                )
    if path.name == "flyology_simd.ads":
        for operation in complete_memory_names:
            blocks = declaration_blocks(text, operation)
            found = sum(
                "This overload uses the portable scalar implementation" in block
                and "For the matching Native overload" in block
                and ("ldr q" in block and "str q" in block)
                and ("movdqu" in block)
                and (operation not in {"Load_Aligned", "Store_Aligned"} or "movdqa" in block)
                for block in blocks
            )
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact root "
                    f"{operation} complete-memory classifications, found {found}"
                )
    if "A target backend can use scalar composition" in text:
        invalid.append(f"{path.relative_to(ROOT)}: generic Native fallback wording")
    if path.name in {"flyology_simd.ads", "flyology_simd-backends-native.ads"}:
        integer_vectors = (
            "U8x16", "I8x16", "U16x8", "I16x8",
            "U32x4", "I32x4", "U64x2", "I64x2",
        )
        for operation in ("Reduce_Add_Wrap", "Reduce_Min", "Reduce_Max"):
            blocks = declaration_blocks(text, operation)
            if len(blocks) != 8:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected eight exact {operation} "
                    f"declarations, found {len(blocks)}"
                )
                continue
            for vector in integer_vectors:
                matching = [block for block in blocks if f"Value : {vector}" in block]
                aarch_phrase = integer_reduction_aarch_phrase(operation, vector)
                x86_phrase = integer_reduction_x86_phrase(operation, vector)
                if (
                    len(matching) != 1
                    or aarch_phrase not in matching[0]
                    or x86_phrase not in matching[0]
                    or (
                        path.name == "flyology_simd.ads"
                        and "This overload uses the portable scalar implementation"
                        not in matching[0]
                    )
                ):
                    invalid.append(
                        f"{path.relative_to(ROOT)}: incorrect exact {vector} "
                        f"{operation} classification"
                    )
    if path.name == "flyology_simd-wide.ads":
        contextual_compact = (
            "In a scalar build, the matching Wide.Native overload uses the same "
            "two-part composition through the portable 128-bit implementation."
        )
        compact_blocks = declaration_blocks(text, "Compress") + declaration_blocks(text, "Expand")
        contextual_count = sum(contextual_compact in block for block in compact_blocks)
        if contextual_count != 20:
            invalid.append(
                f"{path.relative_to(ROOT)}: expected 20 contextualized portable "
                f"Compact support notes, found {contextual_count}"
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
    if path.name in {"flyology_simd.ads", "flyology_simd-backends-native.ads"}:
        wrapping_vectors = (
            "U8x16", "I8x16", "U16x8", "I16x8",
            "U32x4", "I32x4", "U64x2", "I64x2",
        )
        for operation in ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap"):
            blocks = declaration_blocks(text, operation)
            for vector in wrapping_vectors:
                matching = [
                    block for block in blocks if f"Left, Right : {vector}" in block
                ]
                aarch, x86 = wrapping_arithmetic_phrases(operation, vector)
                exact = [
                    block for block in matching
                    if aarch in block and x86 in block
                    and "A scalar build uses the portable scalar implementation" in block
                ]
                if len(matching) != 1 or len(exact) != 1:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: expected one exact {vector} "
                        f"{operation} classification, found {len(exact)}"
                    )
        arrangement_vectors = (
            "U8x16", "I8x16", "U16x8", "I16x8", "U32x4", "I32x4",
            "U64x2", "I64x2", "F32x4", "F64x2",
        )
        for operation in (
            "Reverse_Lanes", "Interleave_Low", "Interleave_High",
            "Deinterleave_Even", "Deinterleave_Odd",
        ):
            blocks = declaration_blocks(text, operation)
            for vector in arrangement_vectors:
                marker = f"Value : {vector}" if operation == "Reverse_Lanes" else f"Left, Right : {vector}"
                matching = [block for block in blocks if marker in block]
                aarch, x86 = lane_arrangement_phrases(operation, vector)
                exact = [
                    block for block in matching
                    if aarch in block and x86 in block
                    and "A scalar build uses the portable scalar implementation" in block
                ]
                if len(matching) != 1 or len(exact) != 1:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: expected one exact {vector} "
                        f"{operation} classification, found {len(exact)}"
                    )
        for operation in ("Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Bitwise_Not"):
            blocks = declaration_blocks(text, operation)
            for vector in wrapping_vectors:
                marker = f"Value : {vector}" if operation == "Bitwise_Not" else f"Left, Right : {vector}"
                matching = [block for block in blocks if marker in block]
                aarch, x86 = bitwise_phrases(operation)
                exact = [
                    block for block in matching
                    if aarch in block and x86 in block
                    and "A scalar build uses the portable scalar implementation" in block
                ]
                if len(matching) != 1 or len(exact) != 1:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: expected one exact {vector} "
                        f"{operation} classification, found {len(exact)}"
                    )
        for operation in ("Min", "Max"):
            blocks = declaration_blocks(text, operation)
            for vector in wrapping_vectors:
                matching = [
                    block for block in blocks if f"Left, Right : {vector}" in block
                ]
                aarch, x86 = integer_minmax_phrases(operation, vector)
                exact = [
                    block for block in matching
                    if aarch in block and x86 in block
                    and "A scalar build uses the portable scalar implementation" in block
                ]
                if len(matching) != 1 or len(exact) != 1:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: expected one exact {vector} "
                        f"{operation} classification, found {len(exact)}"
                    )
        for operation in ("Add_Saturate", "Subtract_Saturate"):
            blocks = declaration_blocks(text, operation)
            for vector in wrapping_vectors:
                matching = [
                    block for block in blocks if f"Left, Right : {vector}" in block
                ]
                aarch, x86 = saturating_arithmetic_phrases(operation, vector)
                exact = [
                    block for block in matching
                    if aarch in block and x86 in block
                    and "A scalar build uses the portable scalar implementation" in block
                ]
                if len(matching) != 1 or len(exact) != 1:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: expected one exact {vector} "
                        f"{operation} classification, found {len(exact)}"
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
        complete_memory_support = {
            "Load": (
                "delegates to Load_Unaligned",
                "loads the array with ldr q and stores the private result with str q",
                "delegates to Load_Unaligned, which uses two movdqu transfers",
            ),
            "Store": (
                "delegates to Store_Unaligned",
                "loads the private value with ldr q and stores the array with str q",
                "delegates to Store_Unaligned, which uses two movdqu transfers",
            ),
            "Load_Unaligned": (
                "loads the array with ldr q and stores the private result with str q",
                "uses two movdqu transfers",
            ),
            "Store_Unaligned": (
                "loads the private value with ldr q and stores the array with str q",
                "uses two movdqu transfers",
            ),
            "Load_Aligned": (
                "same safe ldr q and str q transfers after checking the alignment precondition",
                "loads the aligned array with movdqa and stores the private result with movdqu",
            ),
            "Store_Aligned": (
                "same safe ldr q and str q transfers after checking the alignment precondition",
                "loads the private value with movdqu and stores the aligned array with movdqa",
            ),
        }
        for operation, phrases in complete_memory_support.items():
            blocks = declaration_blocks(text, operation)
            found = sum(all(phrase in block for phrase in phrases) for block in blocks)
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact {operation} "
                    f"complete-memory classifications, found {found}"
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
        comparison_vectors = (
            "U8x16", "I8x16", "U16x8", "I16x8", "U32x4",
            "I32x4", "U64x2", "I64x2", "F32x4", "F64x2",
        )
        for operation in (
            "Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal"
        ):
            blocks = declaration_blocks(text, operation)
            for vector in comparison_vectors:
                matching = [
                    block for block in blocks if f"Left, Right : {vector}" in block
                ]
                aarch, x86 = comparison_phrases(operation, vector)
                exact = [
                    block for block in matching
                    if aarch in block and x86 in block
                    and "Both compact the lane results into the public mask" in block
                    and "A scalar build uses the portable scalar implementation" in block
                ]
                if len(matching) != 1 or len(exact) != 1:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: expected one exact {vector} "
                        f"{operation} comparison classification, found {len(exact)}"
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
        floating_binary_support = {
            "Add": (("NEON fadd instruction over 4s lanes", "SSE2 addps instruction"),
                    ("NEON fadd instruction over 2d lanes", "SSE2 addpd instruction")),
            "Subtract": (("NEON fsub instruction over 4s lanes", "SSE2 subps instruction"),
                         ("NEON fsub instruction over 2d lanes", "SSE2 subpd instruction")),
            "Multiply": (("NEON fmul instruction over 4s lanes", "SSE2 mulps instruction"),
                         ("NEON fmul instruction over 2d lanes", "SSE2 mulpd instruction")),
            "Divide": (("NEON fdiv instruction over 4s lanes", "SSE2 divps instruction"),
                       ("NEON fdiv instruction over 2d lanes", "SSE2 divpd instruction")),
            "Min_Number": (("NEON fminnm instruction over 4s lanes", "integer-only SSE2 classification"),
                           ("NEON fminnm instruction over 2d lanes", "integer-only SSE2 classification")),
            "Max_Number": (("NEON fmaxnm instruction over 4s lanes", "integer-only SSE2 classification"),
                           ("NEON fmaxnm instruction over 2d lanes", "integer-only SSE2 classification")),
        }
        for operation, expected in floating_binary_support.items():
            blocks = declaration_blocks(text, operation)
            float_blocks = [block for block in blocks if "F32x4" in block or "F64x2" in block]
            exact = []
            for vector, (aarch, x86) in zip(("F32x4", "F64x2"), expected):
                matching = [block for block in float_blocks if vector in block.split(";", 1)[0]]
                exact.append(
                    len(matching) == 1
                    and aarch in matching[0]
                    and x86 in matching[0]
                    and (
                        path.name != "flyology_simd.ads"
                        or "This overload uses the portable scalar implementation"
                        in matching[0]
                    )
                )
            if len(float_blocks) != 2 or not all(exact):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact floating {operation} classifications"
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
    if path.name in {"flyology_simd-wide.ads", "flyology_simd-wide-native.ads"}:
        wide_minmax_support = {
            "Min": {"U8x32": "vpminub", "I8x32": "vpminsb"},
            "Max": {"U8x32": "vpmaxub", "I8x32": "vpmaxsb"},
        }
        for operation, byte_instructions in wide_minmax_support.items():
            blocks = declaration_blocks(text, operation)
            selected_phrase = (
                f"selected 128-bit {operation} operation for both private parts"
            )
            selected = sum(selected_phrase in block for block in blocks)
            exact_byte = True
            all_instructions = {
                instruction
                for instructions in wide_minmax_support.values()
                for instruction in instructions.values()
            }
            for block in blocks:
                expected_instruction = next(
                    (instruction for vector, instruction in byte_instructions.items()
                     if vector in block),
                    None,
                )
                present = {
                    instruction
                    for instruction in all_instructions
                    if f"isolated 256-bit {instruction} leaf" in block
                }
                if expected_instruction is None:
                    exact_byte = exact_byte and not present
                else:
                    exact_byte = (
                        exact_byte
                        and present == {expected_instruction}
                        and "and then runs vzeroupper" in block
                    )
            portable = sum(
                "same two-part composition through the portable 128-bit "
                "implementation" in block for block in blocks
            )
            if (len(blocks) != 8 or selected != 8 or not exact_byte
                    or portable != 8):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    "Wide integer Min/Max classifications"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block for block in blocks
                )
                if authority != 8:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected 8"
                    )
        wide_shift_counts = {
            "Shift_Left_Logical": 8,
            "Shift_Right_Logical": 8,
            "Shift_Right_Arithmetic": 4,
        }
        for operation, expected in wide_shift_counts.items():
            blocks = declaration_blocks(text, operation)
            selected_phrase = (
                f"selected 128-bit {operation} operation to both private parts"
            )
            selected = sum(selected_phrase in block for block in blocks)
            portable = sum(
                "same two-part composition through the portable 128-bit "
                "implementation" in block for block in blocks
            )
            if (len(blocks) != expected or selected != expected
                    or portable != expected):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    "Wide shift classifications"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block for block in blocks
                )
                if authority != expected:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected {expected}"
                    )
        wide_bitwise_support = {
            "Bitwise_And": "isolated 256-bit vpand leaf",
            "Bitwise_Or": "isolated 256-bit vpor leaf",
            "Bitwise_Xor": "isolated 256-bit vpxor leaf",
            "Bitwise_Not": (
                "isolated 256-bit leaf that constructs an all-one mask with "
                "vpcmpeqd and complements with vpxor"
            ),
        }
        for operation, byte_phrase in wide_bitwise_support.items():
            blocks = declaration_blocks(text, operation)
            selected_phrase = (
                f"selected 128-bit {operation} operation to both private parts"
            )
            selected = sum(selected_phrase in block for block in blocks)
            byte_avx2 = sum(byte_phrase in block for block in blocks)
            byte_cleanup = sum(
                byte_phrase in block and "and then runs vzeroupper" in block
                for block in blocks
            )
            portable = sum(
                "same two-part composition through the portable 128-bit "
                "implementation" in block for block in blocks
            )
            if (len(blocks) != 8 or selected != 8 or byte_avx2 != 2
                    or byte_cleanup != 2 or portable != 8):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    "Wide bitwise classifications"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block for block in blocks
                )
                if authority != 8:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected 8"
                    )
        wide_wrapping_support = {
            "Add_Wrap": "isolated 256-bit vpaddb leaf",
            "Subtract_Wrap": "isolated 256-bit vpsubb leaf",
            "Multiply_Wrap": (
                "isolated 256-bit byte-multiplication leaf that uses vpmullw, "
                "vpand, vpsrlw, vpsllw, and vpor"
            ),
        }
        for operation, byte_phrase in wide_wrapping_support.items():
            blocks = declaration_blocks(text, operation)
            selected_phrase = (
                f"selected 128-bit {operation} operation for both private parts"
            )
            selected = sum(selected_phrase in block for block in blocks)
            byte_avx2 = sum(byte_phrase in block for block in blocks)
            byte_cleanup = sum(
                byte_phrase in block and "and then runs vzeroupper" in block
                for block in blocks
            )
            portable = sum(
                "same two-part composition through the portable 128-bit "
                "implementation" in block
                for block in blocks
            )
            if (len(blocks) != 8 or selected != 8 or byte_avx2 != 2
                    or byte_cleanup != 2
                    or portable != 8):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    "Wide wrapping classifications "
                    f"({len(blocks)} declarations, {selected} selected-part "
                    f"notes, {byte_avx2} byte-AVX2 notes, {byte_cleanup} byte "
                    f"cleanup notes, {portable} portable composition notes)"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block
                    for block in blocks
                )
                if authority != 8:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected 8"
                    )
        wide_saturating_support = {
            "Add_Saturate": ("vpaddusb", "vpaddsb"),
            "Subtract_Saturate": ("vpsubusb", "vpsubsb"),
        }
        for operation, byte_instructions in wide_saturating_support.items():
            blocks = declaration_blocks(text, operation)
            selected_phrase = (
                f"selected 128-bit {operation} operation for both private parts"
            )
            selected = sum(selected_phrase in block for block in blocks)
            byte_avx2 = sum(
                f"isolated 256-bit {instruction} leaf" in block
                for block in blocks
                for instruction in byte_instructions
            )
            portable = sum(
                "same two-part composition through the portable 128-bit "
                "implementation" in block
                for block in blocks
            )
            if (len(blocks) != 8 or selected != 8 or byte_avx2 != 2
                    or portable != 8):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    "Wide saturation classifications "
                    f"({len(blocks)} declarations, {selected} selected-part "
                    f"notes, {byte_avx2} byte-AVX2 notes, {portable} portable "
                    "composition notes)"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block
                    for block in blocks
                )
                if authority != 8:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected 8"
                    )
        predicate_support = {
            "Equal": 10,
            "Less_Than": 10,
            "Less_Equal": 10,
            "Greater_Than": 10,
            "Greater_Equal": 10,
            "Unordered": 2,
            "Select_Value": 10,
        }
        for operation, expected in predicate_support.items():
            blocks = declaration_blocks(text, operation)
            selected = sum(
                f"selected 128-bit {operation} operation on both private parts"
                in block
                for block in blocks
            )
            avx2_phrase = {
                "Equal": "optional AVX2 build uses an isolated relation-specific 256-bit Equal leaf",
                "Less_Than": "optional AVX2 build uses an isolated relation-specific 256-bit Less_Than leaf. The leaf reverses the operands within its Greater_Than comparison",
                "Less_Equal": "optional AVX2 build uses an isolated relation-specific 256-bit Less_Equal leaf. The leaf complements the result of Greater_Than (Left, Right)",
                "Greater_Than": "optional AVX2 build uses an isolated relation-specific 256-bit Greater_Than leaf",
                "Greater_Equal": "optional AVX2 build uses an isolated relation-specific 256-bit Greater_Equal leaf. The leaf complements the result of Greater_Than (Right, Left)",
                "Select_Value": "optional AVX2 build uses an isolated relation-specific 256-bit Select_Value leaf",
                "Unordered": "",
            }[operation]
            byte_avx2 = sum(avx2_phrase in block for block in blocks) if avx2_phrase else 0
            expected_selected = expected
            expected_byte = 2 if operation != "Unordered" else 0
            if (len(blocks) != expected or selected != expected_selected
                    or byte_avx2 != expected_byte):
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    f"Wide predicate classifications ({len(blocks)} declarations, "
                    f"{selected} selected-part notes, {byte_avx2} byte-AVX2 notes)"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block
                    for block in blocks
                )
                if authority != expected:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected {expected}"
                    )
        construction_support = {
            "Zero": "selected 128-bit Zero operation for both private parts",
            "Splat": "selected 128-bit Splat operation for both private parts",
            "From_Lanes": "selected 128-bit From_Lanes operation for each part",
            "To_Lanes": "selected 128-bit To_Lanes operation for both private parts",
            "Extract": "selected 128-bit Extract operation only on the private part",
            "Replace": "selected 128-bit Replace operation only on the private part",
        }
        for operation, phrase in construction_support.items():
            blocks = declaration_blocks(text, operation)
            classified = sum(phrase in block for block in blocks)
            if len(blocks) != 10 or classified != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: incorrect exact {operation} "
                    f"Wide construction classifications ({len(blocks)} "
                    f"declarations, {classified} mechanism notes)"
                )
            if path.name == "flyology_simd-wide.ads":
                authority = sum(
                    "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block
                    for block in blocks
                )
                if authority != 10:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {operation} portable "
                        f"authority appears {authority} times, expected 10"
                    )
        reduction_support = {
            "function Reduce_Add_Wrap": (
                "reduce each private part with the selected 128-bit "
                "Reduce_Add_Wrap operation, combine the two results with the "
                "selected 128-bit Add_Wrap operation, and extract lane zero"
            ),
            "function Reduce_Min": (
                "reduce each private part with the selected 128-bit Reduce_Min "
                "operation, combine the two results with the selected 128-bit "
                "Min operation, and extract lane zero"
            ),
            "function Reduce_Max": (
                "reduce each private part with the selected 128-bit Reduce_Max "
                "operation, combine the two results with the selected 128-bit "
                "Max operation, and extract lane zero"
            ),
        }
        for declaration, phrase in reduction_support.items():
            count = sum(
                1
                for block in text.split(declaration)[1:]
                if phrase in block.split("function ", 1)[0]
            )
            if count != 8:
                invalid.append(
                    f"{path.relative_to(ROOT)}: {declaration} exact reduction "
                    f"classification appears {count} times, expected 8"
                )
        if path.name == "flyology_simd-wide.ads":
            for declaration, phrase in reduction_support.items():
                count = sum(
                    1
                    for block in text.split(declaration)[1:]
                    if "This overload uses the portable scalar Wide implementation "
                    "on every supported GNAT target" in block.split("function ", 1)[0]
                    and phrase in block.split("function ", 1)[0]
                )
                if count != 8:
                    invalid.append(
                        f"{path.relative_to(ROOT)}: {declaration} portable "
                        f"authority appears {count} times, expected 8"
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
            "function Add (": "optional AVX2 backend uses one isolated 256-bit vadd",
            "function Subtract (": "optional AVX2 backend uses one isolated 256-bit vsub",
            "function Multiply (": "optional AVX2 backend uses one isolated 256-bit vmul",
            "function Divide (": "optional AVX2 backend uses one isolated 256-bit vdiv",
            "function Min_Number": "isolated 256-bit integer-classification and bit-selection sequence",
            "function Max_Number": "isolated 256-bit integer-classification and bit-selection sequence",
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
            "function Test": "only on the private part that contains the requested lane",
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
        full_memory_support = {
            "Load": "selected 128-bit Load operation at Start and Start plus the private lane count",
            "Store": "selected 128-bit Store operation at Start and Start plus the private lane count",
            "Load_Unaligned": "selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count",
            "Store_Unaligned": "selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count",
            "Load_Aligned": "selected 128-bit Load_Aligned operation at Start and Start plus the private lane count",
            "Store_Aligned": "selected 128-bit Store_Aligned operation at Start and Start plus the private lane count",
        }
        for operation, phrase in full_memory_support.items():
            blocks = declaration_blocks(text, operation)
            found = sum(
                phrase in block
                and "same two-part composition through the portable 128-bit implementation" in block
                for block in blocks
            )
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact {operation} "
                    f"Wide memory classifications, found {found}"
                )
        partial_memory_support = {
            "Load_Partial": (
                "selected 128-bit Load_Partial operation for the low result part",
                "selected Load operation for the low result part",
                "selected Zero operation for the high result part",
            ),
            "Store_Partial": (
                "selected 128-bit Store_Partial operation for the low value part",
                "selected Store operation for the low value part",
                "selected Store_Partial operation for the remaining high lanes",
            ),
        }
        for operation, phrases in partial_memory_support.items():
            blocks = declaration_blocks(text, operation)
            found = sum(
                all(phrase in block for phrase in phrases)
                and "A zero count does not evaluate an element address" in block
                and "same conditional composition through the portable 128-bit implementation" in block
                for block in blocks
            )
            if len(blocks) != 10 or found != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: expected ten exact {operation} "
                    f"Wide memory classifications, found {found}"
                )
    if path.name in {"flyology_simd-wide.ads", "flyology_simd-wide-native.ads"}:
        for operation in ("Compress", "Expand"):
            blocks = [
                block.split("function ", 1)[0].split("procedure ", 1)[0]
                for block in text.split(f"function {operation}")[1:]
            ]
            phrase = (
                "AArch64 backend applies the selected 128-bit To_Bit_Mask "
                "operation to each private mask part"
            )
            if len(blocks) != 10 or sum(phrase in block for block in blocks) != 10:
                invalid.append(
                    f"{path.relative_to(ROOT)}: exact Wide {operation} "
                    "selected mask-extraction classifications are incomplete"
                )
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
