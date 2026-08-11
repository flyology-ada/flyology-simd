#!/usr/bin/env python3
"""Generate independent tests for every explicit 128-bit conversion."""

from pathlib import Path

from generate_full_family import (
    FLOAT_WIDENINGS,
    NARROWINGS,
    ROOT,
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
    return [
        "      declare",
        f"         Low : constant {source} := {low_expression};",
        f"         High : constant {source} := {high_expression};",
        f"         Scalar_Result : constant {target} := {name} (Low, High);",
        f"         Native_Result : constant {target} := Backends.Native.{name} (Low, High);",
        "      begin",
        f"         for Lane in Natural range 0 .. {source_lanes - 1} loop",
        f"            Check (Extract (Scalar_Result, Lane) = {helper} (Extract (Low, Lane)), \"scalar {name} {source} low lane\");",
        f"            Check (Extract (Native_Result, Lane) = {helper} (Extract (Low, Lane)), \"native {name} {source} low lane\");",
        f"            Check (Extract (Scalar_Result, Lane + {source_lanes}) = {helper} (Extract (High, Lane)), \"scalar {name} {source} high lane\");",
        f"            Check (Extract (Native_Result, Lane + {source_lanes}) = {helper} (Extract (High, Lane)), \"native {name} {source} high lane\");",
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
        "",
    ]

    for vector in VECTOR_INFO:
        out += random_function(vector)

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
        "",
        "begin",
        "   Put_Line (\"conversion differential tests seed=0xC0457A5712800A11\");",
        "   Test_F32_Widen_Edges;",
    ]
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
    OUTPUT.write_text(program())
