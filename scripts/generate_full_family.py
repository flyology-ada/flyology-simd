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
    "Min": "Return the smaller integer in each lane.",
    "Max": "Return the larger integer in each lane.",
    "Min_Number": "Return the floating number minimum with the documented NaN and signed-zero rules.",
    "Max_Number": "Return the floating number maximum with the documented NaN and signed-zero rules.",
    "Reduce_Add_Wrap": "Add all integer lanes modulo the lane width in ascending lane order.",
    "Reduce_Min": "Return the smallest integer lane.",
    "Reduce_Max": "Return the largest integer lane.",
    "Reduce_Add": "Add all floating lanes in ascending lane order.",
    "Reduce_Min_Number": "Apply Min_Number to all floating lanes in ascending lane order.",
    "Reduce_Max_Number": "Apply Max_Number to all floating lanes in ascending lane order.",
    "Reverse_Lanes": "Reverse logical lane order.",
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
        "With the default round-to-nearest, ties-to-even environment, round "
        "Low into result lanes zero and one and High into lanes two and three. "
        "Signed zero and infinity are preserved. Overflow after rounding "
        "produces infinity. Gradual underflow can produce a subnormal, and a "
        "sufficiently small magnitude rounds to signed zero. A NaN remains a "
        "NaN, but its payload and signaling state are unspecified. The operation "
        "does not modify the floating-point control register."
    ),
    "Convert_Round": (
        "With the default round-to-nearest, ties-to-even environment, convert "
        "each integer lane to the corresponding floating-point lane. The "
        "operation does not modify the floating-point control register."
    ),
    "Convert_Truncate_Saturate": (
        "Truncate each floating-point lane toward zero, then clamp it to the "
        "integer result range. A NaN becomes zero. The operation does not "
        "depend on or modify the floating-point rounding mode."
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

PARAM_DOCS = {
    "Value": "The input value.",
    "Values": "Lane values in logical lane order.",
    "Left": "The left input.",
    "Right": "The right input.",
    "Lane": "The logical lane index.",
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


def document_spec(text: str) -> str:
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
            index + 1 < len(lines) and lines[index + 1].startswith("   --")
        )
        if not has_trailing_doc:
            if kind in ("type", "subtype"):
                documented.append(f"   --  Public lane, array, vector, or mask type {name}.")
            else:
                declaration_text = " ".join(declaration)
                if name == "Convert_Saturate":
                    summary = (
                        CONVERT_SATURATE_SIGNED_DOC
                        if "Value : I" in declaration_text
                        else CONVERT_SATURATE_UNSIGNED_DOC
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
                    documented.append("   --  @return The operation result.")
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
        if stripped.startswith("Public lane, array, vector, or mask type "):
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
            f"   function Min (Left, Right : {vector}) return {vector};",
            f"   function Max (Left, Right : {vector}) return {vector};",
            f"   function Reduce_Add_Wrap (Value : {vector}) return {scalar};",
            f"   function Reduce_Min (Value : {vector}) return {scalar};",
            f"   function Reduce_Max (Value : {vector}) return {scalar};",
            f"   function Reverse_Lanes (Value : {vector}) return {vector};",
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
            f"   function Min_Number (Left, Right : {vector}) return {vector};",
            f"   function Max_Number (Left, Right : {vector}) return {vector};",
            f"   function Reduce_Add (Value : {vector}) return {scalar};",
            f"   function Reduce_Min_Number (Value : {vector}) return {scalar};",
            f"   function Reduce_Max_Number (Value : {vector}) return {scalar};",
            f"   function Reverse_Lanes (Value : {vector}) return {vector};",
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
    for vector, _, _, _, *_ in INTEGER_TYPES + FLOAT_TYPES:
        out += [
            f"   type {vector} is record",
            f"      Lanes : {lane_values(vector)};",
            "   end record;",
            f"   for {vector}'Size use 128;",
            "",
        ]
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
