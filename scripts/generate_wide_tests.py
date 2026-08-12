#!/usr/bin/env python3
"""Generate independent semantic tests for the portable 256-bit family."""

from pathlib import Path

from generate_wide_family import BIT_CAST_TARGETS, FAMILIES, ROOT, Family
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


TEST = ROOT / "tests" / "wide_tests.adb"
BY_HALF = {family.half: family for family in FAMILIES}


def bit_expression(f: Family, expression: str) -> str:
    if f.signed or f.floating:
        return f"Value_To_Bits ({expression})"
    return expression


def bit_cast_tests(f: Family, source: str, label: str) -> str:
    blocks = []
    source_bits = bit_expression(f, f"Wide.Extract ({source}, Lane)")
    for target in BIT_CAST_TARGETS[f.vector]:
        target_family = next(item for item in FAMILIES if item.vector == target)
        target_unsigned = f"U{target_family.bits}"
        if target_family.signed or target_family.floating:
            target_conversion = (
                f"         function Target_To_Bits is new Ada.Unchecked_Conversion "
                f"({target_family.scalar}, {target_unsigned});\n"
            )
            scalar_bits = "Target_To_Bits (Wide.Extract (Scalar_Cast, Lane))"
            native_bits = "Target_To_Bits (Wide.Extract (Native_Cast, Lane))"
        else:
            target_conversion = ""
            scalar_bits = "Wide.Extract (Scalar_Cast, Lane)"
            native_bits = "Wide.Extract (Native_Cast, Lane)"
        blocks.append(f'''      declare
{target_conversion}         Scalar_Cast : constant Wide.{target} := Wide.Bit_Cast ({source});
         Native_Cast : constant Wide.{target} := Native.Bit_Cast ({source});
         Round_Trip : constant Wide.{f.vector} := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.{f.vector} := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.{f.index} loop
            Check ({scalar_bits} = {source_bits}
              and then {native_bits} = {source_bits},
              "{f.vector} to {target} {label}direct bit cast" & Lane'Image);
            Check ({bit_expression(f, 'Wide.Extract (Round_Trip, Lane)')} = {source_bits}
              and then {bit_expression(f, 'Wide.Extract (Native_Round_Trip, Lane)')} = {source_bits},
              "{f.vector} to {target} {label}bit-cast round trip" & Lane'Image);
         end loop;
      end;
''')
    return "".join(blocks)


def lane_values(scalar: str, lanes: int, variant: int = 0) -> str:
    patterns = {
        "U8": ("0", "1", "127", "128", "254", "255"),
        "I8": ("I8'First", "-127", "-1", "0", "1", "126", "I8'Last"),
        "U16": ("0", "1", "255", "256", "32_767", "32_768", "U16'Last"),
        "I16": ("I16'First", "-32_767", "-129", "-1", "0", "127", "128", "I16'Last"),
        "U32": ("0", "1", "65_535", "65_536", "2_147_483_647", "2_147_483_648", "U32'Last"),
        "I32": ("I32'First", "-2_147_483_647", "-65_537", "-1", "0", "65_535", "65_536", "I32'Last"),
        "U64": ("0", "1", "4_294_967_295", "4_294_967_296", "9_223_372_036_854_775_807", "9_223_372_036_854_775_808", "U64'Last"),
        "I64": ("I64'First", "-9_223_372_036_854_775_807", "-4_294_967_297", "-1", "0", "4_294_967_295", "4_294_967_296", "I64'Last"),
        "F32": ("-F32'Last", "-16_777_217.0", "-2.75", "-0.5", "0.0", "1.5", "16_777_217.0", "F32'Last"),
        "F64": ("-F64'Last", "-9_007_199_254_740_993.0", "-2.75", "-0.5", "0.0", "1.5", "9_007_199_254_740_993.0", "F64'Last"),
    }[scalar]
    return ", ".join(patterns[(lane + variant) % len(patterns)] for lane in range(lanes))


def root_half(source: Family, values: str, offset: int) -> str:
    return (
        f"{source.half}'(Flyology_SIMD.From_Lanes "
        f"([for Lane in 0 .. {source.half_lanes - 1} => {values} (Lane + {offset})])"
        f")"
    )


def assembled_expected(target: Family, low: str, high: str) -> str:
    return (
        f"[for Lane in Wide.{target.index} =>\n"
        f"              (if Lane < {target.half_lanes}\n"
        f"               then Flyology_SIMD.Extract ({low}, Lane)\n"
        f"               else Flyology_SIMD.Extract ({high}, Lane - {target.half_lanes}))]"
    )


def random_conversion_helpers() -> str:
    out: list[str] = []
    for family in FAMILIES:
        unsigned = f"U{family.bits}"
        conversion = ""
        if family.signed:
            conversion = (
                f"      function Bits_To_{family.scalar} is new Ada.Unchecked_Conversion "
                f"({unsigned}, {family.scalar});\n"
            )
            raw = "Next_U64" if family.bits == 64 else f"{unsigned} (Next_U64 mod 2 ** {family.bits})"
            value = f"Bits_To_{family.scalar} ({raw})"
        elif family.floating:
            value = (
                f"{family.scalar} (Integer (Next_U64 mod 2_000_001) - 1_000_000) / 128.0"
            )
        else:
            value = "Next_U64" if family.bits == 64 else f"{unsigned} (Next_U64 mod 2 ** {family.bits})"
        out.append(
            f"{conversion}      function Random_{family.values} return Wide.{family.values} is\n"
            f"         Result : Wide.{family.values};\n"
            f"      begin\n"
            f"         for Lane in Wide.{family.index} loop\n"
            f"            Result (Lane) := {value};\n"
            f"         end loop;\n"
            f"         return Result;\n"
            f"      end Random_{family.values};"
        )
    return "\n".join(out)


def conversion_tests() -> str:
    blocks: list[str] = []

    for source_half, _, target_half, *_ in (*WIDENINGS, *FLOAT_WIDENINGS):
        source = BY_HALF[source_half]
        target = BY_HALF[target_half]
        values = lane_values(source.scalar, source.lanes)
        for operation, offset in (("Widen_Low", 0), ("Widen_High", source.half_lanes)):
            root_source = root_half(source, "Source_Lanes", offset)
            blocks.append(f'''      declare
         Source_Lanes : constant Wide.{source.values} := [{values}];
         Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant {source.half} := {root_source};
         Expected_Low : constant {target.half} := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant {target.half} := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.{target.values} :=
           {assembled_expected(target, 'Expected_Low', 'Expected_High')};
      begin
         Check (Wide.To_Lanes (Wide.{operation} (Value)) = Expected
           and then Native.To_Lanes (Native.{operation} (Value)) = Expected,
           "wide {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.{source.values} := Random_{source.values};
            Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant {source.half} := {root_source};
            Expected_Low : constant {target.half} := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant {target.half} := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.{target.values} :=
              {assembled_expected(target, 'Expected_Low', 'Expected_High')};
         begin
            Check (Wide.To_Lanes (Wide.{operation} (Value)) = Expected
              and then Native.To_Lanes (Native.{operation} (Value)) = Expected,
              "wide randomized {operation} {source.vector} to {target.vector}" & Iteration'Image);
         end;
      end loop;
''')

    narrowing_groups = [
        ("Narrow_Truncate", item) for item in NARROWINGS
    ] + [
        ("Narrow_Saturate", item) for item in NARROWINGS
    ] + [
        ("Narrow_Saturate", item) for item in SIGNED_TO_UNSIGNED_NARROWINGS
    ] + [
        ("Narrow_Round", item) for item in FLOAT_NARROWINGS
    ]
    for operation, (source_half, _, target_half, *_) in narrowing_groups:
        source = BY_HALF[source_half]
        target = BY_HALF[target_half]
        low_values = lane_values(source.scalar, source.lanes)
        high_values = lane_values(source.scalar, source.lanes, 3)
        blocks.append(f'''      declare
         Low_Lanes : constant Wide.{source.values} := [{low_values}];
         High_Lanes : constant Wide.{source.values} := [{high_values}];
         Low_Value : constant Wide.{source.vector} := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.{source.vector} := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant {target.half} := Flyology_SIMD.{operation}
           ({root_half(source, 'Low_Lanes', 0)}, {root_half(source, 'Low_Lanes', source.half_lanes)});
         Expected_High : constant {target.half} := Flyology_SIMD.{operation}
           ({root_half(source, 'High_Lanes', 0)}, {root_half(source, 'High_Lanes', source.half_lanes)});
         Expected : constant Wide.{target.values} :=
           {assembled_expected(target, 'Expected_Low', 'Expected_High')};
      begin
         Check (Wide.To_Lanes (Wide.{operation} (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.{operation} (Low_Value, High_Value)) = Expected,
           "wide {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.{source.values} := Random_{source.values};
            High_Lanes : constant Wide.{source.values} := Random_{source.values};
            Low_Value : constant Wide.{source.vector} := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.{source.vector} := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant {target.half} := Flyology_SIMD.{operation}
              ({root_half(source, 'Low_Lanes', 0)}, {root_half(source, 'Low_Lanes', source.half_lanes)});
            Expected_High : constant {target.half} := Flyology_SIMD.{operation}
              ({root_half(source, 'High_Lanes', 0)}, {root_half(source, 'High_Lanes', source.half_lanes)});
            Expected : constant Wide.{target.values} :=
              {assembled_expected(target, 'Expected_Low', 'Expected_High')};
         begin
            Check (Wide.To_Lanes (Wide.{operation} (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.{operation} (Low_Value, High_Value)) = Expected,
              "wide randomized {operation} {source.vector} to {target.vector}" & Iteration'Image);
         end;
      end loop;
''')

    conversion_groups = (
        [("Convert_Round", item) for item in INTEGER_TO_FLOAT_CONVERSIONS]
        + [("Convert_Truncate_Saturate", item) for item in FLOAT_TO_INTEGER_CONVERSIONS]
        + [("Convert_Saturate", item) for item in SIGNED_UNSIGNED_CONVERSIONS]
    )
    for operation, (source_half, _, target_half, *_) in conversion_groups:
        source = BY_HALF[source_half]
        target = BY_HALF[target_half]
        values = lane_values(source.scalar, source.lanes)
        blocks.append(f'''      declare
         Source_Lanes : constant Wide.{source.values} := [{values}];
         Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant {target.half} := Flyology_SIMD.{operation}
           ({root_half(source, 'Source_Lanes', 0)});
         Expected_High : constant {target.half} := Flyology_SIMD.{operation}
           ({root_half(source, 'Source_Lanes', source.half_lanes)});
         Expected : constant Wide.{target.values} :=
           {assembled_expected(target, 'Expected_Low', 'Expected_High')};
      begin
         Check (Wide.To_Lanes (Wide.{operation} (Value)) = Expected
           and then Native.To_Lanes (Native.{operation} (Value)) = Expected,
           "wide {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.{source.values} := Random_{source.values};
            Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant {target.half} := Flyology_SIMD.{operation}
              ({root_half(source, 'Source_Lanes', 0)});
            Expected_High : constant {target.half} := Flyology_SIMD.{operation}
              ({root_half(source, 'Source_Lanes', source.half_lanes)});
            Expected : constant Wide.{target.values} :=
              {assembled_expected(target, 'Expected_Low', 'Expected_High')};
         begin
            Check (Wide.To_Lanes (Wide.{operation} (Value)) = Expected
              and then Native.To_Lanes (Native.{operation} (Value)) = Expected,
              "wide randomized {operation} {source.vector} to {target.vector}" & Iteration'Image);
         end;
      end loop;
''')

    blocks.append('''      declare
         function F32_Of_Bits is new Ada.Unchecked_Conversion (U32, F32);
         function F64_Of_Bits is new Ada.Unchecked_Conversion (U64, F64);
         function F32_To_Bits is new Ada.Unchecked_Conversion (F32, U32);
         function F64_To_Bits is new Ada.Unchecked_Conversion (F64, U64);
         function Is_F64_NaN (Value : F64) return Boolean is
           ((F64_To_Bits (Value) and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#
            and then (F64_To_Bits (Value) and 16#000F_FFFF_FFFF_FFFF#) /= 0);
         F32_Edges : constant Wide.F32x8 := Wide.From_Lanes
           ([F32_Of_Bits (16#0000_0000#), F32_Of_Bits (16#8000_0000#),
             F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#),
             F32_Of_Bits (16#0000_0001#), F32_Of_Bits (16#7FC0_0001#),
             F32_Of_Bits (16#7F80_0001#), F32_Of_Bits (16#7F7F_FFFF#)]);
         F64_Edges : constant Wide.F64x4 := Wide.From_Lanes
           ([F64_Of_Bits (16#0000_0000_0000_0000#),
             F64_Of_Bits (16#8000_0000_0000_0000#),
             F64_Of_Bits (16#7FF0_0000_0000_0000#),
             F64_Of_Bits (16#FFF0_0000_0000_0000#)]);
         F64_NaN_And_Subnormal : constant Wide.F64x4 := Wide.From_Lanes
           ([F64_Of_Bits (16#7FF8_0000_0000_0001#),
             F64_Of_Bits (16#7FF0_0000_0000_0001#),
             F64_Of_Bits (16#3690_0000_0000_0001#),
             F64_Of_Bits (16#B690_0000_0000_0001#)]);
         F64_Rounding_And_Overflow : constant Wide.F64x4 := Wide.From_Lanes
           ([F64_Of_Bits (16#3FF0_0000_1000_0000#),
             F64_Of_Bits (16#3FF0_0000_1000_0001#),
             F64_Of_Bits (16#47EF_FFFF_F000_0000#),
             F64_Of_Bits (16#C7EF_FFFF_F000_0000#)]);
         F32_Integer_Bounds : constant Wide.F32x8 := Wide.From_Lanes
           ([F32_Of_Bits (16#4EFF_FFFF#), F32_Of_Bits (16#4F00_0000#),
             F32_Of_Bits (16#CEFF_FFFF#), F32_Of_Bits (16#CF00_0000#),
             F32_Of_Bits (16#4F7F_FFFF#), F32_Of_Bits (16#4F80_0000#),
             1.75, -1.75]);
         F64_Integer_Bounds : constant Wide.F64x4 := Wide.From_Lanes
           ([F64_Of_Bits (16#43DF_FFFF_FFFF_FFFF#),
             F64_Of_Bits (16#43E0_0000_0000_0000#),
             F64_Of_Bits (16#C3DF_FFFF_FFFF_FFFF#),
             F64_Of_Bits (16#C3E0_0000_0000_0000#)]);
         F64_Unsigned_Bounds : constant Wide.F64x4 := Wide.From_Lanes
           ([F64_Of_Bits (16#43EF_FFFF_FFFF_FFFF#),
             F64_Of_Bits (16#43F0_0000_0000_0000#), -1.75, 1.75]);
         I32_Round_Edges : constant Wide.I32x8 := Wide.From_Lanes
           ([0, 1, 16_777_216, 16_777_217,
             I32'First, -16_777_217, -1, I32'Last]);
         U32_Round_Edges : constant Wide.U32x8 := Wide.From_Lanes
           ([0, 16_777_216, 16_777_217, U32'Last,
             16_777_219, 16_777_220, 2_147_483_648, 1]);
         I64_Round_Edges : constant Wide.I64x4 := Wide.From_Lanes
           ([0, 9_007_199_254_740_993, I64'First, I64'Last]);
         U64_Round_Edges : constant Wide.U64x4 := Wide.From_Lanes
           ([9_007_199_254_740_992, 9_007_199_254_740_993,
             9_007_199_254_740_995, U64'Last]);
         Widened_Low : constant Wide.F64x4 := Wide.Widen_Low (F32_Edges);
         Native_Widened_Low : constant Wide.F64x4 := Native.Widen_Low (F32_Edges);
         Widened_High : constant Wide.F64x4 := Wide.Widen_High (F32_Edges);
         Native_Widened_High : constant Wide.F64x4 := Native.Widen_High (F32_Edges);
         Narrowed_Edges : constant Wide.F32x8 :=
           Wide.Narrow_Round (F64_Edges, F64_NaN_And_Subnormal);
         Native_Narrowed_Edges : constant Wide.F32x8 :=
           Native.Narrow_Round (F64_Edges, F64_NaN_And_Subnormal);
         Narrowed_Rounding : constant Wide.F32x8 :=
           Wide.Narrow_Round (F64_Rounding_And_Overflow, F64_Rounding_And_Overflow);
         Native_Narrowed_Rounding : constant Wide.F32x8 :=
           Native.Narrow_Round (F64_Rounding_And_Overflow, F64_Rounding_And_Overflow);
         F32_To_I32 : constant Wide.I32x8 :=
           Wide.Convert_Truncate_Saturate (F32_Edges);
         Native_F32_To_I32 : constant Wide.I32x8 :=
           Native.Convert_Truncate_Saturate (F32_Edges);
         F32_To_U32 : constant Wide.U32x8 :=
           Wide.Convert_Truncate_Saturate (F32_Edges);
         Native_F32_To_U32 : constant Wide.U32x8 :=
           Native.Convert_Truncate_Saturate (F32_Edges);
         F32_Bounds_To_I32 : constant Wide.I32x8 :=
           Wide.Convert_Truncate_Saturate (F32_Integer_Bounds);
         F32_Bounds_To_U32 : constant Wide.U32x8 :=
           Wide.Convert_Truncate_Saturate (F32_Integer_Bounds);
         F64_Bounds_To_I64 : constant Wide.I64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Integer_Bounds);
         F64_Bounds_To_U64 : constant Wide.U64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Unsigned_Bounds);
         F64_Edges_To_I64 : constant Wide.I64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Edges);
         F64_Edges_To_U64 : constant Wide.U64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Edges);
         I32_Rounded : constant Wide.F32x8 := Wide.Convert_Round (I32_Round_Edges);
         Native_I32_Rounded : constant Wide.F32x8 := Native.Convert_Round (I32_Round_Edges);
         U32_Rounded : constant Wide.F32x8 := Wide.Convert_Round (U32_Round_Edges);
         Native_U32_Rounded : constant Wide.F32x8 := Native.Convert_Round (U32_Round_Edges);
         I64_Rounded : constant Wide.F64x4 := Wide.Convert_Round (I64_Round_Edges);
         Native_I64_Rounded : constant Wide.F64x4 := Native.Convert_Round (I64_Round_Edges);
         U64_Rounded : constant Wide.F64x4 := Wide.Convert_Round (U64_Round_Edges);
         Native_U64_Rounded : constant Wide.F64x4 := Native.Convert_Round (U64_Round_Edges);
         Expected_I32_Rounded : constant Wide.Lane_Values_U32x8 :=
           [16#0000_0000#, 16#3F80_0000#, 16#4B80_0000#, 16#4B80_0000#,
            16#CF00_0000#, 16#CB80_0000#, 16#BF80_0000#, 16#4F00_0000#];
         Expected_U32_Rounded : constant Wide.Lane_Values_U32x8 :=
           [16#0000_0000#, 16#4B80_0000#, 16#4B80_0000#, 16#4F80_0000#,
            16#4B80_0002#, 16#4B80_0002#, 16#4F00_0000#, 16#3F80_0000#];
         Expected_I64_Rounded : constant Wide.Lane_Values_U64x4 :=
           [16#0000_0000_0000_0000#, 16#4340_0000_0000_0000#,
            16#C3E0_0000_0000_0000#, 16#43E0_0000_0000_0000#];
         Expected_U64_Rounded : constant Wide.Lane_Values_U64x4 :=
           [16#4340_0000_0000_0000#, 16#4340_0000_0000_0000#,
            16#4340_0000_0000_0002#, 16#43F0_0000_0000_0000#];
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (F64_To_Bits (Wide.Extract (Widened_Low, Lane)) =
              F64_To_Bits (Wide.Extract (Native_Widened_Low, Lane)),
              "wide F32 low widening special edge" & Lane'Image);
            Check (F64_To_Bits (Wide.Extract (Widened_Low, Lane)) =
              (case Lane is
                 when 0 => 16#0000_0000_0000_0000#,
                 when 1 => 16#8000_0000_0000_0000#,
                 when 2 => 16#7FF0_0000_0000_0000#,
                 when 3 => 16#FFF0_0000_0000_0000#),
              "wide F32 low widening exact category" & Lane'Image);
            if Lane = 1 or else Lane = 2 then
               Check (Is_F64_NaN (Wide.Extract (Widened_High, Lane))
                 and then Is_F64_NaN (Wide.Extract (Native_Widened_High, Lane)),
                 "wide F32 high widening NaN edge" & Lane'Image);
            else
               Check (F64_To_Bits (Wide.Extract (Widened_High, Lane)) =
                 F64_To_Bits (Wide.Extract (Native_Widened_High, Lane)),
                 "wide F32 high widening finite edge" & Lane'Image);
            end if;
         end loop;
         for Lane in Wide.Lane_Index_32x8 loop
            if Lane = 4 or else Lane = 5 then
               Check ((F32_To_Bits (Wide.Extract (Narrowed_Edges, Lane)) and 16#7F80_0000#) = 16#7F80_0000#
                 and then (F32_To_Bits (Wide.Extract (Narrowed_Edges, Lane)) and 16#007F_FFFF#) /= 0
                 and then (F32_To_Bits (Wide.Extract (Native_Narrowed_Edges, Lane)) and 16#7F80_0000#) = 16#7F80_0000#
                 and then (F32_To_Bits (Wide.Extract (Native_Narrowed_Edges, Lane)) and 16#007F_FFFF#) /= 0,
                 "wide F64 narrowing NaN edge" & Lane'Image);
            else
               Check (F32_To_Bits (Wide.Extract (Narrowed_Edges, Lane)) =
                 F32_To_Bits (Wide.Extract (Native_Narrowed_Edges, Lane)),
                 "wide F64 narrowing special edge" & Lane'Image);
            end if;
            Check (F32_To_Bits (Wide.Extract (Narrowed_Rounding, Lane)) =
              F32_To_Bits (Wide.Extract (Native_Narrowed_Rounding, Lane)),
              "wide F64 narrowing rounding edge" & Lane'Image);
            Check (Wide.Extract (F32_To_I32, Lane) = Wide.Extract (Native_F32_To_I32, Lane)
              and then Wide.Extract (F32_To_U32, Lane) = Wide.Extract (Native_F32_To_U32, Lane),
              "wide F32 integer conversion edge" & Lane'Image);
            Check (F32_To_Bits (Wide.Extract (I32_Rounded, Lane)) = Expected_I32_Rounded (Lane)
              and then F32_To_Bits (Wide.Extract (Native_I32_Rounded, Lane)) = Expected_I32_Rounded (Lane),
              "wide I32 to F32 literal rounding edge" & Lane'Image);
            Check (F32_To_Bits (Wide.Extract (U32_Rounded, Lane)) = Expected_U32_Rounded (Lane)
              and then F32_To_Bits (Wide.Extract (Native_U32_Rounded, Lane)) = Expected_U32_Rounded (Lane),
              "wide U32 to F32 literal rounding edge" & Lane'Image);
         end loop;
         for Lane in Wide.Lane_Index_64x4 loop
            Check (F64_To_Bits (Wide.Extract (I64_Rounded, Lane)) = Expected_I64_Rounded (Lane)
              and then F64_To_Bits (Wide.Extract (Native_I64_Rounded, Lane)) = Expected_I64_Rounded (Lane),
              "wide I64 to F64 literal rounding edge" & Lane'Image);
            Check (F64_To_Bits (Wide.Extract (U64_Rounded, Lane)) = Expected_U64_Rounded (Lane)
              and then F64_To_Bits (Wide.Extract (Native_U64_Rounded, Lane)) = Expected_U64_Rounded (Lane),
              "wide U64 to F64 literal rounding edge" & Lane'Image);
         end loop;
         Check (Wide.To_Lanes (F32_To_I32) =
           [0, 0, I32'Last, I32'First, 0, 0, 0, I32'Last],
           "wide F32 to I32 explicit edge results");
         Check (Wide.To_Lanes (F32_To_U32) =
           [0, 0, U32'Last, 0, 0, 0, 0, U32'Last],
           "wide F32 to U32 explicit edge results");
         Check (Wide.To_Lanes (F32_Bounds_To_I32) =
           [2_147_483_520, I32'Last, -2_147_483_520, I32'First,
            I32'Last, I32'Last, 1, -1],
           "wide F32 to I32 boundary results");
         Check (Wide.To_Lanes (F32_Bounds_To_U32) =
           [2_147_483_520, 2_147_483_648, 0, 0,
            4_294_967_040, U32'Last, 1, 0],
           "wide F32 to U32 boundary results");
         Check (Wide.To_Lanes (F64_Bounds_To_I64) =
           [9_223_372_036_854_774_784, I64'Last,
            -9_223_372_036_854_774_784, I64'First],
           "wide F64 to I64 boundary results");
         Check (Wide.To_Lanes (F64_Bounds_To_U64) =
           [18_446_744_073_709_549_568, U64'Last, 0, 1],
           "wide F64 to U64 boundary results");
         Check (Wide.To_Lanes (F64_Edges_To_I64) = [0, 0, I64'Last, I64'First]
           and then Wide.To_Lanes (F64_Edges_To_U64) = [0, 0, U64'Last, 0],
           "wide F64 infinity and signed-zero integer results");
         Check (Wide.To_Lanes (Narrowed_Rounding) =
           [F32_Of_Bits (16#3F80_0000#), F32_Of_Bits (16#3F80_0001#),
            F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#),
            F32_Of_Bits (16#3F80_0000#), F32_Of_Bits (16#3F80_0001#),
            F32_Of_Bits (16#7F80_0000#), F32_Of_Bits (16#FF80_0000#)],
           "wide F64 narrowing tie and overflow results");
      end;
''')

    return (
        "   procedure Test_Wide_Conversions is\n"
        + random_conversion_helpers()
        + "\n   begin\n"
        + "".join(blocks)
        + "   end Test_Wide_Conversions;\n"
    )


def integer_test(f: Family) -> str:
    a_values = ", ".join(str(i - f.lanes // 2) if f.signed else str(i) for i in range(f.lanes))
    b_values = ", ".join("2" for _ in range(f.lanes))
    all_bits = f"{f.mask_bits}'Last"
    alt = sum(1 << i for i in range(0, f.lanes, 2))
    zero = f"Wide.Zero"
    unsigned = f"U{f.bits}"
    raw = (
        "Next_U64"
        if f.bits == 64
        else f"{unsigned} (Next_U64 mod 2 ** {f.bits})"
    )
    random_value = f"Bits_To_Value ({raw})" if f.signed else raw
    edge_patterns = (0, 1 << (f.bits - 1), (1 << f.bits) - 1,
                     int("AA" * (f.bits // 8), 16))
    edge_values = []
    for lane in range(f.lanes):
        bits = f"{unsigned} (16#{edge_patterns[lane % len(edge_patterns)]:0{f.bits // 4}X}#)"
        edge_values.append(f"Bits_To_Value ({bits})" if f.signed else bits)
    bit_lanes = ", ".join(edge_values)
    lookup_declarations = ""
    lookup_checks = ""
    lookup_randomized = ""
    if f.vector == "U8x32":
        lookup_declarations = '''
      function Reference_Table_Lookup
        (Table, Indices : Wide.Lane_Values_U8x32)
         return Wide.Lane_Values_U8x32
      is
         Result : Wide.Lane_Values_U8x32 := [others => 0];
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if Indices (Lane) <= 31 then
               Result (Lane) := Table (Natural (Indices (Lane)));
            end if;
         end loop;
         return Result;
      end Reference_Table_Lookup;
      Lookup_Table_Lanes : constant Wide.Lane_Values_U8x32 :=
        [for Lane in Wide.Lane_Index_8x32 => U8 ((Lane * 7 + 3) mod 256)];
      Lookup_Table : constant Wide.U8x32 := Wide.From_Lanes (Lookup_Table_Lanes);
      Mixed_Index_Lanes : constant Wide.Lane_Values_U8x32 :=
        [0, 31, 16, 15, 32, 255, 1, 30,
         17, 14, 33, 254, 2, 29, 18, 13,
         34, 253, 3, 28, 19, 12, 35, 252,
         4, 27, 20, 11, 36, 251, 5, 26];
      Mixed_Indices : constant Wide.U8x32 := Wide.From_Lanes (Mixed_Index_Lanes);
'''
        lookup_checks = '''
      Check (Wide.To_Lanes (Wide.Table_Lookup (Lookup_Table, Mixed_Indices)) =
        Reference_Table_Lookup (Lookup_Table_Lanes, Mixed_Index_Lanes)
        and then Native.To_Lanes (Native.Table_Lookup (Lookup_Table, Mixed_Indices)) =
          Reference_Table_Lookup (Lookup_Table_Lanes, Mixed_Index_Lanes),
        "U8x32 fixed 32-entry table lookup");
      for Batch in Natural range 0 .. 7 loop
         declare
            Index_Lanes : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 => U8 (Batch * 32 + Lane)];
            Index_Vector : constant Wide.U8x32 := Wide.From_Lanes (Index_Lanes);
            Expected : constant Wide.Lane_Values_U8x32 :=
              Reference_Table_Lookup (Lookup_Table_Lanes, Index_Lanes);
         begin
            Check (Wide.To_Lanes (Wide.Table_Lookup (Lookup_Table, Index_Vector)) = Expected
              and then Native.To_Lanes (Native.Table_Lookup (Lookup_Table, Index_Vector)) = Expected,
              "U8x32 exhaustive unsigned lookup indexes" & Batch'Image);
         end;
      end loop;
'''
        lookup_randomized = '''
            Check (Wide.To_Lanes (Wide.Table_Lookup (R_A, R_B)) =
              Reference_Table_Lookup (Wide.To_Lanes (R_A), Wide.To_Lanes (R_B))
              and then Native.To_Lanes (Native.Table_Lookup (R_A, R_B)) =
                Reference_Table_Lookup (Wide.To_Lanes (R_A), Wide.To_Lanes (R_B)),
              "U8x32 randomized 32-entry table lookup" & Iteration'Image);
'''
    return f"""
   procedure Test_{f.vector} is
{('      function Bits_To_Value is new Ada.Unchecked_Conversion (' + unsigned + ', ' + f.scalar + ');') if f.signed else ''}
{('      function Value_To_Bits is new Ada.Unchecked_Conversion (' + f.scalar + ', ' + unsigned + ');') if f.signed else ''}
      function Random_Lanes return Wide.{f.values} is
         Result : Wide.{f.values};
      begin
         for Lane in Wide.{f.index} loop
            Result (Lane) := {random_value};
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.{f.lane_map} is
         Selectors : Wide.{f.selectors};
      begin
         for Lane in Wide.{f.index} loop
            Selectors (Lane) := Wide.{f.index} (Next_U64 mod {f.lanes});
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
{lookup_declarations}
      A_Lanes : constant Wide.{f.values} := [{a_values}];
      B_Lanes : constant Wide.{f.values} := [{b_values}];
      Bit_Lanes : constant Wide.{f.values} := [{bit_lanes}];
      A : constant Wide.{f.vector} := Wide.From_Lanes (A_Lanes);
      B : constant Wide.{f.vector} := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.{f.vector} := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.{f.mask} :=
        Wide.Mask_From_Bit_Mask ({f.mask_bits} ({alt}));
      Packed : constant Wide.{f.vector} := Wide.Compress (A, Alternating);
      Expanded : constant Wide.{f.vector} := Wide.Expand (Packed, Alternating);
      P : constant Wide.{f.values} := Wide.To_Lanes (Packed);
      E : constant Wide.{f.values} := Wide.To_Lanes (Expanded);
      Data : {f.array} (3 .. {f.lanes + 10}) := [others => 0];
      Native_Data : {f.array} (3 .. {f.lanes + 10}) := [others => 0];
      Aligned_Data : {f.array} (0 .. {f.lanes - 1}) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.{f.selectors};
      Two_Selectors : Wide.{f.two_selectors};
      Native_Two_Selectors : Wide.{f.two_selectors};
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "{f.vector} lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.{f.values}'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.{f.values}'[others => 0],
        "{f.vector} zero construction");
      for Lane in Wide.{f.index} loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.{f.index} => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.{f.index} => (if Position = Lane then A_Lanes (Lane) else 0)],
           "{f.vector} lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.{f.index} => {f.scalar} (A_Lanes (Lane) + 2)],
        "{f.vector} add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.{f.index} => {f.scalar} (A_Lanes (Lane) - 2)],
        "{f.vector} subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.{f.index} => {f.scalar} (A_Lanes (Lane) * 2)],
        "{f.vector} multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.{f.values}'[others => 0],
        "{f.vector} xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.{f.values}'[others => 0],
        "{f.vector} complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "{f.vector} double complement");
{lookup_checks}
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, {f.bits})) = Wide.{f.values}'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, {f.bits + 7})) = Wide.{f.values}'[others => 0],
        "{f.vector} oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = {all_bits},
        "{f.vector} equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.{f.index} => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "{f.vector} selection");
      for Lane in Wide.{f.index} loop
         if Lane < {f.lanes // 2} then
            Check (P (Lane) = A_Lanes (2 * Lane), "{f.vector} compression prefix");
         else
            Check (P (Lane) = 0, "{f.vector} compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "{f.vector} expansion position");
         Map_Selectors (Lane) := Wide.{f.index} ({f.lanes - 1} - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes}))
            else Wide.Select_Right_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes})));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes}))
            else Native.Select_Right_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes})));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.{f.index} => A_Lanes ({f.lanes - 1} - Lane)],
        "{f.vector} lane map");
      declare
         Scalar_Map : constant Wide.{f.two_map} :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.{f.two_map} :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.{f.vector} :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.{f.vector} :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.{f.index} loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod {f.lanes})
               else B_Lanes ((Lane * 3 + 1) mod {f.lanes}))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "{f.vector} two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.{f.two_map};
         Native_Default_Map : Wide.{f.two_map};
         Scalar_Default : constant Wide.{f.vector} :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.{f.vector} :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.{f.index} loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "{f.vector} default two-source lane map" & Lane'Image);
         end loop;
      end;
{bit_cast_tests(f, 'Bit_Vector', 'edge ')}
      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.{f.index} => A_Lanes ({f.lanes - 1} - Lane)],
        "{f.vector} reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, {f.lanes})) = Wide.{f.values}'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, {f.lanes + 1})) = Wide.{f.values}'[others => 0],
        "{f.vector} oversized slides");
      for Count in Wide.{f.count} loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. {f.lanes - 1} loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "{f.vector} partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.{f.index} => (if Lane < Count then A_Lanes (Lane) else 0)],
           "{f.vector} partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = {f.lanes // 2}
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = {f.lanes - 2},
        "{f.vector} mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "{f.vector} native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "{f.vector} native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "{f.vector} native bitwise and extrema");
      for Shift in Natural range 0 .. {f.bits + 2} loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)){' and then Native.To_Lanes (Native.Shift_Right_Arithmetic (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (A, Shift))' if f.signed else ''},
           "{f.vector} native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "{f.vector} native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "{f.vector} native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask ({f.mask_bits} ({alt})))) = P,
        "{f.vector} native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask ({f.mask_bits} ({alt}))),
         Native.Mask_From_Bit_Mask ({f.mask_bits} ({alt})))) = E,
        "{f.vector} native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "{f.vector} native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "{f.vector} native lane movement");
      for Slide in Natural range 0 .. {f.lanes + 2} loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "{f.vector} native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = {all_bits}
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "{f.vector} native mask algebra and reductions");
      for Pattern in Natural range 0 .. {'2 ** ' + str(f.lanes) + ' - 1' if f.lanes <= 16 else '1_023'} loop
         declare
            Bits : constant Wide.{f.mask_bits} :=
              (if {str(f.lanes <= 16)} then Wide.{f.mask_bits} (Pattern)
               else Wide.{f.mask_bits} (Next_U64 mod 2 ** {f.lanes}));
            Scalar_Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.{f.mask} := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "{f.vector} mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = {all_bits})
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "{f.vector} mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = {all_bits}
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = {all_bits}
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = {all_bits},
              "{f.vector} mask algebra" & Pattern'Image);
            for Lane in Wide.{f.index} loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "{f.vector} mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "{f.vector} native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "{f.vector} ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "{f.vector} native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "{f.vector} scalar aligned memory");
      for Count in Wide.{f.count} loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "{f.vector} native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.{f.vector} := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.{f.vector} := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.{f.lane_map} := Random_Map;
            R_Two_Selectors : Wide.{f.two_selectors};
            R_Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask
              ({f.mask_bits} (Next_U64 mod 2 ** {f.lanes}));
            Shift : constant Natural := Natural (Next_U64 mod {f.bits + 3});
            Slide : constant Natural := Natural (Next_U64 mod {f.lanes + 3});
         begin
            for Lane in Wide.{f.index} loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.{f.index} (Next_U64 mod {f.lanes}))
                  else Wide.Select_Right_Lane (Wide.{f.index} (Next_U64 mod {f.lanes})));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "{f.vector} randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "{f.vector} randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)){' and then Native.To_Lanes (Native.Shift_Right_Arithmetic (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (R_A, Shift))' if f.signed else ''},
              "{f.vector} randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "{f.vector} randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "{f.vector} randomized selection and movement" & Iteration'Image);
{lookup_randomized}
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "{f.vector} randomized reductions" & Iteration'Image);
{bit_cast_tests(f, 'R_A', 'randomized ')}
         end;
      end loop;
   end Test_{f.vector};
"""


def float_test(f: Family) -> str:
    a_values = ", ".join(f"{i + 1}.0" for i in range(f.lanes))
    alt = sum(1 << i for i in range(0, f.lanes, 2))
    bit_type = "Interfaces.Unsigned_32" if f.bits == 32 else "Interfaces.Unsigned_64"
    sign_bit = "16#8000_0000#" if f.bits == 32 else "16#8000_0000_0000_0000#"
    inf_bits = "16#7F80_0000#" if f.bits == 32 else "16#7FF0_0000_0000_0000#"
    qnan_bits = "16#7FC1_2345#" if f.bits == 32 else "16#7FF8_1234_5678_9ABC#"
    snan_bits = "16#7F81_2345#" if f.bits == 32 else "16#7FF0_1234_5678_9ABC#"
    special_bits = ["0", sign_bit, inf_bits, qnan_bits, snan_bits]
    while len(special_bits) < f.lanes:
        special_bits.append(str(len(special_bits)))
    special_values = ", ".join(f"Bits_To_Value ({value})" for value in special_bits[:f.lanes])
    order_values = ["2.0", "1.0", f"Bits_To_Value ({snan_bits})", "3.0"]
    while len(order_values) < f.lanes:
        order_values.append("3.0")
    order_lanes = ", ".join(order_values)
    positive_zero_order = ", ".join("0.0" if i % 2 == 0 else f"Bits_To_Value ({sign_bit})" for i in range(f.lanes))
    negative_zero_order = ", ".join(f"Bits_To_Value ({sign_bit})" if i % 2 == 0 else "0.0" for i in range(f.lanes))
    random_bits = "Next_U64" if f.bits == 64 else f"Next_U64 mod 2 ** {f.bits}"
    return f"""
   procedure Test_{f.vector} is
      function Bits_To_Value is new Ada.Unchecked_Conversion ({bit_type}, {f.scalar});
      function Value_To_Bits is new Ada.Unchecked_Conversion ({f.scalar}, {bit_type});
      function Random_Lanes return Wide.{f.values} is
         Result : Wide.{f.values};
      begin
         for Lane in Wide.{f.index} loop
            Result (Lane) := {f.scalar} (Integer (Next_U64 mod 2_000_001) - 1_000_000) / 128.0;
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Bit_Lanes return Wide.{f.values} is
         Result : Wide.{f.values};
      begin
         for Lane in Wide.{f.index} loop
            Result (Lane) := Bits_To_Value
              ({bit_type} ({random_bits}));
         end loop;
         return Result;
      end Random_Bit_Lanes;
      function Random_Map return Wide.{f.lane_map} is
         Selectors : Wide.{f.selectors};
      begin
         for Lane in Wide.{f.index} loop
            Selectors (Lane) := Wide.{f.index} (Next_U64 mod {f.lanes});
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.{f.values} := [{a_values}];
      A : constant Wide.{f.vector} := Wide.From_Lanes (A_Lanes);
      Two : constant Wide.{f.vector} := Wide.Splat (2.0);
      Alternating : constant Wide.{f.mask} :=
        Wide.Mask_From_Bit_Mask ({f.mask_bits} ({alt}));
      Packed : constant Wide.{f.values} := Wide.To_Lanes (Wide.Compress (A, Alternating));
      Expanded : constant Wide.{f.values} := Wide.To_Lanes
        (Wide.Expand (Wide.Compress (A, Alternating), Alternating));
      Data : {f.array} (5 .. {f.lanes + 12}) := [others => 0.0];
      Native_Data : {f.array} (5 .. {f.lanes + 12}) := [others => 0.0];
      Aligned_Data : {f.array} (0 .. {f.lanes - 1}) := [others => 0.0]
        with Alignment => 32;
      Special_Lanes : constant Wide.{f.values} := [{special_values}];
      Specials : constant Wide.{f.vector} := Wide.From_Lanes (Special_Lanes);
      Order_Vector : constant Wide.{f.vector} := Wide.From_Lanes ([{order_lanes}]);
      Positive_Zero_First : constant Wide.{f.vector} :=
        Wide.From_Lanes ([{positive_zero_order}]);
      Negative_Zero_First : constant Wide.{f.vector} :=
        Wide.From_Lanes ([{negative_zero_order}]);
      Map_Selectors : Wide.{f.selectors};
      Two_Selectors : Wide.{f.two_selectors};
      Native_Two_Selectors : Wide.{f.two_selectors};
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "{f.vector} lane round trip");
      for Lane in Wide.{f.index} loop
         Check (Value_To_Bits (Wide.Extract (Wide.Zero, Lane)) = 0
           and then Value_To_Bits (Native.Extract (Native.Zero, Lane)) = 0,
           "{f.vector} zero construction" & Lane'Image);
         for Position in Wide.{f.index} loop
            Check (Value_To_Bits (Wide.Extract (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane)), Position)) =
              (if Position = Lane then Value_To_Bits (A_Lanes (Lane)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Replace (Native.Zero, Lane, A_Lanes (Lane)), Position)) =
              (if Position = Lane then Value_To_Bits (A_Lanes (Lane)) else 0),
              "{f.vector} lane replacement" & Lane'Image & Position'Image);
         end loop;
      end loop;
      Check (Wide.To_Lanes (Wide.Add (A, Two)) =
        [for Lane in Wide.{f.index} => A_Lanes (Lane) + 2.0], "{f.vector} add");
      Check (Wide.To_Lanes (Wide.Multiply (A, Two)) =
        [for Lane in Wide.{f.index} => A_Lanes (Lane) * 2.0], "{f.vector} multiply");
      Check (Wide.To_Bit_Mask (Wide.Less_Than (A, Two)) = 1,
        "{f.vector} ordered comparison");
      for Lane in Wide.{f.index} loop
         Check (Packed (Lane) = (if Lane < {f.lanes // 2} then A_Lanes (2 * Lane) else 0.0),
           "{f.vector} compression");
         Check (Expanded (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0.0),
           "{f.vector} expansion");
      end loop;
      Check (Wide.Reduce_Add (A) = {sum(range(1, f.lanes + 1))}.0,
        "{f.vector} reduction");
      Check (Wide.Reduce_Min_Number (A) = {f.scalar} (1.0)
        and then Wide.Reduce_Max_Number (Wide.Splat (-1.0)) = {f.scalar} (-1.0),
        "{f.vector} min and max reductions");
      Check (Wide.Reduce_Min_Number (Order_Vector) = 3.0
        and then Wide.Reduce_Max_Number (Order_Vector) = 3.0
        and then Native.Reduce_Min_Number (Order_Vector) = 3.0
        and then Native.Reduce_Max_Number (Order_Vector) = 3.0,
        "{f.vector} ordered signaling-NaN reductions");
      Check (Value_To_Bits (Wide.Reduce_Min_Number (Positive_Zero_First)) = {sign_bit}
        and then Value_To_Bits (Wide.Reduce_Max_Number (Positive_Zero_First)) = 0
        and then Value_To_Bits (Wide.Reduce_Min_Number (Negative_Zero_First)) = {sign_bit}
        and then Value_To_Bits (Wide.Reduce_Max_Number (Negative_Zero_First)) = 0
        and then Value_To_Bits (Native.Reduce_Min_Number (Positive_Zero_First)) = {sign_bit}
        and then Value_To_Bits (Native.Reduce_Max_Number (Positive_Zero_First)) = 0
        and then Value_To_Bits (Native.Reduce_Min_Number (Negative_Zero_First)) = {sign_bit}
        and then Value_To_Bits (Native.Reduce_Max_Number (Negative_Zero_First)) = 0,
        "{f.vector} signed-zero reductions");
      Check (Value_To_Bits (Wide.Reduce_Add (Wide.Splat (Bits_To_Value ({sign_bit})))) = 0
        and then Value_To_Bits (Native.Reduce_Add (Native.Splat (Bits_To_Value ({sign_bit})))) = 0,
        "{f.vector} reduction positive-zero start");
      for Count in Wide.{f.count} loop
         Data := [others => 0.0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.{f.index} => (if Lane < Count then A_Lanes (Lane) else 0.0)],
           "{f.vector} partial memory");
      end loop;
      Check (Native.To_Lanes (Native.Multiply
        (Native.From_Lanes (A_Lanes), Native.Splat (2.0))) =
        Wide.To_Lanes (Wide.Multiply (A, Two)), "{f.vector} native multiply");
      Check (Native.To_Lanes (Native.Add (A, Two)) = Wide.To_Lanes (Wide.Add (A, Two))
        and then Native.To_Lanes (Native.Subtract (A, Two)) = Wide.To_Lanes (Wide.Subtract (A, Two))
        and then Native.To_Lanes (Native.Divide (A, Two)) = Wide.To_Lanes (Wide.Divide (A, Two))
        and then Native.To_Lanes (Native.Min_Number (A, Two)) = Wide.To_Lanes (Wide.Min_Number (A, Two))
        and then Native.To_Lanes (Native.Max_Number (A, Two)) = Wide.To_Lanes (Wide.Max_Number (A, Two)),
        "{f.vector} native floating arithmetic");
      Check (Native.To_Bit_Mask (Native.Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Less_Than (A, Two)) = Wide.To_Bit_Mask (Wide.Less_Than (A, Two))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, Two)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, Two))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Unordered (Specials, A)) = Wide.To_Bit_Mask (Wide.Unordered (Specials, A)),
        "{f.vector} native floating comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, Two)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, Two)),
        "{f.vector} native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask ({f.mask_bits} ({alt})))) = Packed,
        "{f.vector} native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask ({f.mask_bits} ({alt}))),
         Native.Mask_From_Bit_Mask ({f.mask_bits} ({alt})))) = Expanded,
        "{f.vector} native expansion");
      Check (Native.Reduce_Min_Number (Native.From_Lanes (A_Lanes)) = {f.scalar} (1.0)
        and then Native.Reduce_Max_Number (Native.Splat (-1.0)) = {f.scalar} (-1.0),
        "{f.vector} native min and max reductions");
      Check (Value_To_Bits (Native.Reduce_Add (A)) = Value_To_Bits (Wide.Reduce_Add (A)),
        "{f.vector} native add reduction");
      for Lane in Wide.{f.index} loop
         Map_Selectors (Lane) := Wide.{f.index} ({f.lanes - 1} - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes}))
            else Wide.Select_Right_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes})));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes}))
            else Native.Select_Right_Lane (Wide.{f.index} ((Lane * 3 + 1) mod {f.lanes})));
      end loop;
      declare
         Scalar_Map : constant Wide.{f.two_map} :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.{f.two_map} :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.{f.vector} :=
           Wide.Permute_Lanes (Specials, A, Scalar_Map);
         Native_Result : constant Wide.{f.vector} :=
           Native.Permute_Lanes (Specials, A, Native_Map);
      begin
         for Lane in Wide.{f.index} loop
            Check (Value_To_Bits (Wide.Extract (Scalar_Result, Lane)) =
              (if Lane mod 2 = 0
               then Value_To_Bits (Special_Lanes ((Lane * 3 + 1) mod {f.lanes}))
               else Value_To_Bits (A_Lanes ((Lane * 3 + 1) mod {f.lanes})))
              and then Value_To_Bits (Native.Extract (Native_Result, Lane)) =
                Value_To_Bits (Wide.Extract (Scalar_Result, Lane)),
              "{f.vector} special-bit two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.{f.two_map};
         Native_Default_Map : Wide.{f.two_map};
         Scalar_Default : constant Wide.{f.vector} :=
           Wide.Permute_Lanes (Specials, A, Scalar_Default_Map);
         Native_Default : constant Wide.{f.vector} :=
           Native.Permute_Lanes (Specials, A, Native_Default_Map);
      begin
         for Lane in Wide.{f.index} loop
            Check (Value_To_Bits (Wide.Extract (Scalar_Default, Lane)) =
              Value_To_Bits (Special_Lanes (0))
              and then Value_To_Bits (Wide.Extract (Native_Default, Lane)) =
                Value_To_Bits (Special_Lanes (0)),
              "{f.vector} default two-source lane map" & Lane'Image);
         end loop;
      end;
{bit_cast_tests(f, 'Specials', 'special ')}
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, Two)) = Wide.To_Lanes (Wide.Interleave_Low (A, Two))
        and then Native.To_Lanes (Native.Interleave_High (A, Two)) = Wide.To_Lanes (Wide.Interleave_High (A, Two))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, Two)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, Two))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, Two)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, Two)),
        "{f.vector} native lane movement");
      for Slide in Natural range 0 .. {f.lanes + 2} loop
         for Lane in Wide.{f.index} loop
            Check (Value_To_Bits (Wide.Extract (Wide.Slide_Lanes_Toward_Low (Specials, Slide), Lane)) =
              (if Slide < {f.lanes} and then Lane < {f.lanes} - Slide then Value_To_Bits (Special_Lanes (Lane + Slide)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Slide_Lanes_Toward_Low (Specials, Slide), Lane)) =
              (if Slide < {f.lanes} and then Lane < {f.lanes} - Slide then Value_To_Bits (Special_Lanes (Lane + Slide)) else 0)
              and then Value_To_Bits (Wide.Extract (Wide.Slide_Lanes_Toward_High (Specials, Slide), Lane)) =
              (if Slide < {f.lanes} and then Lane >= Slide then Value_To_Bits (Special_Lanes (Lane - Slide)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Slide_Lanes_Toward_High (Specials, Slide), Lane)) =
              (if Slide < {f.lanes} and then Lane >= Slide then Value_To_Bits (Special_Lanes (Lane - Slide)) else 0),
              "{f.vector} special-bit slide oracle" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "{f.vector} native mask algebra and reductions");
      for Pattern in Natural range 0 .. {'2 ** ' + str(f.lanes) + ' - 1' if f.lanes <= 16 else '1_023'} loop
         declare
            Bits : constant Wide.{f.mask_bits} :=
              (if {str(f.lanes <= 16)} then Wide.{f.mask_bits} (Pattern)
               else Wide.{f.mask_bits} (Next_U64 mod 2 ** {f.lanes}));
            Scalar_Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.{f.mask} := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask),
              "{f.vector} mask predicates" & Pattern'Image);
            Check (Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = {f.mask_bits}'Last
              and then Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = {f.mask_bits}'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = {f.mask_bits}'Last,
              "{f.vector} mask algebra" & Pattern'Image);
            for Lane in Wide.{f.index} loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "{f.vector} mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0.0];
      Native_Data := [others => 0.0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "{f.vector} native unaligned memory");
      Data := [others => 0.0];
      Native_Data := [others => 0.0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "{f.vector} ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "{f.vector} native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, Two);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = Wide.To_Lanes (Two),
        "{f.vector} scalar aligned memory");
      for Count in Wide.{f.count} loop
         Data := [others => 0.0];
         Native_Data := [others => 0.0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "{f.vector} native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.{f.vector} := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.{f.vector} := Wide.From_Lanes (Random_Lanes);
            R_Bits : constant Wide.{f.vector} := Wide.From_Lanes (Random_Bit_Lanes);
            R_Map : constant Wide.{f.lane_map} := Random_Map;
            R_Two_Selectors : Wide.{f.two_selectors};
            R_Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask
              ({f.mask_bits} (Next_U64 mod 2 ** {f.lanes}));
            Slide : constant Natural := Natural (Next_U64 mod {f.lanes + 3});
         begin
            for Lane in Wide.{f.index} loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.{f.index} (Next_U64 mod {f.lanes}))
                  else Wide.Select_Right_Lane (Wide.{f.index} (Next_U64 mod {f.lanes})));
            end loop;
            Check (Native.To_Lanes (Native.Add (R_A, R_B)) = Wide.To_Lanes (Wide.Add (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply (R_A, R_B)),
              "{f.vector} randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Min_Number (R_A, R_B)) = Wide.To_Lanes (Wide.Min_Number (R_A, R_B))
              and then Native.To_Lanes (Native.Max_Number (R_A, R_B)) = Wide.To_Lanes (Wide.Max_Number (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "{f.vector} randomized extrema and comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "{f.vector} randomized selection and movement" & Iteration'Image);
            Check (Value_To_Bits (Native.Reduce_Add (R_A)) = Value_To_Bits (Wide.Reduce_Add (R_A))
              and then Value_To_Bits (Native.Reduce_Min_Number (R_A)) = Value_To_Bits (Wide.Reduce_Min_Number (R_A))
              and then Value_To_Bits (Native.Reduce_Max_Number (R_A)) = Value_To_Bits (Wide.Reduce_Max_Number (R_A)),
              "{f.vector} randomized reductions" & Iteration'Image);
{bit_cast_tests(f, 'R_Bits', 'randomized ')}
         end;
      end loop;
   end Test_{f.vector};
"""


def source() -> str:
    procedures = "\n".join(float_test(f) if f.floating else integer_test(f) for f in FAMILIES)
    procedures += "\n" + conversion_tests()
    calls = "\n".join(f"   Test_{f.vector};" for f in FAMILIES) + "\n   Test_Wide_Conversions;"
    return f"""with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Interfaces;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Wide_Tests is
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;
   use Flyology_SIMD;
   use Flyology_SIMD.Wide;
   use type U8;
   use type I8;
   use type U16;
   use type I16;
   use type U32;
   use type I32;
   use type U64;
   use type I64;
   use type F32;
   use type F64;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         raise Program_Error with Message;
      end if;
   end Check;

   Random_State : U64 := 16#A5C3_71D9_4E82_B60F#;
   function Next_U64 return U64 is
   begin
      Random_State := Random_State xor Interfaces.Shift_Left (Random_State, 13);
      Random_State := Random_State xor Interfaces.Shift_Right (Random_State, 7);
      Random_State := Random_State xor Interfaces.Shift_Left (Random_State, 17);
      return Random_State;
   end Next_U64;

{procedures}
begin
   Ada.Text_IO.Put_Line ("wide-family differential tests seed=0xA5C371D94E82B60F");
{calls}
   Ada.Text_IO.Put_Line ("wide-family semantic tests: PASS");
end Wide_Tests;
"""


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = source()
    if args.check:
        if not TEST.exists() or TEST.read_text() != content:
            raise SystemExit("generated file is stale: tests/wide_tests.adb")
    else:
        TEST.write_text(content)


if __name__ == "__main__":
    main()
