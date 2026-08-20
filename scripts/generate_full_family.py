#!/usr/bin/env python3
"""Generate the repetitive scalar 128-bit family from one type matrix."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "src" / "flyology_simd.ads"
BODY = ROOT / "src" / "flyology_simd.adb"

INTEGER_TYPES = [
    ("I8x16", "I8", 8, 16, True),
    ("U16x8", "U16", 16, 8, False),
    ("I16x8", "I16", 16, 8, True),
    ("U32x4", "U32", 32, 4, False),
    ("I32x4", "I32", 32, 4, True),
    ("U64x2", "U64", 64, 2, False),
    ("I64x2", "I64", 64, 2, True),
]
FLOAT_TYPES = [
    ("F32x4", "F32", 32, 4),
    ("F64x2", "F64", 64, 2),
]
MASKS = [(16, 8, "Unsigned_8"), (32, 4, "Unsigned_8"), (64, 2, "Unsigned_8")]

# Bit casts preserve one lane's bits and therefore only connect vector types
# with the same lane width and lane count.  Width-changing operations have
# distinct names and contracts below.
BIT_CAST_GROUPS = [
    (("U8x16", "U8"), ("I8x16", "I8")),
    (("U16x8", "U16"), ("I16x8", "I16")),
    (("U32x4", "U32"), ("I32x4", "I32"), ("F32x4", "F32")),
    (("U64x2", "U64"), ("I64x2", "I64"), ("F64x2", "F64")),
]

# Source vector, source lane, result vector, result lane, source bits, lanes.
WIDENINGS = [
    ("U8x16", "U8", "U16x8", "U16", 8, 8),
    ("I8x16", "I8", "I16x8", "I16", 8, 8),
    ("U16x8", "U16", "U32x4", "U32", 16, 4),
    ("I16x8", "I16", "I32x4", "I32", 16, 4),
    ("U32x4", "U32", "U64x2", "U64", 32, 2),
    ("I32x4", "I32", "I64x2", "I64", 32, 2),
]
FLOAT_WIDENINGS = [("F32x4", "F32", "F64x2", "F64", 2)]

# Narrowing consumes two vectors so that every result lane is defined.  The
# low source supplies the low result half and the high source supplies the
# high result half.
NARROWINGS = [
    ("U16x8", "U16", "U8x16", "U8", 8, 8, False),
    ("I16x8", "I16", "I8x16", "I8", 8, 8, True),
    ("U32x4", "U32", "U16x8", "U16", 16, 4, False),
    ("I32x4", "I32", "I16x8", "I16", 16, 4, True),
    ("U64x2", "U64", "U32x4", "U32", 32, 2, False),
    ("I64x2", "I64", "I32x4", "I32", 32, 2, True),
]
SIGNED_TO_UNSIGNED_NARROWINGS = [
    ("I16x8", "I16", "U8x16", "U8", 8, 8, True),
    ("I32x4", "I32", "U16x8", "U16", 16, 4, True),
    ("I64x2", "I64", "U32x4", "U32", 32, 2, True),
]
FLOAT_NARROWINGS = [("F64x2", "F64", "F32x4", "F32", 2)]

INTEGER_TO_FLOAT_CONVERSIONS = [
    ("I32x4", "I32", "F32x4", "F32", 32, 4, True),
    ("U32x4", "U32", "F32x4", "F32", 32, 4, False),
    ("I64x2", "I64", "F64x2", "F64", 64, 2, True),
    ("U64x2", "U64", "F64x2", "F64", 64, 2, False),
]

FLOAT_TO_INTEGER_CONVERSIONS = [
    ("F32x4", "F32", "I32x4", "I32", 32, 4, True),
    ("F32x4", "F32", "U32x4", "U32", 32, 4, False),
    ("F64x2", "F64", "I64x2", "I64", 64, 2, True),
    ("F64x2", "F64", "U64x2", "U64", 64, 2, False),
]


def wrapping_arithmetic_support(name: str, declaration: str) -> str:
    """Describe the exact target lowering for one wrapping arithmetic overload."""
    vector = next(
        candidate
        for candidate in (
            "U8x16", "I8x16", "U16x8", "I16x8",
            "U32x4", "I32x4", "U64x2", "I64x2",
        )
        if candidate in declaration
    )
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[bits]
    if name == "Add_Wrap":
        aarch = f"the NEON add instruction over {shape} lanes"
        x86 = f"the SSE2 padd{ {8: 'b', 16: 'w', 32: 'd', 64: 'q'}[bits] } instruction"
    elif name == "Subtract_Wrap":
        aarch = f"the NEON sub instruction over {shape} lanes"
        x86 = f"the SSE2 psub{ {8: 'b', 16: 'w', 32: 'd', 64: 'q'}[bits] } instruction"
    elif bits < 64:
        aarch = f"the NEON mul instruction over {shape} lanes"
        x86 = {
            8: "an SSE2 sequence that widens bytes, uses two pmullw instructions, and packs the low product bytes",
            16: "the SSE2 pmullw instruction",
            32: "an SSE2 sequence that uses two pmuludq instructions and repacks the dword products",
        }[bits]
    else:
        aarch = "a NEON 32-bit partial-product sequence"
        x86 = "an SSE2 three-pmuludq partial-product sequence"
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. "
        f"The x86-64 backend uses {x86}. A scalar build uses the portable "
        "scalar implementation."
    )


def lane_arrangement_support(name: str, declaration: str) -> str:
    """Describe one exact fixed-width canonical lane arrangement."""
    vector = next(
        candidate for candidate in (
            "U8x16", "I8x16", "U16x8", "I16x8", "U32x4", "I32x4",
            "U64x2", "I64x2", "F32x4", "F64x2",
        ) if candidate in declaration
    )
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[bits]
    if name == "Reverse_Lanes":
        if bits == 64:
            aarch = "the NEON ext instruction with an eight-byte offset"
        else:
            aarch = (
                f"NEON rev64 over {shape} lanes followed by ext with an "
                "eight-byte offset"
            )
        x86 = {
            8: "SSE2 byte shifts and OR followed by pshuflw, pshufhw, and pshufd",
            16: "SSE2 pshuflw, pshufhw, and pshufd",
            32: "SSE2 pshufd with control 0x1B",
            64: "SSE2 pshufd with control 0x4E",
        }[bits]
    elif name in {"Interleave_Low", "Interleave_High"}:
        high = name.endswith("High")
        aarch = f"the NEON {'zip2' if high else 'zip1'} instruction over {shape} lanes"
        if vector.startswith("F"):
            x86 = f"the SSE2 unpck{'h' if high else 'l'}{'ps' if bits == 32 else 'pd'} instruction"
        else:
            suffix = {8: "bw", 16: "wd", 32: "dq", 64: "qdq"}[bits]
            x86 = f"the SSE2 punpck{'h' if high else 'l'}{suffix} instruction"
    else:
        odd = name.endswith("Odd")
        aarch = f"the NEON {'uzp2' if odd else 'uzp1'} instruction over {shape} lanes"
        if bits == 8:
            x86 = "SSE2 word shifts and packuswb" if odd else "SSE2 low-byte masking and packuswb"
        elif bits == 16:
            control = "0xDD" if odd else "0x88"
            x86 = (
                f"SSE2 pshuflw and pshufhw with control {control}, followed "
                "by pshufd and punpcklqdq"
            )
        elif bits == 32:
            control = "0xDD" if odd else "0x88"
            x86 = f"SSE2 pshufd with control {control}, followed by punpcklqdq"
        else:
            x86 = f"the SSE2 punpck{'h' if odd else 'l'}qdq instruction"
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. The x86-64 "
        f"backend uses {x86}. A scalar build uses the portable scalar implementation."
    )


def bitwise_support(name: str) -> str:
    """Describe one exact fixed-width integer bitwise operation."""
    aarch = {
        "Bitwise_And": "one NEON and instruction over 16b",
        "Bitwise_Or": "one NEON orr instruction over 16b",
        "Bitwise_Xor": "one NEON eor instruction over 16b",
        "Bitwise_Not": "one NEON mvn instruction over 16b",
    }[name]
    x86 = {
        "Bitwise_And": "one SSE2 pand instruction",
        "Bitwise_Or": "one SSE2 por instruction",
        "Bitwise_Xor": "one SSE2 pxor instruction",
        "Bitwise_Not": (
            "one SSE2 pcmpeqd instruction to construct all-one bits, followed "
            "by one pxor instruction"
        ),
    }[name]
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. The x86-64 "
        f"backend uses {x86}. A scalar build uses the portable scalar implementation."
    )


def integer_minmax_support(name: str, declaration: str) -> str:
    """Describe one exact fixed-width integer pairwise minimum or maximum."""
    vector = next(
        candidate for candidate in (
            "U8x16", "I8x16", "U16x8", "I16x8",
            "U32x4", "I32x4", "U64x2", "I64x2",
        ) if candidate in declaration
    )
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    signed = vector.startswith("I")
    maximum = name == "Max"
    if bits < 64:
        shape = {8: "16b", 16: "8h", 32: "4s"}[bits]
        aarch = (
            f"one NEON {'s' if signed else 'u'}{'max' if maximum else 'min'} "
            f"instruction over {shape} lanes"
        )
    else:
        aarch = (
            f"a NEON {'cmgt' if signed else 'cmhi'} comparison followed by "
            f"{'bif' if maximum else 'bit'} selection over 2d lanes"
        )
    if vector == "U8x16":
        x86 = f"one SSE2 p{'max' if maximum else 'min'}ub instruction"
    elif vector == "I16x8":
        x86 = f"one SSE2 p{'max' if maximum else 'min'}sw instruction"
    elif bits == 64:
        order = "signed" if signed else "unsigned"
        x86 = (
            f"an SSE2 equality-gated two-dword {order} lexicographic comparison "
            "followed by compact-mask expansion and pand, pandn, and por selection"
        )
    else:
        compare = {8: "pcmpgtb", 16: "pcmpgtw", 32: "pcmpgtd"}[bits]
        bias = " with unsigned sign-bit bias" if not signed else ""
        x86 = (
            f"an SSE2 {compare} comparison{bias} followed by compact-mask "
            "expansion and pand, pandn, and por selection"
        )
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. The x86-64 "
        f"backend uses {x86}. A scalar build uses the portable scalar implementation."
    )


def saturating_arithmetic_support(name: str, declaration: str) -> str:
    """Describe one exact fixed-width saturating arithmetic overload."""
    vector = next(
        candidate for candidate in (
            "U8x16", "I8x16", "U16x8", "I16x8",
            "U32x4", "I32x4", "U64x2", "I64x2",
        ) if candidate in declaration
    )
    bits = int(re.search(r"(8|16|32|64)x", vector).group(1))
    signed = vector.startswith("I")
    adding = name == "Add_Saturate"
    shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[bits]
    aarch = f"one NEON {'sq' if signed else 'uq'}{'add' if adding else 'sub'} instruction over {shape} lanes"
    if bits < 32:
        x86 = (
            f"one SSE2 p{'add' if adding else 'sub'}"
            f"{'s' if signed else 'us'}{'b' if bits == 8 else 'w'} instruction"
        )
    elif signed:
        x86 = (
            "an SSE2 sequence that derives a signed-overflow mask and selects "
            "the signed minimum or maximum"
        )
    elif adding:
        x86 = (
            "an SSE2 sequence that derives a carry mask and selects the unsigned maximum"
        )
    else:
        x86 = "an SSE2 sequence that derives a borrow mask and selects zero"
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. The x86-64 "
        f"backend uses {x86}. A scalar build uses the portable scalar implementation."
    )

SIGNED_UNSIGNED_CONVERSIONS = [
    ("I8x16", "I8", "U8x16", "U8", 8, 16, True),
    ("U8x16", "U8", "I8x16", "I8", 8, 16, False),
    ("I16x8", "I16", "U16x8", "U16", 16, 8, True),
    ("U16x8", "U16", "I16x8", "I16", 16, 8, False),
    ("I32x4", "I32", "U32x4", "U32", 32, 4, True),
    ("U32x4", "U32", "I32x4", "I32", 32, 4, False),
    ("I64x2", "I64", "U64x2", "U64", 64, 2, True),
    ("U64x2", "U64", "I64x2", "I64", 64, 2, False),
]


OPERATION_DOCS = {
    "Zero": "Return a vector in which each lane is zero.",
    "Splat": "Return a vector in which each lane has the same value.",
    "From_Lanes": "Construct a vector from lanes in logical lane order.",
    "To_Lanes": "Return all lanes in logical lane order.",
    "Extract": "Return one logical lane.",
    "Replace": "Return a copy with one logical lane replaced.",
    "Add_Wrap": "Add corresponding lanes modulo the lane width.",
    "Subtract_Wrap": "Subtract corresponding lanes modulo the lane width.",
    "Multiply_Wrap": "Multiply corresponding lanes modulo the lane width.",
    "Add_Saturate": "Add corresponding lanes and clamp to the lane range.",
    "Subtract_Saturate": "Subtract corresponding lanes and clamp to the lane range.",
    "Bitwise_And": "Apply bitwise AND to corresponding integer lanes.",
    "Bitwise_Or": "Apply bitwise OR to corresponding integer lanes.",
    "Bitwise_Xor": "Apply bitwise exclusive OR to corresponding integer lanes.",
    "Bitwise_Not": "Complement every bit in every integer lane.",
    "Shift_Left_Logical": "Shift each lane left. Return zero lanes when the count reaches the lane width.",
    "Shift_Right_Logical": "Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.",
    "Shift_Right_Arithmetic": "Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.",
    "Equal": "Compare corresponding lanes for equality.",
    "Less_Than": "Compare corresponding lanes with the lane type's ordering.",
    "Less_Equal": "Compare corresponding lanes with the lane type's ordering.",
    "Greater_Than": "Compare corresponding lanes with the lane type's ordering.",
    "Greater_Equal": "Compare corresponding lanes with the lane type's ordering.",
    "Unordered": "Return true in lanes where either floating input is NaN.",
    "Select_Value": "Select the true input in true mask lanes and the false input in other lanes.",
    "Compress": (
        "Stably pack lanes whose mask lane is true toward lane zero. Preserve "
        "their complete bit encodings and fill the remaining lanes with zero."
    ),
    "Expand": (
        "Place consecutive low input lanes into result lanes whose mask lane is "
        "true. Preserve their complete bit encodings and fill false lanes with zero."
    ),
    "Min": "Return the smaller integer in each lane.",
    "Max": "Return the larger integer in each lane.",
    "Horizontal_Sum": "Return the exact sum of all unsigned byte lanes as Natural.",
    "Has_Extent": "Return true when Count byte elements fit in Data starting at Start. A zero Count requires no valid address.",
    "Min_Number": "Return the floating number minimum with the documented NaN and signed-zero rules.",
    "Max_Number": "Return the floating number maximum with the documented NaN and signed-zero rules.",
    "Reduce_Add_Wrap": "Add all integer lanes modulo the lane width in ascending lane order.",
    "Reduce_Min": "Return the smallest integer lane.",
    "Reduce_Max": "Return the largest integer lane.",
    "Reduce_Add": "Add all floating lanes in ascending lane order.",
    "Reduce_Min_Number": "Use lane zero as the initial result. Apply Min_Number to each remaining lane in ascending order.",
    "Reduce_Max_Number": "Use lane zero as the initial result. Apply Max_Number to each remaining lane in ascending order.",
    "Reverse_Lanes": "Reverse logical lane order.",
    "Reverse_Bytes": "Reverse logical byte-lane order. This is the compatibility name for Reverse_Lanes.",
    "Make_Lane_Map": (
        "Build a reusable lane map. For each result lane, the selector gives "
        "the source lane. Selectors can repeat source lanes. A default-initialized "
        "map selects source lane zero for every result lane."
    ),
    "Select_Left_Lane": "Construct a selector for one lane of the left input.",
    "Select_Right_Lane": "Construct a selector for one lane of the right input.",
    "Make_Two_Source_Lane_Map": (
        "Build a reusable two-source lane map. For each result lane, the "
        "selector gives one lane of the left or right input. Selectors can "
        "repeat source lanes. A default-initialized map selects left lane "
        "zero for every result lane."
    ),
    "Permute_Lanes": (
        "Select each result lane through a reusable lane map. Moved lanes keep "
        "their complete bit encoding."
    ),
    "Interleave_Low": "Alternate lanes from the low half of both inputs, starting with the left input.",
    "Interleave_High": "Alternate lanes from the high half of both inputs, starting with the left input.",
    "Deinterleave_Even": "Collect even lanes from the left input, then even lanes from the right input.",
    "Deinterleave_Odd": "Collect odd lanes from the left input, then odd lanes from the right input.",
    "Slide_Lanes_Toward_Low": (
        "Count is in lanes. A zero count returns Value. Retained lanes keep "
        "their complete bit encoding. Move them toward lower lane indexes "
        "and fill vacated high-index lanes with zero. Return Zero when Count "
        "is equal to or greater than the lane count."
    ),
    "Slide_Lanes_Toward_High": (
        "Count is in lanes. A zero count returns Value. Retained lanes keep "
        "their complete bit encoding. Move them toward higher lane indexes "
        "and fill vacated low-index lanes with zero. Return Zero when Count "
        "is equal to or greater than the lane count."
    ),
    "Table_Lookup": (
        "Use the unsigned value in each index lane for the corresponding result "
        "lane. A value from zero through 15 selects the table lane with the "
        "same lane index. A larger value returns zero."
    ),
    "Is_Aligned_16": "Report whether the selected first element has a 16-byte-aligned address.",
    "Load": "Load one complete vector without an alignment requirement.",
    "Store": "Store one complete vector without an alignment requirement.",
    "Load_Unaligned": "Load one complete vector from an address with any alignment.",
    "Store_Unaligned": "Store one complete vector to an address with any alignment.",
    "Load_Aligned": "Load one complete vector from a 16-byte-aligned address.",
    "Store_Aligned": "Store one complete vector to a 16-byte-aligned address.",
    "Load_Partial": "Read exactly Count elements and set the remaining lanes to zero.",
    "Store_Partial": "Write exactly Count elements and leave all other elements unchanged.",
    "Mask_From_Bit_Mask": "Construct lane truths from compact bits. Bit zero represents lane zero.",
    "To_Bit_Mask": "Return compact lane truths. Bit zero represents lane zero.",
    "Mask_And": "Apply Boolean AND to corresponding mask lanes.",
    "Mask_Or": "Apply Boolean OR to corresponding mask lanes.",
    "Mask_Xor": "Apply Boolean exclusive OR to corresponding mask lanes.",
    "Mask_Not": "Complement every mask lane truth.",
    "Test": "Return the Boolean truth of one mask lane.",
    "Any_True": "Return true when at least one mask lane is true.",
    "All_True": "Return true when every mask lane is true.",
    "None_True": "Return true when every mask lane is false.",
    "Population_Count": "Return the number of true mask lanes.",
    "First_True": "Return the first true lane, or the lane-count value when no lane is true.",
    "Last_True": "Return the last true lane, or the lane-count value when no lane is true.",
    "Add": "Add corresponding floating-point lanes.",
    "Subtract": "Subtract corresponding floating-point lanes.",
    "Multiply": "Multiply corresponding floating-point lanes.",
    "Divide": "Divide corresponding floating-point lanes.",
    "Bit_Cast": "Reinterpret every lane's bits without changing its lane position.",
    "Widen_Low": "Convert the low source half according to the documented widening semantics.",
    "Widen_High": "Convert the high source half according to the documented widening semantics.",
    "Narrow_Truncate": "Keep the low bits of each source lane and combine both source vectors.",
    "Narrow_Saturate": "Clamp each source lane to the result range and combine both source vectors.",
    "Narrow_Round": (
        "With the default round-to-nearest, ties-to-even and gradual-underflow "
        "environment, round "
        "Low into result lanes zero and one and High into lanes two and three. "
        "Signed zero and infinity are preserved. Overflow after rounding "
        "produces infinity. Gradual underflow can produce a subnormal, and a "
        "sufficiently small magnitude rounds to signed zero. A NaN remains a "
        "NaN, but its payload and signaling state are unspecified. The operation "
        "does not change the rounding mode or exception-control settings. It can "
        "update floating-point exception-status flags."
    ),
    "Convert_Round": (
        "With the default round-to-nearest, ties-to-even environment, convert "
        "each integer lane to the corresponding floating-point lane. The "
        "operation does not change the rounding mode or exception-control "
        "settings. It can update floating-point exception-status flags."
    ),
    "Convert_Truncate_Saturate": (
        "Truncate each floating-point lane toward zero, then clamp it to the "
        "integer result range. A NaN becomes zero. The operation does not "
        "depend on or modify the floating-point rounding mode. It can update "
        "floating-point exception-status flags."
    ),
}

CONVERT_SATURATE_SIGNED_DOC = (
    "Convert each signed lane to the same-width unsigned lane. A negative "
    "input becomes zero. Other values and all lane positions are preserved."
)

CONVERT_SATURATE_UNSIGNED_DOC = (
    "Convert each unsigned lane to the same-width signed lane. An input above "
    "the signed maximum becomes that maximum. Other values and all lane "
    "positions are preserved."
)

TWO_SOURCE_PERMUTE_DOC = (
    "Select each result lane from the left or right vector through a reusable "
    "two-source lane map. Moved lanes keep their complete bit encoding."
)

PORTABLE_SUPPORT_DOC = (
    "Cross-platform support: portable scalar semantics are available on every "
    "supported GNAT target. Use the matching Backends.Native overload for "
    "statically selected target lowering."
)

PORTABLE_SHARED_SUPPORT_DOC = (
    "Cross-platform support: this fixed-width Ada operation is available on "
    "every supported GNAT target and has no separate Backends.Native overload."
)

SCALAR_SUPPORT_DOC = (
    "Cross-platform support: this scalar implementation is available on every "
    "supported GNAT target."
)

NATIVE_SUPPORT_DOC = ""

LEGACY_NATIVE_SUPPORT_DOC = (
    "Cross-platform support: build-time selection provides AArch64 NEON, "
    "x86-64 SSE2, or scalar lowering. A target backend can use scalar "
    "composition when no matching SIMD instruction exists."
)

LEGACY_NATIVE_SUPPORT_PREFIXES = (
    "Cross-platform support: AArch64 uses ",
    "Cross-platform support: AArch64, x86-64, and scalar builds use ",
    "Cross-platform support: this overload provides portable scalar semantics ",
)


def comparison_support_doc(name: str, declaration: str) -> str:
    """Describe one fixed-width comparison's exact target mechanisms."""
    vector = next(
        vector for vector in (
            "U8x16", "I8x16", "U16x8", "I16x8", "U32x4",
            "I32x4", "U64x2", "I64x2", "F32x4", "F64x2",
        ) if vector in declaration
    )
    relation = {
        "Equal": "equality", "Less_Than": "less-than",
        "Less_Equal": "less-than-or-equal",
        "Greater_Than": "greater-than",
        "Greater_Equal": "greater-than-or-equal",
    }[name]
    if vector.startswith("F"):
        shape = "4s" if vector == "F32x4" else "2d"
        x86_shape = "ps" if vector == "F32x4" else "pd"
        neon = {
            "Equal": "fcmeq", "Less_Than": "fcmgt with reversed operands",
            "Less_Equal": "fcmge with reversed operands",
            "Greater_Than": "fcmgt", "Greater_Equal": "fcmge",
        }[name]
        sse2 = {
            "Equal": f"cmpeq{x86_shape}", "Less_Than": f"cmplt{x86_shape}",
            "Less_Equal": f"cmple{x86_shape}",
            "Greater_Than": f"cmplt{x86_shape} with reversed operands",
            "Greater_Equal": f"cmple{x86_shape} with reversed operands",
        }[name]
        aarch = f"the NEON {neon} comparison over {shape} lanes"
        x86 = f"the SSE2 {sse2} comparison"
    else:
        signed = vector.startswith("I")
        width = re.search(r"(8|16|32|64)x", vector).group(1)
        shape = {"8": "16b", "16": "8h", "32": "4s", "64": "2d"}[width]
        pcmpeq = {"8": "pcmpeqb", "16": "pcmpeqw", "32": "pcmpeqd", "64": "pcmpeqd"}[width]
        pcmpgt = {"8": "pcmpgtb", "16": "pcmpgtw", "32": "pcmpgtd", "64": "pcmpgtd"}[width]
        if name == "Equal":
            aarch = f"the NEON cmeq comparison over {shape} lanes"
            x86 = f"the SSE2 {pcmpeq} comparison"
            if width == "64":
                x86 += " with adjacent dword results combined per 64-bit lane"
        else:
            neon = (("cmgt" if signed else "cmhi") if "Than" in name
                    else ("cmge" if signed else "cmhs"))
            direction = " with reversed operands" if name.startswith("Less") else ""
            aarch = f"the NEON {neon} comparison over {shape} lanes{direction}"
            if width == "64":
                bias = " with an unsigned sign-bit bias" if not signed else ""
                x86 = (
                    "an SSE2 equality-gated two-dword lexicographic comparison "
                    f"using {pcmpgt}{bias}"
                )
            else:
                bias = " with an unsigned sign-bit bias" if not signed else ""
                x86 = f"the SSE2 {pcmpgt} comparison{bias}"
                if "Equal" in name:
                    x86 += f" merged with {pcmpeq} equality"
                if name.startswith("Less"):
                    x86 += " using reversed operands"
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch} for "
        f"the {relation} predicate. The x86-64 backend uses {x86} for "
        f"the same predicate. Both compact the lane results into the "
        "public mask. A scalar build uses the portable scalar implementation."
    )


def integer_conversion_support_doc(name: str, declaration: str) -> str:
    """Describe one exact fixed-width integer conversion lowering."""
    source_match = re.search(r"(?:Value|Low, High) : ([UI][0-9]+x[0-9]+)", declaration)
    target_match = re.search(r"return ([UI][0-9]+x[0-9]+)", declaration)
    if source_match is None or target_match is None:
        raise ValueError(f"not an integer conversion declaration: {declaration}")
    source = source_match.group(1)
    target = target_match.group(1)
    source_bits = int(re.search(r"[UI]([0-9]+)x", source).group(1))
    target_bits = int(re.search(r"[UI]([0-9]+)x", target).group(1))
    source_signed = source.startswith("I")
    target_signed = target.startswith("I")

    if name in {"Widen_Low", "Widen_High"}:
        high = name == "Widen_High"
        shape = {8: "8h", 16: "4s", 32: "2d"}[source_bits]
        neon = ("sshll" if source_signed else "ushll") + ("2" if high else "")
        unpack = {
            (8, False, False): "punpcklbw with a zero vector",
            (8, False, True): "punpckhbw with a zero vector",
            (8, True, False): "pcmpgtb to form a sign mask, then punpcklbw",
            (8, True, True): "pcmpgtb to form a sign mask, then punpckhbw",
            (16, False, False): "punpcklwd with a zero vector",
            (16, False, True): "punpckhwd with a zero vector",
            (16, True, False): "pcmpgtw to form a sign mask, then punpcklwd",
            (16, True, True): "pcmpgtw to form a sign mask, then punpckhwd",
            (32, False, False): "punpckldq with a zero vector",
            (32, False, True): "punpckhdq with a zero vector",
            (32, True, False): "pcmpgtd to form a sign mask, then punpckldq",
            (32, True, True): "pcmpgtd to form a sign mask, then punpckhdq",
        }[(source_bits, source_signed, high)]
        aarch = f"the NEON {neon} instruction over {shape} lanes with a zero shift"
        x86 = f"an SSE2 sequence using {unpack}"
    elif name == "Narrow_Truncate":
        low_shape, high_shape = {
            8: ("8b", "16b"), 16: ("4h", "8h"), 32: ("2s", "4s")
        }[target_bits]
        aarch = f"the NEON xtn.{low_shape} and xtn2.{high_shape} instructions"
        x86 = {
            8: "an SSE2 packuswb sequence that retains each lane's low byte",
            16: (
                "an SSE2 pshuflw, pshufhw, pshufd, and punpcklqdq sequence "
                "that retains each lane's low word"
            ),
            32: (
                "an SSE2 pshufd and punpcklqdq sequence that retains each "
                "lane's low doubleword"
            ),
        }[target_bits]
    elif name == "Narrow_Saturate":
        low_shape, high_shape = {
            8: ("8b", "16b"), 16: ("4h", "8h"), 32: ("2s", "4s")
        }[target_bits]
        if source_signed and not target_signed:
            neon = "sqxtun"
        elif source_signed:
            neon = "sqxtn"
        else:
            neon = "uqxtn"
        aarch = f"the NEON {neon}.{low_shape} and {neon}2.{high_shape} instructions"
        x86 = {
            ("U16x8", "U8x16"): "an SSE2 psrlw, pcmpeqw, pandn, and packuswb clamp-and-pack sequence",
            ("I16x8", "I8x16"): "the SSE2 packsswb instruction",
            ("U32x4", "U16x8"): "an SSE2 psrld, pcmpeqd, pandn, and punpcklqdq clamp-and-pack sequence",
            ("I32x4", "I16x8"): "the SSE2 packssdw instruction",
            ("U64x2", "U32x4"): "an SSE2 psrlq, pcmpeqd, pandn, pshufd, and punpcklqdq clamp-and-pack sequence",
            ("I64x2", "I32x4"): "an SSE2 psrad, pcmpeqd, pandn, pshufd, and punpcklqdq clamp-and-pack sequence",
            ("I16x8", "U8x16"): "the SSE2 packuswb instruction",
            ("I32x4", "U16x8"): "an SSE2 pcmpgtd, pandn, pshufd, and punpcklqdq clamp-and-pack sequence",
            ("I64x2", "U32x4"): "an SSE2 psrad, pcmpeqd, pandn, pshufd, and punpcklqdq clamp-and-pack sequence",
        }[(source, target)]
    elif name == "Convert_Saturate":
        shape = {8: "16b", 16: "8h", 32: "4s", 64: "2d"}[source_bits]
        if source_signed and source_bits < 64:
            aarch = f"a NEON movi-zero and smax.{shape} clamp sequence"
        elif source_signed:
            aarch = "a NEON cmge.2d nonnegative mask followed by and.16b"
        elif source_bits < 64:
            aarch = (
                f"a NEON movi-all-ones and ushr.{shape} signed-maximum "
                f"construction followed by umin.{shape}"
            )
        else:
            aarch = (
                "a NEON movi-all-ones and ushr.2d signed-maximum construction "
                "followed by cmhi.2d and bsl.16b selection"
            )
        compare = {8: "pcmpgtb", 16: "pcmpgtw", 32: "pcmpgtd", 64: "psrad"}[source_bits]
        if source_signed:
            x86 = f"an SSE2 {compare} sign-mask and pandn clamp sequence"
        else:
            shift = {8: "psrlw", 16: "psrlw", 32: "psrld", 64: "psrlq"}[source_bits]
            x86 = (
                f"an SSE2 {compare}, {shift}, pandn, and por sequence that "
                "constructs and selects the signed maximum"
            )
    else:
        raise ValueError(f"unsupported integer conversion: {name}")
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. The x86-64 "
        f"backend uses {x86}. A scalar build uses the portable scalar implementation."
    )


def native_support_doc(name: str, declaration: str) -> str:
    """Describe the verified implementation class of one exact overload."""
    fixed_ada = {
        "Mask_From_Bit_Mask", "To_Bit_Mask", "Mask_And", "Mask_Or",
        "Mask_Xor", "Mask_Not", "Test", "Any_True", "All_True",
        "None_True",
        "Is_Aligned_16", "Has_Extent",
    }
    if name in {
        "Widen_Low", "Widen_High", "Narrow_Truncate", "Narrow_Saturate",
        "Convert_Saturate",
    } and re.search(r"(?:Value|Low, High) : [UI][0-9]+x[0-9]+", declaration):
        return integer_conversion_support_doc(name, declaration)
    if name in {"From_Lanes", "To_Lanes", "Extract", "Replace"}:
        action = {
            "From_Lanes": "copy the supplied lane array into private vector storage",
            "To_Lanes": "copy private vector storage into the result lane array",
            "Extract": "read the selected position from private vector storage",
            "Replace": "copy private vector storage and write the selected position",
        }[name]
        return (
            f"Cross-platform support: The AArch64 and x86-64 backends {action} "
            "directly with fixed-width Ada code. They do not call the portable "
            "root operation. A scalar build uses the portable scalar "
            "implementation."
        )
    if name in {"Load_Partial", "Store_Partial"}:
        action = (
            "read exactly Count elements and initialize every inactive "
            "result lane to positive zero"
            if name == "Load_Partial"
            else
            "write the first Count value lanes to exactly Count destination "
            "elements and leave every other array element unchanged"
        )
        return (
            f"Cross-platform support: The AArch64 and x86-64 backends {action} "
            "with a direct fixed-width Ada loop. A zero count does not "
            "evaluate an element address. They do not call the portable root "
            "operation. A scalar build uses the portable scalar implementation."
        )
    if name in {
        "Load", "Store", "Load_Unaligned", "Store_Unaligned",
        "Load_Aligned", "Store_Aligned",
    }:
        actions = {
            "Load": (
                "delegates to Load_Unaligned, whose isolated NEON leaf "
                "loads the array into a vector register with ldr q",
                "delegates to Load_Unaligned, which loads the array into a "
                "vector register with movdqu",
            ),
            "Store": (
                "delegates to Store_Unaligned, whose isolated NEON leaf "
                "stores a vector register to the array with str q",
                "delegates to Store_Unaligned, which stores a vector "
                "register to the array with movdqu",
            ),
            "Load_Unaligned": (
                "uses an isolated NEON leaf that loads the array into a "
                "vector register with ldr q",
                "loads the array into a vector register with movdqu",
            ),
            "Store_Unaligned": (
                "uses an isolated NEON leaf that stores a vector register "
                "to the array with str q",
                "stores a vector register to the array with movdqu",
            ),
            "Load_Aligned": (
                "uses the same ldr q transfer after checking the alignment "
                "precondition",
                "loads the aligned array into a vector register with movdqa",
            ),
            "Store_Aligned": (
                "uses the same str q transfer after checking the alignment "
                "precondition",
                "stores a vector register to the aligned array with movdqa",
            ),
        }
        aarch, x86 = actions[name]
        return (
            f"Cross-platform support: The AArch64 backend {aarch}. The x86-64 "
            f"backend {x86}. A scalar build uses the portable scalar implementation."
        )
    if name == "Bit_Cast":
        return (
            "Cross-platform support: The AArch64 and x86-64 backends "
            "reinterpret the complete 128-bit private vector value directly "
            "with Ada.Unchecked_Conversion. They do not call the portable root "
            "operation. A scalar build uses the portable scalar implementation."
        )
    if name in {
        "Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal"
    }:
        return comparison_support_doc(name, declaration)
    if name == "Table_Lookup":
        return (
            "Cross-platform support: The AArch64 backend uses one NEON tbl "
            "instruction. The x86-64 backend uses an SSE2 sequence that "
            "compares each index with every valid table position, broadcasts "
            "the matching table byte, masks it, and merges all matches into an "
            "initially zero result. Indexes above 15 match no position and "
            "remain zero. A scalar build uses the portable scalar implementation."
        )
    if name == "Is_Aligned_16":
        return (
            "Cross-platform support: The AArch64 and x86-64 backends first "
            "check that Start is in the array range. For a valid Start, they "
            "test the selected element address modulo 16 directly with "
            "fixed-width Ada code. They do not call the portable root "
            "operation. A scalar build uses the portable scalar implementation."
        )
    if name == "Zero":
        if "U8x16" in declaration:
            target = (
                "The AArch64 and x86-64 backends construct the all-zero "
                "U8x16 result directly in result registers."
            )
        else:
            target = (
                "The AArch64 backend constructs the all-zero result with "
                "the NEON movi instruction. The x86-64 backend uses the "
                "SSE2 pxor instruction."
            )
        return (
            f"Cross-platform support: {target} A scalar build uses the "
            "portable scalar implementation."
        )
    if name == "Splat":
        if "U8x16" in declaration:
            x86 = (
                "unpacks the input byte through word width and broadcasts "
                "the result with the SSE2 pshufd instruction"
            )
        elif "I8x16" in declaration or "U16x8" in declaration or "I16x8" in declaration:
            x86 = (
                "replicates the input bits through 32-bit width and "
                "broadcasts them with the SSE2 pshufd instruction"
            )
        elif any(vector in declaration for vector in ("U32x4", "I32x4", "F32x4")):
            x86 = "broadcasts the input bits with the SSE2 pshufd instruction"
        else:
            x86 = (
                "broadcasts the input bits with the SSE2 punpcklqdq "
                "instruction"
            )
        return (
            "Cross-platform support: The AArch64 backend broadcasts the "
            "input bit encoding to every lane with the NEON dup instruction. "
            f"The x86-64 backend {x86}. A scalar build uses the portable "
            "scalar implementation."
        )
    if name in {"Slide_Lanes_Toward_Low", "Slide_Lanes_Toward_High"}:
        entry = next(
            candidate for candidate in [("U8x16", "U8", 8, 16)] + INTEGER_TYPES + FLOAT_TYPES
            if candidate[0] in declaration
        )
        vector, _, bits, lanes = entry[:4]
        direction = "lower" if name.endswith("Low") else "higher"
        x86_instruction = "psrldq" if name.endswith("Low") else "pslldq"
        return (
            "Cross-platform support: For each in-range constant Count, the "
            f"AArch64 backend uses NEON ext to move {bits}-bit lanes toward "
            f"{direction} indexes and inserts zero bytes. The x86-64 backend "
            f"uses SSE2 {x86_instruction} with the corresponding byte count. "
            "A zero count returns Value directly. When Count is equal to or "
            f"greater than {lanes}, each backend calls its own target Zero "
            "operation and does not call the portable root operation. A scalar "
            "build uses the portable scalar implementation."
        )
    if name in {"Shift_Left_Logical", "Shift_Right_Logical"}:
        vector = next(
            candidate
            for candidate in (
                "U8x16", "I8x16", "U16x8", "I16x8",
                "U32x4", "I32x4", "U64x2", "I64x2",
            )
            if candidate in declaration
        )
        bits = int(vector[1:vector.index("x")])
        direction = "left" if name == "Shift_Left_Logical" else "right"
        if bits == 8:
            x86 = (
                f"widens the bytes, shifts the 16-bit lanes {direction}, "
                "and packs the result bytes"
            )
        else:
            instruction = {
                ("left", 16): "psllw", ("left", 32): "pslld",
                ("left", 64): "psllq", ("right", 16): "psrlw",
                ("right", 32): "psrld", ("right", 64): "psrlq",
            }[(direction, bits)]
            x86 = f"shifts the {bits}-bit lanes with {instruction}"
        return (
            "Cross-platform support: The AArch64 backend shifts the "
            f"{bits}-bit lanes with the NEON ushl instruction and a "
            f"{'positive' if direction == 'left' else 'negative'} count. "
            f"The x86-64 backend uses an SSE2 sequence that {x86}. When Count "
            f"exceeds {bits}, both backends clamp it to {bits}. The clamped "
            "count produces the defined all-zero result without calling the "
            "portable root operation. A scalar build uses the portable scalar "
            "implementation."
        )
    if name == "Shift_Right_Arithmetic":
        vector = next(
            candidate for candidate in ("I8x16", "I16x8", "I32x4", "I64x2")
            if candidate in declaration
        )
        bits = {"I8x16": 8, "I16x8": 16, "I32x4": 32, "I64x2": 64}[vector]
        if bits == 8:
            x86 = (
                "widens the signed bytes, shifts the 16-bit lanes with psraw, "
                "and packs the result bytes"
            )
        elif bits == 16:
            x86 = "shifts the signed 16-bit lanes with psraw"
        elif bits == 32:
            x86 = "shifts the signed 32-bit lanes with psrad"
        else:
            x86 = (
                "derives each lane's sign mask, applies a logical right shift "
                "to each 64-bit lane and its sign mask, and merges the sign fill"
            )
        return (
            "Cross-platform support: The AArch64 backend shifts the signed "
            f"{bits}-bit lanes with the NEON sshl instruction and a negative "
            f"count. The x86-64 backend uses an SSE2 sequence that {x86}. "
            f"When Count exceeds {bits}, both backends clamp it to {bits}. "
            "The clamped count produces the defined full sign fill without "
            "calling the portable root operation. A scalar build uses the "
            "portable scalar implementation."
        )
    if name in {"First_True", "Last_True"}:
        direction = "first" if name == "First_True" else "last"
        aarch = (
            "a dedicated bit-reversal and leading-zero-count sequence"
            if name == "First_True" else
            "a dedicated leading-zero-count sequence"
        )
        x86 = (
            "a dedicated bit-scan-forward sequence"
            if name == "First_True" else
            "a dedicated bit-scan-reverse sequence"
        )
        return (
            f"Cross-platform support: The AArch64 backend uses {aarch} to find "
            f"the {direction} set compact-mask bit. The x86-64 backend uses "
            f"{x86} to find the {direction} set compact-mask bit. Both return "
            "the lane-count value for a zero mask. A scalar build uses the "
            "portable scalar implementation."
        )
    if name == "Population_Count":
        return (
            "Cross-platform support: The AArch64 backend counts set bits with "
            "a dedicated NEON byte-count and horizontal-add sequence. The "
            "x86-64 backend uses a dedicated fixed-width arithmetic bit-count "
            "sequence that does not require POPCNT. A scalar build uses the "
            "portable scalar implementation."
        )
    if name in {
        "Mask_From_Bit_Mask", "To_Bit_Mask", "Mask_And", "Mask_Or",
        "Mask_Xor", "Mask_Not", "Test", "Any_True", "All_True",
        "None_True",
    }:
        return (
            "Cross-platform support: The AArch64 and x86-64 backends apply "
            "this operation directly to the fixed-width compact integer mask. "
            "No vector instruction is required. A scalar build uses the "
            "portable scalar implementation."
        )
    if name == "Horizontal_Sum":
        return (
            "Cross-platform support: The AArch64 backend uses the NEON "
            "uaddlv instruction to sum all 16 unsigned byte lanes. The "
            "x86-64 backend uses SSE2 psadbw to form two 64-bit partial "
            "sums and adds them. A scalar build uses the portable scalar "
            "implementation."
        )
    if name == "Unordered" and (
        "F32x4" in declaration or "F64x2" in declaration
    ):
        return (
            "Cross-platform support: The AArch64 backend uses a dedicated "
            "NEON sequence that compares each input with itself to mark lanes "
            "that are not NaN. It combines the masks with bitwise AND and "
            "inverts the result. The x86-64 backend "
            "uses a dedicated SSE2 unordered comparison. A scalar build uses "
            "the portable scalar implementation."
        )
    if name == "Convert_Round" and "I32x4" in declaration:
        return (
            "Cross-platform support: The AArch64 backend uses a dedicated "
            "NEON instruction that converts the integer lanes to floating-point "
            "lanes. The x86-64 backend converts the lanes with the dedicated "
            "SSE2 cvtdq2ps instruction. A scalar build uses the portable scalar "
            "implementation."
        )
    if name == "Convert_Round" and "U32x4" in declaration:
        return (
            "Cross-platform support: The AArch64 backend uses a dedicated "
            "NEON instruction that converts the integer lanes to floating-point "
            "lanes. Under the required default round-to-nearest, ties-to-even "
            "mode, the x86-64 backend adjusts unsigned values above the signed "
            "maximum. It then converts the lanes with cvtdq2ps. A scalar build "
            "uses the portable scalar implementation."
        )
    if name == "Convert_Round" and "I64x2" in declaration:
        return (
            "Cross-platform support: The AArch64 backend uses a dedicated "
            "NEON instruction that converts both integer lanes. The x86-64 "
            "backend converts each signed lane with cvtsi2sdq and merges the "
            "two binary64 results. A scalar build uses the portable scalar "
            "implementation."
        )
    if name == "Convert_Round" and "U64x2" in declaration:
        return (
            "Cross-platform support: The AArch64 backend uses a dedicated "
            "NEON instruction that converts both integer lanes. Under the "
            "required default round-to-nearest, ties-to-even mode, the x86-64 "
            "backend shifts each unsigned value above the signed maximum to "
            "the right by one bit and preserves its discarded low bit. It converts the "
            "adjusted value with cvtsi2sdq and doubles the binary64 result. A "
            "scalar build uses the portable scalar implementation."
        )
    if name == "Convert_Truncate_Saturate":
        signed_result = "return I32x4" in declaration or "return I64x2" in declaration
        outcome = (
            "It selects zero for NaN, the signed maximum for positive overflow, "
            "and the signed minimum for negative overflow."
            if signed_result else
            "It selects zero for NaN or a negative input and the unsigned "
            "maximum for positive overflow."
        )
        if "F32x4" in declaration:
            return (
                "Cross-platform support: The AArch64 backend uses a dedicated NEON "
                "sequence that truncates floating-point lanes toward zero. "
                f"{outcome} The x86-64 backend truncates the lanes with cvttps2dq. "
                f"{outcome} A scalar build uses the portable scalar implementation."
            )
        x86 = (
            "The x86-64 backend truncates each lane with cvttsd2siq and "
            "classifies the binary64 encoding to select zero or a signed "
            "range limit. "
            if signed_result else
            "For a value that is at least 2 to the power of 63 and less than "
            "2 to the power of 64, "
            "the x86-64 backend subtracts 2 to the power of 63, truncates with cvttsd2siq, "
            "and restores the destination high bit. It classifies the binary64 "
            "encoding to select zero or the unsigned maximum. "
        )
        return (
            "Cross-platform support: The AArch64 backend uses a dedicated NEON "
            "sequence that truncates floating-point lanes toward zero. "
            f"{outcome} {x86}{outcome} A scalar build uses the portable scalar "
            "implementation."
        )
    if name in fixed_ada:
        return (
            "Cross-platform support: The AArch64, x86-64, and scalar backends use "
            "the same fixed-width Ada implementation."
        )
    if name in {"Add_Wrap", "Subtract_Wrap", "Multiply_Wrap"}:
        return wrapping_arithmetic_support(name, declaration)
    elif name in {
        "Reverse_Lanes", "Interleave_Low", "Interleave_High",
        "Deinterleave_Even", "Deinterleave_Odd",
    }:
        return lane_arrangement_support(name, declaration)
    elif name in {"Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Bitwise_Not"}:
        return bitwise_support(name)
    elif name in {"Min", "Max"} and any(
        vector in declaration for vector in (
            "U8x16", "I8x16", "U16x8", "I16x8",
            "U32x4", "I32x4", "U64x2", "I64x2",
        )
    ):
        return integer_minmax_support(name, declaration)
    elif name == "Select_Value":
        aarch = "a dedicated NEON compact-mask expansion and bit-selection sequence"
        x86 = "a dedicated SSE2 compact-mask expansion and bit-selection sequence"
    elif name in {"Add_Saturate", "Subtract_Saturate"}:
        return saturating_arithmetic_support(name, declaration)
    elif name == "Reduce_Add_Wrap":
        x86_add = {
            "U8x16": "paddb instruction in a four-stage fixed-shuffle tree",
            "I8x16": "paddb instruction in a four-stage fixed-shuffle tree",
            "U16x8": "paddw instruction in a three-stage fixed-shuffle tree",
            "I16x8": "paddw instruction in a three-stage fixed-shuffle tree",
            "U32x4": "paddd instruction in a two-stage fixed-shuffle tree",
            "I32x4": "paddd instruction in a two-stage fixed-shuffle tree",
            "U64x2": "paddq instruction in a one-stage fixed-shuffle tree",
            "I64x2": "paddq instruction in a one-stage fixed-shuffle tree",
        }
        vector = next(vector for vector in x86_add if vector in declaration)
        if "U8x16" in declaration:
            aarch = (
                "the NEON uaddlv instruction to form a widening sum and "
                "retains its low eight bits"
            )
        elif "I8x16" in declaration:
            aarch = "the NEON addv instruction over 16 byte lanes"
        elif "16x8" in declaration:
            aarch = "the NEON addv instruction over eight 16-bit lanes"
        elif "32x4" in declaration:
            aarch = "the NEON addv instruction over four 32-bit lanes"
        else:
            aarch = "the NEON addp instruction over two 64-bit lanes"
        x86 = f"the SSE2 {x86_add[vector]}"
    elif name in {"Add", "Subtract", "Multiply", "Divide"} and (
        "F32x4" in declaration or "F64x2" in declaration
    ):
        width = "4s" if "F32x4" in declaration else "2d"
        x86_width = "ps" if "F32x4" in declaration else "pd"
        instruction = {
            "Add": ("fadd", "add"), "Subtract": ("fsub", "sub"),
            "Multiply": ("fmul", "mul"), "Divide": ("fdiv", "div"),
        }[name]
        aarch = f"the NEON {instruction[0]} instruction over {width} lanes"
        x86 = f"the SSE2 {instruction[1]}{x86_width} instruction"
    elif name == "Reduce_Add" and (
        "F32x4" in declaration or "F64x2" in declaration
    ):
        lane_kind = "binary32" if "F32x4" in declaration else "binary64"
        aarch = (
            "a dedicated NEON sequence that starts from positive zero and "
            f"adds one {lane_kind} lane at a time in ascending order"
        )
        x86 = (
            "a dedicated SSE2 sequence that starts from positive zero and "
            f"adds one {lane_kind} lane at a time in ascending order"
        )
    elif name in {
        "Min_Number", "Max_Number", "Reduce_Min_Number", "Reduce_Max_Number"
    }:
        extreme = "minimum" if "Min" in name else "maximum"
        if name in {"Min_Number", "Max_Number"}:
            shape = "4s" if "F32x4" in declaration else "2d"
            instruction = "fminnm" if "Min" in name else "fmaxnm"
            aarch = f"the NEON {instruction} instruction over {shape} lanes"
        else:
            aarch = f"a dedicated NEON number-{extreme} sequence"
        if name in {"Min_Number", "Max_Number"}:
            x86 = (
                "a dedicated integer-only SSE2 classification and bit-selection "
                "sequence that preserves the documented NaN and signed-zero rules"
            )
        else:
            x86 = (
                "a dedicated integer-only SSE2 classification and bit-selection "
                "sequence that folds lanes in ascending order"
            )
    elif name in {"Reduce_Min", "Reduce_Max"}:
        result = "minimum" if name == "Reduce_Min" else "maximum"
        vector = next(
            vector for vector in (
                "U8x16", "I8x16", "U16x8", "I16x8",
                "U32x4", "I32x4", "U64x2", "I64x2",
            ) if vector in declaration
        )
        if "64x2" in declaration:
            compare = "cmgt" if "I64x2" in declaration else "cmhi"
            select = "bit" if name == "Reduce_Min" else "bif"
            aarch = (
                "a dedicated NEON sequence that broadcasts the high lane, "
                f"compares with {compare}, and selects the {result} with {select}"
            )
        else:
            prefix = "s" if re.search(r"Value : I(?:8x16|16x8|32x4)", declaration) else "u"
            lane_shape = (
                "16 byte lanes" if "8x16" in declaration
                else "eight 16-bit lanes" if "16x8" in declaration
                else "four 32-bit lanes"
            )
            instruction = f"{prefix}{'minv' if name == 'Reduce_Min' else 'maxv'}"
            aarch = f"the NEON {instruction} instruction over {lane_shape}"
        if vector == "U8x16":
            instruction = "pminub" if name == "Reduce_Min" else "pmaxub"
            x86 = f"the SSE2 {instruction} instruction in a four-stage fixed-shuffle tree"
        elif vector == "I16x8":
            instruction = "pminsw" if name == "Reduce_Min" else "pmaxsw"
            x86 = f"the SSE2 {instruction} instruction in a three-stage fixed-shuffle tree"
        elif vector in {"I8x16", "U16x8", "U32x4", "I32x4"}:
            instruction = {
                "I8x16": "pcmpgtb",
                "U16x8": "pcmpgtw with a sign-bit bias",
                "U32x4": "pcmpgtd with a sign-bit bias",
                "I32x4": "pcmpgtd",
            }[vector]
            stages = {"I8x16": 4, "U16x8": 3, "U32x4": 2, "I32x4": 2}[vector]
            x86 = (
                f"a dedicated SSE2 {instruction} comparison-and-selection "
                f"{result} reduction in a {stages}-stage fixed-shuffle tree"
            )
        else:
            bias = " with a sign-bit bias" if vector == "U64x2" else ""
            x86 = (
                "a dedicated SSE2 equality-gated two-dword lexicographic "
                f"comparison{bias} that selects the {result}"
            )
    elif name in {"Widen_Low", "Widen_High"}:
        aarch = (
            f"a dedicated NEON instruction that converts the selected lanes with {'fcvtl' if name == 'Widen_Low' else 'fcvtl2'}"
            if "F32x4" in declaration
            else "a dedicated NEON instruction that extends the selected lanes"
        )
        x86 = (
            (
                "a dedicated SSE2 instruction that converts the selected lanes with cvtps2pd"
                if name == "Widen_Low"
                else "a dedicated SSE2 sequence that shuffles the upper lanes and converts them with cvtps2pd"
            )
            if "F32x4" in declaration
            else "a dedicated SSE2 sequence that unpacks and extends the selected lanes"
        )
    elif name == "Narrow_Truncate":
        aarch = "a dedicated NEON instruction sequence that narrows the lanes"
        x86 = "a dedicated SSE2 sequence that selects the low bits and packs the result lanes"
    elif name == "Narrow_Saturate":
        aarch = "a dedicated NEON instruction sequence that narrows with saturation"
        x86 = "a dedicated SSE2 sequence that clamps and packs the result lanes"
    elif name == "Narrow_Round":
        aarch = "a dedicated NEON sequence that converts the lanes with fcvtn and fcvtn2"
        x86 = "a dedicated SSE2 sequence that converts with cvtpd2ps and merges the result lanes"
    elif name == "Convert_Saturate":
        aarch = "a dedicated NEON sequence that clamps each lane to the destination type's range"
        x86 = "a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes"
    elif name == "Convert_Round":
        aarch = "a dedicated NEON instruction that converts the integer lanes to floating-point lanes"
        x86 = (
            "scalar composition"
        )
    elif name == "Permute_Lanes":
        aarch = (
            "a dedicated NEON tbl sequence that selects complete lane byte "
            "groups through the reusable map"
        )
        x86 = (
            "a dedicated SSE2 sequence that compares every byte selector "
            "with each valid source position, broadcasts matching source "
            "bytes, and merges them into the result"
        )
    elif name in {"Compress", "Expand"}:
        map_action = (
            "a stable compression byte map from the mask"
            if name == "Compress"
            else "an expansion byte map from the mask"
        )
        aarch = (
            f"fixed-width Ada code to derive {map_action}, followed by a "
            "dedicated NEON tbl sequence"
        )
        x86 = (
            f"fixed-width Ada code to derive {map_action}, followed by a "
            "dedicated SSE2 sequence that compares every byte selector with "
            "each valid source position, broadcasts matching source bytes, "
            "and merges them into the result"
        )
    else:
        aarch = "a dedicated NEON implementation"
        x86 = "a dedicated SSE2 implementation"
    return (
        f"Cross-platform support: The AArch64 backend uses {aarch}. The x86-64 "
        f"backend uses {x86}. A scalar build uses the portable scalar implementation."
    )


def portable_support_doc(name: str, declaration: str) -> str:
    """Describe portable availability and the matching Native lowering."""
    no_native = name in {
        "Make_Lane_Map", "Select_Left_Lane", "Select_Right_Lane",
        "Make_Two_Source_Lane_Map", "Has_Extent",
    } or (name == "Is_Aligned_16" and "Byte_Array" in declaration)
    if no_native:
        return PORTABLE_SHARED_SUPPORT_DOC
    native = native_support_doc(name, declaration).removeprefix("Cross-platform support: ")
    native = native[0].lower() + native[1:]
    return (
        "Cross-platform support: This overload uses the portable scalar "
        "implementation on every supported GNAT target. For the matching "
        f"Native overload, {native}"
    )

PARAM_DOCS = {
    "Value": "The input value.",
    "Values": "Lane values in logical lane order.",
    "Left": "The left input.",
    "Right": "The right input.",
    "Lane": "The logical lane index.",
    "Selectors": "One source-lane selector for each result lane.",
    "Map": "The reusable lane map.",
    "With_Value": "The replacement lane value.",
    "Count": "The bit-shift count, lane-slide count, or valid element count, as applicable.",
    "Mask": "The input mask.",
    "If_True": "The value selected in true mask lanes.",
    "If_False": "The value selected in false mask lanes.",
    "Bits": "Compact lane bits. Bit zero represents lane zero.",
    "Data": "The typed lane array.",
    "Start": "The Ada index of the first selected element.",
    "Low": "The source for the low result half.",
    "High": "The source for the high result half.",
    "Table": "The 16 selectable byte lanes.",
    "Indices": "One unsigned table index for each result lane.",
}


def _parameter_names(declaration: str) -> list[str]:
    start = declaration.find("(")
    if start < 0:
        return []
    depth = 0
    end = -1
    for index in range(start, len(declaration)):
        if declaration[index] == "(":
            depth += 1
        elif declaration[index] == ")":
            depth -= 1
            if depth == 0:
                end = index
                break
    if end < 0:
        return []
    names: list[str] = []
    for group in declaration[start + 1 : end].split(";"):
        if ":" not in group:
            continue
        for name in group.split(":", 1)[0].split(","):
            names.append(name.strip())
    return names


def document_spec(text: str, support: str = "portable") -> str:
    """Attach synchronized GNATdoc comments to generated public declarations."""
    lines = text.splitlines()
    documented: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        match = re.match(r"   (function|procedure|type|subtype)\s+([A-Za-z0-9_]+)", line)
        if not match:
            documented.append(line)
            index += 1
            continue
        declaration = [line]
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
        documented.extend(declaration)
        kind, name = match.groups()
        has_trailing_doc = (
            index + 1 < len(lines)
            and lines[index + 1].startswith("   --")
            and "GENERATED" not in lines[index + 1]
        )
        if not has_trailing_doc:
            if kind in ("type", "subtype"):
                if name.startswith("Lane_Selectors_"):
                    documented.append(
                        "   --  One valid source-lane selector for each result lane."
                    )
                elif name.startswith("Lane_Map_"):
                    documented.append(
                        "   --  A private, reusable result-lane to source-lane map."
                    )
                elif name.startswith("Two_Source_Lane_Selector_"):
                    documented.append(
                        "   --  Select one lane from the left or right source vector."
                    )
                elif name.startswith("Two_Source_Lane_Selectors_"):
                    documented.append(
                        "   --  One two-source selector for each result lane."
                    )
                elif name.startswith("Two_Source_Lane_Map_"):
                    documented.append(
                        "   --  A private, reusable result-lane to two-source-lane map."
                    )
                else:
                    documented.append(f"   --  Public lane, array, vector, or mask type {name}.")
            else:
                declaration_text = " ".join(declaration)
                if name == "Convert_Saturate":
                    summary = (
                        CONVERT_SATURATE_SIGNED_DOC
                        if "Value : I" in declaration_text
                        else CONVERT_SATURATE_UNSIGNED_DOC
                    )
                elif name == "Permute_Lanes" and "Left, Right" in declaration_text:
                    summary = TWO_SOURCE_PERMUTE_DOC
                elif name in {"Widen_Low", "Widen_High"} and "F32x4" in declaration_text:
                    half = "low" if name == "Widen_Low" else "high"
                    summary = (
                        "With the platform's default gradual-underflow environment, "
                        f"convert the {half} binary32 source half exactly to binary64. "
                        "Signed zero and infinity are preserved. A NaN produces a NaN "
                        "with unspecified payload and signaling state. The operation "
                        "can update floating-point exception-status flags."
                    )
                else:
                    summary = OPERATION_DOCS.get(
                        name, "Perform the documented portable operation."
                    )
                if name.startswith("Slide_Lanes_"):
                    for sentence in summary.split(". "):
                        documented.append(
                            f"   --  {sentence if sentence.endswith('.') else sentence + '.'}"
                        )
                else:
                    documented.append(f"   --  {summary}")
                support_doc = {
                    "portable": portable_support_doc(name, declaration_text),
                    "scalar": SCALAR_SUPPORT_DOC,
                    "native": native_support_doc(name, declaration_text),
                }[support]
                documented.append(f"   --  {support_doc}")
                if name.startswith("Slide_Lanes_") and (
                    "F32x4" in declaration_text or "F64x2" in declaration_text
                ):
                    documented.append(
                        "   --  Vacated floating lanes contain positive zero."
                    )
                for parameter in _parameter_names(" ".join(declaration)):
                    parameter_doc = PARAM_DOCS.get(
                        parameter, "The input parameter."
                    )
                    if parameter == "Count":
                        if name.startswith("Slide_Lanes_"):
                            parameter_doc = "The number of lane positions to move."
                        elif name.startswith("Shift_"):
                            parameter_doc = "The number of bit positions to shift."
                        else:
                            parameter_doc = "The number of valid elements."
                    documented.append(
                        f"   --  @param {parameter} {parameter_doc}"
                    )
                if kind == "function":
                    if name == "Select_Left_Lane":
                        result_doc = "A selector for the requested left-input lane."
                    elif name == "Select_Right_Lane":
                        result_doc = "A selector for the requested right-input lane."
                    elif name == "Make_Two_Source_Lane_Map":
                        result_doc = "A reusable two-source lane map."
                    elif name == "Make_Lane_Map":
                        result_doc = "A reusable one-source lane map."
                    else:
                        result_doc = "The operation result."
                    documented.append(f"   --  @return {result_doc}")
        index += 1
    return "\n".join(documented)


def strip_generated_docs(text: str) -> str:
    """Remove synchronized comments before regenerating them."""
    summaries = set(OPERATION_DOCS.values())
    summaries.update(
        {
            "Convert the low source half to wider lanes without loss.",
            "Convert the high source half to wider lanes without loss.",
            "Select one table byte for each index lane. An index from zero through 15 selects that table lane. An index of 16 or greater returns zero.",
            CONVERT_SATURATE_SIGNED_DOC,
            CONVERT_SATURATE_UNSIGNED_DOC,
            TWO_SOURCE_PERMUTE_DOC,
            "Count is in lanes. Move lanes toward lower lane indexes by Count positions and fill vacated high-index lanes with zero. Return zero when Count is equal to or greater than the lane count. Floating zero fill is positive zero.",
            "Count is in lanes. Move lanes toward higher lane indexes by Count positions and fill vacated low-index lanes with zero. Return zero when Count is equal to or greater than the lane count. Floating zero fill is positive zero.",
            "Vacated floating lanes contain positive zero.",
        }
    )
    result: list[str] = []
    for line in text.splitlines():
        stripped = line.removeprefix("   --  ")
        if stripped.startswith("@param ") or stripped.startswith("@return "):
            continue
        if stripped in (
            PORTABLE_SUPPORT_DOC, PORTABLE_SHARED_SUPPORT_DOC, SCALAR_SUPPORT_DOC,
            LEGACY_NATIVE_SUPPORT_DOC,
        ) or stripped.startswith(
            "Cross-platform support:"
        ) or any(stripped.startswith(prefix) for prefix in LEGACY_NATIVE_SUPPORT_PREFIXES):
            continue
        if stripped.startswith(
            "With the platform's default gradual-underflow environment, convert the "
        ):
            continue
        if stripped.startswith("Public lane, array, vector, or mask type "):
            continue
        if stripped in (
            "One valid source-lane selector for each result lane.",
            "A private, reusable result-lane to source-lane map.",
            "Select one lane from the left or right source vector.",
            "One two-source selector for each result lane.",
            "A private, reusable result-lane to two-source-lane map.",
        ):
            continue
        if stripped in summaries or stripped == "Perform the documented portable operation.":
            continue
        if any(
            stripped.rstrip(".") in [part.rstrip(".") for part in summary.split(". ")]
            for summary in summaries
        ):
            continue
        result.append(line)
    return "\n".join(result) + ("\n" if text.endswith("\n") else "")


def replace_block(text: str, label: str, generated: str) -> str:
    begin = f"   --  BEGIN {label}"
    end = f"   --  END {label}"
    before, remainder = text.split(begin, 1)
    _, after = remainder.split(end, 1)
    return before + begin + "\n" + generated.rstrip() + "\n" + end + after


def mask_for(bits: int, lanes: int) -> str:
    return f"Mask_{bits}x{lanes}"


def lane_index(bits: int, lanes: int) -> str:
    return f"Lane_Index_{bits}x{lanes}"


def lane_count(bits: int, lanes: int) -> str:
    return f"Lane_Count_{bits}x{lanes}"


def lane_values(vector: str) -> str:
    return f"Lane_Values_{vector}"


def lane_selectors(bits: int, lanes: int) -> str:
    return f"Lane_Selectors_{bits}x{lanes}"


def lane_map(bits: int, lanes: int) -> str:
    return f"Lane_Map_{bits}x{lanes}"


def two_source_lane_selector(bits: int, lanes: int) -> str:
    return f"Two_Source_Lane_Selector_{bits}x{lanes}"


def two_source_lane_selectors(bits: int, lanes: int) -> str:
    return f"Two_Source_Lane_Selectors_{bits}x{lanes}"


def two_source_lane_map(bits: int, lanes: int) -> str:
    return f"Two_Source_Lane_Map_{bits}x{lanes}"


def array_name(scalar: str) -> str:
    return f"{scalar}_Array"


def bit_cast_pairs():
    """Yield every directed, lane-preserving bit-cast pair."""
    for group in BIT_CAST_GROUPS:
        for source in group:
            for target in group:
                if source != target:
                    yield source[0], source[1], target[0], target[1]


def emit_conversion_spec() -> str:
    """Emit explicit 128-bit reinterpretation and width conversion operations."""
    out: list[str] = []
    for source_vector, _, target_vector, _ in bit_cast_pairs():
        out.append(
            f"   function Bit_Cast (Value : {source_vector}) return {target_vector};"
        )
    out.append("")

    for source_vector, _, target_vector, _, _, _ in WIDENINGS:
        out += [
            f"   function Widen_Low (Value : {source_vector}) return {target_vector};",
            f"   function Widen_High (Value : {source_vector}) return {target_vector};",
        ]
    for source_vector, _, target_vector, _, _ in FLOAT_WIDENINGS:
        out += [
            f"   function Widen_Low (Value : {source_vector}) return {target_vector};",
            f"   function Widen_High (Value : {source_vector}) return {target_vector};",
        ]
    out.append("")

    for source_vector, _, target_vector, _, _, _, _ in NARROWINGS:
        out += [
            f"   function Narrow_Truncate (Low, High : {source_vector}) return {target_vector};",
            f"   function Narrow_Saturate (Low, High : {source_vector}) return {target_vector};",
        ]
    for source_vector, _, target_vector, _, _, _, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        out.append(
            f"   function Narrow_Saturate (Low, High : {source_vector}) return {target_vector};"
        )
    for source_vector, _, target_vector, _, _ in FLOAT_NARROWINGS:
        out.append(
            f"   function Narrow_Round (Low, High : {source_vector}) return {target_vector};"
        )
    for source_vector, _, target_vector, _, _, _, _ in INTEGER_TO_FLOAT_CONVERSIONS:
        out.append(f"   function Convert_Round (Value : {source_vector}) return {target_vector};")
    for source_vector, _, target_vector, _, _, _, _ in FLOAT_TO_INTEGER_CONVERSIONS:
        out.append(
            f"   function Convert_Truncate_Saturate (Value : {source_vector}) return {target_vector};"
        )
    for source_vector, _, target_vector, _, _, _, _ in SIGNED_UNSIGNED_CONVERSIONS:
        out.append(f"   function Convert_Saturate (Value : {source_vector}) return {target_vector};")
    out.append("")
    return document_spec("\n".join(out))


def emit_spec() -> str:
    out = []
    out += [
        "   subtype I8 is Interfaces.Integer_8;",
        "   subtype U16 is Interfaces.Unsigned_16;",
        "   subtype I16 is Interfaces.Integer_16;",
        "   subtype U32 is Interfaces.Unsigned_32;",
        "   subtype I32 is Interfaces.Integer_32;",
        "   subtype U64 is Interfaces.Unsigned_64;",
        "   subtype I64 is Interfaces.Integer_64;",
        "   subtype F32 is Interfaces.IEEE_Float_32;",
        "   subtype F64 is Interfaces.IEEE_Float_64;",
        "",
    ]
    seen_shapes = {(8, 16)}
    for vector, scalar, bits, lanes, *_ in INTEGER_TYPES + FLOAT_TYPES:
        shape = (bits, lanes)
        if shape not in seen_shapes:
            out += [
                f"   subtype {lane_index(bits, lanes)} is Natural range 0 .. {lanes - 1};",
                f"   subtype {lane_count(bits, lanes)} is Natural range 0 .. {lanes};",
                f"   type {lane_selectors(bits, lanes)} is array ({lane_index(bits, lanes)}) of {lane_index(bits, lanes)};",
                f"   type {lane_map(bits, lanes)} is private;",
                f"   function Make_Lane_Map (Selectors : {lane_selectors(bits, lanes)}) return {lane_map(bits, lanes)};",
                f"   type {two_source_lane_selector(bits, lanes)} is private;",
                f"   function Select_Left_Lane (Lane : {lane_index(bits, lanes)}) return {two_source_lane_selector(bits, lanes)};",
                f"   function Select_Right_Lane (Lane : {lane_index(bits, lanes)}) return {two_source_lane_selector(bits, lanes)};",
                f"   type {two_source_lane_selectors(bits, lanes)} is array ({lane_index(bits, lanes)}) of {two_source_lane_selector(bits, lanes)};",
                f"   type {two_source_lane_map(bits, lanes)} is private;",
                f"   function Make_Two_Source_Lane_Map (Selectors : {two_source_lane_selectors(bits, lanes)}) return {two_source_lane_map(bits, lanes)};",
            ]
            seen_shapes.add(shape)
        out += [
            f"   type {lane_values(vector)} is array ({lane_index(bits, lanes)}) of {scalar};",
            f"   type {array_name(scalar)} is array (Natural range <>) of aliased {scalar};",
            f"   type {vector} is private;",
            "",
        ]
    for bits, lanes, _ in MASKS:
        out.append(f"   type {mask_for(bits, lanes)} is private;")
    out.append("")

    out.append(emit_conversion_spec().rstrip())
    out.append("")

    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        vals = lane_values(vector)
        count = lane_count(bits, lanes)
        arr = array_name(scalar)
        extent = f"Start in Data'Range and then {lanes - 1} <= Natural (Data'Last - Start)"
        partial = "Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start))"
        out += [
            f"   function Zero return {vector};",
            f"   function Splat (Value : {scalar}) return {vector};",
            f"   function From_Lanes (Values : {vals}) return {vector};",
            f"   function To_Lanes (Value : {vector}) return {vals};",
            f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar};",
            f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector};",
            f"   function Add_Wrap (Left, Right : {vector}) return {vector};",
            f"   function Subtract_Wrap (Left, Right : {vector}) return {vector};",
            f"   function Multiply_Wrap (Left, Right : {vector}) return {vector};",
            f"   function Add_Saturate (Left, Right : {vector}) return {vector};",
            f"   function Subtract_Saturate (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_And (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_Or (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_Xor (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_Not (Value : {vector}) return {vector};",
            f"   function Shift_Left_Logical (Value : {vector}; Count : Natural) return {vector};",
            f"   function Shift_Right_Logical (Value : {vector}; Count : Natural) return {vector};",
        ]
        if signed:
            out.append(f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector};")
        out += [
            f"   function Equal (Left, Right : {vector}) return {mask};",
            f"   function Less_Than (Left, Right : {vector}) return {mask};",
            f"   function Less_Equal (Left, Right : {vector}) return {mask};",
            f"   function Greater_Than (Left, Right : {vector}) return {mask};",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask};",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector};",
            f"   function Compress (Value : {vector}; Mask : {mask}) return {vector};",
            f"   function Expand (Value : {vector}; Mask : {mask}) return {vector};",
            f"   function Min (Left, Right : {vector}) return {vector};",
            f"   function Max (Left, Right : {vector}) return {vector};",
            f"   function Reduce_Add_Wrap (Value : {vector}) return {scalar};",
            f"   function Reduce_Min (Value : {vector}) return {scalar};",
            f"   function Reduce_Max (Value : {vector}) return {scalar};",
            f"   function Reverse_Lanes (Value : {vector}) return {vector};",
            f"   function Permute_Lanes (Value : {vector}; Map : {lane_map(bits, lanes)}) return {vector};",
            f"   function Permute_Lanes (Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}) return {vector};",
            f"   function Interleave_Low (Left, Right : {vector}) return {vector};",
            f"   function Interleave_High (Left, Right : {vector}) return {vector};",
            f"   function Deinterleave_Even (Left, Right : {vector}) return {vector};",
            f"   function Deinterleave_Odd (Left, Right : {vector}) return {vector};",
            f"   function Slide_Lanes_Toward_Low (Value : {vector}; Count : Natural) return {vector};",
            f"   function Slide_Lanes_Toward_High (Value : {vector}; Count : Natural) return {vector};",
            f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean;",
            f"   function Load (Data : {arr}; Start : Natural) return {vector}",
            f"     with Pre => {extent};",
            f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent};",
            f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} with Pre => {partial};",
            f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) with Pre => {partial};",
            "",
        ]

    for vector, scalar, bits, lanes in FLOAT_TYPES:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        vals = lane_values(vector)
        count = lane_count(bits, lanes)
        arr = array_name(scalar)
        extent = f"Start in Data'Range and then {lanes - 1} <= Natural (Data'Last - Start)"
        partial = "Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start))"
        out += [
            f"   function Zero return {vector};",
            f"   function Splat (Value : {scalar}) return {vector};",
            f"   function From_Lanes (Values : {vals}) return {vector};",
            f"   function To_Lanes (Value : {vector}) return {vals};",
            f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar};",
            f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector};",
            f"   function Add (Left, Right : {vector}) return {vector};",
            f"   function Subtract (Left, Right : {vector}) return {vector};",
            f"   function Multiply (Left, Right : {vector}) return {vector};",
            f"   function Divide (Left, Right : {vector}) return {vector};",
            f"   function Equal (Left, Right : {vector}) return {mask};",
            f"   function Less_Than (Left, Right : {vector}) return {mask};",
            f"   function Less_Equal (Left, Right : {vector}) return {mask};",
            f"   function Greater_Than (Left, Right : {vector}) return {mask};",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask};",
            f"   function Unordered (Left, Right : {vector}) return {mask};",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector};",
            f"   function Compress (Value : {vector}; Mask : {mask}) return {vector};",
            f"   function Expand (Value : {vector}; Mask : {mask}) return {vector};",
            f"   function Min_Number (Left, Right : {vector}) return {vector};",
            f"   function Max_Number (Left, Right : {vector}) return {vector};",
            f"   function Reduce_Add (Value : {vector}) return {scalar};",
            f"   function Reduce_Min_Number (Value : {vector}) return {scalar};",
            f"   function Reduce_Max_Number (Value : {vector}) return {scalar};",
            f"   function Reverse_Lanes (Value : {vector}) return {vector};",
            f"   function Permute_Lanes (Value : {vector}; Map : {lane_map(bits, lanes)}) return {vector};",
            f"   function Permute_Lanes (Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}) return {vector};",
            f"   function Interleave_Low (Left, Right : {vector}) return {vector};",
            f"   function Interleave_High (Left, Right : {vector}) return {vector};",
            f"   function Deinterleave_Even (Left, Right : {vector}) return {vector};",
            f"   function Deinterleave_Odd (Left, Right : {vector}) return {vector};",
            f"   function Slide_Lanes_Toward_Low (Value : {vector}; Count : Natural) return {vector};",
            f"   function Slide_Lanes_Toward_High (Value : {vector}; Count : Natural) return {vector};",
            f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean;",
            f"   function Load (Data : {arr}; Start : Natural) return {vector} with Pre => {extent};",
            f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent};",
            f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} with Pre => {partial};",
            f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) with Pre => {partial};",
            "",
        ]

    for bits, lanes, storage in MASKS:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        count = lane_count(bits, lanes)
        out += [
            f"   function Mask_From_Bit_Mask (Bits : Interfaces.{storage}) return {mask};",
            f"   function To_Bit_Mask (Mask : {mask}) return Interfaces.{storage};",
            f"   function Mask_And (Left, Right : {mask}) return {mask};",
            f"   function Mask_Or (Left, Right : {mask}) return {mask};",
            f"   function Mask_Xor (Left, Right : {mask}) return {mask};",
            f"   function Mask_Not (Value : {mask}) return {mask};",
            f"   function Test (Mask : {mask}; Lane : {idx}) return Boolean;",
            f"   function Any_True (Mask : {mask}) return Boolean;",
            f"   function All_True (Mask : {mask}) return Boolean;",
            f"   function None_True (Mask : {mask}) return Boolean;",
            f"   function Population_Count (Mask : {mask}) return {count};",
            f"   function First_True (Mask : {mask}) return {count};",
            f"   function Last_True (Mask : {mask}) return {count};",
            "",
        ]
    return document_spec("\n".join(out))


def emit_private() -> str:
    out = []
    seen_shapes = {(8, 16)}
    for vector, _, _, _, *_ in INTEGER_TYPES + FLOAT_TYPES:
        out += [
            f"   type {vector} is record",
            f"      Lanes : {lane_values(vector)};",
            "   end record;",
            f"   for {vector}'Size use 128;",
            "",
        ]
        bits = next(item[2] for item in INTEGER_TYPES + FLOAT_TYPES if item[0] == vector)
        lanes = next(item[3] for item in INTEGER_TYPES + FLOAT_TYPES if item[0] == vector)
        if (bits, lanes) not in seen_shapes:
            lane_bytes = bits // 8
            default_indices = ", ".join(
                str(byte) for _ in range(lanes) for byte in range(lane_bytes)
            )
            out += [
                f"   type {lane_map(bits, lanes)} is record",
                f"      Byte_Indices : Lane_Values_8x16 := [{default_indices}];",
                "   end record;",
                f"   for {lane_map(bits, lanes)}'Size use 128;",
                "",
                f"   type {two_source_lane_selector(bits, lanes)} is record",
                "      Encoded : U8 := 0;",
                "   end record;",
                f"   for {two_source_lane_selector(bits, lanes)}'Size use 8;",
                "",
                f"   type {two_source_lane_map(bits, lanes)} is record",
                f"      Byte_Indices : Lane_Values_8x16 := [{default_indices}];",
                "   end record;",
                f"   for {two_source_lane_map(bits, lanes)}'Size use 128;",
                "",
            ]
            seen_shapes.add((bits, lanes))
    for bits, lanes, storage in MASKS:
        mask = mask_for(bits, lanes)
        out += [
            f"   type {mask} is record",
            f"      Bits : Interfaces.{storage};",
            "   end record;",
            f"   for {mask}'Size use 8;",
            "",
        ]
    return "\n".join(out)


def emit_scalar_backend_renames() -> str:
    """Emit the scalar package's full-family renames from the public spec."""
    out: list[str] = []
    for vector, _, bits, lanes, *_ in INTEGER_TYPES + FLOAT_TYPES:
        out.append(
            f"   function Permute_Lanes (Value : {vector}; Map : {lane_map(bits, lanes)}) return {vector} renames Flyology_SIMD.Permute_Lanes;"
        )
        out.append(
            f"   function Permute_Lanes (Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}) return {vector} renames Flyology_SIMD.Permute_Lanes;"
        )
        out.append(
            f"   function Compress (Value : {vector}; Mask : {mask_for(bits, lanes)}) return {vector} renames Flyology_SIMD.Compress;"
        )
        out.append(
            f"   function Expand (Value : {vector}; Mask : {mask_for(bits, lanes)}) return {vector} renames Flyology_SIMD.Expand;"
        )
    return document_spec("\n".join(out))
def signed_unsigned(bits: int) -> str:
    return f"U{bits}"


def emit_lane_slides(vector: str, idx: str, lanes: int) -> list[str]:
    """Emit portable lane-index slides with zero-filled vacated lanes."""
    return [
        f"   function Slide_Lanes_Toward_Low (Value : {vector}; Count : Natural) return {vector} is",
        f"      Result : {vector} := Zero;",
        "   begin",
        f"      if Count >= {lanes} then return Result; end if;",
        f"      for Lane in {idx} loop",
        f"         if Lane < {lanes} - Count then",
        "            Result.Lanes (Lane) := Value.Lanes (Lane + Count);",
        "         end if;",
        "      end loop;",
        "      return Result;",
        "   end Slide_Lanes_Toward_Low;",
        "",
        f"   function Slide_Lanes_Toward_High (Value : {vector}; Count : Natural) return {vector} is",
        f"      Result : {vector} := Zero;",
        "   begin",
        f"      if Count >= {lanes} then return Result; end if;",
        f"      for Lane in {idx} loop",
        "         if Lane >= Count then",
        "            Result.Lanes (Lane) := Value.Lanes (Lane - Count);",
        "         end if;",
        "      end loop;",
        "      return Result;",
        "   end Slide_Lanes_Toward_High;",
        "",
    ]


def emit_compress_expand(vector: str, bits: int, lanes: int) -> list[str]:
    """Emit stable scalar mask compression and expansion."""
    idx = lane_index(bits, lanes)
    mask = mask_for(bits, lanes)
    return [
        f"   function Compress (Value : {vector}; Mask : {mask}) return {vector} is",
        f"      Result : {vector} := Zero;",
        "      Result_Lane : Natural := 0;",
        "   begin",
        f"      for Source_Lane in {idx} loop",
        "         if Test (Mask, Source_Lane) then",
        "            Result.Lanes (Result_Lane) := Value.Lanes (Source_Lane);",
        "            Result_Lane := Result_Lane + 1;",
        "         end if;",
        "      end loop;",
        "      return Result;",
        "   end Compress;",
        "",
        f"   function Expand (Value : {vector}; Mask : {mask}) return {vector} is",
        f"      Result : {vector} := Zero;",
        "      Source_Lane : Natural := 0;",
        "   begin",
        f"      for Result_Lane in {idx} loop",
        "         if Test (Mask, Result_Lane) then",
        "            Result.Lanes (Result_Lane) := Value.Lanes (Source_Lane);",
        "            Source_Lane := Source_Lane + 1;",
        "         end if;",
        "      end loop;",
        "      return Result;",
        "   end Expand;",
        "",
    ]


def emit_lane_map(bits: int, lanes: int) -> list[str]:
    """Emit a private byte-index map that can feed a native table lookup."""
    idx = lane_index(bits, lanes)
    selectors = lane_selectors(bits, lanes)
    mapping = lane_map(bits, lanes)
    bytes_per_lane = bits // 8
    return [
        f"   function Make_Lane_Map (Selectors : {selectors}) return {mapping} is",
        f"      Result : {mapping};",
        "   begin",
        f"      for Result_Lane in {idx} loop",
        f"         for Byte in Natural range 0 .. {bytes_per_lane - 1} loop",
        "            Result.Byte_Indices",
        f"              (Result_Lane * {bytes_per_lane} + Byte) :=",
        "                U8",
        f"                  (Natural (Selectors (Result_Lane)) * {bytes_per_lane}",
        "                   + Byte);",
        "         end loop;",
        "      end loop;",
        "      return Result;",
        "   end Make_Lane_Map;",
        "",
    ]


def emit_lane_permute(vector: str, bits: int, lanes: int) -> list[str]:
    idx = lane_index(bits, lanes)
    mapping = lane_map(bits, lanes)
    bytes_per_lane = bits // 8
    return [
        f"   function Permute_Lanes (Value : {vector}; Map : {mapping}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Result_Lane in {idx} loop",
        "         Result.Lanes (Result_Lane) :=",
        "           Value.Lanes",
        f"             ({idx}",
        "                (Natural",
        "                   (Map.Byte_Indices",
        f"                      (Result_Lane * {bytes_per_lane}))",
        f"                 / {bytes_per_lane}));",
        "      end loop;",
        "      return Result;",
        "   end Permute_Lanes;",
        "",
    ]


def emit_two_source_lane_selectors(bits: int, lanes: int) -> list[str]:
    """Emit scalar two-source selector constructors for one lane shape."""
    selector = two_source_lane_selector(bits, lanes)
    idx = lane_index(bits, lanes)
    selectors = two_source_lane_selectors(bits, lanes)
    mapping = two_source_lane_map(bits, lanes)
    lane_bytes = bits // 8
    return [
        f"   function Select_Left_Lane (Lane : {idx}) return {selector} is",
        "     (Encoded => U8 (Lane));",
        f"   function Select_Right_Lane (Lane : {idx}) return {selector} is",
        f"     (Encoded => U8 ({lanes} + Lane));",
        f"   function Make_Two_Source_Lane_Map (Selectors : {selectors}) return {mapping} is",
        f"      Result : {mapping};",
        "   begin",
        f"      for Result_Lane in {idx} loop",
        f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop",
        "            Result.Byte_Indices",
        f"              (Result_Lane * {lane_bytes} + Byte) :=",
        "                U8",
        "                  (Natural (Selectors (Result_Lane).Encoded) *",
        f"                     {lane_bytes} + Byte);",
        "         end loop;",
        "      end loop;",
        "      return Result;",
        "   end Make_Two_Source_Lane_Map;",
        "",
    ]


def emit_two_source_lane_permute(vector: str, bits: int, lanes: int) -> list[str]:
    """Emit scalar selection from either of two same-shaped vectors."""
    idx = lane_index(bits, lanes)
    mapping = two_source_lane_map(bits, lanes)
    return [
        f"   function Permute_Lanes (Left, Right : {vector}; Map : {mapping}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Result_Lane in {idx} loop",
        "         declare",
        "            Encoded_Byte : constant Natural :=",
        "              Natural",
        "                (Map.Byte_Indices",
        f"                   (Result_Lane * {bits // 8}));",
        f"            Encoded : constant Natural := Encoded_Byte / {bits // 8};",
        "         begin",
        "            Result.Lanes (Result_Lane) :=",
        f"              (if Encoded < {lanes} then",
        f"                  Left.Lanes ({idx} (Encoded))",
        "               else",
        f"                  Right.Lanes ({idx} (Encoded - {lanes})));",
        "         end;",
        "      end loop;",
        "      return Result;",
        "   end Permute_Lanes;",
        "",
    ]


def emit_integer_body(vector: str, scalar: str, bits: int, lanes: int, signed: bool) -> list[str]:
    idx = lane_index(bits, lanes)
    vals = lane_values(vector)
    mask = mask_for(bits, lanes)
    count = lane_count(bits, lanes)
    arr = array_name(scalar)
    storage = "Interfaces.Unsigned_16" if lanes == 16 else "Interfaces.Unsigned_8"
    all_bits = "Interfaces.Unsigned_16'Last" if lanes == 16 else str((1 << lanes) - 1)
    out = []
    if signed:
        unsigned = signed_unsigned(bits)
        out += [
            f"   function To_{unsigned} is new Ada.Unchecked_Conversion ({scalar}, {unsigned});",
            f"   function To_{scalar} is new Ada.Unchecked_Conversion ({unsigned}, {scalar});",
            "",
        ]
    out += [
        f"   function Zero return {vector} is (Lanes => [others => 0]);",
        f"   function Splat (Value : {scalar}) return {vector} is (Lanes => [others => Value]);",
        f"   function From_Lanes (Values : {vals}) return {vector} is (Lanes => Values);",
        f"   function To_Lanes (Value : {vector}) return {vals} is (Value.Lanes);",
        f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar} is (Value.Lanes (Lane));",
        f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector} is",
        f"      Result : {vector} := Value;",
        "   begin",
        "      Result.Lanes (Lane) := With_Value;",
        "      return Result;",
        "   end Replace;",
        "",
    ]
    out += emit_two_source_lane_permute(vector, bits, lanes)
    out += emit_lane_permute(vector, bits, lanes)
    out += emit_compress_expand(vector, bits, lanes)
    for name, op in (("Add_Wrap", "+"), ("Subtract_Wrap", "-")):
        expr = f"Left.Lanes (Lane) {op} Right.Lanes (Lane)"
        if signed:
            expr = f"To_{scalar} (To_{signed_unsigned(bits)} (Left.Lanes (Lane)) {op} To_{signed_unsigned(bits)} (Right.Lanes (Lane)))"
        out += [
            f"   function {name} (Left, Right : {vector}) return {vector} is",
            f"      Result : {vector};",
            "   begin",
            f"      for Lane in {idx} loop",
            f"         Result.Lanes (Lane) := {expr};",
            "      end loop;",
            "      return Result;",
            f"   end {name};",
            "",
        ]
    out += [
        f"   function Multiply_Wrap (Left, Right : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop",
        f"         Result.Lanes (Lane) := " +
        (f"To_{scalar} (To_{signed_unsigned(bits)} (Left.Lanes (Lane)) * To_{signed_unsigned(bits)} (Right.Lanes (Lane)));" if signed else "Left.Lanes (Lane) * Right.Lanes (Lane);"),
        "      end loop;",
        "      return Result;",
        "   end Multiply_Wrap;",
        "",
    ]
    out += [
        f"   function Add_Saturate (Left, Right : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop",
    ]
    if signed:
        out += [
            f"         if Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) > {scalar}'Last - Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'Last;",
            f"         elsif Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) < {scalar}'First - Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'First;",
            "         else",
            "            Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);",
            "         end if;",
        ]
    else:
        out += [
            f"         Result.Lanes (Lane) := (if Left.Lanes (Lane) > {scalar}'Last - Right.Lanes (Lane) then {scalar}'Last else Left.Lanes (Lane) + Right.Lanes (Lane));",
        ]
    out += ["      end loop;", "      return Result;", "   end Add_Saturate;", ""]
    out += [
        f"   function Subtract_Saturate (Left, Right : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop",
    ]
    if signed:
        out += [
            f"         if Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) > {scalar}'Last + Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'Last;",
            f"         elsif Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) < {scalar}'First + Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'First;",
            "         else",
            "            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);",
            "         end if;",
        ]
    else:
        out += ["         Result.Lanes (Lane) := (if Left.Lanes (Lane) < Right.Lanes (Lane) then 0 else Left.Lanes (Lane) - Right.Lanes (Lane));"]
    out += ["      end loop;", "      return Result;", "   end Subtract_Saturate;", ""]
    for name, op in (("Bitwise_And", "and"), ("Bitwise_Or", "or"), ("Bitwise_Xor", "xor")):
        expr = f"Left.Lanes (Lane) {op} Right.Lanes (Lane)"
        if signed:
            expr = f"To_{scalar} (To_{signed_unsigned(bits)} (Left.Lanes (Lane)) {op} To_{signed_unsigned(bits)} (Right.Lanes (Lane)))"
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := {expr};", "      end loop;", "      return Result;", f"   end {name};", ""]
    not_expr = "not Value.Lanes (Lane)" if not signed else f"To_{scalar} (not To_{signed_unsigned(bits)} (Value.Lanes (Lane)))"
    out += [f"   function Bitwise_Not (Value : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := {not_expr};", "      end loop;", "      return Result;", "   end Bitwise_Not;", ""]
    for name, shift in (("Shift_Left_Logical", "Shift_Left"), ("Shift_Right_Logical", "Shift_Right")):
        base = f"Value.Lanes (Lane)" if not signed else f"To_{signed_unsigned(bits)} (Value.Lanes (Lane))"
        expr = f"Interfaces.{shift} ({base}, Count)"
        if signed:
            expr = f"To_{scalar} ({expr})"
        out += [f"   function {name} (Value : {vector}; Count : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      if Count >= {bits} then return Zero; end if;", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := {expr};", "      end loop;", "      return Result;", f"   end {name};", ""]
    if signed:
        out += [f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      if Count >= {bits} then", f"         for Lane in {idx} loop Result.Lanes (Lane) := (if Value.Lanes (Lane) < 0 then -1 else 0); end loop;", "         return Result;", "      end if;", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := To_{scalar} (Interfaces.Shift_Right_Arithmetic (To_{signed_unsigned(bits)} (Value.Lanes (Lane)), Count));", "      end loop;", "      return Result;", "   end Shift_Right_Arithmetic;", ""]
    out += [
        f"   function Compare_{vector} (Left, Right : {vector}; Kind : Character) return {mask} is",
        f"      Bits : {storage} := 0;",
        "      Truth : Boolean;",
        "   begin",
        f"      for Lane in {idx} loop",
        "         case Kind is",
        "            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);",
        "            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);",
        "            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);",
        "            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);",
        "            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);",
        "         end case;",
        f"         if Truth then Bits := Bits or Interfaces.Shift_Left ({storage}'(1), Lane); end if;",
        "      end loop;",
        "      return (Bits => Bits);",
        f"   end Compare_{vector};",
    ]
    for name, kind in (("Equal", "="), ("Less_Than", "<"), ("Less_Equal", "L"), ("Greater_Than", ">"), ("Greater_Equal", "G")):
        out.append(f"   function {name} (Left, Right : {vector}) return {mask} is (Compare_{vector} (Left, Right, '{kind}'));")
    out += [
        f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;",
        "      return Result;",
        "   end Select_Value;",
    ]
    for name, attr in (("Min", "Min"), ("Max", "Max")):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := {scalar}'{attr} (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;", "      return Result;", f"   end {name};"]
    add_expr = "Result + Value.Lanes (Lane)"
    if signed:
        add_expr = f"To_{scalar} (To_{signed_unsigned(bits)} (Result) + To_{signed_unsigned(bits)} (Value.Lanes (Lane)))"
    out += [f"   function Reduce_Add_Wrap (Value : {vector}) return {scalar} is", f"      Result : {scalar} := 0;", "   begin", f"      for Lane in {idx} loop Result := {add_expr}; end loop;", "      return Result;", "   end Reduce_Add_Wrap;", f"   function Reduce_Min (Value : {vector}) return {scalar} is", "      Result : " + scalar + " := Value.Lanes (0);", "   begin", f"      for Lane in {idx} range 1 .. {lanes - 1} loop Result := {scalar}'Min (Result, Value.Lanes (Lane)); end loop;", "      return Result;", "   end Reduce_Min;", f"   function Reduce_Max (Value : {vector}) return {scalar} is", "      Result : " + scalar + " := Value.Lanes (0);", "   begin", f"      for Lane in {idx} range 1 .. {lanes - 1} loop Result := {scalar}'Max (Result, Value.Lanes (Lane)); end loop;", "      return Result;", "   end Reduce_Max;", ""]
    out += [f"   function Reverse_Lanes (Value : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Value.Lanes ({lanes - 1} - Lane); end loop;", "      return Result;", "   end Reverse_Lanes;"]
    for name, offset in (("Interleave_Low", 0), ("Interleave_High", lanes // 2)):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in Natural range 0 .. {lanes // 2 - 1} loop", f"         Result.Lanes (2 * Lane) := Left.Lanes (Lane + {offset});", f"         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + {offset});", "      end loop;", "      return Result;", f"   end {name};"]
    for name, parity in (("Deinterleave_Even", 0), ("Deinterleave_Odd", 1)):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in Natural range 0 .. {lanes // 2 - 1} loop", f"         Result.Lanes (Lane) := Left.Lanes (2 * Lane + {parity});", f"         Result.Lanes (Lane + {lanes // 2}) := Right.Lanes (2 * Lane + {parity});", "      end loop;", "      return Result;", f"   end {name};"]
    out += emit_lane_slides(vector, idx, lanes)
    out += [f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);", f"   function Load (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store;", f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Data (Start + Lane); end loop;", "      return Result;", "   end Load_Unaligned;", f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is", "   begin", f"      for Lane in {idx} loop Data (Start + Lane) := Value.Lanes (Lane); end loop;", "   end Store_Unaligned;", f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;", f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} is", "      Result : " + vector + " := Zero;", "   begin", "      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;", "      return Result;", "   end Load_Partial;", f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is", "   begin", "      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;", "   end Store_Partial;", ""]
    return out


def emit_float_body(vector: str, scalar: str, bits: int, lanes: int) -> list[str]:
    idx = lane_index(bits, lanes)
    vals = lane_values(vector)
    mask = mask_for(bits, lanes)
    count = lane_count(bits, lanes)
    arr = array_name(scalar)
    storage = "Interfaces.Unsigned_8"
    uint = f"U{bits}"
    sign = f"2 ** {bits - 1}"
    exponent = "16#7F80_0000#" if bits == 32 else "16#7FF0_0000_0000_0000#"
    fraction = "16#007F_FFFF#" if bits == 32 else "16#000F_FFFF_FFFF_FFFF#"
    quiet = "16#0040_0000#" if bits == 32 else "16#0008_0000_0000_0000#"
    out = [
        f"   function Bits_Of_{scalar} is new Ada.Unchecked_Conversion ({scalar}, {uint});",
        f"   function {scalar}_Of_Bits is new Ada.Unchecked_Conversion ({uint}, {scalar});",
        f"   function Is_Signaling_NaN (Value : {scalar}) return Boolean is",
        f"      Bits : constant {uint} := Bits_Of_{scalar} (Value);",
        "   begin",
        f"      return (Bits and {exponent}) = {exponent}",
        f"        and then (Bits and {fraction}) /= 0",
        f"        and then (Bits and {quiet}) = 0;",
        "   end Is_Signaling_NaN;",
        f"   function Quiet_NaN (Value : {scalar}) return {scalar} is",
        f"     ({scalar}_Of_Bits (Bits_Of_{scalar} (Value) or {quiet}));",
        f"   function Zero return {vector} is (Lanes => [others => 0.0]);",
        f"   function Splat (Value : {scalar}) return {vector} is (Lanes => [others => Value]);",
        f"   function From_Lanes (Values : {vals}) return {vector} is (Lanes => Values);",
        f"   function To_Lanes (Value : {vector}) return {vals} is (Value.Lanes);",
        f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar} is (Value.Lanes (Lane));",
        f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector} is",
        f"      Result : {vector} := Value;",
        "   begin Result.Lanes (Lane) := With_Value; return Result; end Replace;",
    ]
    out += emit_two_source_lane_permute(vector, bits, lanes)
    out += emit_lane_permute(vector, bits, lanes)
    out += emit_compress_expand(vector, bits, lanes)
    for name, op in (("Add", "+"), ("Subtract", "-"), ("Multiply", "*"), ("Divide", "/")):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Left.Lanes (Lane) {op} Right.Lanes (Lane); end loop;", "      return Result;", f"   end {name};"]
    out += [f"   function Compare_{vector} (Left, Right : {vector}; Kind : Character) return {mask} is", f"      Bits : {storage} := 0;", "      Truth : Boolean;", "   begin", f"      for Lane in {idx} loop", "         case Kind is", "            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);", "            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);", "            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);", "            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);", "            when 'G' => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);", "            when others => Truth := Left.Lanes (Lane) /= Left.Lanes (Lane) or else Right.Lanes (Lane) /= Right.Lanes (Lane);", "         end case;", f"         if Truth then Bits := Bits or Interfaces.Shift_Left ({storage}'(1), Lane); end if;", "      end loop;", "      return (Bits => Bits);", f"   end Compare_{vector};"]
    for name, kind in (("Equal", "="), ("Less_Than", "<"), ("Less_Equal", "L"), ("Greater_Than", ">"), ("Greater_Equal", "G"), ("Unordered", "U")):
        out.append(f"   function {name} (Left, Right : {vector}) return {mask} is (Compare_{vector} (Left, Right, '{kind}'));")
    out += [f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;", "      return Result;", "   end Select_Value;"]
    for name, choose in (("Min_Number", "<"), ("Max_Number", ">")):
        zero_choice = (f"(if (Bits_Of_{scalar} (Left.Lanes (Lane)) and {sign}) /= 0 then Left.Lanes (Lane) else Right.Lanes (Lane))" if name == "Min_Number" else f"(if (Bits_Of_{scalar} (Left.Lanes (Lane)) and {sign}) = 0 then Left.Lanes (Lane) else Right.Lanes (Lane))")
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop", "         if Is_Signaling_NaN (Left.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Left.Lanes (Lane));", "         elsif Is_Signaling_NaN (Right.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Right.Lanes (Lane));", "         elsif Left.Lanes (Lane) /= Left.Lanes (Lane) then Result.Lanes (Lane) := Right.Lanes (Lane);", "         elsif Right.Lanes (Lane) /= Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);", f"         elsif Left.Lanes (Lane) = 0.0 and then Right.Lanes (Lane) = 0.0 then Result.Lanes (Lane) := {zero_choice};", f"         elsif Left.Lanes (Lane) {choose} Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);", "         else Result.Lanes (Lane) := Right.Lanes (Lane); end if;", "      end loop;", "      return Result;", f"   end {name};"]
    out += [f"   function Reduce_Add (Value : {vector}) return {scalar} is", f"      Result : {scalar} := 0.0;", "   begin", f"      for Lane in {idx} loop Result := Result + Value.Lanes (Lane); end loop;", "      return Result;", "   end Reduce_Add;"]
    for name in ("Min_Number", "Max_Number"):
        reduce_name = f"Reduce_{name}"
        out += [
            f"   function {reduce_name} (Value : {vector}) return {scalar} is",
            f"      Result : {vector} := Splat (Value.Lanes (0));",
            "   begin",
            f"      for Lane in {idx} range 1 .. {lanes - 1} loop",
            f"         Result := {name} (Result, Splat (Value.Lanes (Lane)));",
            "      end loop;",
            "      return Result.Lanes (0);",
            f"   end {reduce_name};",
        ]
    out += [f"   function Reverse_Lanes (Value : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Value.Lanes ({lanes - 1} - Lane); end loop;", "      return Result;", "   end Reverse_Lanes;"]
    for name, offset in (("Interleave_Low", 0), ("Interleave_High", lanes // 2)):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in Natural range 0 .. {lanes // 2 - 1} loop Result.Lanes (2 * Lane) := Left.Lanes (Lane + {offset}); Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + {offset}); end loop;", "      return Result;", f"   end {name};"]
    for name, parity in (("Deinterleave_Even", 0), ("Deinterleave_Odd", 1)):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in Natural range 0 .. {lanes // 2 - 1} loop Result.Lanes (Lane) := Left.Lanes (2 * Lane + {parity}); Result.Lanes (Lane + {lanes // 2}) := Right.Lanes (2 * Lane + {parity}); end loop;", "      return Result;", f"   end {name};"]
    out += emit_lane_slides(vector, idx, lanes)
    out += [f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);", f"   function Load (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store;", f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Data (Start + Lane); end loop;", "      return Result;", "   end Load_Unaligned;", f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin for Lane in {idx} loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end Store_Unaligned;", f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;", f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} is", f"      Result : {vector} := Zero;", "   begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if; return Result; end Load_Partial;", f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if; end Store_Partial;", ""]
    return out


def emit_conversion_body() -> str:
    """Emit the scalar authority for explicit bit and width conversions."""
    out: list[str] = []
    vector_shape = {
        vector: (bits, lanes)
        for vector, _, bits, lanes, *_ in INTEGER_TYPES + FLOAT_TYPES
    }
    vector_shape["U8x16"] = (8, 16)

    for source_vector, source_scalar, target_vector, target_scalar in bit_cast_pairs():
        bits, lanes = vector_shape[source_vector]
        helper = f"Cast_{source_scalar}_To_{target_scalar}_For_{source_vector}"
        out += [
            f"   function {helper} is new Ada.Unchecked_Conversion ({source_scalar}, {target_scalar});",
            f"   function Bit_Cast (Value : {source_vector}) return {target_vector} is",
            f"      Result : {target_vector};",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Result.Lanes (Lane) := {helper} (Value.Lanes (Lane));",
            "      end loop;",
            "      return Result;",
            "   end Bit_Cast;",
            "",
        ]

    for source_vector, source_scalar, target_vector, target_scalar, _, result_lanes in WIDENINGS:
        source_lanes = result_lanes * 2
        for name, offset in (("Widen_Low", 0), ("Widen_High", result_lanes)):
            out += [
                f"   function {name} (Value : {source_vector}) return {target_vector} is",
                f"      Result : {target_vector};",
                "   begin",
                f"      for Lane in Natural range 0 .. {result_lanes - 1} loop",
                f"         Result.Lanes (Lane) := {target_scalar} (Value.Lanes (Lane + {offset}));",
                "      end loop;",
                "      return Result;",
                f"   end {name};",
                "",
            ]
        assert source_lanes == vector_shape[source_vector][1]

    for source_vector, source_scalar, target_vector, target_scalar, result_lanes in FLOAT_WIDENINGS:
        for name, offset in (("Widen_Low", 0), ("Widen_High", result_lanes)):
            out += [
                f"   function {name} (Value : {source_vector}) return {target_vector} is",
                f"      Result : {target_vector};",
                "   begin",
                f"      for Lane in Natural range 0 .. {result_lanes - 1} loop",
                f"         Result.Lanes (Lane) := {target_scalar} (Value.Lanes (Lane + {offset}));",
                "      end loop;",
                "      return Result;",
                f"   end {name};",
                "",
            ]

    for source_vector, _, target_vector, target_scalar, source_lanes in FLOAT_NARROWINGS:
        out += [
            f"   function Narrow_Round (Low, High : {source_vector}) return {target_vector} is",
            f"      Result : {target_vector};",
            "   begin",
            f"      for Lane in Natural range 0 .. {source_lanes - 1} loop",
            f"         Result.Lanes (Lane) := {target_scalar} (Low.Lanes (Lane));",
            f"         Result.Lanes (Lane + {source_lanes}) := {target_scalar} (High.Lanes (Lane));",
            "      end loop;",
            "      return Result;",
            "   end Narrow_Round;",
            "",
        ]

    for source_vector, _, target_vector, target_scalar, _, source_lanes, _ in INTEGER_TO_FLOAT_CONVERSIONS:
        out += [
            f"   function Convert_Round (Value : {source_vector}) return {target_vector} is",
            f"      Result : {target_vector};",
            "   begin",
            f"      for Lane in Natural range 0 .. {source_lanes - 1} loop",
            f"         Result.Lanes (Lane) := {target_scalar} (Value.Lanes (Lane));",
            "      end loop;",
            "      return Result;",
            "   end Convert_Round;",
            "",
        ]

    for source_vector, source_scalar, target_vector, target_scalar, bits, source_lanes, signed in FLOAT_TO_INTEGER_CONVERSIONS:
        helper = f"Convert_Truncate_Saturate_{source_scalar}_To_{target_scalar}_Lane"
        upper = f"2.0 ** {bits - 1 if signed else bits}"
        out += [
            f"   function {helper} (Value : {source_scalar}) return {target_scalar} is",
            f"      Upper : constant {source_scalar} := {upper};",
        ]
        if signed:
            out.append(f"      Lower : constant {source_scalar} := -Upper;")
        out += [
            "   begin",
            "      if Value /= Value then",
            "         return 0;",
        ]
        if signed:
            out += [
                "      elsif Value >= Upper then",
                f"         return {target_scalar}'Last;",
                "      elsif Value <= Lower then",
                f"         return {target_scalar}'First;",
            ]
        else:
            out += [
                "      elsif Value <= 0.0 then",
                "         return 0;",
                "      elsif Value >= Upper then",
                f"         return {target_scalar}'Last;",
            ]
        out += [
            "      else",
            f"         return {target_scalar} ({source_scalar}'Truncation (Value));",
            "      end if;",
            f"   end {helper};",
            "",
            f"   function Convert_Truncate_Saturate (Value : {source_vector}) return {target_vector} is",
            f"      Result : {target_vector};",
            "   begin",
            f"      for Lane in Natural range 0 .. {source_lanes - 1} loop",
            f"         Result.Lanes (Lane) := {helper} (Value.Lanes (Lane));",
            "      end loop;",
            "      return Result;",
            "   end Convert_Truncate_Saturate;",
            "",
        ]

    for source_vector, source_scalar, target_vector, target_scalar, _, source_lanes, signed in SIGNED_UNSIGNED_CONVERSIONS:
        helper = f"Convert_Saturate_{source_scalar}_To_{target_scalar}_Lane"
        expression = (
            f"(if Value < 0 then 0 else {target_scalar} (Value))"
            if signed
            else f"(if Value > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last else {target_scalar} (Value))"
        )
        out += [
            f"   function {helper} (Value : {source_scalar}) return {target_scalar} is {expression};",
            f"   function Convert_Saturate (Value : {source_vector}) return {target_vector} is",
            f"      Result : {target_vector};",
            "   begin",
            f"      for Lane in Natural range 0 .. {source_lanes - 1} loop",
            f"         Result.Lanes (Lane) := {helper} (Value.Lanes (Lane));",
            "      end loop;",
            "      return Result;",
            "   end Convert_Saturate;",
            "",
        ]

    for source_vector, source_scalar, target_vector, target_scalar, target_bits, source_lanes, signed in NARROWINGS:
        source_bits = target_bits * 2
        unsigned_source = f"U{source_bits}"
        unsigned_target = f"U{target_bits}"
        if signed:
            to_unsigned = f"Narrow_Bits_Of_{source_scalar}"
            to_signed = f"Narrow_{target_scalar}_Of_Bits"
            out += [
                f"   function {to_unsigned} is new Ada.Unchecked_Conversion ({source_scalar}, {unsigned_source});",
                f"   function {to_signed} is new Ada.Unchecked_Conversion ({unsigned_target}, {target_scalar});",
            ]
            truncate = (
                f"{to_signed} ({unsigned_target} ({to_unsigned} (Item) and "
                f"{unsigned_source} ({unsigned_target}'Last)))"
            )
            saturate = (
                f"(if Item < {source_scalar} ({target_scalar}'First) then {target_scalar}'First "
                f"elsif Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last "
                f"else {target_scalar} (Item))"
            )
        else:
            truncate = (
                f"{target_scalar} (Item and {source_scalar} ({target_scalar}'Last))"
            )
            saturate = (
                f"(if Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last "
                f"else {target_scalar} (Item))"
            )
        for name, expression in (("Narrow_Truncate", truncate), ("Narrow_Saturate", saturate)):
            helper = f"{name}_{source_vector}_Lane"
            out += [
                f"   function {helper} (Item : {source_scalar}) return {target_scalar} is",
                f"     ({expression});",
                f"   function {name} (Low, High : {source_vector}) return {target_vector} is",
                f"      Result : {target_vector};",
                "   begin",
                f"      for Lane in Natural range 0 .. {source_lanes - 1} loop",
                f"         Result.Lanes (Lane) := {helper} (Low.Lanes (Lane));",
                f"         Result.Lanes (Lane + {source_lanes}) := {helper} (High.Lanes (Lane));",
                "      end loop;",
                "      return Result;",
                f"   end {name};",
                "",
            ]

    for source_vector, source_scalar, target_vector, target_scalar, _, source_lanes, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        helper = f"Narrow_Saturate_{source_vector}_To_{target_vector}_Lane"
        out += [
            f"   function {helper} (Item : {source_scalar}) return {target_scalar} is",
            f"     (if Item < 0 then 0 elsif Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last else {target_scalar} (Item));",
            f"   function Narrow_Saturate (Low, High : {source_vector}) return {target_vector} is",
            f"      Result : {target_vector};",
            "   begin",
            f"      for Lane in Natural range 0 .. {source_lanes - 1} loop",
            f"         Result.Lanes (Lane) := {helper} (Low.Lanes (Lane));",
            f"         Result.Lanes (Lane + {source_lanes}) := {helper} (High.Lanes (Lane));",
            "      end loop;",
            "      return Result;",
            "   end Narrow_Saturate;",
            "",
        ]

    return "\n".join(out)


def emit_body() -> str:
    out = [emit_conversion_body()]
    seen_shapes = {(8, 16)}
    for _, _, bits, lanes, *_ in INTEGER_TYPES + FLOAT_TYPES:
        if (bits, lanes) not in seen_shapes:
            out += emit_lane_map(bits, lanes)
            out += emit_two_source_lane_selectors(bits, lanes)
            seen_shapes.add((bits, lanes))
    for item in INTEGER_TYPES:
        out += emit_integer_body(*item)
    for item in FLOAT_TYPES:
        out += emit_float_body(*item)
    for bits, lanes, storage in MASKS:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        count = lane_count(bits, lanes)
        st = f"Interfaces.{storage}"
        full = str((1 << lanes) - 1)
        out += [f"   function Mask_From_Bit_Mask (Bits : {st}) return {mask} is (Bits => Bits and {full});", f"   function To_Bit_Mask (Mask : {mask}) return {st} is (Mask.Bits);", f"   function Mask_And (Left, Right : {mask}) return {mask} is (Bits => Left.Bits and Right.Bits);", f"   function Mask_Or (Left, Right : {mask}) return {mask} is (Bits => Left.Bits or Right.Bits);", f"   function Mask_Xor (Left, Right : {mask}) return {mask} is (Bits => Left.Bits xor Right.Bits);", f"   function Mask_Not (Value : {mask}) return {mask} is (Bits => (not Value.Bits) and {full});", f"   function Test (Mask : {mask}; Lane : {idx}) return Boolean is ((Mask.Bits and Interfaces.Shift_Left ({st}'(1), Lane)) /= 0);", f"   function Any_True (Mask : {mask}) return Boolean is (Mask.Bits /= 0);", f"   function All_True (Mask : {mask}) return Boolean is (Mask.Bits = {full});", f"   function None_True (Mask : {mask}) return Boolean is (Mask.Bits = 0);", f"   function Population_Count (Mask : {mask}) return {count} is", f"      Bits : {st} := Mask.Bits;", f"      Result : {count} := 0;", "   begin while Bits /= 0 loop Result := Result + 1; Bits := Bits and (Bits - 1); end loop; return Result; end Population_Count;", f"   function First_True (Mask : {mask}) return {count} is", f"   begin for Lane in {idx} loop if Test (Mask, Lane) then return Lane; end if; end loop; return {count}'Last; end First_True;", f"   function Last_True (Mask : {mask}) return {count} is", f"   begin for Lane in reverse {idx} loop if Test (Mask, Lane) then return Lane; end if; end loop; return {count}'Last; end Last_True;", ""]
    return "\n".join(out)


def main() -> None:
    spec = strip_generated_docs(SPEC.read_text())
    spec = replace_block(spec, "GENERATED 128-BIT FAMILIES", emit_spec())
    spec = replace_block(spec, "GENERATED 128-BIT REPRESENTATIONS", emit_private())
    spec = document_spec(spec)
    SPEC.write_text(spec)

    body = BODY.read_text()
    body = replace_block(body, "GENERATED 128-BIT SCALAR BODIES", emit_body())
    BODY.write_text(body)


if __name__ == "__main__":
    main()
