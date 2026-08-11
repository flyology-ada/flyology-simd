#!/usr/bin/env python3
"""Generate independent tests for every explicit 128-bit conversion."""

import sys
from pathlib import Path

from generate_full_family import (
    FLOAT_TO_INTEGER_CONVERSIONS,
    FLOAT_NARROWINGS,
    FLOAT_WIDENINGS,
    INTEGER_TO_FLOAT_CONVERSIONS,
    NARROWINGS,
    ROOT,
    SIGNED_UNSIGNED_CONVERSIONS,
    SIGNED_TO_UNSIGNED_NARROWINGS,
    WIDENINGS,
    bit_cast_pairs,
    lane_index,
    lane_values,
)

OUTPUT = ROOT / "tests" / "conversion_tests.adb"


VECTOR_INFO = {
    "U8x16": ("U8", 8, 16, False),
    "I8x16": ("I8", 8, 16, True),
    "U16x8": ("U16", 16, 8, False),
    "I16x8": ("I16", 16, 8, True),
    "U32x4": ("U32", 32, 4, False),
    "I32x4": ("I32", 32, 4, True),
    "U64x2": ("U64", 64, 2, False),
    "I64x2": ("I64", 64, 2, True),
    "F32x4": ("F32", 32, 4, False),
    "F64x2": ("F64", 64, 2, False),
}


SIGNED_UNSIGNED_EDGE_CASES = [
    ("I8x16", "U8x16", 8, 16,
     "[-128, -1, 0, 1, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127]",
     "[0, 0, 0, 1, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127]"),
    ("U8x16", "I8x16", 8, 16,
     "[0, 1, 127, 128, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]",
     "[0, 1, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127]"),
    ("I16x8", "U16x8", 16, 8,
     "[-32_768, -1, 0, 1, 32_767, 32_767, 32_767, 32_767]",
     "[0, 0, 0, 1, 32_767, 32_767, 32_767, 32_767]"),
    ("U16x8", "I16x8", 16, 8,
     "[0, 1, 32_767, 32_768, 65_535, 65_535, 65_535, 65_535]",
     "[0, 1, 32_767, 32_767, 32_767, 32_767, 32_767, 32_767]"),
    ("I32x4", "U32x4", 32, 4,
     "[I32'First, -1, 0, 1]", "[0, 0, 0, 1]"),
    ("I32x4", "U32x4", 32, 4,
     "[I32'Last, I32'Last, I32'Last, I32'Last]",
     "[2_147_483_647, 2_147_483_647, 2_147_483_647, 2_147_483_647]"),
    ("U32x4", "I32x4", 32, 4,
     "[0, 1, 2_147_483_647, 2_147_483_648]",
     "[0, 1, 2_147_483_647, 2_147_483_647]"),
    ("U32x4", "I32x4", 32, 4,
     "[U32'Last, U32'Last, U32'Last, U32'Last]",
     "[I32'Last, I32'Last, I32'Last, I32'Last]"),
    ("I64x2", "U64x2", 64, 2,
     "[I64'First, -1]", "[0, 0]"),
    ("I64x2", "U64x2", 64, 2,
     "[0, 1]", "[0, 1]"),
    ("I64x2", "U64x2", 64, 2,
     "[I64'Last, I64'Last]",
     "[9_223_372_036_854_775_807, 9_223_372_036_854_775_807]"),
    ("U64x2", "I64x2", 64, 2,
     "[0, 1]", "[0, 1]"),
    ("U64x2", "I64x2", 64, 2,
     "[9_223_372_036_854_775_807, 9_223_372_036_854_775_808]",
     "[I64'Last, I64'Last]"),
    ("U64x2", "I64x2", 64, 2,
     "[U64'Last, U64'Last]", "[I64'Last, I64'Last]"),
]


def vector_values(vector: str) -> str:
    return "Lane_Values_8x16" if vector == "U8x16" else lane_values(vector)


def random_function(vector: str) -> list[str]:
    scalar, bits, lanes, signed = VECTOR_INFO[vector]
    values = vector_values(vector)
    index = lane_index(bits, lanes)
    if scalar.startswith("U"):
        expression = f"{scalar} (Next_U64 and U64 ({scalar}'Last))"
    elif scalar.startswith("I"):
        unsigned = "U" + scalar[1:]
        expression = f"{scalar}_Of_Bits ({unsigned} (Next_U64 and U64 ({unsigned}'Last)))"
    elif scalar == "F32":
        expression = "F32 (Interfaces.Integer_32 (Next_U64 mod 2_000_001) - 1_000_000) / 16.0"
    else:
        expression = "F64 (Interfaces.Integer_64 (Next_U64 mod 2_000_001) - 1_000_000) / 16.0"
    return [
        f"   function Random_{vector} return {vector} is",
        f"      Values : {values};",
        "   begin",
        f"      for Lane in {index} loop Values (Lane) := {expression}; end loop;",
        "      return From_Lanes (Values);",
        f"   end Random_{vector};",
        "",
    ]


def emit_bit_cast_test(source: str, source_scalar: str, target: str, target_scalar: str) -> list[str]:
    _, bits, lanes, _ = VECTOR_INFO[source]
    return [
        "      declare",
        f"         Source : constant {source} := Random_{source};",
        f"         Scalar_Result : constant {target} := Bit_Cast (Source);",
        f"         Native_Result : constant {target} := Backends.Native.Bit_Cast (Source);",
        "      begin",
        f"         for Lane in {lane_index(bits, lanes)} loop",
        f"            Check (Same (Extract (Scalar_Result, Lane), Cast_{source_scalar}_To_{target_scalar} (Extract (Source, Lane))), \"scalar {source} to {target} bit cast lane\");",
        f"            Check (Same (Extract (Native_Result, Lane), Cast_{source_scalar}_To_{target_scalar} (Extract (Source, Lane))), \"native {source} to {target} bit cast lane\");",
        "         end loop;",
        "      end;",
    ]


def emit_widen_test(source: str, source_scalar: str, target: str, target_scalar: str, result_lanes: int) -> list[str]:
    return [
        "      declare",
        f"         Source : constant {source} := Random_{source};",
        f"         Scalar_Low : constant {target} := Widen_Low (Source);",
        f"         Scalar_High : constant {target} := Widen_High (Source);",
        f"         Native_Low : constant {target} := Backends.Native.Widen_Low (Source);",
        f"         Native_High : constant {target} := Backends.Native.Widen_High (Source);",
        "      begin",
        f"         for Lane in Natural range 0 .. {result_lanes - 1} loop",
        f"            Check (Extract (Scalar_Low, Lane) = {target_scalar} (Extract (Source, Lane)), \"scalar {source} low widening lane\");",
        f"            Check (Extract (Native_Low, Lane) = {target_scalar} (Extract (Source, Lane)), \"native {source} low widening lane\");",
        f"            Check (Extract (Scalar_High, Lane) = {target_scalar} (Extract (Source, Lane + {result_lanes})), \"scalar {source} high widening lane\");",
        f"            Check (Extract (Native_High, Lane) = {target_scalar} (Extract (Source, Lane + {result_lanes})), \"native {source} high widening lane\");",
        "         end loop;",
        "      end;",
    ]


def emit_narrow_test(
    source: str,
    target: str,
    source_lanes: int,
    name: str,
    low_expression: str | None = None,
    high_expression: str | None = None,
) -> list[str]:
    helper = f"Oracle_{name}_{source}_To_{target}"
    low_expression = low_expression or f"Random_{source}"
    high_expression = high_expression or f"Random_{source}"
    def comparison(actual: str, expected: str) -> str:
        if name == "Narrow_Round":
            return f"Same ({actual}, {expected})"
        return f"{actual} = {expected}"

    scalar_low = comparison(
        "Extract (Scalar_Result, Lane)", f"{helper} (Extract (Low, Lane))"
    )
    native_low = comparison(
        "Extract (Native_Result, Lane)", f"{helper} (Extract (Low, Lane))"
    )
    scalar_high = comparison(
        f"Extract (Scalar_Result, Lane + {source_lanes})",
        f"{helper} (Extract (High, Lane))",
    )
    native_high = comparison(
        f"Extract (Native_Result, Lane + {source_lanes})",
        f"{helper} (Extract (High, Lane))",
    )
    return [
        "      declare",
        f"         Low : constant {source} := {low_expression};",
        f"         High : constant {source} := {high_expression};",
        f"         Scalar_Result : constant {target} := {name} (Low, High);",
        f"         Native_Result : constant {target} := Backends.Native.{name} (Low, High);",
        "      begin",
        f"         for Lane in Natural range 0 .. {source_lanes - 1} loop",
        f"            Check ({scalar_low}, \"scalar {name} {source} low lane\");",
        f"            Check ({native_low}, \"native {name} {source} low lane\");",
        f"            Check ({scalar_high}, \"scalar {name} {source} high lane\");",
        f"            Check ({native_high}, \"native {name} {source} high lane\");",
        "         end loop;",
        "      end;",
    ]


def emit_convert_round_test(source: str, target: str, bits: int, lanes: int) -> list[str]:
    return [
        "      declare",
        f"         Source : constant {source} := Random_{source};",
        f"         Scalar_Result : constant {target} := Convert_Round (Source);",
        f"         Native_Result : constant {target} := Backends.Native.Convert_Round (Source);",
        "      begin",
        f"         for Lane in {lane_index(bits, lanes)} loop",
        f"            Check (Same (Extract (Scalar_Result, Lane), Oracle_Convert_Round_{source}_To_{target} (Extract (Source, Lane))), \"scalar Convert_Round {source} lane\");",
        f"            Check (Same (Extract (Native_Result, Lane), Oracle_Convert_Round_{source}_To_{target} (Extract (Source, Lane))), \"native Convert_Round {source} lane\");",
        "         end loop;",
        "      end;",
    ]


def emit_float_to_integer_test(source: str, target: str, bits: int, lanes: int) -> list[str]:
    return [
        "      declare",
        f"         Source : constant {source} := Random_Convert_{source};",
        f"         Scalar_Result : constant {target} := Convert_Truncate_Saturate (Source);",
        f"         Native_Result : constant {target} := Backends.Native.Convert_Truncate_Saturate (Source);",
        "      begin",
        f"         for Lane in {lane_index(bits, lanes)} loop",
        f"            Check (Extract (Scalar_Result, Lane) = Oracle_Convert_Truncate_Saturate_{source}_To_{target} (Extract (Source, Lane)), \"scalar Convert_Truncate_Saturate {source} lane\");",
        f"            Check (Extract (Native_Result, Lane) = Oracle_Convert_Truncate_Saturate_{source}_To_{target} (Extract (Source, Lane)), \"native Convert_Truncate_Saturate {source} lane\");",
        "         end loop;",
        "      end;",
    ]


def emit_signed_unsigned_test(
    source: str,
    target: str,
    bits: int,
    lanes: int,
    source_expression: str | None = None,
) -> list[str]:
    source_expression = source_expression or f"Random_{source}"
    return [
        "      declare",
        f"         Source : constant {source} := {source_expression};",
        f"         Scalar_Result : constant {target} := Convert_Saturate (Source);",
        f"         Native_Result : constant {target} := Backends.Native.Convert_Saturate (Source);",
        "      begin",
        f"         for Lane in {lane_index(bits, lanes)} loop",
        f"            Check (Extract (Scalar_Result, Lane) = Oracle_Convert_Saturate_{source}_To_{target} (Extract (Source, Lane)), \"scalar Convert_Saturate {source} lane\");",
        f"            Check (Extract (Native_Result, Lane) = Oracle_Convert_Saturate_{source}_To_{target} (Extract (Source, Lane)), \"native Convert_Saturate {source} lane\");",
        "         end loop;",
        "      end;",
    ]


def emit_signed_unsigned_literal_test(
    source: str,
    target: str,
    bits: int,
    lanes: int,
    source_values: str,
    expected_values: str,
) -> list[str]:
    return [
        "      declare",
        f"         Source : constant {source} := From_Lanes ({source_values});",
        f"         Expected : constant {vector_values(target)} := {expected_values};",
        f"         Scalar_Result : constant {target} := Convert_Saturate (Source);",
        f"         Native_Result : constant {target} := Backends.Native.Convert_Saturate (Source);",
        "      begin",
        f"         for Lane in {lane_index(bits, lanes)} loop",
        f"            Check (Extract (Scalar_Result, Lane) = Expected (Lane), \"scalar literal Convert_Saturate {source} lane\");",
        f"            Check (Extract (Native_Result, Lane) = Expected (Lane), \"native literal Convert_Saturate {source} lane\");",
        "         end loop;",
        "      end;",
    ]


def boundary_vectors(
    source: str,
    source_scalar: str,
    target_scalar: str,
    source_lanes: int,
    signed_to_unsigned: bool,
) -> tuple[str, str]:
    slots = source_lanes * 2
    if signed_to_unsigned:
        cases = [
            "-1",
            "0",
            f"{source_scalar} ({target_scalar}'Last)",
            f"{source_scalar} ({target_scalar}'Last) + 1",
            f"{source_scalar}'First",
            f"{source_scalar}'Last",
        ]
    elif source_scalar.startswith("I"):
        cases = [
            f"{source_scalar} ({target_scalar}'First) - 1",
            f"{source_scalar} ({target_scalar}'First)",
            f"{source_scalar} ({target_scalar}'Last)",
            f"{source_scalar} ({target_scalar}'Last) + 1",
            "-1",
            "0",
            f"{source_scalar}'First",
            f"{source_scalar}'Last",
        ]
    else:
        cases = [
            "0",
            f"{source_scalar} ({target_scalar}'Last)",
            f"{source_scalar} ({target_scalar}'Last) + 1",
            f"{source_scalar}'Last",
        ]
    selected = [cases[index % len(cases)] for index in range(slots)]
    low = f"From_Lanes ([{', '.join(selected[:source_lanes])}])"
    high = f"From_Lanes ([{', '.join(selected[source_lanes:])}])"
    return low, high


def program() -> str:
    out = [
        "--  Generated by scripts/generate_conversion_tests.py; do not edit.",
        "with Ada.Command_Line;",
        "with Ada.Text_IO;",
        "with Ada.Unchecked_Conversion;",
        "with Interfaces;",
        "with Flyology_SIMD;",
        "with Flyology_SIMD.Backends.Native;",
        "",
        "procedure Conversion_Tests is",
        "   use Ada.Text_IO;",
        "   use Flyology_SIMD;",
        "   use type Interfaces.Unsigned_8;",
        "   use type Interfaces.Unsigned_16;",
        "   use type Interfaces.Unsigned_32;",
        "   use type Interfaces.Unsigned_64;",
        "   use type Interfaces.Integer_8;",
        "   use type Interfaces.Integer_16;",
        "   use type Interfaces.Integer_32;",
        "   use type Interfaces.Integer_64;",
        "   use type Interfaces.IEEE_Float_32;",
        "   use type Interfaces.IEEE_Float_64;",
        "",
        "   Seed : constant Interfaces.Unsigned_64 := 16#C045_7A57_1280_0A11#;",
        "   State : Interfaces.Unsigned_64 := Seed;",
        "   Failures : Natural := 0;",
        "",
        "   procedure Check (Condition : Boolean; Message : String) is",
        "   begin",
        "      if not Condition then Failures := Failures + 1; Put_Line (\"FAIL: \" & Message); end if;",
        "   end Check;",
        "",
        "   function Next_U64 return Interfaces.Unsigned_64 is",
        "   begin",
        "      State := State xor Interfaces.Shift_Left (State, 13);",
        "      State := State xor Interfaces.Shift_Right (State, 7);",
        "      State := State xor Interfaces.Shift_Left (State, 17);",
        "      return State;",
        "   end Next_U64;",
        "",
    ]

    for bits in (8, 16, 32, 64):
        out.append(
            f"   function I{bits}_Of_Bits is new Ada.Unchecked_Conversion (U{bits}, I{bits});"
        )
    for bits in (16, 32, 64):
        out.append(
            f"   function U{bits}_Of_Bits is new Ada.Unchecked_Conversion (I{bits}, U{bits});"
        )
    out += [
        "   function F32_Of_Bits is new Ada.Unchecked_Conversion (U32, F32);",
        "   function F64_Of_Bits is new Ada.Unchecked_Conversion (U64, F64);",
        "   function U32_Of_Bits is new Ada.Unchecked_Conversion (F32, U32);",
        "   function U64_Of_Bits is new Ada.Unchecked_Conversion (F64, U64);",
        "",
    ]

    for source, source_scalar, target, target_scalar in bit_cast_pairs():
        out.append(
            f"   function Cast_{source_scalar}_To_{target_scalar} is new Ada.Unchecked_Conversion ({source_scalar}, {target_scalar});"
        )
    out += [
        "",
        "   function Same (Left, Right : F32) return Boolean is (U32_Of_Bits (Left) = U32_Of_Bits (Right));",
        "   function Same (Left, Right : F64) return Boolean is (U64_Of_Bits (Left) = U64_Of_Bits (Right));",
    ]
    for scalar in ("U8", "I8", "U16", "I16", "U32", "I32", "U64", "I64"):
        out.append(f"   function Same (Left, Right : {scalar}) return Boolean is (Left = Right);")
    out += [
        "",
        "   function Is_NaN (Value : F64) return Boolean is",
        "      Bits : constant U64 := U64_Of_Bits (Value);",
        "   begin",
        "      return (Bits and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#",
        "        and then (Bits and 16#000F_FFFF_FFFF_FFFF#) /= 0;",
        "   end Is_NaN;",
        "   function Is_NaN (Value : F32) return Boolean is",
        "      Bits : constant U32 := U32_Of_Bits (Value);",
        "   begin",
        "      return (Bits and 16#7F80_0000#) = 16#7F80_0000#",
        "        and then (Bits and 16#007F_FFFF#) /= 0;",
        "   end Is_NaN;",
        "",
    ]

    for vector in VECTOR_INFO:
        out += random_function(vector)

    out += [
        "   function Random_Narrow_F64x2 return F64x2 is",
        "      Values : Lane_Values_F64x2;",
        "   begin",
        "      for Lane in Lane_Index_64x2 loop",
        "         declare",
        "            Sign_And_Fraction : constant U64 := Next_U64;",
        "            Unbiased_Exponent : constant Integer := Integer (Next_U64 mod 288) - 160;",
        "            Bits : constant U64 :=",
        "              (Sign_And_Fraction and 16#800F_FFFF_FFFF_FFFF#)",
        "              or Interfaces.Shift_Left (U64 (Unbiased_Exponent + 1_023), 52);",
        "         begin",
        "            Values (Lane) := F64_Of_Bits (Bits);",
        "         end;",
        "      end loop;",
        "      return From_Lanes (Values);",
        "   end Random_Narrow_F64x2;",
        "",
        "   function Random_Convert_F32x4 return F32x4 is",
        "      Values : Lane_Values_F32x4;",
        "   begin",
        "      for Lane in Lane_Index_32x4 loop",
        "         Values (Lane) := F32_Of_Bits (U32 (Next_U64 and U64 (U32'Last)));",
        "      end loop;",
        "      return From_Lanes (Values);",
        "   end Random_Convert_F32x4;",
        "",
        "   function Random_Convert_F64x2 return F64x2 is",
        "      Values : Lane_Values_F64x2;",
        "   begin",
        "      for Lane in Lane_Index_64x2 loop",
        "         Values (Lane) := F64_Of_Bits (Next_U64);",
        "      end loop;",
        "      return From_Lanes (Values);",
        "   end Random_Convert_F64x2;",
        "",
    ]

    for source, source_scalar, target, target_scalar, target_bits, _, signed in NARROWINGS:
        source_bits = target_bits * 2
        if signed:
            truncate = f"I{target_bits}_Of_Bits (U{target_bits} (U{source_bits}_Of_Bits (Item) and U{source_bits} (U{target_bits}'Last)))"
            saturate = f"(if Item < {source_scalar} ({target_scalar}'First) then {target_scalar}'First elsif Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last else {target_scalar} (Item))"
        else:
            truncate = f"{target_scalar} (Item and {source_scalar} ({target_scalar}'Last))"
            saturate = f"(if Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last else {target_scalar} (Item))"
        out += [
            f"   function Oracle_Narrow_Truncate_{source}_To_{target} (Item : {source_scalar}) return {target_scalar} is ({truncate});",
            f"   function Oracle_Narrow_Saturate_{source}_To_{target} (Item : {source_scalar}) return {target_scalar} is ({saturate});",
        ]
    for source, source_scalar, target, target_scalar, _, _, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        out.append(
            f"   function Oracle_Narrow_Saturate_{source}_To_{target} (Item : {source_scalar}) return {target_scalar} is (if Item < 0 then 0 elsif Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last else {target_scalar} (Item));"
        )
    for source, source_scalar, target, target_scalar, _, _, signed in SIGNED_UNSIGNED_CONVERSIONS:
        expression = (
            f"(if Item < 0 then 0 else {target_scalar} (Item))"
            if signed
            else f"(if Item > {source_scalar} ({target_scalar}'Last) then {target_scalar}'Last else {target_scalar} (Item))"
        )
        out.append(
            f"   function Oracle_Convert_Saturate_{source}_To_{target} (Item : {source_scalar}) return {target_scalar} is {expression};"
        )
    for source, _, target, _, _ in FLOAT_NARROWINGS:
        out += [
            f"   function Oracle_Narrow_Round_{source}_To_{target} (Item : F64) return F32 is",
            "      Bits : constant U64 := U64_Of_Bits (Item);",
            "      Sign : constant U32 :=",
            "        (if (Bits and 16#8000_0000_0000_0000#) = 0 then 0 else 16#8000_0000#);",
            "      Encoded_Exponent : constant Natural :=",
            "        Natural (Interfaces.Shift_Right (Bits, 52) and 16#7FF#);",
            "      Fraction : constant U64 := Bits and 16#000F_FFFF_FFFF_FFFF#;",
            "",
            "      function Round_Right (Value : U64; Count : Positive) return U64 is",
            "         Quotient : constant U64 := Interfaces.Shift_Right (Value, Count);",
            "         Half : constant U64 := Interfaces.Shift_Left (1, Count - 1);",
            "         Remainder : constant U64 :=",
            "           Value and (Interfaces.Shift_Left (1, Count) - 1);",
            "      begin",
            "         if Remainder > Half",
            "           or else (Remainder = Half and then (Quotient and 1) /= 0)",
            "         then",
            "            return Quotient + 1;",
            "         else",
            "            return Quotient;",
            "         end if;",
            "      end Round_Right;",
            "",
            "      Exponent : Integer;",
            "      Significant : U64;",
            "      Rounded : U64;",
            "   begin",
            "      if Encoded_Exponent = 0 then",
            "         return F32_Of_Bits (Sign);",
            "      elsif Encoded_Exponent = 16#7FF# then",
            "         if Fraction = 0 then",
            "            return F32_Of_Bits (Sign or 16#7F80_0000#);",
            "         else",
            "            return F32_Of_Bits (Sign or 16#7FC0_0000#);",
            "         end if;",
            "      end if;",
            "",
            "      Exponent := Encoded_Exponent - 1_023;",
            "      Significant := 16#0010_0000_0000_0000# or Fraction;",
            "      if Exponent >= -126 then",
            "         Rounded := Round_Right (Significant, 29);",
            "         if Rounded = 16#0100_0000# then",
            "            Rounded := 16#0080_0000#;",
            "            Exponent := Exponent + 1;",
            "         end if;",
            "         if Exponent > 127 then",
            "            return F32_Of_Bits (Sign or 16#7F80_0000#);",
            "         end if;",
            "         return F32_Of_Bits",
            "           (Sign or Interfaces.Shift_Left (U32 (Exponent + 127), 23)",
            "            or U32 (Rounded - 16#0080_0000#));",
            "      end if;",
            "",
            "      declare",
            "         Shift : constant Positive := -Exponent - 97;",
            "      begin",
            "         if Shift > 53 then",
            "            return F32_Of_Bits (Sign);",
            "         end if;",
            "         Rounded := Round_Right (Significant, Shift);",
            "         return F32_Of_Bits (Sign or U32 (Rounded));",
            "      end;",
            f"   end Oracle_Narrow_Round_{source}_To_{target};",
        ]

    out += [
        "",
        "   function Oracle_Integer_To_Float_Bits",
        "     (Magnitude : U64; Sign : U64; Fraction_Bits, Bias : Natural)",
        "      return U64",
        "   is",
        "      function Round_Right (Value : U64; Count : Positive) return U64 is",
        "         Quotient : constant U64 := Interfaces.Shift_Right (Value, Count);",
        "         Half : constant U64 := Interfaces.Shift_Left (1, Count - 1);",
        "         Remainder : constant U64 :=",
        "           Value and (Interfaces.Shift_Left (1, Count) - 1);",
        "      begin",
        "         if Remainder > Half",
        "           or else (Remainder = Half and then (Quotient and 1) /= 0)",
        "         then",
        "            return Quotient + 1;",
        "         else",
        "            return Quotient;",
        "         end if;",
        "      end Round_Right;",
        "",
        "      Highest : Natural := 0;",
        "      Scan : U64 := Magnitude;",
        "      Significant : U64;",
        "      Exponent : Natural;",
        "   begin",
        "      if Magnitude = 0 then",
        "         return Sign;",
        "      end if;",
        "      while Interfaces.Shift_Right (Scan, 1) /= 0 loop",
        "         Scan := Interfaces.Shift_Right (Scan, 1);",
        "         Highest := Highest + 1;",
        "      end loop;",
        "      Exponent := Highest;",
        "      if Highest <= Fraction_Bits then",
        "         Significant := Interfaces.Shift_Left (Magnitude, Fraction_Bits - Highest);",
        "      else",
        "         Significant := Round_Right (Magnitude, Highest - Fraction_Bits);",
        "         if Significant = Interfaces.Shift_Left (1, Fraction_Bits + 1) then",
        "            Significant := Interfaces.Shift_Right (Significant, 1);",
        "            Exponent := Exponent + 1;",
        "         end if;",
        "      end if;",
        "      return Sign",
        "        or Interfaces.Shift_Left (U64 (Exponent + Bias), Fraction_Bits)",
        "        or (Significant - Interfaces.Shift_Left (1, Fraction_Bits));",
        "   end Oracle_Integer_To_Float_Bits;",
        "",
        "   function Oracle_Convert_Round_I32x4_To_F32x4 (Item : I32) return F32 is",
        "      Bits : constant U32 := U32_Of_Bits (Item);",
        "      Negative : constant Boolean := (Bits and 16#8000_0000#) /= 0;",
        "      Magnitude : constant U64 :=",
        "        (if Negative then U64 ((not Bits) + 1) else U64 (Bits));",
        "      Sign : constant U64 := (if Negative then 16#8000_0000# else 0);",
        "   begin",
        "      return F32_Of_Bits",
        "        (U32 (Oracle_Integer_To_Float_Bits (Magnitude, Sign, 23, 127)));",
        "   end Oracle_Convert_Round_I32x4_To_F32x4;",
        "",
        "   function Oracle_Convert_Round_U32x4_To_F32x4 (Item : U32) return F32 is",
        "   begin",
        "      return F32_Of_Bits",
        "        (U32 (Oracle_Integer_To_Float_Bits (U64 (Item), 0, 23, 127)));",
        "   end Oracle_Convert_Round_U32x4_To_F32x4;",
        "",
        "   function Oracle_Convert_Round_I64x2_To_F64x2 (Item : I64) return F64 is",
        "      Bits : constant U64 := U64_Of_Bits (Item);",
        "      Negative : constant Boolean := (Bits and 16#8000_0000_0000_0000#) /= 0;",
        "      Magnitude : constant U64 := (if Negative then (not Bits) + 1 else Bits);",
        "      Sign : constant U64 := (if Negative then 16#8000_0000_0000_0000# else 0);",
        "   begin",
        "      return F64_Of_Bits",
        "        (Oracle_Integer_To_Float_Bits (Magnitude, Sign, 52, 1_023));",
        "   end Oracle_Convert_Round_I64x2_To_F64x2;",
        "",
        "   function Oracle_Convert_Round_U64x2_To_F64x2 (Item : U64) return F64 is",
        "   begin",
        "      return F64_Of_Bits",
        "        (Oracle_Integer_To_Float_Bits (Item, 0, 52, 1_023));",
        "   end Oracle_Convert_Round_U64x2_To_F64x2;",
        "",
        "   function Oracle_Float_To_Integer_Bits",
        "     (Bits, Sign_Mask, Fraction_Mask : U64;",
        "      Encoded_Exponent_Max, Fraction_Bits, Bias, Destination_Bits : Natural;",
        "      Signed : Boolean) return U64",
        "   is",
        "      Destination_Mask : constant U64 :=",
        "        (if Destination_Bits = 64 then U64'Last",
        "         else Interfaces.Shift_Left (1, Destination_Bits) - 1);",
        "      Minimum_Bits : constant U64 := Interfaces.Shift_Left (1, Destination_Bits - 1);",
        "      Maximum_Bits : constant U64 := Minimum_Bits - 1;",
        "      Negative : constant Boolean := (Bits and Sign_Mask) /= 0;",
        "      Fraction : constant U64 := Bits and Fraction_Mask;",
        "      Encoded_Exponent : constant Natural := Natural",
        "        (Interfaces.Shift_Right (Bits, Fraction_Bits) and U64 (Encoded_Exponent_Max));",
        "      Exponent : Integer;",
        "      Significant, Magnitude : U64;",
        "   begin",
        "      if Encoded_Exponent = Encoded_Exponent_Max and then Fraction /= 0 then",
        "         return 0;",
        "      elsif not Signed and then Negative then",
        "         return 0;",
        "      elsif Encoded_Exponent = 0 then",
        "         return 0;",
        "      end if;",
        "      Exponent := Encoded_Exponent - Bias;",
        "      if Exponent < 0 then",
        "         return 0;",
        "      elsif Exponent >= (if Signed then Destination_Bits - 1 else Destination_Bits) then",
        "         if Signed then",
        "            return (if Negative then Minimum_Bits else Maximum_Bits);",
        "         else",
        "            return Destination_Mask;",
        "         end if;",
        "      end if;",
        "      Significant := Interfaces.Shift_Left (1, Fraction_Bits) or Fraction;",
        "      if Exponent >= Fraction_Bits then",
        "         Magnitude := Interfaces.Shift_Left (Significant, Exponent - Fraction_Bits);",
        "      else",
        "         Magnitude := Interfaces.Shift_Right (Significant, Fraction_Bits - Exponent);",
        "      end if;",
        "      if Signed and then Negative then",
        "         return (0 - Magnitude) and Destination_Mask;",
        "      else",
        "         return Magnitude and Destination_Mask;",
        "      end if;",
        "   end Oracle_Float_To_Integer_Bits;",
        "",
        "   function Oracle_Convert_Truncate_Saturate_F32x4_To_I32x4 (Item : F32) return I32 is",
        "     (I32_Of_Bits (U32 (Oracle_Float_To_Integer_Bits",
        "        (U64 (U32_Of_Bits (Item)), 16#8000_0000#, 16#007F_FFFF#, 255, 23, 127, 32, True))));",
        "   function Oracle_Convert_Truncate_Saturate_F32x4_To_U32x4 (Item : F32) return U32 is",
        "     (U32 (Oracle_Float_To_Integer_Bits",
        "        (U64 (U32_Of_Bits (Item)), 16#8000_0000#, 16#007F_FFFF#, 255, 23, 127, 32, False)));",
        "   function Oracle_Convert_Truncate_Saturate_F64x2_To_I64x2 (Item : F64) return I64 is",
        "     (I64_Of_Bits (Oracle_Float_To_Integer_Bits",
        "        (U64_Of_Bits (Item), 16#8000_0000_0000_0000#, 16#000F_FFFF_FFFF_FFFF#, 2_047, 52, 1_023, 64, True)));",
        "   function Oracle_Convert_Truncate_Saturate_F64x2_To_U64x2 (Item : F64) return U64 is",
        "     (Oracle_Float_To_Integer_Bits",
        "        (U64_Of_Bits (Item), 16#8000_0000_0000_0000#, 16#000F_FFFF_FFFF_FFFF#, 2_047, 52, 1_023, 64, False));",
    ]

    out += [
        "",
        "   procedure Test_F32_Widen_Edges is",
        "      Zeros_And_Infinities : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#0000_0000#), F32_Of_Bits (16#8000_0000#),",
        "          F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#)]);",
        "      Finite_Boundaries : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#0000_0001#), F32_Of_Bits (16#007F_FFFF#),",
        "          F32_Of_Bits (16#0080_0000#), F32_Of_Bits (16#7F7F_FFFF#)]);",
        "      NaNs : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#7FC0_0001#), F32_Of_Bits (16#7F80_0001#),",
        "          F32_Of_Bits (16#FFC0_0001#), F32_Of_Bits (16#FF80_0001#)]);",
        "      type Expected_F64_Bits is array (Lane_Index_64x2) of U64;",
        "      Expected_Zero_Low : constant Expected_F64_Bits :=",
        "        [16#0000_0000_0000_0000#, 16#8000_0000_0000_0000#];",
        "      Expected_Zero_High : constant Expected_F64_Bits :=",
        "        [16#7FF0_0000_0000_0000#, 16#FFF0_0000_0000_0000#];",
        "      Expected_Finite_Low : constant Expected_F64_Bits :=",
        "        [16#36A0_0000_0000_0000#, 16#380F_FFFF_C000_0000#];",
        "      Expected_Finite_High : constant Expected_F64_Bits :=",
        "        [16#3810_0000_0000_0000#, 16#47EF_FFFF_E000_0000#];",
        "",
        "      procedure Check_Exact",
        "        (Value : F32x4; Expected_Low, Expected_High : Expected_F64_Bits) is",
        "         Scalar_Low : constant F64x2 := Widen_Low (Value);",
        "         Scalar_High : constant F64x2 := Widen_High (Value);",
        "         Native_Low : constant F64x2 := Backends.Native.Widen_Low (Value);",
        "         Native_High : constant F64x2 := Backends.Native.Widen_High (Value);",
        "      begin",
        "         for Lane in Lane_Index_64x2 loop",
        "            Check (U64_Of_Bits (Extract (Scalar_Low, Lane)) = Expected_Low (Lane), \"scalar F32 low widening edge\");",
        "            Check (U64_Of_Bits (Extract (Native_Low, Lane)) = Expected_Low (Lane), \"native F32 low widening edge\");",
        "            Check (U64_Of_Bits (Extract (Scalar_High, Lane)) = Expected_High (Lane), \"scalar F32 high widening edge\");",
        "            Check (U64_Of_Bits (Extract (Native_High, Lane)) = Expected_High (Lane), \"native F32 high widening edge\");",
        "         end loop;",
        "      end Check_Exact;",
        "",
        "      Scalar_NaN_Low : constant F64x2 := Widen_Low (NaNs);",
        "      Scalar_NaN_High : constant F64x2 := Widen_High (NaNs);",
        "      Native_NaN_Low : constant F64x2 := Backends.Native.Widen_Low (NaNs);",
        "      Native_NaN_High : constant F64x2 := Backends.Native.Widen_High (NaNs);",
        "   begin",
        "      Check_Exact (Zeros_And_Infinities, Expected_Zero_Low, Expected_Zero_High);",
        "      Check_Exact (Finite_Boundaries, Expected_Finite_Low, Expected_Finite_High);",
        "      for Lane in Lane_Index_64x2 loop",
        "         Check (Is_NaN (Extract (Scalar_NaN_Low, Lane)), \"scalar F32 low NaN widening\");",
        "         Check (Is_NaN (Extract (Native_NaN_Low, Lane)), \"native F32 low NaN widening\");",
        "         Check (Is_NaN (Extract (Scalar_NaN_High, Lane)), \"scalar F32 high NaN widening\");",
        "         Check (Is_NaN (Extract (Native_NaN_High, Lane)), \"native F32 high NaN widening\");",
        "      end loop;",
        "   end Test_F32_Widen_Edges;",
        "",
        "   procedure Test_F64_Narrow_Edges is",
        "      Zeros_And_Infinities_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#0000_0000_0000_0000#), F64_Of_Bits (16#8000_0000_0000_0000#)]);",
        "      Zeros_And_Infinities_High : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#7FF0_0000_0000_0000#), F64_Of_Bits (16#FFF0_0000_0000_0000#)]);",
        "      Rounding_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#3FF0_0000_1000_0000#), F64_Of_Bits (16#3FF0_0000_1000_0001#)]);",
        "      Rounding_High : constant F64x2 := From_Lanes",
        "        ([F64 (F32_Of_Bits (16#7F7F_FFFF#)), F64_Of_Bits (16#7FEF_FFFF_FFFF_FFFF#)]);",
        "      Negative_Rounding_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#BFF0_0000_1000_0000#), F64_Of_Bits (16#BFF0_0000_3000_0000#)]);",
        "      Negative_Rounding_High : constant F64x2 := From_Lanes",
        "        ([-F64 (F32_Of_Bits (16#7F7F_FFFF#)), F64_Of_Bits (16#FFEF_FFFF_FFFF_FFFF#)]);",
        "      Subnormal_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#3690_0000_0000_0000#), F64_Of_Bits (16#3690_0000_0000_0001#)]);",
        "      Subnormal_High : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#B690_0000_0000_0000#), F64_Of_Bits (16#B690_0000_0000_0001#)]);",
        "      Positive_Overflow_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#47EF_FFFF_EFFF_FFFF#), F64_Of_Bits (16#47EF_FFFF_F000_0000#)]);",
        "      Positive_Overflow_High : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#47EF_FFFF_F000_0001#), F64_Of_Bits (16#47EF_FFFF_E000_0000#)]);",
        "      Negative_Overflow_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#C7EF_FFFF_EFFF_FFFF#), F64_Of_Bits (16#C7EF_FFFF_F000_0000#)]);",
        "      Negative_Overflow_High : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#C7EF_FFFF_F000_0001#), F64_Of_Bits (16#C7EF_FFFF_E000_0000#)]);",
        "      NaN_Low : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#7FF8_0000_0000_0001#), F64_Of_Bits (16#7FF0_0000_0000_0001#)]);",
        "      NaN_High : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#FFF8_0000_0000_0001#), F64_Of_Bits (16#FFF0_0000_0000_0001#)]);",
        "      Exact : constant F32x4 := Narrow_Round (Zeros_And_Infinities_Low, Zeros_And_Infinities_High);",
        "      Native_Exact : constant F32x4 := Backends.Native.Narrow_Round (Zeros_And_Infinities_Low, Zeros_And_Infinities_High);",
        "      Rounded : constant F32x4 := Narrow_Round (Rounding_Low, Rounding_High);",
        "      Native_Rounded : constant F32x4 := Backends.Native.Narrow_Round (Rounding_Low, Rounding_High);",
        "      Negative_Rounded : constant F32x4 := Narrow_Round (Negative_Rounding_Low, Negative_Rounding_High);",
        "      Native_Negative_Rounded : constant F32x4 := Backends.Native.Narrow_Round (Negative_Rounding_Low, Negative_Rounding_High);",
        "      Subnormal : constant F32x4 := Narrow_Round (Subnormal_Low, Subnormal_High);",
        "      Native_Subnormal : constant F32x4 := Backends.Native.Narrow_Round (Subnormal_Low, Subnormal_High);",
        "      Positive_Overflow : constant F32x4 := Narrow_Round (Positive_Overflow_Low, Positive_Overflow_High);",
        "      Native_Positive_Overflow : constant F32x4 := Backends.Native.Narrow_Round (Positive_Overflow_Low, Positive_Overflow_High);",
        "      Negative_Overflow : constant F32x4 := Narrow_Round (Negative_Overflow_Low, Negative_Overflow_High);",
        "      Native_Negative_Overflow : constant F32x4 := Backends.Native.Narrow_Round (Negative_Overflow_Low, Negative_Overflow_High);",
        "      NaNs : constant F32x4 := Narrow_Round (NaN_Low, NaN_High);",
        "      Native_NaNs : constant F32x4 := Backends.Native.Narrow_Round (NaN_Low, NaN_High);",
        "      Expected_Exact : constant Lane_Values_F32x4 :=",
        "        [F32_Of_Bits (16#0000_0000#), F32_Of_Bits (16#8000_0000#), F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#)];",
        "      Expected_Rounded : constant Lane_Values_F32x4 :=",
        "        [F32_Of_Bits (16#3F80_0000#), F32_Of_Bits (16#3F80_0001#), F32_Of_Bits (16#7F7F_FFFF#), F32_Of_Bits (16#7F80_0000#)];",
        "      Expected_Negative_Rounded : constant Lane_Values_F32x4 :=",
        "        [F32_Of_Bits (16#BF80_0000#), F32_Of_Bits (16#BF80_0002#), F32_Of_Bits (16#FF7F_FFFF#), F32_Of_Bits (16#FF80_0000#)];",
        "      Expected_Subnormal : constant Lane_Values_F32x4 :=",
        "        [F32_Of_Bits (16#0000_0000#), F32_Of_Bits (16#0000_0001#), F32_Of_Bits (16#8000_0000#), F32_Of_Bits (16#8000_0001#)];",
        "      Expected_Positive_Overflow : constant Lane_Values_F32x4 :=",
        "        [F32_Of_Bits (16#7F7F_FFFF#), F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#7F7F_FFFF#)];",
        "      Expected_Negative_Overflow : constant Lane_Values_F32x4 :=",
        "        [F32_Of_Bits (16#FF7F_FFFF#), F32_Of_Bits (16#FF80_0000#), F32_Of_Bits (16#FF80_0000#), F32_Of_Bits (16#FF7F_FFFF#)];",
        "   begin",
        "      for Lane in Lane_Index_32x4 loop",
        "         Check (Same (Extract (Exact, Lane), Expected_Exact (Lane)) and then Same (Extract (Native_Exact, Lane), Expected_Exact (Lane)), \"F64 narrowing zero/infinity edge\");",
        "         Check (Same (Extract (Rounded, Lane), Expected_Rounded (Lane)) and then Same (Extract (Native_Rounded, Lane), Expected_Rounded (Lane)), \"F64 narrowing rounded edge\");",
        "         Check (Same (Extract (Negative_Rounded, Lane), Expected_Negative_Rounded (Lane)) and then Same (Extract (Native_Negative_Rounded, Lane), Expected_Negative_Rounded (Lane)), \"F64 narrowing negative rounded edge\");",
        "         Check (Same (Extract (Subnormal, Lane), Expected_Subnormal (Lane)) and then Same (Extract (Native_Subnormal, Lane), Expected_Subnormal (Lane)), \"F64 narrowing subnormal edge\");",
        "         Check (Same (Extract (Positive_Overflow, Lane), Expected_Positive_Overflow (Lane)) and then Same (Extract (Native_Positive_Overflow, Lane), Expected_Positive_Overflow (Lane)), \"F64 narrowing positive overflow boundary\");",
        "         Check (Same (Extract (Negative_Overflow, Lane), Expected_Negative_Overflow (Lane)) and then Same (Extract (Native_Negative_Overflow, Lane), Expected_Negative_Overflow (Lane)), \"F64 narrowing negative overflow boundary\");",
        "         Check (Is_NaN (Extract (NaNs, Lane)) and then Is_NaN (Extract (Native_NaNs, Lane)), \"F64 narrowing NaN edge\");",
        "      end loop;",
        "   end Test_F64_Narrow_Edges;",
        "",
        "   procedure Test_Integer_To_Float_Edges is",
        "      I32_A : constant I32x4 := From_Lanes ([0, 1, 16_777_216, 16_777_217]);",
        "      I32_B : constant I32x4 := From_Lanes ([I32'First, -16_777_217, -1, I32'Last]);",
        "      U32_A : constant U32x4 := From_Lanes ([0, 16_777_216, 16_777_217, U32'Last]);",
        "      I64_A : constant I64x2 := From_Lanes ([0, 9_007_199_254_740_993]);",
        "      I64_B : constant I64x2 := From_Lanes ([I64'First, I64'Last]);",
        "      U64_A : constant U64x2 := From_Lanes ([9_007_199_254_740_992, 9_007_199_254_740_993]);",
        "      U64_C : constant U64x2 := From_Lanes ([9_007_199_254_740_995, 9_007_199_254_740_996]);",
        "      U64_B : constant U64x2 := From_Lanes ([0, U64'Last]);",
        "      Expected_I32_A : constant Lane_Values_U32x4 := [16#0000_0000#, 16#3F80_0000#, 16#4B80_0000#, 16#4B80_0000#];",
        "      Expected_I32_B : constant Lane_Values_U32x4 := [16#CF00_0000#, 16#CB80_0000#, 16#BF80_0000#, 16#4F00_0000#];",
        "      Expected_U32_A : constant Lane_Values_U32x4 := [16#0000_0000#, 16#4B80_0000#, 16#4B80_0000#, 16#4F80_0000#];",
        "      Expected_I64_A : constant Lane_Values_U64x2 := [16#0000_0000_0000_0000#, 16#4340_0000_0000_0000#];",
        "      Expected_I64_B : constant Lane_Values_U64x2 := [16#C3E0_0000_0000_0000#, 16#43E0_0000_0000_0000#];",
        "      Expected_U64_A : constant Lane_Values_U64x2 := [16#4340_0000_0000_0000#, 16#4340_0000_0000_0000#];",
        "      Expected_U64_C : constant Lane_Values_U64x2 := [16#4340_0000_0000_0002#, 16#4340_0000_0000_0002#];",
        "      Expected_U64_B : constant Lane_Values_U64x2 := [16#0000_0000_0000_0000#, 16#43F0_0000_0000_0000#];",
        "",
        "      procedure Check_I32 (Value : I32x4; Expected : Lane_Values_U32x4) is",
        "         Scalar_Result : constant F32x4 := Convert_Round (Value);",
        "         Native_Result : constant F32x4 := Backends.Native.Convert_Round (Value);",
        "      begin",
        "         for Lane in Lane_Index_32x4 loop",
        "            Check (U32_Of_Bits (Extract (Scalar_Result, Lane)) = Expected (Lane), \"scalar I32 to F32 edge\");",
        "            Check (U32_Of_Bits (Extract (Native_Result, Lane)) = Expected (Lane), \"native I32 to F32 edge\");",
        "         end loop;",
        "      end Check_I32;",
        "",
        "      procedure Check_U32 (Value : U32x4; Expected : Lane_Values_U32x4) is",
        "         Scalar_Result : constant F32x4 := Convert_Round (Value);",
        "         Native_Result : constant F32x4 := Backends.Native.Convert_Round (Value);",
        "      begin",
        "         for Lane in Lane_Index_32x4 loop",
        "            Check (U32_Of_Bits (Extract (Scalar_Result, Lane)) = Expected (Lane), \"scalar U32 to F32 edge\");",
        "            Check (U32_Of_Bits (Extract (Native_Result, Lane)) = Expected (Lane), \"native U32 to F32 edge\");",
        "         end loop;",
        "      end Check_U32;",
        "",
        "      procedure Check_I64 (Value : I64x2; Expected : Lane_Values_U64x2) is",
        "         Scalar_Result : constant F64x2 := Convert_Round (Value);",
        "         Native_Result : constant F64x2 := Backends.Native.Convert_Round (Value);",
        "      begin",
        "         for Lane in Lane_Index_64x2 loop",
        "            Check (U64_Of_Bits (Extract (Scalar_Result, Lane)) = Expected (Lane), \"scalar I64 to F64 edge\");",
        "            Check (U64_Of_Bits (Extract (Native_Result, Lane)) = Expected (Lane), \"native I64 to F64 edge\");",
        "         end loop;",
        "      end Check_I64;",
        "",
        "      procedure Check_U64 (Value : U64x2; Expected : Lane_Values_U64x2) is",
        "         Scalar_Result : constant F64x2 := Convert_Round (Value);",
        "         Native_Result : constant F64x2 := Backends.Native.Convert_Round (Value);",
        "      begin",
        "         for Lane in Lane_Index_64x2 loop",
        "            Check (U64_Of_Bits (Extract (Scalar_Result, Lane)) = Expected (Lane), \"scalar U64 to F64 edge\");",
        "            Check (U64_Of_Bits (Extract (Native_Result, Lane)) = Expected (Lane), \"native U64 to F64 edge\");",
        "         end loop;",
        "      end Check_U64;",
        "   begin",
        "      Check_I32 (I32_A, Expected_I32_A);",
        "      Check_I32 (I32_B, Expected_I32_B);",
        "      Check_U32 (U32_A, Expected_U32_A);",
        "      Check_I64 (I64_A, Expected_I64_A);",
        "      Check_I64 (I64_B, Expected_I64_B);",
        "      Check_U64 (U64_A, Expected_U64_A);",
        "      Check_U64 (U64_C, Expected_U64_C);",
        "      Check_U64 (U64_B, Expected_U64_B);",
        "   end Test_Integer_To_Float_Edges;",
        "",
        "   procedure Test_Float_To_Integer_Edges is",
        "      F32_I32_A : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#0000_0000#), F32_Of_Bits (16#8000_0000#),",
        "          F32_Of_Bits (16#7FC0_0001#), F32_Of_Bits (16#7F80_0001#)]);",
        "      F32_I32_B : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#),",
        "          F32_Of_Bits (16#4EFF_FFFF#), F32_Of_Bits (16#4F00_0000#)]);",
        "      F32_I32_C : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#CF00_0000#), F32_Of_Bits (16#CF00_0001#), 1.75, -1.75]);",
        "      F32_I32_D : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#CEFF_FFFF#), F32_Of_Bits (16#FFC0_0001#),",
        "          F32_Of_Bits (16#FF80_0001#), F32_Of_Bits (16#8000_0001#)]);",
        "      F32_U32_A : constant F32x4 := From_Lanes",
        "        ([-1.75, 1.75, F32_Of_Bits (16#4F7F_FFFF#), F32_Of_Bits (16#4F80_0000#)]);",
        "      F32_U32_B : constant F32x4 := From_Lanes",
        "        ([F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#),",
        "          F32_Of_Bits (16#7FC0_0001#), F32_Of_Bits (16#0000_0001#)]);",
        "      F64_I64_A : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#0000_0000_0000_0000#), F64_Of_Bits (16#7FF8_0000_0000_0001#)]);",
        "      F64_I64_A2 : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#8000_0000_0000_0000#), F64_Of_Bits (16#7FF0_0000_0000_0001#)]);",
        "      F64_I64_A3 : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#FFF8_0000_0000_0001#), F64_Of_Bits (16#FFF0_0000_0000_0001#)]);",
        "      F64_I64_B : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#7FF0_0000_0000_0000#), F64_Of_Bits (16#FFF0_0000_0000_0000#)]);",
        "      F64_I64_C : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#43DF_FFFF_FFFF_FFFF#), F64_Of_Bits (16#43E0_0000_0000_0000#)]);",
        "      F64_I64_D : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#C3E0_0000_0000_0000#), F64_Of_Bits (16#C3E0_0000_0000_0001#)]);",
        "      F64_I64_E : constant F64x2 := From_Lanes ([1.75, -1.75]);",
        "      F64_I64_F : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#C3DF_FFFF_FFFF_FFFF#), F64_Of_Bits (16#8000_0000_0000_0001#)]);",
        "      F64_U64_A : constant F64x2 := From_Lanes ([-1.75, 1.75]);",
        "      F64_U64_B : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#43EF_FFFF_FFFF_FFFF#), F64_Of_Bits (16#43F0_0000_0000_0000#)]);",
        "      F64_U64_C : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#7FF0_0000_0000_0000#), F64_Of_Bits (16#FFF0_0000_0000_0000#)]);",
        "      F64_U64_D : constant F64x2 := From_Lanes",
        "        ([F64_Of_Bits (16#7FF8_0000_0000_0001#), F64_Of_Bits (16#0000_0000_0000_0001#)]);",
        "",
        "      procedure Check_F32_I32 (Value : F32x4; Expected : Lane_Values_I32x4) is",
        "         Scalar_Result : constant I32x4 := Convert_Truncate_Saturate (Value);",
        "         Native_Result : constant I32x4 := Backends.Native.Convert_Truncate_Saturate (Value);",
        "      begin",
        "         for Lane in Lane_Index_32x4 loop",
        "            Check (Extract (Scalar_Result, Lane) = Expected (Lane), \"scalar F32 to I32 edge\");",
        "            Check (Extract (Native_Result, Lane) = Expected (Lane), \"native F32 to I32 edge\");",
        "         end loop;",
        "      end Check_F32_I32;",
        "      procedure Check_F32_U32 (Value : F32x4; Expected : Lane_Values_U32x4) is",
        "         Scalar_Result : constant U32x4 := Convert_Truncate_Saturate (Value);",
        "         Native_Result : constant U32x4 := Backends.Native.Convert_Truncate_Saturate (Value);",
        "      begin",
        "         for Lane in Lane_Index_32x4 loop",
        "            Check (Extract (Scalar_Result, Lane) = Expected (Lane), \"scalar F32 to U32 edge\");",
        "            Check (Extract (Native_Result, Lane) = Expected (Lane), \"native F32 to U32 edge\");",
        "         end loop;",
        "      end Check_F32_U32;",
        "      procedure Check_F64_I64 (Value : F64x2; Expected : Lane_Values_I64x2) is",
        "         Scalar_Result : constant I64x2 := Convert_Truncate_Saturate (Value);",
        "         Native_Result : constant I64x2 := Backends.Native.Convert_Truncate_Saturate (Value);",
        "      begin",
        "         for Lane in Lane_Index_64x2 loop",
        "            Check (Extract (Scalar_Result, Lane) = Expected (Lane), \"scalar F64 to I64 edge\");",
        "            Check (Extract (Native_Result, Lane) = Expected (Lane), \"native F64 to I64 edge\");",
        "         end loop;",
        "      end Check_F64_I64;",
        "      procedure Check_F64_U64 (Value : F64x2; Expected : Lane_Values_U64x2) is",
        "         Scalar_Result : constant U64x2 := Convert_Truncate_Saturate (Value);",
        "         Native_Result : constant U64x2 := Backends.Native.Convert_Truncate_Saturate (Value);",
        "      begin",
        "         for Lane in Lane_Index_64x2 loop",
        "            Check (Extract (Scalar_Result, Lane) = Expected (Lane), \"scalar F64 to U64 edge\");",
        "            Check (Extract (Native_Result, Lane) = Expected (Lane), \"native F64 to U64 edge\");",
        "         end loop;",
        "      end Check_F64_U64;",
        "   begin",
        "      Check_F32_I32 (F32_I32_A, [0, 0, 0, 0]);",
        "      Check_F32_I32 (F32_I32_B, [I32'Last, I32'First, 2_147_483_520, I32'Last]);",
        "      Check_F32_I32 (F32_I32_C, [I32'First, I32'First, 1, -1]);",
        "      Check_F32_I32 (F32_I32_D, [-2_147_483_520, 0, 0, 0]);",
        "      Check_F32_U32 (F32_U32_A, [0, 1, 4_294_967_040, U32'Last]);",
        "      Check_F32_U32 (F32_U32_B, [U32'Last, 0, 0, 0]);",
        "      Check_F64_I64 (F64_I64_A, [0, 0]);",
        "      Check_F64_I64 (F64_I64_A2, [0, 0]);",
        "      Check_F64_I64 (F64_I64_A3, [0, 0]);",
        "      Check_F64_I64 (F64_I64_B, [I64'Last, I64'First]);",
        "      Check_F64_I64 (F64_I64_C, [9_223_372_036_854_774_784, I64'Last]);",
        "      Check_F64_I64 (F64_I64_D, [I64'First, I64'First]);",
        "      Check_F64_I64 (F64_I64_E, [1, -1]);",
        "      Check_F64_I64 (F64_I64_F, [-9_223_372_036_854_774_784, 0]);",
        "      Check_F64_U64 (F64_U64_A, [0, 1]);",
        "      Check_F64_U64 (F64_U64_B, [18_446_744_073_709_549_568, U64'Last]);",
        "      Check_F64_U64 (F64_U64_C, [U64'Last, 0]);",
        "      Check_F64_U64 (F64_U64_D, [0, 0]);",
        "   end Test_Float_To_Integer_Edges;",
        "",
        "",
        "begin",
        "   Put_Line (\"conversion differential tests seed=0xC0457A5712800A11\");",
        "   Test_F32_Widen_Edges;",
        "   Test_F64_Narrow_Edges;",
        "   Test_Integer_To_Float_Edges;",
        "   Test_Float_To_Integer_Edges;",
    ]
    for edge_case in SIGNED_UNSIGNED_EDGE_CASES:
        out += emit_signed_unsigned_literal_test(*edge_case)
    for source, source_scalar, target, target_scalar, _, source_lanes, _ in NARROWINGS:
        low, high = boundary_vectors(source, source_scalar, target_scalar, source_lanes, False)
        out += emit_narrow_test(source, target, source_lanes, "Narrow_Truncate", low, high)
        out += emit_narrow_test(source, target, source_lanes, "Narrow_Saturate", low, high)
    for source, source_scalar, target, target_scalar, _, source_lanes, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        low, high = boundary_vectors(source, source_scalar, target_scalar, source_lanes, True)
        out += emit_narrow_test(source, target, source_lanes, "Narrow_Saturate", low, high)
    out += [
        "   for Iteration in Positive range 1 .. 512 loop",
        "      pragma Unreferenced (Iteration);",
    ]
    for pair in bit_cast_pairs():
        out += emit_bit_cast_test(*pair)
    for source, source_scalar, target, target_scalar, _, result_lanes in WIDENINGS:
        out += emit_widen_test(source, source_scalar, target, target_scalar, result_lanes)
    for source, source_scalar, target, target_scalar, result_lanes in FLOAT_WIDENINGS:
        out += emit_widen_test(source, source_scalar, target, target_scalar, result_lanes)
    for source, _, target, _, _, source_lanes, _ in NARROWINGS:
        out += emit_narrow_test(source, target, source_lanes, "Narrow_Truncate")
        out += emit_narrow_test(source, target, source_lanes, "Narrow_Saturate")
    for source, _, target, _, _, source_lanes, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        out += emit_narrow_test(source, target, source_lanes, "Narrow_Saturate")
    for source, _, target, _, source_lanes in FLOAT_NARROWINGS:
        out += emit_narrow_test(
            source,
            target,
            source_lanes,
            "Narrow_Round",
            "Random_Narrow_F64x2",
            "Random_Narrow_F64x2",
        )
    for source, _, target, _, bits, lanes, _ in INTEGER_TO_FLOAT_CONVERSIONS:
        out += emit_convert_round_test(source, target, bits, lanes)
    for source, _, target, _, bits, lanes, _ in FLOAT_TO_INTEGER_CONVERSIONS:
        out += emit_float_to_integer_test(source, target, bits, lanes)
    for source, _, target, _, bits, lanes, _ in SIGNED_UNSIGNED_CONVERSIONS:
        out += emit_signed_unsigned_test(source, target, bits, lanes)
    out += [
        "   end loop;",
        "   if Failures = 0 then",
        "      Put_Line (\"PASS\");",
        "   else",
        "      Put_Line (\"FAILURES:\" & Failures'Image);",
        "      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);",
        "   end if;",
        "end Conversion_Tests;",
        "",
    ]
    return "\n".join(out)


if __name__ == "__main__":
    generated = program()
    if "--check" in sys.argv[1:]:
        if not OUTPUT.exists() or OUTPUT.read_text() != generated:
            raise SystemExit(f"generated file is stale: {OUTPUT}")
    else:
        OUTPUT.write_text(generated)
