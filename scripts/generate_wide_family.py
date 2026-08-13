#!/usr/bin/env python3
"""Generate the portable 256-bit value family and pair-composed backend."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re

from generate_full_family import (
    FLOAT_NARROWINGS,
    FLOAT_TO_INTEGER_CONVERSIONS,
    FLOAT_WIDENINGS,
    INTEGER_TO_FLOAT_CONVERSIONS,
    NARROWINGS,
    SIGNED_TO_UNSIGNED_NARROWINGS,
    SIGNED_UNSIGNED_CONVERSIONS,
    WIDENINGS,
)
from generate_backends import x86_float_minmax_instruction


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "src" / "flyology_simd-wide.ads"
BODY = ROOT / "src" / "flyology_simd-wide.adb"
NATIVE_SPEC = ROOT / "src" / "flyology_simd-wide-native.ads"
NATIVE_BODY = ROOT / "src" / "flyology_simd-wide-native.adb"
COMPACT_SPEC = ROOT / "src" / "flyology_simd-wide-compact_mechanism.ads"
COMPACT_AARCH64 = ROOT / "src" / "wide" / "aarch64" / "flyology_simd-wide-compact_mechanism.adb"
COMPACT_COMPOSED = ROOT / "src" / "wide" / "composed" / "flyology_simd-wide-compact_mechanism.adb"
COMPACT_AVX2 = ROOT / "src" / "wide" / "avx2" / "flyology_simd-wide-compact_mechanism.adb"
COMPACT_INVALID = ROOT / "src" / "wide" / "invalid" / "flyology_simd-wide-compact_mechanism.adb"
PERMUTE_SPEC = ROOT / "src" / "flyology_simd-wide-permute_mechanism.ads"
PERMUTE_AARCH64 = ROOT / "src" / "wide" / "aarch64" / "flyology_simd-wide-permute_mechanism.adb"
PERMUTE_COMPOSED = ROOT / "src" / "wide" / "composed" / "flyology_simd-wide-permute_mechanism.adb"
PERMUTE_AVX2 = ROOT / "src" / "wide" / "avx2" / "flyology_simd-wide-permute_mechanism.adb"
PERMUTE_INVALID = ROOT / "src" / "wide" / "invalid" / "flyology_simd-wide-permute_mechanism.adb"
FLOAT_REDUCE_SPEC = ROOT / "src" / "flyology_simd-wide-float_reduce_mechanism.ads"
FLOAT_REDUCE_AARCH64 = ROOT / "src" / "wide" / "aarch64" / "flyology_simd-wide-float_reduce_mechanism.adb"
FLOAT_REDUCE_COMPOSED = ROOT / "src" / "wide" / "composed" / "flyology_simd-wide-float_reduce_mechanism.adb"
FLOAT_REDUCE_AVX2 = ROOT / "src" / "wide" / "avx2" / "flyology_simd-wide-float_reduce_mechanism.adb"
FLOAT_REDUCE_INVALID = ROOT / "src" / "wide" / "invalid" / "flyology_simd-wide-float_reduce_mechanism.adb"
FLOAT_ARITH_SPEC = ROOT / "src" / "flyology_simd-wide-float_arithmetic_mechanism.ads"
FLOAT_ARITH_AARCH64 = ROOT / "src" / "wide" / "aarch64" / "flyology_simd-wide-float_arithmetic_mechanism.adb"
FLOAT_ARITH_COMPOSED = ROOT / "src" / "wide" / "composed" / "flyology_simd-wide-float_arithmetic_mechanism.adb"
FLOAT_ARITH_AVX2 = ROOT / "src" / "wide" / "avx2" / "flyology_simd-wide-float_arithmetic_mechanism.adb"
FLOAT_ARITH_INVALID = ROOT / "src" / "wide" / "invalid" / "flyology_simd-wide-float_arithmetic_mechanism.adb"
FLOAT_ARITH_AVX2_LEAF_SPEC = ROOT / "src" / "wide" / "avx2" / "flyology_simd-wide-float_avx2_leaf.ads"
FLOAT_ARITH_AVX2_LEAF_BODY = ROOT / "src" / "wide" / "avx2" / "flyology_simd-wide-float_avx2_leaf.adb"


@dataclass(frozen=True)
class Family:
    vector: str
    half: str
    scalar: str
    bits: int
    lanes: int
    signed: bool = False
    floating: bool = False

    @property
    def half_lanes(self) -> int:
        return self.lanes // 2

    @property
    def index(self) -> str:
        return f"Lane_Index_{self.bits}x{self.lanes}"

    @property
    def count(self) -> str:
        return f"Lane_Count_{self.bits}x{self.lanes}"

    @property
    def values(self) -> str:
        suffix = self.vector.removesuffix(str(self.lanes))
        return f"Lane_Values_{suffix}{self.lanes}"

    @property
    def mask(self) -> str:
        return f"Mask_{self.bits}x{self.lanes}"

    @property
    def half_mask(self) -> str:
        return f"Mask_{self.bits}x{self.half_lanes}"

    @property
    def mask_bits(self) -> str:
        return f"Mask_Bits_{self.bits}x{self.lanes}"

    @property
    def selectors(self) -> str:
        return f"Lane_Selectors_{self.bits}x{self.lanes}"

    @property
    def lane_map(self) -> str:
        return f"Lane_Map_{self.bits}x{self.lanes}"

    @property
    def two_selector(self) -> str:
        return f"Two_Source_Lane_Selector_{self.bits}x{self.lanes}"

    @property
    def two_selectors(self) -> str:
        return f"Two_Source_Lane_Selectors_{self.bits}x{self.lanes}"

    @property
    def two_map(self) -> str:
        return f"Two_Source_Lane_Map_{self.bits}x{self.lanes}"

    @property
    def array(self) -> str:
        return "Byte_Array" if self.scalar == "U8" else f"{self.scalar}_Array"


FAMILIES = [
    Family("U8x32", "U8x16", "U8", 8, 32),
    Family("I8x32", "I8x16", "I8", 8, 32, signed=True),
    Family("U16x16", "U16x8", "U16", 16, 16),
    Family("I16x16", "I16x8", "I16", 16, 16, signed=True),
    Family("U32x8", "U32x4", "U32", 32, 8),
    Family("I32x8", "I32x4", "I32", 32, 8, signed=True),
    Family("U64x4", "U64x2", "U64", 64, 4),
    Family("I64x4", "I64x2", "I64", 64, 4, signed=True),
    Family("F32x8", "F32x4", "F32", 32, 8, floating=True),
    Family("F64x4", "F64x2", "F64", 64, 4, floating=True),
]

BY_VECTOR = {family.vector: family for family in FAMILIES}
BY_HALF = {family.half: family for family in FAMILIES}

BIT_CAST_TARGETS = {
    "U8x32": ("I8x32",), "I8x32": ("U8x32",),
    "U16x16": ("I16x16",), "I16x16": ("U16x16",),
    "U32x8": ("I32x8", "F32x8"),
    "I32x8": ("U32x8", "F32x8"),
    "F32x8": ("U32x8", "I32x8"),
    "U64x4": ("I64x4", "F64x4"),
    "I64x4": ("U64x4", "F64x4"),
    "F64x4": ("U64x4", "I64x4"),
}

WIDE_PORTABLE_SUPPORT = (
    "Cross-platform support: portable scalar semantics are available on every "
    "supported GNAT target. Use the matching Wide.Native overload for "
    "statically selected target lowering."
)

WIDE_NATIVE_SUPPORT = ""


def wide_native_support(summary: str, declaration: str = "") -> str:
    """Describe the verified Wide.Native implementation class."""
    match = re.match(r"   (?:function|procedure)\s+([A-Za-z0-9_]+)", declaration)
    operation = match.group(1) if match else ""
    if operation in {
        "Reverse_Lanes", "Slide_Lanes_Toward_Low", "Slide_Lanes_Toward_High",
    }:
        return (
            "Cross-platform support: The AArch64 backend derives a 32-byte "
            "index map and runs one two-register NEON tbl operation for each "
            "result half. The composed x86-64 backend calls the Wide scalar "
            "implementation. The optional AVX2 backend derives a 32-byte "
            "index map and uses two vpshufb instructions, one vperm2i128 "
            "instruction, mask selection, and vzeroupper. In a scalar build, "
            "this overload calls the portable Wide implementation."
        )
    if operation in {
        "Interleave_Low", "Interleave_High", "Deinterleave_Even",
        "Deinterleave_Odd",
    }:
        return (
            "Cross-platform support: The AArch64 backend derives a 32-byte "
            "index map and runs one four-register NEON tbl operation for each "
            "result half. The composed x86-64 backend calls the Wide scalar "
            "implementation. The optional AVX2 backend derives a 32-byte "
            "index map and uses four vpshufb instructions, two vperm2i128 "
            "instructions, mask selection, and vzeroupper. In a scalar build, "
            "this overload calls the portable Wide implementation."
        )
    if summary.startswith("Select each result lane through"):
        return (
            "Cross-platform support: The AArch64 backend derives a 32-byte "
            "index map and runs one two-register NEON tbl operation for each "
            "result half. The composed x86-64 backend calls the Wide scalar "
            "implementation. The optional AVX2 backend derives a 32-byte index "
            "map and uses two vpshufb instructions, one vperm2i128 instruction, "
            "mask selection, and vzeroupper. In a scalar build, this overload "
            "calls the portable Wide implementation."
        )
    elif summary.startswith("Select each result lane from one lane of either"):
        return (
            "Cross-platform support: The AArch64 backend derives a 32-byte "
            "index map and runs one four-register NEON tbl operation for each "
            "result half. The composed x86-64 backend calls the Wide scalar "
            "implementation. The optional AVX2 backend derives a 32-byte index "
            "map and uses four vpshufb instructions, two vperm2i128 "
            "instructions, mask selection, and vzeroupper. In a scalar build, "
            "this overload calls the portable Wide implementation."
        )
    elif summary.startswith("Stably pack") or summary.startswith("Place consecutive"):
        mechanism = (
            "AArch64 derives a byte map and uses two-register NEON tbl for each "
            "result half; x86-64 uses the Wide scalar implementation"
        )
    elif summary.startswith("Select each result byte"):
        mechanism = (
            "AArch64 uses two-register NEON tbl for each result half; the "
            "x86-64 composed selection calls the Wide scalar implementation, "
            "and the optional AVX2 selection uses a dedicated U8x32 implementation"
        )
    elif operation in {
            "Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate",
            "Subtract_Saturate", "Bitwise_And", "Bitwise_Or", "Bitwise_Xor",
            "Min", "Max", "Equal", "Less_Than", "Less_Equal",
            "Greater_Than", "Greater_Equal",
        } or operation in {"Bitwise_Not", "Select_Value"}:
        byte_shape = "U8x32" in declaration or "I8x32" in declaration
        mechanism = (
            "AArch64 runs the selected 128-bit operation on both private "
            "parts; x86-64 does the same by default, and the optional AVX2 "
            "build uses a dedicated 256-bit implementation"
            if byte_shape else
            "AArch64 and x86-64 run the selected 128-bit operation on both "
            "private parts"
        )
    elif operation in {
        "Shift_Left_Logical", "Shift_Right_Logical", "Shift_Right_Arithmetic",
        "Unordered", "Bit_Cast", "Load", "Store",
        "Load_Unaligned", "Store_Unaligned", "Load_Aligned", "Store_Aligned",
        "Horizontal_Sum", "Widen_Low", "Widen_High", "Narrow_Truncate",
        "Narrow_Saturate", "Narrow_Round", "Convert_Round",
        "Convert_Truncate_Saturate", "Convert_Saturate",
    }:
        mechanism = (
            "AArch64 and x86-64 run the selected 128-bit operation on both "
            "private parts"
        )
    elif operation in {
        "Zero", "Splat", "From_Lanes", "To_Lanes",
        "Mask_From_Bit_Mask", "To_Bit_Mask", "Mask_And", "Mask_Or",
        "Mask_Xor", "Mask_Not", "Any_True", "All_True",
        "None_True",
    }:
        mechanism = (
            "AArch64 and x86-64 call the selected 128-bit operation on each "
            "private part and combine the results in Ada"
        )
    elif operation in {"First_True", "Last_True"}:
        if operation == "First_True":
            mechanism = (
                "AArch64 and x86-64 query both private parts with the selected "
                "128-bit mask-position operation. They return a valid low-part "
                "result first. Otherwise, they return a valid high-part result "
                "plus the private lane count. If neither part contains a true "
                "lane, they return the Wide lane-count value"
            )
        else:
            mechanism = (
                "AArch64 and x86-64 query both private parts with the selected "
                "128-bit mask-position operation. They return a valid high-part "
                "result plus the private lane count first. Otherwise, they "
                "return a valid low-part result. If neither part contains a "
                "true lane, they return the Wide lane-count value"
            )
    elif operation == "Population_Count":
        mechanism = (
            "AArch64 and x86-64 call the selected 128-bit population-count "
            "operation on both private parts and add the two counts"
        )
    elif operation in {"Extract", "Replace", "Test"}:
        mechanism = (
            "AArch64 and x86-64 call the selected 128-bit operation only on "
            "the private part that contains the requested lane"
        )
    elif operation in {"Add", "Subtract", "Multiply", "Divide"}:
        precision = "ps" if "F32x8" in declaration else "pd"
        instruction = {
            "Add": f"vadd{precision}",
            "Subtract": f"vsub{precision}",
            "Multiply": f"vmul{precision}",
            "Divide": f"vdiv{precision}",
        }[operation]
        return (
            "Cross-platform support: The AArch64 backend and the composed "
            "x86-64 backend run the selected 128-bit operation on both private "
            "parts. The optional AVX2 backend uses one isolated 256-bit "
            f"{instruction} operation and vzeroupper. In a scalar build, this "
            "overload calls the portable Wide implementation."
        )
    elif operation in {"Min_Number", "Max_Number"}:
        return (
            "Cross-platform support: The AArch64 backend and the composed "
            "x86-64 backend run the selected 128-bit operation on both private "
            "parts. The optional AVX2 backend uses one isolated 256-bit "
            "integer-classification and bit-selection sequence. The sequence "
            "preserves the documented NaN and signed-zero rules. Each leaf "
            "ends with vzeroupper. "
            "In a scalar build, this overload calls the portable Wide "
            "implementation."
        )
    elif operation == "Is_Aligned_32":
        mechanism = (
            "AArch64 and x86-64 first check that Start is in the array range. "
            "For a valid Start, they test the selected element address modulo "
            "32 directly with fixed-width Ada code"
        )
    elif operation in {"Load_Partial", "Store_Partial"}:
        mechanism = (
            "AArch64 and x86-64 conditionally compose selected 128-bit full "
            "and partial memory operations"
        )
    elif operation in {"Reduce_Add_Wrap", "Reduce_Min", "Reduce_Max"}:
        combine = {
            "Reduce_Add_Wrap": "Add_Wrap",
            "Reduce_Min": "Min",
            "Reduce_Max": "Max",
        }[operation]
        mechanism = (
            "AArch64 and x86-64 reduce each private part with the selected "
            f"128-bit {operation} operation, combine the two results with "
            f"the selected 128-bit {combine} operation, and extract lane zero"
        )
    elif operation in {
        "Reduce_Add", "Reduce_Min_Number", "Reduce_Max_Number",
    }:
        if operation == "Reduce_Add":
            mechanism = (
                "AArch64 uses a dedicated ordered Advanced SIMD sequence "
                "that starts from positive zero and visits lanes in ascending "
                "order; x86-64 uses portable Ada composition"
            )
        else:
            instruction = "fminnm" if operation == "Reduce_Min_Number" else "fmaxnm"
            mechanism = (
                "AArch64 uses a dedicated ordered Advanced SIMD sequence with "
                f"scalar {instruction} operations that visits lanes in ascending "
                "order; x86-64 uses portable Ada composition"
            )
    else:
        mechanism = "AArch64 and x86-64 use portable Ada code"
    if "; x86-64 " in mechanism:
        aarch, x86 = mechanism.split("; x86-64 ", 1)
        mechanism_text = (
            f"The AArch64 backend {aarch.removeprefix('AArch64 ')}. "
            f"The x86-64 backend {x86}. "
        )
    elif mechanism.startswith("AArch64 and x86-64 "):
        action = mechanism.removeprefix("AArch64 and x86-64 ")
        mechanism_text = f"The AArch64 and x86-64 backends {action}. "
    else:
        mechanism_text = mechanism + ". "
    return (
        "Cross-platform support: " + mechanism_text
        + "A scalar build uses the portable Wide implementation."
    )


def wide_portable_support(summary: str, declaration: str) -> str:
    native = wide_native_support(summary, declaration).removeprefix(
        "Cross-platform support: "
    )
    native = native.replace(
        "In a scalar build, this overload calls the portable Wide implementation.",
        "In a scalar build, the matching Wide.Native overload calls the "
        "portable Wide implementation.",
    )
    if native.startswith("The "):
        native = "the " + native.removeprefix("The ")
    return (
        "Cross-platform support: This overload uses the portable scalar Wide "
        "implementation on every supported GNAT target. For the matching "
        f"Wide.Native overload, {native}"
    )


def mask_storage(family: Family) -> str:
    if family.lanes == 32:
        return "Interfaces.Unsigned_32"
    if family.lanes == 16:
        return "Interfaces.Unsigned_16"
    return "Interfaces.Unsigned_8"


def half_mask_storage(family: Family) -> str:
    if family.half_lanes == 16:
        return "Interfaces.Unsigned_16"
    return "Interfaces.Unsigned_8"


def doc(
    summary: str,
    params: tuple[str, ...] = (),
    returns: bool = True,
    support: str = "portable",
    declaration: str = "",
) -> str:
    support_doc = (
        wide_native_support(summary, declaration)
        if support == "native"
        else wide_portable_support(summary, declaration)
    )
    lines = [f"   --  {summary}", f"   --  {support_doc}"]
    for param in params:
        lines.append(f"   --  @param {param} The {param.lower().replace('_', ' ')} input.")
    if returns:
        lines.append("   --  @return The operation result.")
    return "\n".join(lines)


def contextualize_support(text: str) -> str:
    """Bind generated support text to the exact declaration and summary."""
    lines = text.splitlines()
    declaration_line = ""
    summary = ""
    for index, line in enumerate(lines):
        if line.startswith("   function ") or line.startswith("   procedure "):
            declaration_line = line
            summary = ""
        elif line.startswith("   --  ") and not line.startswith("   --  @"):
            content = line.removeprefix("   --  ")
            if content.startswith("Cross-platform support:"):
                lines[index] = f"   --  {wide_portable_support(summary, declaration_line)}"
            elif not summary:
                summary = content
    return "\n".join(lines)


def declaration(f: Family, first_shape: bool) -> str:
    binary_integer = (
        "Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate",
        "Subtract_Saturate", "Bitwise_And", "Bitwise_Or", "Bitwise_Xor",
        "Min", "Max",
    )
    binary_float = ("Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number")
    comparisons = ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal")
    movement = ("Interleave_Low", "Interleave_High", "Deinterleave_Even", "Deinterleave_Odd")
    out = []
    if first_shape:
        out += [
            f"   subtype {f.index} is Natural range 0 .. {f.lanes - 1};",
            f"   --  Logical lane indexes for {f.lanes}-lane vectors.",
            f"   subtype {f.count} is Natural range 0 .. {f.lanes};",
            f"   --  Counts from zero through the complete {f.lanes}-lane width.",
            f"   type {f.selectors} is array ({f.index}) of {f.index};",
            "   --  One source-lane selector for each result lane.",
            f"   type {f.lane_map} is private;",
            "   --  A reusable, validated mapping from result lanes to source lanes.",
            f"   function Make_Lane_Map (Selectors : {f.selectors}) return {f.lane_map};",
            doc("Build a reusable map from result lanes to source lanes.", ("Selectors",)),
            f"   type {f.two_selector} is private;",
            "   --  Select one lane from the left or right source vector.",
            f"   function Select_Left_Lane (Lane : {f.index}) return {f.two_selector};",
            doc("Construct a selector for one lane of the left input.", ("Lane",)),
            f"   function Select_Right_Lane (Lane : {f.index}) return {f.two_selector};",
            doc("Construct a selector for one lane of the right input.", ("Lane",)),
            f"   type {f.two_selectors} is array ({f.index}) of {f.two_selector};",
            "   --  One two-source selector for each result lane.",
            f"   type {f.two_map} is private;",
            "   --  A private, reusable result-lane to two-source-lane map.",
            f"   function Make_Two_Source_Lane_Map (Selectors : {f.two_selectors}) return {f.two_map};",
            doc("Build a reusable map from result lanes to lanes of two inputs.", ("Selectors",)),
            f"   type {f.mask} is private;",
            f"   --  One semantic Boolean truth for each of {f.lanes} lanes.",
            f"   subtype {f.mask_bits} is {mask_storage(f)} range 0 .. {(1 << f.lanes) - 1};",
            f"   --  Compact bits for exactly {f.lanes} mask lanes.",
        ]
    out += [
        f"   type {f.values} is array ({f.index}) of {f.scalar};",
        f"   --  {f.scalar} lane values in logical lane order.",
        f"   function Zero return {f.vector};",
        doc("Return a vector whose lanes are zero."),
        f"   function Splat (Value : {f.scalar}) return {f.vector};",
        doc("Return a vector whose lanes all contain Value.", ("Value",)),
        f"   function From_Lanes (Values : {f.values}) return {f.vector};",
        doc("Construct a vector in logical lane order.", ("Values",)),
        f"   function To_Lanes (Value : {f.vector}) return {f.values};",
        doc("Return all lanes in logical lane order.", ("Value",)),
        f"   function Extract (Value : {f.vector}; Lane : {f.index}) return {f.scalar};",
        doc("Return one logical lane.", ("Value", "Lane")),
        f"   function Replace (Value : {f.vector}; Lane : {f.index}; With_Value : {f.scalar}) return {f.vector};",
        doc("Return a copy with one lane replaced.", ("Value", "Lane", "With_Value")),
    ]
    if f.vector == "U8x32":
        out += [
            "   function Table_Lookup (Table, Indices : U8x32) return U8x32;",
            doc(
                "Select each result byte from the corresponding unsigned index. "
                "Indexes from 0 through 31 select that table lane; larger indexes produce zero.",
                ("Table", "Indices"),
            ),
        ]
    for target in BIT_CAST_TARGETS[f.vector]:
        out += [
            f"   function Bit_Cast (Value : {f.vector}) return {target};",
            doc("Reinterpret every lane bit pattern without changing lane position.", ("Value",)),
        ]
    for name in binary_float if f.floating else binary_integer:
        out += [f"   function {name} (Left, Right : {f.vector}) return {f.vector};",
                doc(f"Apply {name} independently to corresponding lanes.", ("Left", "Right"))]
    if not f.floating:
        out += [f"   function Bitwise_Not (Value : {f.vector}) return {f.vector};",
                doc("Complement every bit in every lane.", ("Value",))]
        for name in ("Shift_Left_Logical", "Shift_Right_Logical") + (("Shift_Right_Arithmetic",) if f.signed else ()):
            out += [f"   function {name} (Value : {f.vector}; Count : Natural) return {f.vector};",
                    doc("Shift every lane with the documented oversized-count result.", ("Value", "Count"))]
    for name in comparisons + (("Unordered",) if f.floating else ()):
        out += [f"   function {name} (Left, Right : {f.vector}) return {f.mask};",
                doc(f"Apply {name} independently to corresponding lanes.", ("Left", "Right"))]
    out += [
        f"   function Select_Value (Mask : {f.mask}; If_True, If_False : {f.vector}) return {f.vector};",
        doc("Select one input in each lane according to mask truth.", ("Mask", "If_True", "If_False")),
        f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector};",
        doc("Stably pack true-mask lanes toward lane zero and zero-fill the remainder.", ("Value", "Mask")),
        f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector};",
        doc("Place consecutive low input lanes into true-mask positions and zero-fill false positions.", ("Value", "Mask")),
    ]
    if f.vector == "U8x32":
        out += [
            "   function Horizontal_Sum (Value : U8x32) return Natural"
            " with Post => Horizontal_Sum'Result <= 32 * 255;",
            doc("Return the exact sum of all 32 unsigned byte lanes as Natural.", ("Value",)),
        ]
    reductions = (("Reduce_Add", "Reduce_Min_Number", "Reduce_Max_Number") if f.floating
                  else ("Reduce_Add_Wrap", "Reduce_Min", "Reduce_Max"))
    for name in reductions:
        out += [f"   function {name} (Value : {f.vector}) return {f.scalar};",
                doc(f"Apply {name} in ascending lane order.", ("Value",))]
    out += [
        f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector};",
        doc("Reverse logical lane order.", ("Value",)),
        f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector};",
        doc("Select each result lane through a reusable lane map.", ("Value", "Map")),
        f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector};",
        doc("Select each result lane from one lane of either input.", ("Left", "Right", "Map")),
    ]
    movement_docs = {
        "Interleave_Low": (
            "Alternate lanes from the low half of Left and Right, starting with Left."
        ),
        "Interleave_High": (
            "Alternate lanes from the high half of Left and Right, starting with Left."
        ),
        "Deinterleave_Even": (
            "Return the even-index lanes of Left followed by the even-index lanes of Right."
        ),
        "Deinterleave_Odd": (
            "Return the odd-index lanes of Left followed by the odd-index lanes of Right."
        ),
    }
    for name in movement:
        out += [f"   function {name} (Left, Right : {f.vector}) return {f.vector};",
                doc(movement_docs[name], ("Left", "Right"))]
    for name in ("Slide_Lanes_Toward_Low", "Slide_Lanes_Toward_High"):
        out += [f"   function {name} (Value : {f.vector}; Count : Natural) return {f.vector};",
                doc("Move retained lanes and zero-fill vacated lanes.", ("Value", "Count"))]
    if first_shape:
        out += [
        f"   function Mask_From_Bit_Mask (Bits : {f.mask_bits}) return {f.mask};",
        doc("Construct lane truths from compact bits. Bit zero represents lane zero.", ("Bits",)),
        f"   function To_Bit_Mask (Mask : {f.mask}) return {f.mask_bits};",
        doc("Return compact lane truths. Bit zero represents lane zero.", ("Mask",)),
    ]
        for name in ("Mask_And", "Mask_Or", "Mask_Xor"):
            out += [f"   function {name} (Left, Right : {f.mask}) return {f.mask};",
                    doc(f"Apply {name} to corresponding mask truths.", ("Left", "Right"))]
        out += [
        f"   function Mask_Not (Value : {f.mask}) return {f.mask};",
        doc("Complement every mask truth.", ("Value",)),
        f"   function Test (Mask : {f.mask}; Lane : {f.index}) return Boolean;",
        doc("Return one mask truth.", ("Mask", "Lane")),
    ]
        for name in ("Any_True", "All_True", "None_True"):
            out += [f"   function {name} (Mask : {f.mask}) return Boolean;",
                    doc(f"Return the {name} mask reduction.", ("Mask",))]
        mask_reductions = {
            "Population_Count": "Return the number of true lanes.",
            "First_True": (
                "Return the lowest true lane, or the lane-count value when no "
                "lane is true."
            ),
            "Last_True": (
                "Return the highest true lane, or the lane-count value when no "
                "lane is true."
            ),
        }
        for name, summary in mask_reductions.items():
            out += [f"   function {name} (Mask : {f.mask}) return {f.count};",
                    doc(summary, ("Mask",))]
    extent = f"Start in Data'Range and then {f.lanes - 1} <= Natural (Data'Last - Start)"
    partial = f"Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start))"
    out += [
        f"   function Is_Aligned_32 (Data : {f.array}; Start : Natural) return Boolean;",
        doc("Report whether the selected first element has a 32-byte-aligned address.", ("Data", "Start")),
        f"   function Load (Data : {f.array}; Start : Natural) return {f.vector} with Pre => {extent};",
        doc("Load one complete vector without an alignment requirement.", ("Data", "Start")),
        f"   procedure Store (Data : in out {f.array}; Start : Natural; Value : {f.vector}) with Pre => {extent};",
        doc("Store one complete vector without an alignment requirement.", ("Data", "Start", "Value"), False),
        f"   function Load_Unaligned (Data : {f.array}; Start : Natural) return {f.vector} with Pre => {extent};",
        doc("Load one complete vector from an address with any alignment.", ("Data", "Start")),
        f"   procedure Store_Unaligned (Data : in out {f.array}; Start : Natural; Value : {f.vector}) with Pre => {extent};",
        doc("Store one complete vector to an address with any alignment.", ("Data", "Start", "Value"), False),
        f"   function Load_Aligned (Data : {f.array}; Start : Natural) return {f.vector} with Pre => {extent} and then Is_Aligned_32 (Data, Start);",
        doc("Load one complete vector from a 32-byte-aligned address.", ("Data", "Start")),
        f"   procedure Store_Aligned (Data : in out {f.array}; Start : Natural; Value : {f.vector}) with Pre => {extent} and then Is_Aligned_32 (Data, Start);",
        doc("Store one complete vector to a 32-byte-aligned address.", ("Data", "Start", "Value"), False),
        f"   function Load_Partial (Data : {f.array}; Start : Natural; Count : {f.count}) return {f.vector} with Pre => {partial};",
        doc("Read exactly Count elements and zero-fill remaining lanes.", ("Data", "Start", "Count")),
        f"   procedure Store_Partial (Data : in out {f.array}; Start : Natural; Count : {f.count}; Value : {f.vector}) with Pre => {partial};",
        doc("Write exactly Count elements and leave all others unchanged.", ("Data", "Start", "Count", "Value"), False),
    ]
    return contextualize_support("\n".join(out))


def conversion_declarations(native: bool = False) -> str:
    out: list[str] = []

    def add(line: str, summary: str, params: tuple[str, ...]) -> None:
        if native:
            line = line[:-1] + " with Inline_Always;"
        out.extend((line, doc(summary, params, support="native" if native else "portable", declaration=line)))

    for source, _, target, *_ in (*WIDENINGS, *FLOAT_WIDENINGS):
        source_wide = BY_HALF[source].vector
        target_wide = BY_HALF[target].vector
        for name, half in (("Widen_Low", "low"), ("Widen_High", "high")):
            summary = (
                "With the platform's default gradual-underflow environment, "
                f"widen the {half} binary32 source half exactly to binary64 and preserve lane order. "
                "Signed zero and infinity are preserved. A NaN produces a NaN with "
                "unspecified payload and signaling state. The operation can update "
                "floating-point exception-status flags."
                if source.startswith("F") else
                f"Widen the {half} integer source half exactly, preserve signedness, and preserve lane order."
            )
            add(
                f"   function {name} (Value : {source_wide}) return {target_wide};",
                summary,
                ("Value",),
            )

    for source, _, target, *_ in NARROWINGS:
        source_wide = BY_HALF[source].vector
        target_wide = BY_HALF[target].vector
        add(
            f"   function Narrow_Truncate (Low, High : {source_wide}) return {target_wide};",
            "Keep the low bits of every source lane and concatenate Low before High.",
            ("Low", "High"),
        )
        add(
            f"   function Narrow_Saturate (Low, High : {source_wide}) return {target_wide};",
            "Clamp every source lane to the result range and concatenate Low before High.",
            ("Low", "High"),
        )

    for source, _, target, *_ in SIGNED_TO_UNSIGNED_NARROWINGS:
        add(
            f"   function Narrow_Saturate (Low, High : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            "Clamp signed lanes to the unsigned result range and concatenate Low before High.",
            ("Low", "High"),
        )

    for source, _, target, *_ in FLOAT_NARROWINGS:
        add(
            f"   function Narrow_Round (Low, High : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            "With the default round-to-nearest, ties-to-even and gradual-underflow environment, round binary64 lanes to binary32 and concatenate Low before High. Preserve signed zero and infinity. Use gradual underflow and signed overflow to infinity. A NaN remains a NaN with unspecified payload and signaling state. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.",
            ("Low", "High"),
        )

    for source, _, target, *_ in INTEGER_TO_FLOAT_CONVERSIONS:
        add(
            f"   function Convert_Round (Value : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            "With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.",
            ("Value",),
        )

    for source, _, target, *_ in FLOAT_TO_INTEGER_CONVERSIONS:
        add(
            f"   function Convert_Truncate_Saturate (Value : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            "Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.",
            ("Value",),
        )

    for source, _, target, _, _, _, source_signed in SIGNED_UNSIGNED_CONVERSIONS:
        summary = (
            "Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values."
            if source_signed else
            "Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values."
        )
        add(
            f"   function Convert_Saturate (Value : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            summary,
            ("Value",),
        )
    return "\n".join(out)


def spec_text() -> str:
    seen_shapes: set[tuple[int, int]] = set()
    declarations_list = []
    for f in FAMILIES:
        shape = (f.bits, f.lanes)
        declarations_list.append(declaration(f, shape not in seen_shapes))
        seen_shapes.add(shape)
    declarations = "\n\n".join(declarations_list)
    conversions = conversion_declarations()
    vector_types = "\n".join(
        f"   type {family.vector} is private;\n"
        f"   --  A private 256-bit vector containing {family.lanes} {family.scalar} lanes."
        for family in FAMILIES
    )
    reps = []
    seen_shapes = set()
    for f in FAMILIES:
        reps += [
            f"   type {f.vector} is record\n      Low, High : {f.half};\n   end record;",
            f"   for {f.vector}'Size use 256;",
        ]
        shape = (f.bits, f.lanes)
        if shape not in seen_shapes:
            reps += [
                f"   type {f.lane_map} is record\n      Selectors : {f.selectors} := [others => 0];\n   end record;",
                f"   type {f.two_selector} is record\n      From_Right : Boolean := False;\n      Lane : {f.index} := 0;\n   end record;",
                f"   type {f.two_map} is record\n      Selectors : {f.two_selectors} := [others => (From_Right => False, Lane => 0)];\n   end record;",
                f"   type {f.mask} is record\n      Low, High : {f.half_mask};\n   end record;",
            ]
            seen_shapes.add(shape)
    return f"""with Interfaces;

--  Portable 256-bit values. Representations stay private and are not an ABI.
package Flyology_SIMD.Wide
  with Preelaborate
is
{vector_types}

{declarations}

{conversions}

private
{chr(10).join(reps)}
end Flyology_SIMD.Wide;
"""


def half_expr(f: Family, operation: str, args: str, prefix: str = "Flyology_SIMD") -> str:
    return f"{prefix}.{operation} ({args})"


def pair_function(name: str, f: Family, params: str, low_args: str, high_args: str,
                  result: str | None = None, prefix: str = "Flyology_SIMD") -> str:
    result = result or f.vector
    return (f"   function {name} ({params}) return {result} is\n"
            f"     ((Low => {half_expr(f, name, low_args, prefix)},\n"
            f"       High => {half_expr(f, name, high_args, prefix)}));")


def family_body(f: Family, first_shape: bool, prefix: str = "Flyology_SIMD") -> str:
    p = prefix
    out = []
    if first_shape:
        out += [
            f"   function Make_Lane_Map (Selectors : {f.selectors}) return {f.lane_map} is\n     ((Selectors => Selectors));",
            f"   function Select_Left_Lane (Lane : {f.index}) return {f.two_selector} is\n     ((From_Right => False, Lane => Lane));",
            f"   function Select_Right_Lane (Lane : {f.index}) return {f.two_selector} is\n     ((From_Right => True, Lane => Lane));",
            f"   function Make_Two_Source_Lane_Map (Selectors : {f.two_selectors}) return {f.two_map} is\n     ((Selectors => Selectors));",
        ]
    out += [
        f"   function Zero return {f.vector} is\n     ((Low => {p}.Zero, High => {p}.Zero));",
        pair_function("Splat", f, f"Value : {f.scalar}", "Value", "Value", prefix=p),
        f"   function From_Lanes (Values : {f.values}) return {f.vector} is\n"
        f"     ((Low => {p}.From_Lanes ([for Lane in 0 .. {f.half_lanes - 1} => Values (Lane)]),\n"
        f"       High => {p}.From_Lanes ([for Lane in 0 .. {f.half_lanes - 1} => Values (Lane + {f.half_lanes})])));",
        f"   function To_Lanes (Value : {f.vector}) return {f.values} is\n"
        f"      Low : constant {f.values} := [for Lane in {f.index} => (if Lane < {f.half_lanes} then {p}.Extract (Value.Low, Lane) else {p}.Extract (Value.High, Lane - {f.half_lanes}))];\n"
        f"   begin\n      return Low;\n   end To_Lanes;",
        f"   function Extract (Value : {f.vector}; Lane : {f.index}) return {f.scalar} is\n"
        f"     (if Lane < {f.half_lanes} then {p}.Extract (Value.Low, Lane) else {p}.Extract (Value.High, Lane - {f.half_lanes}));",
        f"   function Replace (Value : {f.vector}; Lane : {f.index}; With_Value : {f.scalar}) return {f.vector} is\n"
        f"     (if Lane < {f.half_lanes}\n"
        f"      then (Low => {p}.Replace (Value.Low, Lane, With_Value), High => Value.High)\n"
        f"      else (Low => Value.Low, High => {p}.Replace (Value.High, Lane - {f.half_lanes}, With_Value)));",
    ]
    if f.vector == "U8x32":
        if p == "Flyology_SIMD":
            out.append(
                "   function Table_Lookup (Table, Indices : U8x32) return U8x32 is\n"
                "      Table_Lanes : constant Lane_Values_U8x32 := To_Lanes (Table);\n"
                "      Index_Lanes : constant Lane_Values_U8x32 := To_Lanes (Indices);\n"
                "      Result : Lane_Values_U8x32 := [others => 0];\n"
                "   begin\n"
                "      for Lane in Lane_Index_8x32 loop\n"
                "         if Index_Lanes (Lane) <= 31 then\n"
                "            Result (Lane) := Table_Lanes (Natural (Index_Lanes (Lane)));\n"
                "         end if;\n"
                "      end loop;\n"
                "      return From_Lanes (Result);\n"
                "   end Table_Lookup;"
            )
        else:
            out.append(
                "   function Table_Lookup (Table, Indices : U8x32) return U8x32 is\n"
                "     (Lookup_Mechanism.Table_Lookup_32 (Table, Indices));"
            )
        out.append(
            "   function Horizontal_Sum (Value : U8x32) return Natural is\n"
            "      --  Each exact half sum is at most 16 * 255, so their sum\n"
            "      --  is at most 8_160 and cannot overflow Natural.\n"
            "      pragma Suppress (Overflow_Check);\n"
            "   begin\n"
            f"      return {p}.Horizontal_Sum (Value.Low) + "
            f"{p}.Horizontal_Sum (Value.High);\n"
            "   end Horizontal_Sum;"
        )
    for target_name in BIT_CAST_TARGETS[f.vector]:
        target = BY_VECTOR[target_name]
        out.append(
            f"   function Bit_Cast (Value : {f.vector}) return {target.vector} is\n"
            f"     ((Low => {p}.Bit_Cast (Value.Low), High => {p}.Bit_Cast (Value.High)));"
        )
    binary = (("Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number") if f.floating else
              ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate",
               "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max"))
    for name in binary:
        if p != "Flyology_SIMD" and f.vector in ("U8x32", "I8x32"):
            out.append(
                f"   function {name} (Left, Right : {f.vector}) return {f.vector} is\n"
                f"     (Byte_Mechanism.{name} (Left, Right));"
            )
        elif p != "Flyology_SIMD" and f.floating and name in {
            "Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number",
        }:
            out.append(
                f"   function {name} (Left, Right : {f.vector}) return {f.vector} is\n"
                f"     (Float_Arithmetic_Mechanism.{name} (Left, Right));"
            )
        else:
            out.append(pair_function(name, f, f"Left, Right : {f.vector}", "Left.Low, Right.Low", "Left.High, Right.High", prefix=p))
    if not f.floating:
        if p != "Flyology_SIMD" and f.vector in ("U8x32", "I8x32"):
            out.append(
                f"   function Bitwise_Not (Value : {f.vector}) return {f.vector} is\n"
                "     (Byte_Mechanism.Bitwise_Not (Value));"
            )
        else:
            out.append(pair_function("Bitwise_Not", f, f"Value : {f.vector}", "Value.Low", "Value.High", prefix=p))
        for name in ("Shift_Left_Logical", "Shift_Right_Logical") + (("Shift_Right_Arithmetic",) if f.signed else ()):
            out.append(pair_function(name, f, f"Value : {f.vector}; Count : Natural", "Value.Low, Count", "Value.High, Count", prefix=p))
    comparisons = ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal") + (("Unordered",) if f.floating else ())
    for name in comparisons:
        if p != "Flyology_SIMD" and f.vector in ("U8x32", "I8x32"):
            out.append(
                f"   function {name} (Left, Right : {f.vector}) return {f.mask} is\n"
                f"     (Mask_From_Bit_Mask (Byte_Mechanism.{name} (Left, Right)));"
            )
        else:
            out.append(pair_function(name, f, f"Left, Right : {f.vector}", "Left.Low, Right.Low", "Left.High, Right.High", result=f.mask, prefix=p))
    if p != "Flyology_SIMD" and f.vector in ("U8x32", "I8x32"):
        out.append(
            f"   function Select_Value (Mask : {f.mask}; If_True, If_False : {f.vector}) return {f.vector} is\n"
            "     (Byte_Mechanism.Select_Value\n"
            "        (To_Bit_Mask (Mask), If_True, If_False));"
        )
    else:
        out.append(pair_function("Select_Value", f, f"Mask : {f.mask}; If_True, If_False : {f.vector}",
                                 "Mask.Low, If_True.Low, If_False.Low", "Mask.High, If_True.High, If_False.High", prefix=p))
    out += scalar_movement_body(f, p)
    if first_shape:
        out += mask_body(f, p)
    out += memory_body(f, p)
    return "\n\n".join(out)


def conversion_bodies(prefix: str = "Flyology_SIMD") -> str:
    out: list[str] = []

    for source, _, target, *_ in (*WIDENINGS, *FLOAT_WIDENINGS):
        source_wide = BY_HALF[source]
        target_wide = BY_HALF[target]
        out.extend((
            f"   function Widen_Low (Value : {source_wide.vector}) return {target_wide.vector} is\n"
            f"     ((Low => {prefix}.Widen_Low (Value.Low),\n"
            f"       High => {prefix}.Widen_High (Value.Low)));",
            f"   function Widen_High (Value : {source_wide.vector}) return {target_wide.vector} is\n"
            f"     ((Low => {prefix}.Widen_Low (Value.High),\n"
            f"       High => {prefix}.Widen_High (Value.High)));",
        ))

    for source, _, target, *_ in NARROWINGS:
        source_wide = BY_HALF[source]
        target_wide = BY_HALF[target]
        for name in ("Narrow_Truncate", "Narrow_Saturate"):
            out.append(
                f"   function {name} (Low, High : {source_wide.vector}) return {target_wide.vector} is\n"
                f"     ((Low => {prefix}.{name} (Low.Low, Low.High),\n"
                f"       High => {prefix}.{name} (High.Low, High.High)));"
            )

    for source, _, target, *_ in SIGNED_TO_UNSIGNED_NARROWINGS:
        source_wide = BY_HALF[source]
        target_wide = BY_HALF[target]
        out.append(
            f"   function Narrow_Saturate (Low, High : {source_wide.vector}) return {target_wide.vector} is\n"
            f"     ((Low => {prefix}.Narrow_Saturate (Low.Low, Low.High),\n"
            f"       High => {prefix}.Narrow_Saturate (High.Low, High.High)));"
        )

    for source, _, target, *_ in FLOAT_NARROWINGS:
        source_wide = BY_HALF[source]
        target_wide = BY_HALF[target]
        out.append(
            f"   function Narrow_Round (Low, High : {source_wide.vector}) return {target_wide.vector} is\n"
            f"     ((Low => {prefix}.Narrow_Round (Low.Low, Low.High),\n"
            f"       High => {prefix}.Narrow_Round (High.Low, High.High)));"
        )

    for operation, conversions in (
        ("Convert_Round", INTEGER_TO_FLOAT_CONVERSIONS),
        ("Convert_Truncate_Saturate", FLOAT_TO_INTEGER_CONVERSIONS),
        ("Convert_Saturate", SIGNED_UNSIGNED_CONVERSIONS),
    ):
        for source, _, target, *_ in conversions:
            source_wide = BY_HALF[source]
            target_wide = BY_HALF[target]
            out.append(
                f"   function {operation} (Value : {source_wide.vector}) return {target_wide.vector} is\n"
                f"     ((Low => {prefix}.{operation} (Value.Low),\n"
                f"       High => {prefix}.{operation} (Value.High)));"
            )
    return "\n\n".join(out)


def scalar_movement_body(f: Family, prefix: str) -> list[str]:
    vals, idx, total, half = f.values, f.index, f.lanes, f.half_lanes
    zero = "0.0" if f.floating else "0"
    reductions = []
    if f.floating:
        reductions = ([
            f"   function Reduce_Add (Value : {f.vector}) return {f.scalar} is\n      Lanes : constant {vals} := To_Lanes (Value);\n      Result : {f.scalar} := 0.0;\n   begin\n      for Lane in {f.index} loop Result := Result + Lanes (Lane); end loop;\n      return Result;\n   end Reduce_Add;",
            f"   function Reduce_Min_Number (Value : {f.vector}) return {f.scalar} is\n      Result : {f.scalar} := Extract (Value, 0);\n   begin\n      for Lane in 1 .. {total - 1} loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Min_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;\n      return Result;\n   end Reduce_Min_Number;",
            f"   function Reduce_Max_Number (Value : {f.vector}) return {f.scalar} is\n      Result : {f.scalar} := Extract (Value, 0);\n   begin\n      for Lane in 1 .. {total - 1} loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Max_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;\n      return Result;\n   end Reduce_Max_Number;",
        ] if prefix == "Flyology_SIMD" else [
            f"   function Reduce_Add (Value : {f.vector}) return {f.scalar} is\n     (Float_Reduce_Mechanism.Reduce_Add (Value));",
            f"   function Reduce_Min_Number (Value : {f.vector}) return {f.scalar} is\n     (Float_Reduce_Mechanism.Reduce_Min_Number (Value));",
            f"   function Reduce_Max_Number (Value : {f.vector}) return {f.scalar} is\n     (Float_Reduce_Mechanism.Reduce_Max_Number (Value));",
        ])
    else:
        reduction_prefix = (
            "Flyology_SIMD" if prefix == "Flyology_SIMD"
            else "Flyology_SIMD.Backends.Native"
        )
        reductions = [
            f"   function Reduce_Add_Wrap (Value : {f.vector}) return {f.scalar} is\n      Pair : constant {f.half} := {reduction_prefix}.Add_Wrap ({reduction_prefix}.Splat ({reduction_prefix}.Reduce_Add_Wrap (Value.Low)), {reduction_prefix}.Splat ({reduction_prefix}.Reduce_Add_Wrap (Value.High)));\n   begin return {reduction_prefix}.Extract (Pair, 0); end Reduce_Add_Wrap;",
            f"   function Reduce_Min (Value : {f.vector}) return {f.scalar} is\n      Pair : constant {f.half} := {reduction_prefix}.Min ({reduction_prefix}.Splat ({reduction_prefix}.Reduce_Min (Value.Low)), {reduction_prefix}.Splat ({reduction_prefix}.Reduce_Min (Value.High)));\n   begin return {reduction_prefix}.Extract (Pair, 0); end Reduce_Min;",
            f"   function Reduce_Max (Value : {f.vector}) return {f.scalar} is\n      Pair : constant {f.half} := {reduction_prefix}.Max ({reduction_prefix}.Splat ({reduction_prefix}.Reduce_Max (Value.Low)), {reduction_prefix}.Splat ({reduction_prefix}.Reduce_Max (Value.High)));\n   begin return {reduction_prefix}.Extract (Pair, 0); end Reduce_Max;",
        ]
    compact = [
        f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n      Result : {vals} := [others => {zero}];\n      Next : Natural := 0;\n   begin\n      for Lane in {idx} loop\n         if Test (Mask, Lane) then Result (Next) := Extract (Value, Lane); Next := Next + 1; end if;\n      end loop;\n      return From_Lanes (Result);\n   end Compress;",
        f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n      Result : {vals} := [others => {zero}];\n      Next : Natural := 0;\n   begin\n      for Lane in {idx} loop\n         if Test (Mask, Lane) then Result (Lane) := Extract (Value, Next); Next := Next + 1; end if;\n      end loop;\n      return From_Lanes (Result);\n   end Expand;",
    ] if prefix == "Flyology_SIMD" else [
        f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n     (Compact_Mechanism.Compress (Value, Mask));",
        f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n     (Compact_Mechanism.Expand (Value, Mask));",
    ]
    permutations = [
        f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract (Value, Map.Selectors (Lane))]));",
        f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract ((if Map.Selectors (Lane).From_Right then Right else Left), Map.Selectors (Lane).Lane)]));",
    ] if prefix == "Flyology_SIMD" else [
        f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n     (Permute_Mechanism.Permute_Lanes (Value, Map));",
        f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector} is\n     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));",
    ]
    movement = [
        f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract (Value, {total - 1} - Lane)]));",
        f"   function Interleave_Low (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane mod 2 = 0 then Extract (Left, Lane / 2) else Extract (Right, Lane / 2))]));",
        f"   function Interleave_High (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane mod 2 = 0 then Extract (Left, {half} + Lane / 2) else Extract (Right, {half} + Lane / 2))]));",
        f"   function Deinterleave_Even (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane < {half} then Extract (Left, 2 * Lane) else Extract (Right, 2 * (Lane - {half})))]));",
        f"   function Deinterleave_Odd (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane < {half} then Extract (Left, 2 * Lane + 1) else Extract (Right, 2 * (Lane - {half}) + 1))]));",
        f"   function Slide_Lanes_Toward_Low (Value : {f.vector}; Count : Natural) return {f.vector} is\n     (if Count >= {total} then Zero else From_Lanes ([for Lane in {idx} => (if Lane + Count < {total} then Extract (Value, Lane + Count) else {zero})]));",
        f"   function Slide_Lanes_Toward_High (Value : {f.vector}; Count : Natural) return {f.vector} is\n     (if Count >= {total} then Zero else From_Lanes ([for Lane in {idx} => (if Lane >= Count then Extract (Value, Lane - Count) else {zero})]));",
    ] if prefix == "Flyology_SIMD" else [
        f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector} is\n     (Permute_Mechanism.Reverse_Lanes (Value));",
        f"   function Interleave_Low (Left, Right : {f.vector}) return {f.vector} is\n     (Permute_Mechanism.Interleave_Low (Left, Right));",
        f"   function Interleave_High (Left, Right : {f.vector}) return {f.vector} is\n     (Permute_Mechanism.Interleave_High (Left, Right));",
        f"   function Deinterleave_Even (Left, Right : {f.vector}) return {f.vector} is\n     (Permute_Mechanism.Deinterleave_Even (Left, Right));",
        f"   function Deinterleave_Odd (Left, Right : {f.vector}) return {f.vector} is\n     (Permute_Mechanism.Deinterleave_Odd (Left, Right));",
        f"   function Slide_Lanes_Toward_Low (Value : {f.vector}; Count : Natural) return {f.vector} is\n     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));",
        f"   function Slide_Lanes_Toward_High (Value : {f.vector}; Count : Natural) return {f.vector} is\n     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));",
    ]
    return [
        *compact,
        *reductions,
        movement[0],
        *permutations,
        *movement[1:],
    ]


def mask_body(f: Family, p: str) -> list[str]:
    shift = f.half_lanes
    cast = f.mask_bits
    half_cast = half_mask_storage(f)
    low_mask = (1 << f.half_lanes) - 1
    low_expr = "Bits" if half_cast == cast else f"Bits and {cast} ({low_mask})"
    high_expr = f"Interfaces.Shift_Right (Bits, {shift})"
    same_base = f.lanes <= 8
    low_bits = low_expr if same_base else f"{half_cast} ({low_expr})"
    high_bits = (
        high_expr if same_base else f"{half_cast} ({high_expr})"
    )
    return [
        f"   function Mask_From_Bit_Mask (Bits : {f.mask_bits}) return {f.mask} is\n"
        f"     ((Low => {p}.Mask_From_Bit_Mask ({low_bits}),\n"
        f"       High => {p}.Mask_From_Bit_Mask ({high_bits})));",
        f"   function To_Bit_Mask (Mask : {f.mask}) return {f.mask_bits} is\n"
        f"     ({cast} ({p}.To_Bit_Mask (Mask.Low)) or Interfaces.Shift_Left ({cast} ({p}.To_Bit_Mask (Mask.High)), {shift}));",
        pair_function("Mask_And", f, f"Left, Right : {f.mask}", "Left.Low, Right.Low", "Left.High, Right.High", result=f.mask, prefix=p),
        pair_function("Mask_Or", f, f"Left, Right : {f.mask}", "Left.Low, Right.Low", "Left.High, Right.High", result=f.mask, prefix=p),
        pair_function("Mask_Xor", f, f"Left, Right : {f.mask}", "Left.Low, Right.Low", "Left.High, Right.High", result=f.mask, prefix=p),
        pair_function("Mask_Not", f, f"Value : {f.mask}", "Value.Low", "Value.High", result=f.mask, prefix=p),
        f"   function Test (Mask : {f.mask}; Lane : {f.index}) return Boolean is\n     (if Lane < {f.half_lanes} then {p}.Test (Mask.Low, Lane) else {p}.Test (Mask.High, Lane - {f.half_lanes}));",
        f"   function Any_True (Mask : {f.mask}) return Boolean is ({p}.Any_True (Mask.Low) or else {p}.Any_True (Mask.High));",
        f"   function All_True (Mask : {f.mask}) return Boolean is ({p}.All_True (Mask.Low) and then {p}.All_True (Mask.High));",
        f"   function None_True (Mask : {f.mask}) return Boolean is (not Any_True (Mask));",
        f"   function Population_Count (Mask : {f.mask}) return {f.count} is ({f.count} ({p}.Population_Count (Mask.Low) + {p}.Population_Count (Mask.High)));",
        f"   function First_True (Mask : {f.mask}) return {f.count} is\n      Low : constant Natural := {p}.First_True (Mask.Low);\n      High : constant Natural := {p}.First_True (Mask.High);\n   begin\n      return (if Low < {f.half_lanes} then Low elsif High < {f.half_lanes} then {f.half_lanes} + High else {f.lanes});\n   end First_True;",
        f"   function Last_True (Mask : {f.mask}) return {f.count} is\n      Low : constant Natural := {p}.Last_True (Mask.Low);\n      High : constant Natural := {p}.Last_True (Mask.High);\n   begin\n      return (if High < {f.half_lanes} then {f.half_lanes} + High elsif Low < {f.half_lanes} then Low else {f.lanes});\n   end Last_True;",
    ]


def memory_body(f: Family, p: str) -> list[str]:
    return [
        f"   function Is_Aligned_32 (Data : {f.array}; Start : Natural) return Boolean is\n     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);",
        f"   function Load (Data : {f.array}; Start : Natural) return {f.vector} is\n     ((Low => {p}.Load (Data, Start), High => {p}.Load (Data, Start + {f.half_lanes})));",
        f"   procedure Store (Data : in out {f.array}; Start : Natural; Value : {f.vector}) is\n   begin\n      {p}.Store (Data, Start, Value.Low); {p}.Store (Data, Start + {f.half_lanes}, Value.High);\n   end Store;",
        f"   function Load_Unaligned (Data : {f.array}; Start : Natural) return {f.vector} is\n     ((Low => {p}.Load_Unaligned (Data, Start), High => {p}.Load_Unaligned (Data, Start + {f.half_lanes})));",
        f"   procedure Store_Unaligned (Data : in out {f.array}; Start : Natural; Value : {f.vector}) is\n   begin\n      {p}.Store_Unaligned (Data, Start, Value.Low); {p}.Store_Unaligned (Data, Start + {f.half_lanes}, Value.High);\n   end Store_Unaligned;",
        f"   function Load_Aligned (Data : {f.array}; Start : Natural) return {f.vector} is\n     ((Low => {p}.Load_Aligned (Data, Start), High => {p}.Load_Aligned (Data, Start + {f.half_lanes})));",
        f"   procedure Store_Aligned (Data : in out {f.array}; Start : Natural; Value : {f.vector}) is\n   begin\n      {p}.Store_Aligned (Data, Start, Value.Low); {p}.Store_Aligned (Data, Start + {f.half_lanes}, Value.High);\n   end Store_Aligned;",
        f"   function Load_Partial (Data : {f.array}; Start : Natural; Count : {f.count}) return {f.vector} is\n"
        f"     (if Count <= {f.half_lanes}\n"
        f"      then (Low => {p}.Load_Partial (Data, Start, Count), High => {p}.Zero)\n"
        f"      else (Low => {p}.Load (Data, Start), High => {p}.Load_Partial (Data, Start + {f.half_lanes}, Count - {f.half_lanes})));",
        f"   procedure Store_Partial (Data : in out {f.array}; Start : Natural; Count : {f.count}; Value : {f.vector}) is\n"
        f"   begin\n      if Count <= {f.half_lanes} then {p}.Store_Partial (Data, Start, Count, Value.Low);\n"
        f"      else {p}.Store (Data, Start, Value.Low); {p}.Store_Partial (Data, Start + {f.half_lanes}, Count - {f.half_lanes}, Value.High); end if;\n"
        f"   end Store_Partial;",
    ]


def body_text() -> str:
    seen_shapes: set[tuple[int, int]] = set()
    body_list = []
    for f in FAMILIES:
        shape = (f.bits, f.lanes)
        body_list.append(family_body(f, shape not in seen_shapes))
        seen_shapes.add(shape)
    bodies = "\n\n".join(body_list)
    conversions = conversion_bodies()
    return f"""with System.Storage_Elements;

package body Flyology_SIMD.Wide is
   use type System.Storage_Elements.Integer_Address;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type F32;
   use type F64;
{bodies}

{conversions}
end Flyology_SIMD.Wide;
"""


def native_declaration(f: Family, first_shape: bool) -> str:
    """Reuse the public operation declarations without redeclaring types."""
    lines = declaration(f, first_shape).splitlines()
    result: list[str] = []
    skip_doc = False
    for line in lines:
        if line.startswith("   subtype ") or line.startswith("   type "):
            skip_doc = True
            continue
        if skip_doc and line.startswith("   --"):
            continue
        skip_doc = False
        if (line.startswith("   function ") or line.startswith("   procedure ")) and line.endswith(";"):
            if " with " in line:
                line = line[:-1] + ", Inline_Always;"
            else:
                line = line[:-1] + " with Inline_Always;"
        if line.startswith(
            "   --  Cross-platform support: This overload uses the portable scalar Wide implementation"
        ) and result:
            summary = result[-1].removeprefix("   --  ")
            declaration_line = next(
                (item for item in reversed(result) if item.startswith("   function ") or item.startswith("   procedure ")),
                "",
            )
            line = f"   --  {wide_native_support(summary, declaration_line)}"
        result.append(line)
    return "\n".join(result)


def native_spec_text() -> str:
    seen_shapes: set[tuple[int, int]] = set()
    declarations = []
    for f in FAMILIES:
        shape = (f.bits, f.lanes)
        declarations.append(native_declaration(f, shape not in seen_shapes))
        seen_shapes.add(shape)
    conversions = conversion_declarations(native=True)
    return f"""--  Statically selected 256-bit composition through the native 128-bit backend.
package Flyology_SIMD.Wide.Native
  with Preelaborate
is
{chr(10).join(declarations)}

{conversions}
end Flyology_SIMD.Wide.Native;
"""


def native_body_text() -> str:
    seen_shapes: set[tuple[int, int]] = set()
    body_list = []
    for f in FAMILIES:
        shape = (f.bits, f.lanes)
        body_list.append(
            family_body(f, shape not in seen_shapes, "Flyology_SIMD.Backends.Native")
        )
        seen_shapes.add(shape)
    conversions = conversion_bodies("Flyology_SIMD.Backends.Native")
    return f"""with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Wide.Byte_Mechanism;
with Flyology_SIMD.Wide.Compact_Mechanism;
with Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
with Flyology_SIMD.Wide.Float_Reduce_Mechanism;
with Flyology_SIMD.Wide.Lookup_Mechanism;
with Flyology_SIMD.Wide.Permute_Mechanism;
with System.Storage_Elements;

package body Flyology_SIMD.Wide.Native is
   package Byte_Mechanism renames Flyology_SIMD.Wide.Byte_Mechanism;
   package Compact_Mechanism renames Flyology_SIMD.Wide.Compact_Mechanism;
   package Float_Arithmetic_Mechanism renames Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
   package Float_Reduce_Mechanism renames Flyology_SIMD.Wide.Float_Reduce_Mechanism;
   package Lookup_Mechanism renames Flyology_SIMD.Wide.Lookup_Mechanism;
   package Permute_Mechanism renames Flyology_SIMD.Wide.Permute_Mechanism;
   use type System.Storage_Elements.Integer_Address;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
{chr(10).join(body_list)}

{conversions}
end Flyology_SIMD.Wide.Native;
"""


def compact_spec_text() -> str:
    declarations = []
    for f in FAMILIES:
        for operation, description in (
            ("Compress", "Stably pack true-mask lanes and zero-fill the suffix."),
            ("Expand", "Place packed lanes at true-mask positions and zero-fill false positions."),
        ):
            declarations.append(
                f"   function {operation} (Value : {f.vector}; Mask : {f.mask}) return {f.vector}\n"
                "     with Inline_Always;\n"
                f"   --  {description}\n"
                "   --  @param Value The input lanes.\n"
                "   --  @param Mask The semantic selection mask.\n"
                "   --  @return The moved lanes and defined zero fill."
            )
    return f"""private package Flyology_SIMD.Wide.Compact_Mechanism
  with Preelaborate
is
   --  Target-selected mechanism for Wide stable mask movement.

{chr(10).join(declarations)}
end Flyology_SIMD.Wide.Compact_Mechanism;
"""


def float_reduce_spec_text() -> str:
    return """private package Flyology_SIMD.Wide.Float_Reduce_Mechanism
  with Preelaborate
is
   --  Target-selected ordered Wide floating-point reductions.

   function Reduce_Add (Value : F32x8) return F32
     with Inline_Always;
   --  Add lanes from lane zero through lane seven, starting from positive zero.
   --  @param Value The input lanes.
   --  @return The ordered binary32 sum.
   function Reduce_Min_Number (Value : F32x8) return F32
     with Inline_Always;
   --  Apply Min_Number from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 minimum-number result.
   function Reduce_Max_Number (Value : F32x8) return F32
     with Inline_Always;
   --  Apply Max_Number from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 maximum-number result.

   function Reduce_Add (Value : F64x4) return F64
     with Inline_Always;
   --  Add lanes from lane zero through lane three, starting from positive zero.
   --  @param Value The input lanes.
   --  @return The ordered binary64 sum.
   function Reduce_Min_Number (Value : F64x4) return F64
     with Inline_Always;
   --  Apply Min_Number from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 minimum-number result.
   function Reduce_Max_Number (Value : F64x4) return F64
     with Inline_Always;
   --  Apply Max_Number from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 maximum-number result.
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
"""


def float_arithmetic_spec_text() -> str:
    declarations = []
    for vector in ("F32x8", "F64x4"):
        for operation in (
            "Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number",
        ):
            declarations.append(
                f"   function {operation} (Left, Right : {vector}) return {vector}\n"
                "     with Inline_Always;\n"
                f"   --  Apply {operation} independently to corresponding lanes.\n"
                "   --  @param Left The left input lanes.\n"
                "   --  @param Right The right input lanes.\n"
                "   --  @return The lane-wise floating-point results."
            )
    return f"""private package Flyology_SIMD.Wide.Float_Arithmetic_Mechanism
  with Preelaborate
is
   --  Target-selected Wide floating-point arithmetic.

{chr(10).join(declarations)}
end Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
"""


def float_arithmetic_composed_body_text() -> str:
    bodies = []
    for vector, half in (("F32x8", "F32x4"), ("F64x4", "F64x2")):
        del half
        for operation in (
            "Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number",
        ):
            bodies.append(
                f"   function {operation} (Left, Right : {vector}) return {vector} is\n"
                f"     ((Low => Flyology_SIMD.Backends.Native.{operation}\n"
                "                (Left.Low, Right.Low),\n"
                f"       High => Flyology_SIMD.Backends.Native.{operation}\n"
                "                (Left.High, Right.High)));"
            )
    return f"""with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Wide.Float_Arithmetic_Mechanism is
{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
"""


def float_arithmetic_avx2_leaf_spec_text() -> str:
    declarations = []
    for vector in ("F32x8", "F64x4"):
        for operation in (
            "Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number",
        ):
            declarations.append(
                f"   function {operation} (Left, Right : {vector}) return {vector};"
            )
    return f"""private package Flyology_SIMD.Wide.Float_AVX2_Leaf
  with Preelaborate
is
   --  Isolated AVX2-width floating-point arithmetic leaves.

{chr(10).join(declarations)}
end Flyology_SIMD.Wide.Float_AVX2_Leaf;
"""


def avx2_integer_sequence(instruction: str) -> str:
    """Widen the verified two-operand SSE2 integer sequence to AVX2 YMM form."""
    result = []
    three_operand = {
        "pand": "vpand", "pandn": "vpandn", "por": "vpor", "pxor": "vpxor",
        "pcmpeqd": "vpcmpeqd", "pcmpgtd": "vpcmpgtd",
    }
    shifts = {
        "psrad": "vpsrad", "psrld": "vpsrld", "pslld": "vpslld",
        "psrlq": "vpsrlq", "psllq": "vpsllq",
    }
    for line in instruction.splitlines():
        parts = line.split()
        operation = parts[0]
        operands = " ".join(parts[1:]).replace("xmm", "ymm")
        split_operands = [item.strip() for item in operands.split(",")]
        if operation == "movdqa":
            result.append(f"vmovdqa {operands}")
        elif operation == "pshufd":
            result.append(f"vpshufd {operands}")
        elif operation in three_operand:
            source, destination = split_operands
            result.append(
                f"{three_operand[operation]} {source}, {destination}, {destination}"
            )
        elif operation in shifts:
            count, destination = split_operands
            result.append(
                f"{shifts[operation]} {count}, {destination}, {destination}"
            )
        else:
            raise ValueError(f"unsupported SSE2 instruction in AVX2 lift: {line}")
    return "\n".join(result)


def float_arithmetic_avx2_leaf_body_text() -> str:
    bodies = []
    instructions = {
        "Add": ("vaddps", "vaddpd"),
        "Subtract": ("vsubps", "vsubpd"),
        "Multiply": ("vmulps", "vmulpd"),
        "Divide": ("vdivps", "vdivpd"),
    }
    for vector, instruction_index in (("F32x8", 0), ("F64x4", 1)):
        operations = {
            **{name: variants[instruction_index]
               for name, variants in instructions.items()},
            "Min_Number": avx2_integer_sequence(
                x86_float_minmax_instruction(32 if vector == "F32x8" else 64,
                                             maximum=False)),
            "Max_Number": avx2_integer_sequence(
                x86_float_minmax_instruction(32 if vector == "F32x8" else 64,
                                             maximum=True)),
        }
        for operation, instruction in operations.items():
            ada_instruction = instruction.replace(
                "\n", '" & ASCII.LF & ASCII.HT &\n           "'
            )
            instruction_line = (
                f'           "{ada_instruction} %%ymm1, %%ymm0, %%ymm0" & '
                'ASCII.LF & ASCII.HT &\n'
                if operation in instructions else
                f'           "{ada_instruction}" & ASCII.LF & ASCII.HT &\n'
            )
            bodies.append(
                f"   function {operation} (Left, Right : {vector}) return {vector} is\n"
                f"      Result : {vector};\n"
                "   begin\n"
                "      Asm\n"
                "        (Template =>\n"
                '           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &\n'
                '           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &\n'
                + instruction_line +
                '           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &\n'
                '           "vzeroupper",\n'
                "         Inputs =>\n"
                "           [System.Address'Asm_Input (\"r\", Result'Address),\n"
                "            System.Address'Asm_Input (\"r\", Left'Address),\n"
                "            System.Address'Asm_Input (\"r\", Right'Address)],\n"
                '         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",\n'
                "         Volatile => True);\n"
                "      return Result;\n"
                f"   end {operation};"
            )
    return f"""with System.Machine_Code;

package body Flyology_SIMD.Wide.Float_AVX2_Leaf is
   use System.Machine_Code;

{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Float_AVX2_Leaf;
"""


def float_arithmetic_avx2_body_text() -> str:
    bodies = []
    for vector in ("F32x8", "F64x4"):
        for operation in (
            "Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number",
        ):
            bodies.append(
                f"   function {operation} (Left, Right : {vector}) return {vector} is\n"
                f"     (Flyology_SIMD.Wide.Float_AVX2_Leaf.{operation} (Left, Right));"
            )
    return f"""with Flyology_SIMD.Wide.Float_AVX2_Leaf;

package body Flyology_SIMD.Wide.Float_Arithmetic_Mechanism is
{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
"""


def float_reduce_composed_body_text() -> str:
    return """package body Flyology_SIMD.Wide.Float_Reduce_Mechanism is
   function Reduce_Add (Value : F32x8) return F32 is
     (Flyology_SIMD.Wide.Reduce_Add (Value));
   function Reduce_Min_Number (Value : F32x8) return F32 is
     (Flyology_SIMD.Wide.Reduce_Min_Number (Value));
   function Reduce_Max_Number (Value : F32x8) return F32 is
     (Flyology_SIMD.Wide.Reduce_Max_Number (Value));
   function Reduce_Add (Value : F64x4) return F64 is
     (Flyology_SIMD.Wide.Reduce_Add (Value));
   function Reduce_Min_Number (Value : F64x4) return F64 is
     (Flyology_SIMD.Wide.Reduce_Min_Number (Value));
   function Reduce_Max_Number (Value : F64x4) return F64 is
     (Flyology_SIMD.Wide.Reduce_Max_Number (Value));
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
"""


def float_reduce_aarch64_body_text() -> str:
    return """with System.Machine_Code;

package body Flyology_SIMD.Wide.Float_Reduce_Mechanism is
   use System.Machine_Code;

   function Reduce_Add (Value : F32x8) return F32 is
      Result : F32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov s2, wzr" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s0" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[1]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[2]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[3]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s1" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[1]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[2]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[3]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "str s2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Add;

   function Reduce_Min_Number (Value : F32x8) return F32 is
      Result : F32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov s2, s0" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[1]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[2]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[3]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s1" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[1]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[2]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[3]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "str s2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Min_Number;

   function Reduce_Max_Number (Value : F32x8) return F32 is
      Result : F32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov s2, s0" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[2]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[3]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s1" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[2]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[3]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "str s2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Max_Number;

   function Reduce_Add (Value : F64x4) return F64 is
      Result : F64;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov d2, xzr" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d0" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v0.d[1]" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d3" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d1" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v1.d[1]" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d3" & ASCII.LF & ASCII.HT &
           "str d2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Add;

   function Reduce_Min_Number (Value : F64x4) return F64 is
      Result : F64;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov d2, d0" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v0.d[1]" & ASCII.LF & ASCII.HT &
           "fminnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "fminnm d2, d2, d1" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v1.d[1]" & ASCII.LF & ASCII.HT &
           "fminnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "str d2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Min_Number;

   function Reduce_Max_Number (Value : F64x4) return F64 is
      Result : F64;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov d2, d0" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v0.d[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "fmaxnm d2, d2, d1" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v1.d[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "str d2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Max_Number;
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
"""


def permute_spec_text() -> str:
    declarations = []
    for f in FAMILIES:
        declarations.extend((
            f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Select each result lane from one source through Map.\n"
            "   --  @param Value The source lanes.\n"
            "   --  @param Map The reusable one-source lane map.\n"
            "   --  @return The selected lanes in result-lane order.",
            f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Select each result lane from Left or Right through Map.\n"
            "   --  @param Left The left source lanes.\n"
            "   --  @param Right The right source lanes.\n"
            "   --  @param Map The reusable two-source lane map.\n"
            "   --  @return The selected lanes in result-lane order.",
            f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Reverse logical lane order.\n"
            "   --  @param Value The source lanes.\n"
            "   --  @return The lanes in reverse order.",
            f"   function Interleave_Low (Left, Right : {f.vector}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Interleave the low halves of two inputs.\n"
            "   --  @param Left The left source lanes.\n"
            "   --  @param Right The right source lanes.\n"
            "   --  @return The interleaved low halves.",
            f"   function Interleave_High (Left, Right : {f.vector}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Interleave the high halves of two inputs.\n"
            "   --  @param Left The left source lanes.\n"
            "   --  @param Right The right source lanes.\n"
            "   --  @return The interleaved high halves.",
            f"   function Deinterleave_Even (Left, Right : {f.vector}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Gather even lanes from two inputs.\n"
            "   --  @param Left The left source lanes.\n"
            "   --  @param Right The right source lanes.\n"
            "   --  @return The even lanes of Left followed by those of Right.",
            f"   function Deinterleave_Odd (Left, Right : {f.vector}) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Gather odd lanes from two inputs.\n"
            "   --  @param Left The left source lanes.\n"
            "   --  @param Right The right source lanes.\n"
            "   --  @return The odd lanes of Left followed by those of Right.",
            f"   function Slide_Lanes_Toward_Low (Value : {f.vector}; Count : Natural) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Slide lanes toward lower indexes and zero-fill the high lanes.\n"
            "   --  @param Value The source lanes.\n"
            "   --  @param Count The lane displacement.\n"
            "   --  @return The slid lanes, or zero when Count reaches or exceeds the width.",
            f"   function Slide_Lanes_Toward_High (Value : {f.vector}; Count : Natural) return {f.vector}\n"
            "     with Inline_Always;\n"
            "   --  Slide lanes toward higher indexes and zero-fill the low lanes.\n"
            "   --  @param Value The source lanes.\n"
            "   --  @param Count The lane displacement.\n"
            "   --  @return The slid lanes, or zero when Count reaches or exceeds the width.",
        ))
    return f"""private package Flyology_SIMD.Wide.Permute_Mechanism
  with Preelaborate
is
   --  Target-selected mechanism for reusable Wide lane maps.

{chr(10).join(declarations)}
end Flyology_SIMD.Wide.Permute_Mechanism;
"""


def permute_composed_body_text() -> str:
    bodies = []
    for f in FAMILIES:
        bodies.extend((
            f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));",
            f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));",
            f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Reverse_Lanes (Value));",
            f"   function Interleave_Low (Left, Right : {f.vector}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));",
            f"   function Interleave_High (Left, Right : {f.vector}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Interleave_High (Left, Right));",
            f"   function Deinterleave_Even (Left, Right : {f.vector}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));",
            f"   function Deinterleave_Odd (Left, Right : {f.vector}) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));",
            f"   function Slide_Lanes_Toward_Low (Value : {f.vector}; Count : Natural) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));",
            f"   function Slide_Lanes_Toward_High (Value : {f.vector}; Count : Natural) return {f.vector} is\n"
            "     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));",
        ))
    return f"""package body Flyology_SIMD.Wide.Permute_Mechanism is
{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Permute_Mechanism;
"""


def movement_mechanism_bodies(
    f: Family, one_permute: str, two_permute: str
) -> list[str]:
    """Generate fixed lane movements through the private byte-map leaves."""
    lane_bytes = f.bits // 8
    last = f.lanes - 1
    half = f.half_lanes

    def one_source(name: str, source_lane: str) -> str:
        return (
            f"   function {name} (Value : {f.vector}) return {f.vector} is\n"
            "      Indexes : Byte_Map;\n"
            "   begin\n"
            f"      for Result_Lane in {f.index} loop\n"
            f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"            Indexes (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"              U8 (({source_lane}) * {lane_bytes} + Byte);\n"
            "         end loop;\n"
            "      end loop;\n"
            f"      return {one_permute} (Value, Indexes);\n"
            f"   end {name};"
        )

    def two_source(name: str, lane: str, from_right: str) -> str:
        return (
            f"   function {name} (Left, Right : {f.vector}) return {f.vector} is\n"
            "      Indexes : Byte_Map;\n"
            "   begin\n"
            f"      for Result_Lane in {f.index} loop\n"
            f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"            Indexes (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"              (if {from_right} then U8 (32) else U8 (0))\n"
            f"              + U8 (({lane}) * {lane_bytes} + Byte);\n"
            "         end loop;\n"
            "      end loop;\n"
            f"      return {two_permute} (Left, Right, Indexes);\n"
            f"   end {name};"
        )

    return [
        one_source("Reverse_Lanes", f"{last} - Result_Lane"),
        two_source("Interleave_Low", "Result_Lane / 2", "Result_Lane mod 2 = 1"),
        two_source(
            "Interleave_High", f"{half} + Result_Lane / 2",
            "Result_Lane mod 2 = 1",
        ),
        two_source(
            "Deinterleave_Even",
            f"2 * (Result_Lane mod {half})",
            f"Result_Lane >= {half}",
        ),
        two_source(
            "Deinterleave_Odd",
            f"2 * (Result_Lane mod {half}) + 1",
            f"Result_Lane >= {half}",
        ),
        (
            f"   function Slide_Lanes_Toward_Low (Value : {f.vector}; Count : Natural) return {f.vector} is\n"
            "      Indexes : Byte_Map := [others => 32];\n"
            "   begin\n"
            f"      if Count < {f.lanes} then\n"
            f"         for Result_Lane in {f.index} loop\n"
            f"            if Result_Lane + Count < {f.lanes} then\n"
            f"               for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"                  Indexes (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"                    U8 ((Result_Lane + Count) * {lane_bytes} + Byte);\n"
            "               end loop;\n"
            "            end if;\n"
            "         end loop;\n"
            "      end if;\n"
            f"      return {one_permute} (Value, Indexes);\n"
            "   end Slide_Lanes_Toward_Low;"
        ),
        (
            f"   function Slide_Lanes_Toward_High (Value : {f.vector}; Count : Natural) return {f.vector} is\n"
            "      Indexes : Byte_Map := [others => 32];\n"
            "   begin\n"
            f"      if Count < {f.lanes} then\n"
            f"         for Result_Lane in {f.index} loop\n"
            "            if Result_Lane >= Count then\n"
            f"               for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"                  Indexes (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"                    U8 ((Result_Lane - Count) * {lane_bytes} + Byte);\n"
            "               end loop;\n"
            "            end if;\n"
            "         end loop;\n"
            "      end if;\n"
            f"      return {one_permute} (Value, Indexes);\n"
            "   end Slide_Lanes_Toward_High;"
        ),
    ]


def permute_aarch64_body_text() -> str:
    one_instantiations = []
    two_instantiations = []
    bodies = []
    for f in FAMILIES:
        one_permute = f"Permute_One_{f.vector}"
        two_permute = f"Permute_Two_{f.vector}"
        one_instantiations.extend((
            f"   function {one_permute} is new Permute_One_256 ({f.vector});",
            f"   pragma Inline_Always ({one_permute});",
        ))
        two_instantiations.extend((
            f"   function {two_permute} is new Permute_Two_256 ({f.vector});",
            f"   pragma Inline_Always ({two_permute});",
        ))
        lane_bytes = f.bits // 8
        bodies.append(
            f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n"
            "      Indexes : Byte_Map;\n"
            "   begin\n"
            f"      for Result_Lane in {f.index} loop\n"
            f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"            Indexes (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"              U8 (Map.Selectors (Result_Lane) * {lane_bytes} + Byte);\n"
            "         end loop;\n"
            "      end loop;\n"
            f"      return {one_permute} (Value, Indexes);\n"
            "   end Permute_Lanes;"
        )
        bodies.extend(movement_mechanism_bodies(f, one_permute, two_permute))
        bodies.append(
            f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector} is\n"
            "      Indexes : Byte_Map;\n"
            "   begin\n"
            f"      for Result_Lane in {f.index} loop\n"
            f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            "            Indexes (Result_Lane * " + str(lane_bytes) + " + Byte) :=\n"
            "              (if Map.Selectors (Result_Lane).From_Right\n"
            "               then U8 (32)\n"
            "               else U8 (0))\n"
            f"              + U8 (Map.Selectors (Result_Lane).Lane * {lane_bytes} + Byte);\n"
            "         end loop;\n"
            "      end loop;\n"
            f"      return {two_permute} (Left, Right, Indexes);\n"
            "   end Permute_Lanes;"
        )
    return f"""with System.Machine_Code;

package body Flyology_SIMD.Wide.Permute_Mechanism is
   use System.Machine_Code;
   use type Interfaces.Unsigned_8;

   type Byte_Map is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;

   generic
      type Vector_Type is private;
   function Permute_One_256
     (Value : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_One_256
     (Value : Vector_Type; Map : Byte_Map) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2]" & ASCII.LF & ASCII.HT &
           "tbl v3.16b, {{v0.16b, v1.16b}}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2, #16]" & ASCII.LF & ASCII.HT &
           "tbl v3.16b, {{v0.16b, v1.16b}}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0, #16]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Map'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Permute_One_256;

   generic
      type Vector_Type is private;
   function Permute_Two_256
     (Left, Right : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_Two_256
     (Left, Right : Vector_Type; Map : Byte_Map) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2]" & ASCII.LF & ASCII.HT &
           "ldr q3, [%2, #16]" & ASCII.LF & ASCII.HT &
           "ldr q4, [%3]" & ASCII.LF & ASCII.HT &
           "tbl v5.16b, {{v0.16b, v1.16b, v2.16b, v3.16b}}, v4.16b" & ASCII.LF & ASCII.HT &
           "str q5, [%0]" & ASCII.LF & ASCII.HT &
           "ldr q4, [%3, #16]" & ASCII.LF & ASCII.HT &
           "tbl v5.16b, {{v0.16b, v1.16b, v2.16b, v3.16b}}, v4.16b" & ASCII.LF & ASCII.HT &
           "str q5, [%0, #16]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address),
            System.Address'Asm_Input ("r", Map'Address)],
         Clobber => "v0,v1,v2,v3,v4,v5,memory",
         Volatile => True);
      return Result;
   end Permute_Two_256;

{chr(10).join(one_instantiations)}
{chr(10).join(two_instantiations)}

{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Permute_Mechanism;
"""


def permute_avx2_body_text() -> str:
    one_instantiations = []
    two_instantiations = []
    bodies = []
    for f in FAMILIES:
        one_permute = f"Permute_One_{f.vector}"
        two_permute = f"Permute_Two_{f.vector}"
        one_instantiations.extend((
            f"   function {one_permute} is new Permute_One_256 ({f.vector});",
            f"   pragma Inline_Always ({one_permute});",
        ))
        two_instantiations.extend((
            f"   function {two_permute} is new Permute_Two_256 ({f.vector});",
            f"   pragma Inline_Always ({two_permute});",
        ))
        lane_bytes = f.bits // 8
        bodies.append(
            f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n"
            "      Indexes : Byte_Map;\n"
            "   begin\n"
            f"      for Result_Lane in {f.index} loop\n"
            f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"            Indexes (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"              U8 (Map.Selectors (Result_Lane) * {lane_bytes} + Byte);\n"
            "         end loop;\n"
            "      end loop;\n"
            f"      return {one_permute} (Value, Indexes);\n"
            "   end Permute_Lanes;"
        )
        bodies.extend(movement_mechanism_bodies(f, one_permute, two_permute))
        bodies.append(
            f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector} is\n"
            "      Indexes : Byte_Map;\n"
            "   begin\n"
            f"      for Result_Lane in {f.index} loop\n"
            f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            "            Indexes (Result_Lane * " + str(lane_bytes) + " + Byte) :=\n"
            "              (if Map.Selectors (Result_Lane).From_Right\n"
            "               then U8 (32)\n"
            "               else U8 (0))\n"
            f"              + U8 (Map.Selectors (Result_Lane).Lane * {lane_bytes} + Byte);\n"
            "         end loop;\n"
            "      end loop;\n"
            f"      return {two_permute} (Left, Right, Indexes);\n"
            "   end Permute_Lanes;"
        )
    return f"""with System.Machine_Code;

package body Flyology_SIMD.Wide.Permute_Mechanism is
   use System.Machine_Code;
   use type Interfaces.Unsigned_8;

   type Byte_Map is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;
   type Byte_Constants is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;

   Lane_Bias : aliased constant Byte_Constants :=
     [0 .. 15 => 0, 16 .. 31 => 16];
   Sixteen : aliased constant U8 := 16;
   Thirty_Two : aliased constant U8 := 32;

   generic
      type Vector_Type is private;
   function Permute_One_256
     (Value : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_One_256
     (Value : Vector_Type; Map : Byte_Map) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm1, %%ymm0, %%ymm2" & ASCII.LF & ASCII.HT &
           "vperm2i128 $1, %%ymm0, %%ymm0, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqu (%3), %%ymm4" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm4, %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%4), %%ymm5" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%5), %%ymm6" & ASCII.LF & ASCII.HT &
           "vpand %%ymm1, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm5, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpand %%ymm6, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm2, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Map'Address),
            System.Address'Asm_Input ("r", Lane_Bias'Address),
            System.Address'Asm_Input ("r", Sixteen'Address),
            System.Address'Asm_Input ("r", Thirty_Two'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,memory",
         Volatile => True);
      return Result;
   end Permute_One_256;

   generic
      type Vector_Type is private;
   function Permute_Two_256
     (Left, Right : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_Two_256
     (Left, Right : Vector_Type; Map : Byte_Map) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmovdqu (%3), %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqu (%4), %%ymm9" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm9, %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%5), %%ymm8" & ASCII.LF & ASCII.HT &
           "vpand %%ymm8, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm8, %%ymm8, %%ymm8" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm8, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm0, %%ymm4" & ASCII.LF & ASCII.HT &
           "vperm2i128 $1, %%ymm0, %%ymm0, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm5, %%ymm3, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpor %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm1, %%ymm6" & ASCII.LF & ASCII.HT &
           "vperm2i128 $1, %%ymm1, %%ymm1, %%ymm7" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm7, %%ymm7" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm7, %%ymm3, %%ymm7" & ASCII.LF & ASCII.HT &
           "vpor %%ymm7, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%6), %%ymm10" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm10, %%ymm10" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm8, %%ymm10, %%ymm10" & ASCII.LF & ASCII.HT &
           "vpand %%ymm10, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm6, %%ymm10, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpor %%ymm6, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm4, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address),
            System.Address'Asm_Input ("r", Map'Address),
            System.Address'Asm_Input ("r", Lane_Bias'Address),
            System.Address'Asm_Input ("r", Sixteen'Address),
            System.Address'Asm_Input ("r", Thirty_Two'Address)],
         Clobber =>
           "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,ymm8,ymm9,ymm10,memory",
         Volatile => True);
      return Result;
   end Permute_Two_256;

{chr(10).join(one_instantiations)}
{chr(10).join(two_instantiations)}

{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Permute_Mechanism;
"""


def compact_composed_body_text() -> str:
    bodies = []
    for f in FAMILIES:
        for operation in ("Compress", "Expand"):
            bodies.append(
                f"   function {operation} (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n"
                f"     (Flyology_SIMD.Wide.{operation} (Value, Mask));"
            )
    return f"""package body Flyology_SIMD.Wide.Compact_Mechanism is
{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Compact_Mechanism;
"""


def compact_aarch64_body_text() -> str:
    instantiations = []
    bodies = []
    for f in FAMILIES:
        permute = f"Permute_{f.vector}"
        instantiations.extend((
            f"   function {permute} is new Permute_256 ({f.vector});",
            f"   pragma Inline_Always ({permute});",
        ))
        lane_bytes = f.bits // 8
        truth = (
            f"(Bits and Interfaces.Shift_Left ({f.mask_bits}'(1), Lane)) /= 0"
        )
        bodies.append(
            f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n"
            "      Map : Byte_Map := [others => 32];\n"
            f"      Bits : constant {f.mask_bits} := Flyology_SIMD.Wide.To_Bit_Mask (Mask);\n"
            "      Result_Lane : Natural := 0;\n"
            "   begin\n"
            f"      for Lane in {f.index} loop\n"
            f"         if {truth} then\n"
            f"            for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"               Map (Result_Lane * {lane_bytes} + Byte) :=\n"
            f"                 U8 (Lane * {lane_bytes} + Byte);\n"
            "            end loop;\n"
            "            Result_Lane := Result_Lane + 1;\n"
            "         end if;\n"
            "      end loop;\n"
            f"      return {permute} (Value, Map);\n"
            "   end Compress;"
        )
        bodies.append(
            f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n"
            "      Map : Byte_Map := [others => 32];\n"
            f"      Bits : constant {f.mask_bits} := Flyology_SIMD.Wide.To_Bit_Mask (Mask);\n"
            "      Source_Lane : Natural := 0;\n"
            "   begin\n"
            f"      for Lane in {f.index} loop\n"
            f"         if {truth} then\n"
            f"            for Byte in Natural range 0 .. {lane_bytes - 1} loop\n"
            f"               Map (Lane * {lane_bytes} + Byte) :=\n"
            f"                 U8 (Source_Lane * {lane_bytes} + Byte);\n"
            "            end loop;\n"
            "            Source_Lane := Source_Lane + 1;\n"
            "         end if;\n"
            "      end loop;\n"
            f"      return {permute} (Value, Map);\n"
            "   end Expand;"
        )
    return f"""with System.Machine_Code;

package body Flyology_SIMD.Wide.Compact_Mechanism is
   use System.Machine_Code;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   type Byte_Map is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;

   generic
      type Vector_Type is private;
   function Permute_256 (Value : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_256 (Value : Vector_Type; Map : Byte_Map) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2]" & ASCII.LF & ASCII.HT &
           "tbl v3.16b, {{v0.16b, v1.16b}}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2, #16]" & ASCII.LF & ASCII.HT &
           "tbl v3.16b, {{v0.16b, v1.16b}}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0, #16]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Map'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Permute_256;

{chr(10).join(instantiations)}

{chr(10).join(bodies)}
end Flyology_SIMD.Wide.Compact_Mechanism;
"""


def write_or_check(path: Path, content: str, check: bool) -> None:
    if check:
        if not path.exists() or path.read_text() != content:
            raise SystemExit(f"generated file is stale: {path.relative_to(ROOT)}")
    else:
        path.write_text(content)


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    outputs = {
        SPEC: spec_text(), BODY: body_text(),
        NATIVE_SPEC: native_spec_text(), NATIVE_BODY: native_body_text(),
        COMPACT_SPEC: compact_spec_text(),
        COMPACT_AARCH64: compact_aarch64_body_text(),
        COMPACT_COMPOSED: compact_composed_body_text(),
        COMPACT_AVX2: compact_composed_body_text(),
        COMPACT_INVALID: compact_composed_body_text(),
        FLOAT_REDUCE_SPEC: float_reduce_spec_text(),
        FLOAT_REDUCE_AARCH64: float_reduce_aarch64_body_text(),
        FLOAT_REDUCE_COMPOSED: float_reduce_composed_body_text(),
        FLOAT_REDUCE_AVX2: float_reduce_composed_body_text(),
        FLOAT_REDUCE_INVALID: float_reduce_composed_body_text(),
        FLOAT_ARITH_SPEC: float_arithmetic_spec_text(),
        FLOAT_ARITH_AARCH64: float_arithmetic_composed_body_text(),
        FLOAT_ARITH_COMPOSED: float_arithmetic_composed_body_text(),
        FLOAT_ARITH_AVX2: float_arithmetic_avx2_body_text(),
        FLOAT_ARITH_INVALID: float_arithmetic_composed_body_text(),
        FLOAT_ARITH_AVX2_LEAF_SPEC: float_arithmetic_avx2_leaf_spec_text(),
        FLOAT_ARITH_AVX2_LEAF_BODY: float_arithmetic_avx2_leaf_body_text(),
        PERMUTE_SPEC: permute_spec_text(),
        PERMUTE_AARCH64: permute_aarch64_body_text(),
        PERMUTE_COMPOSED: permute_composed_body_text(),
        PERMUTE_AVX2: permute_avx2_body_text(),
        PERMUTE_INVALID: permute_composed_body_text(),
    }
    for path, content in outputs.items():
        write_or_check(path, content, args.check)


if __name__ == "__main__":
    main()
