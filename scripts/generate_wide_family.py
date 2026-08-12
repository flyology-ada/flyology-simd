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


def doc(summary: str, params: tuple[str, ...] = (), returns: bool = True) -> str:
    lines = [f"   --  {summary}"]
    for param in params:
        lines.append(f"   --  @param {param} The {param.lower().replace('_', ' ')} input.")
    if returns:
        lines.append("   --  @return The operation result.")
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
    for name in movement:
        out += [f"   function {name} (Left, Right : {f.vector}) return {f.vector};",
                doc(f"Apply {name} with the documented lane mapping.", ("Left", "Right"))]
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
        for name in ("Population_Count", "First_True", "Last_True"):
            out += [f"   function {name} (Mask : {f.mask}) return {f.count};",
                    doc(f"Return the {name} mask position or count result.", ("Mask",))]
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
    return "\n".join(out)


def conversion_declarations(native: bool = False) -> str:
    out: list[str] = []

    def add(line: str, summary: str, params: tuple[str, ...]) -> None:
        if native:
            line = line[:-1] + " with Inline_Always;"
        out.extend((line, doc(summary, params)))

    for source, _, target, *_ in (*WIDENINGS, *FLOAT_WIDENINGS):
        source_wide = BY_HALF[source].vector
        target_wide = BY_HALF[target].vector
        for name, half in (("Widen_Low", "low"), ("Widen_High", "high")):
            summary = (
                f"Widen the {half} binary32 source half to binary64 and preserve lane order. "
                "Finite values convert exactly. Signed zero and infinity are preserved. "
                "A NaN produces a NaN with unspecified payload and signaling state."
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
            "With the default round-to-nearest, ties-to-even environment, round binary64 lanes to binary32 and concatenate Low before High. Preserve signed zero and infinity. Use gradual underflow and signed overflow to infinity. A NaN remains a NaN with unspecified payload and signaling state. Do not modify the floating-point control register.",
            ("Low", "High"),
        )

    for source, _, target, *_ in INTEGER_TO_FLOAT_CONVERSIONS:
        add(
            f"   function Convert_Round (Value : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            "With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not modify the floating-point control register.",
            ("Value",),
        )

    for source, _, target, *_ in FLOAT_TO_INTEGER_CONVERSIONS:
        add(
            f"   function Convert_Truncate_Saturate (Value : {BY_HALF[source].vector}) return {BY_HALF[target].vector};",
            "Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode.",
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
        reductions = [
            f"   function Reduce_Add (Value : {f.vector}) return {f.scalar} is\n      Lanes : constant {vals} := To_Lanes (Value);\n      Result : {f.scalar} := 0.0;\n   begin\n      for Lane in {f.index} loop Result := Result + Lanes (Lane); end loop;\n      return Result;\n   end Reduce_Add;",
            f"   function Reduce_Min_Number (Value : {f.vector}) return {f.scalar} is\n      Result : {f.scalar} := Extract (Value, 0);\n   begin\n      for Lane in 1 .. {total - 1} loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Min_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;\n      return Result;\n   end Reduce_Min_Number;",
            f"   function Reduce_Max_Number (Value : {f.vector}) return {f.scalar} is\n      Result : {f.scalar} := Extract (Value, 0);\n   begin\n      for Lane in 1 .. {total - 1} loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Max_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;\n      return Result;\n   end Reduce_Max_Number;",
        ]
    else:
        reductions = [
            f"   function Reduce_Add_Wrap (Value : {f.vector}) return {f.scalar} is\n      Pair : constant {f.half} := Flyology_SIMD.Add_Wrap (Flyology_SIMD.Splat (Flyology_SIMD.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Splat (Flyology_SIMD.Reduce_Add_Wrap (Value.High)));\n   begin return Flyology_SIMD.Extract (Pair, 0); end Reduce_Add_Wrap;",
            f"   function Reduce_Min (Value : {f.vector}) return {f.scalar} is\n      Pair : constant {f.half} := Flyology_SIMD.Min (Flyology_SIMD.Splat (Flyology_SIMD.Reduce_Min (Value.Low)), Flyology_SIMD.Splat (Flyology_SIMD.Reduce_Min (Value.High)));\n   begin return Flyology_SIMD.Extract (Pair, 0); end Reduce_Min;",
            f"   function Reduce_Max (Value : {f.vector}) return {f.scalar} is\n      Pair : constant {f.half} := Flyology_SIMD.Max (Flyology_SIMD.Splat (Flyology_SIMD.Reduce_Max (Value.Low)), Flyology_SIMD.Splat (Flyology_SIMD.Reduce_Max (Value.High)));\n   begin return Flyology_SIMD.Extract (Pair, 0); end Reduce_Max;",
        ]
    compact = [
        f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n      Result : {vals} := [others => {zero}];\n      Next : Natural := 0;\n   begin\n      for Lane in {idx} loop\n         if Test (Mask, Lane) then Result (Next) := Extract (Value, Lane); Next := Next + 1; end if;\n      end loop;\n      return From_Lanes (Result);\n   end Compress;",
        f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n      Result : {vals} := [others => {zero}];\n      Next : Natural := 0;\n   begin\n      for Lane in {idx} loop\n         if Test (Mask, Lane) then Result (Lane) := Extract (Value, Next); Next := Next + 1; end if;\n      end loop;\n      return From_Lanes (Result);\n   end Expand;",
    ] if prefix == "Flyology_SIMD" else [
        f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n     (Compact_Mechanism.Compress (Value, Mask));",
        f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n     (Compact_Mechanism.Expand (Value, Mask));",
    ]
    return [
        *compact,
        *reductions,
        f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract (Value, {total - 1} - Lane)]));",
        f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract (Value, Map.Selectors (Lane))]));",
        f"   function Permute_Lanes (Left, Right : {f.vector}; Map : {f.two_map}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract ((if Map.Selectors (Lane).From_Right then Right else Left), Map.Selectors (Lane).Lane)]));",
        f"   function Interleave_Low (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane mod 2 = 0 then Extract (Left, Lane / 2) else Extract (Right, Lane / 2))]));",
        f"   function Interleave_High (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane mod 2 = 0 then Extract (Left, {half} + Lane / 2) else Extract (Right, {half} + Lane / 2))]));",
        f"   function Deinterleave_Even (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane < {half} then Extract (Left, 2 * Lane) else Extract (Right, 2 * (Lane - {half})))]));",
        f"   function Deinterleave_Odd (Left, Right : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => (if Lane < {half} then Extract (Left, 2 * Lane + 1) else Extract (Right, 2 * (Lane - {half}) + 1))]));",
        f"   function Slide_Lanes_Toward_Low (Value : {f.vector}; Count : Natural) return {f.vector} is\n     (if Count >= {total} then Zero else From_Lanes ([for Lane in {idx} => (if Lane + Count < {total} then Extract (Value, Lane + Count) else {zero})]));",
        f"   function Slide_Lanes_Toward_High (Value : {f.vector}; Count : Natural) return {f.vector} is\n     (if Count >= {total} then Zero else From_Lanes ([for Lane in {idx} => (if Lane >= Count then Extract (Value, Lane - Count) else {zero})]));",
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
with Flyology_SIMD.Wide.Lookup_Mechanism;
with System.Storage_Elements;

package body Flyology_SIMD.Wide.Native is
   package Byte_Mechanism renames Flyology_SIMD.Wide.Byte_Mechanism;
   package Compact_Mechanism renames Flyology_SIMD.Wide.Compact_Mechanism;
   package Lookup_Mechanism renames Flyology_SIMD.Wide.Lookup_Mechanism;
   use type System.Storage_Elements.Integer_Address;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type F32;
   use type F64;
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
    }
    for path, content in outputs.items():
        write_or_check(path, content, args.check)


if __name__ == "__main__":
    main()
