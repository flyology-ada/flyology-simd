#!/usr/bin/env python3
"""Generate the portable 256-bit value family and pair-composed backend."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "src" / "flyology_simd-wide.ads"
BODY = ROOT / "src" / "flyology_simd-wide.adb"
NATIVE_SPEC = ROOT / "src" / "flyology_simd-wide-native.ads"
NATIVE_BODY = ROOT / "src" / "flyology_simd-wide-native.adb"


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
            f"   type {f.mask} is private;",
            f"   --  One semantic Boolean truth for each of {f.lanes} lanes.",
            f"   subtype {f.mask_bits} is {mask_storage(f)} range 0 .. {(1 << f.lanes) - 1};",
            f"   --  Compact bits for exactly {f.lanes} mask lanes.",
        ]
    out += [
        f"   type {f.values} is array ({f.index}) of {f.scalar};",
        f"   --  {f.scalar} lane values in logical lane order.",
        f"   type {f.vector} is private;",
        f"   --  A private 256-bit vector containing {f.lanes} {f.scalar} lanes.",
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


def spec_text() -> str:
    seen_shapes: set[tuple[int, int]] = set()
    declarations_list = []
    for f in FAMILIES:
        shape = (f.bits, f.lanes)
        declarations_list.append(declaration(f, shape not in seen_shapes))
        seen_shapes.add(shape)
    declarations = "\n\n".join(declarations_list)
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
                f"   type {f.mask} is record\n      Low, High : {f.half_mask};\n   end record;",
            ]
            seen_shapes.add(shape)
    return f"""with Interfaces;

--  Portable 256-bit values. Representations stay private and are not an ABI.
package Flyology_SIMD.Wide
  with Preelaborate
is
{declarations}

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
        out.append(f"   function Make_Lane_Map (Selectors : {f.selectors}) return {f.lane_map} is\n     ((Selectors => Selectors));")
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
    binary = (("Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number") if f.floating else
              ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate",
               "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max"))
    for name in binary:
        out.append(pair_function(name, f, f"Left, Right : {f.vector}", "Left.Low, Right.Low", "Left.High, Right.High", prefix=p))
    if not f.floating:
        out.append(pair_function("Bitwise_Not", f, f"Value : {f.vector}", "Value.Low", "Value.High", prefix=p))
        for name in ("Shift_Left_Logical", "Shift_Right_Logical") + (("Shift_Right_Arithmetic",) if f.signed else ()):
            out.append(pair_function(name, f, f"Value : {f.vector}; Count : Natural", "Value.Low, Count", "Value.High, Count", prefix=p))
    comparisons = ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal") + (("Unordered",) if f.floating else ())
    for name in comparisons:
        out.append(pair_function(name, f, f"Left, Right : {f.vector}", "Left.Low, Right.Low", "Left.High, Right.High", result=f.mask, prefix=p))
    out.append(pair_function("Select_Value", f, f"Mask : {f.mask}; If_True, If_False : {f.vector}",
                             "Mask.Low, If_True.Low, If_False.Low", "Mask.High, If_True.High, If_False.High", prefix=p))
    out += scalar_movement_body(f)
    if first_shape:
        out += mask_body(f, p)
    out += memory_body(f, p)
    return "\n\n".join(out)


def scalar_movement_body(f: Family) -> list[str]:
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
    return [
        f"   function Compress (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n      Result : {vals} := [others => {zero}];\n      Next : Natural := 0;\n   begin\n      for Lane in {idx} loop\n         if Test (Mask, Lane) then Result (Next) := Extract (Value, Lane); Next := Next + 1; end if;\n      end loop;\n      return From_Lanes (Result);\n   end Compress;",
        f"   function Expand (Value : {f.vector}; Mask : {f.mask}) return {f.vector} is\n      Result : {vals} := [others => {zero}];\n      Next : Natural := 0;\n   begin\n      for Lane in {idx} loop\n         if Test (Mask, Lane) then Result (Lane) := Extract (Value, Next); Next := Next + 1; end if;\n      end loop;\n      return From_Lanes (Result);\n   end Expand;",
        *reductions,
        f"   function Reverse_Lanes (Value : {f.vector}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract (Value, {total - 1} - Lane)]));",
        f"   function Permute_Lanes (Value : {f.vector}; Map : {f.lane_map}) return {f.vector} is\n     (From_Lanes ([for Lane in {idx} => Extract (Value, Map.Selectors (Lane))]));",
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
    return f"""with System.Storage_Elements;

package body Flyology_SIMD.Wide is
   use type System.Storage_Elements.Integer_Address;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type F32;
   use type F64;
{bodies}
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
            if " with Pre => " in line:
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
    return f"""--  Statically selected 256-bit composition through the native 128-bit backend.
package Flyology_SIMD.Wide.Native
  with Preelaborate
is
{chr(10).join(declarations)}
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
    return f"""with Flyology_SIMD.Backends.Native;
with System.Storage_Elements;

package body Flyology_SIMD.Wide.Native is
   use type System.Storage_Elements.Integer_Address;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type F32;
   use type F64;
{chr(10).join(body_list)}
end Flyology_SIMD.Wide.Native;
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
    }
    for path, content in outputs.items():
        write_or_check(path, content, args.check)


if __name__ == "__main__":
    main()
