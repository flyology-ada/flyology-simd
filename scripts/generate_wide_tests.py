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


def predicate_declarations(f: Family) -> str:
    """Generate an independent lane oracle for comparisons and selection."""
    unordered_kind = ", Is_Unordered" if f.floating else ""
    if f.floating:
        cases = """when Is_Equal         => not Is_NaN (Left (Lane)) and then not Is_NaN (Right (Lane)) and then Left (Lane) = Right (Lane),
                  when Is_Less          => not Is_NaN (Left (Lane)) and then not Is_NaN (Right (Lane)) and then Left (Lane) < Right (Lane),
                  when Is_Less_Equal    => not Is_NaN (Left (Lane)) and then not Is_NaN (Right (Lane)) and then Left (Lane) <= Right (Lane),
                  when Is_Greater       => not Is_NaN (Left (Lane)) and then not Is_NaN (Right (Lane)) and then Left (Lane) > Right (Lane),
                  when Is_Greater_Equal => not Is_NaN (Left (Lane)) and then not Is_NaN (Right (Lane)) and then Left (Lane) >= Right (Lane),
                  when Is_Unordered     => Is_NaN (Left (Lane)) or else Is_NaN (Right (Lane))"""
        unordered_expected = """
         Unordered_Bits : constant Wide.{mask_bits} :=
           Reference_Comparison (Left_Values, Right_Values, Is_Unordered);""".format(
               mask_bits=f.mask_bits)
        unordered_check = """
           and then Wide.To_Bit_Mask (Wide.Unordered (Left_Value, Right_Value)) = Unordered_Bits
           and then Native.To_Bit_Mask (Native.Unordered (Left_Value, Right_Value)) = Unordered_Bits"""
        selection_check = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Wide.Extract (Scalar_Selected, Lane)) =
                Value_To_Bits (Expected_Selected (Lane)))
           and then (for all Lane in Wide.{index} =>
              Value_To_Bits (Native.Extract (Native_Selected, Lane)) =
                Value_To_Bits (Expected_Selected (Lane)))""".format(index=f.index)
    else:
        cases = """when Is_Equal         => Left (Lane) = Right (Lane),
                  when Is_Less          => Left (Lane) < Right (Lane),
                  when Is_Less_Equal    => Left (Lane) <= Right (Lane),
                  when Is_Greater       => Left (Lane) > Right (Lane),
                  when Is_Greater_Equal => Left (Lane) >= Right (Lane)"""
        unordered_expected = ""
        unordered_check = ""
        selection_check = (
            "Wide.To_Lanes (Scalar_Selected) = Expected_Selected\n"
            "           and then Native.To_Lanes (Native_Selected) = Expected_Selected"
        )

    return f'''
      type Comparison_Kind is
        (Is_Equal, Is_Less, Is_Less_Equal, Is_Greater, Is_Greater_Equal{unordered_kind});

      function Reference_Comparison
        (Left, Right : Wide.{f.values}; Kind : Comparison_Kind)
         return Wide.{f.mask_bits}
      is
         Result : Wide.{f.mask_bits} := 0;
      begin
         for Lane in Wide.{f.index} loop
            if (case Kind is
                  {cases})
            then
               Result := Result or Interfaces.Shift_Left
                 (Wide.{f.mask_bits} (1), Lane);
            end if;
         end loop;
         return Result;
      end Reference_Comparison;

      function Reference_Select
        (Bits : Wide.{f.mask_bits}; If_True, If_False : Wide.{f.values})
         return Wide.{f.values}
      is
        ([for Lane in Wide.{f.index} =>
           (if ((Bits / 2 ** Lane) mod 2) = 1
            then If_True (Lane) else If_False (Lane))]);

      procedure Check_Predicates
        (Left_Values, Right_Values : Wide.{f.values};
         Select_Bits : Wide.{f.mask_bits};
         Context : String)
      is
         Left_Value : constant Wide.{f.vector} := Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.{f.vector} := Wide.From_Lanes (Right_Values);
         Select_Mask : constant Wide.{f.mask} :=
           Wide.Mask_From_Bit_Mask (Select_Bits);
         Equal_Bits : constant Wide.{f.mask_bits} :=
           Reference_Comparison (Left_Values, Right_Values, Is_Equal);
         Less_Bits : constant Wide.{f.mask_bits} :=
           Reference_Comparison (Left_Values, Right_Values, Is_Less);
         Less_Equal_Bits : constant Wide.{f.mask_bits} :=
           Reference_Comparison (Left_Values, Right_Values, Is_Less_Equal);
         Greater_Bits : constant Wide.{f.mask_bits} :=
           Reference_Comparison (Left_Values, Right_Values, Is_Greater);
         Greater_Equal_Bits : constant Wide.{f.mask_bits} :=
           Reference_Comparison (Left_Values, Right_Values, Is_Greater_Equal);{unordered_expected}
         Expected_Selected : constant Wide.{f.values} :=
           Reference_Select (Select_Bits, Left_Values, Right_Values);
         Scalar_Selected : constant Wide.{f.vector} :=
           Wide.Select_Value (Select_Mask, Left_Value, Right_Value);
         Native_Selected : constant Wide.{f.vector} :=
           Native.Select_Value (Select_Mask, Left_Value, Right_Value);
      begin
         Check
           (Wide.To_Bit_Mask (Wide.Equal (Left_Value, Right_Value)) = Equal_Bits
           and then Native.To_Bit_Mask (Native.Equal (Left_Value, Right_Value)) = Equal_Bits
           and then Wide.To_Bit_Mask (Wide.Less_Than (Left_Value, Right_Value)) = Less_Bits
           and then Native.To_Bit_Mask (Native.Less_Than (Left_Value, Right_Value)) = Less_Bits
           and then Wide.To_Bit_Mask (Wide.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits
           and then Native.To_Bit_Mask (Native.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits
           and then Wide.To_Bit_Mask (Wide.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
           and then Native.To_Bit_Mask (Native.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
           and then Wide.To_Bit_Mask (Wide.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits
           and then Native.To_Bit_Mask (Native.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits{unordered_check},
            "{f.vector} independent comparison oracle " & Context);
         Check ({selection_check},
           "{f.vector} independent selection oracle " & Context);
      end Check_Predicates;
'''


def compaction_declarations(f: Family) -> str:
    zero = "0.0" if f.floating else "0"
    if f.floating:
        scalar_packed_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Wide.Extract (Scalar_Packed, Lane)) =
                Value_To_Bits (Expected_Packed (Lane)))""".format(index=f.index)
        native_packed_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Native.Extract (Native_Packed, Lane)) =
                Value_To_Bits (Expected_Packed (Lane)))""".format(index=f.index)
        scalar_direct_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Wide.Extract (Scalar_Direct, Lane)) =
                Value_To_Bits (Expected_Direct (Lane)))""".format(index=f.index)
        native_direct_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Native.Extract (Native_Direct, Lane)) =
                Value_To_Bits (Expected_Direct (Lane)))""".format(index=f.index)
        scalar_round_trip_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Wide.Extract (Scalar_Round_Trip, Lane)) =
                Value_To_Bits (Expected_Round_Trip (Lane)))""".format(index=f.index)
        native_round_trip_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Native.Extract (Native_Round_Trip, Lane)) =
                Value_To_Bits (Expected_Round_Trip (Lane)))""".format(index=f.index)
    else:
        scalar_packed_matches = "Wide.To_Lanes (Scalar_Packed) = Expected_Packed"
        native_packed_matches = "Native.To_Lanes (Native_Packed) = Expected_Packed"
        scalar_direct_matches = "Wide.To_Lanes (Scalar_Direct) = Expected_Direct"
        native_direct_matches = "Native.To_Lanes (Native_Direct) = Expected_Direct"
        scalar_round_trip_matches = "Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip"
        native_round_trip_matches = "Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip"

    return f'''
      function Reference_Compress
        (Values : Wide.{f.values}; Bits : Wide.{f.mask_bits})
         return Wide.{f.values}
      is
         Result : Wide.{f.values} := [others => {zero}];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.{f.index} loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.{f.values}; Bits : Wide.{f.mask_bits})
         return Wide.{f.values}
      is
         Result : Wide.{f.values} := [others => {zero}];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.{f.index} loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.{f.values};
         Bits : Wide.{f.mask_bits};
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.{f.mask} :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.{f.mask} :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.{f.vector} := Wide.From_Lanes (Values);
         Native_Source : constant Wide.{f.vector} := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.{f.values} :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.{f.values} :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.{f.values} :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.{f.vector} :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.{f.vector} :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.{f.vector} :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.{f.vector} :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.{f.vector} :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.{f.vector} :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check ({scalar_packed_matches}
           and then {native_packed_matches},
           "{f.vector} independent compression " & Label_Text);
         Check ({scalar_direct_matches}
           and then {native_direct_matches},
           "{f.vector} independent direct expansion " & Label_Text);
         Check ({scalar_round_trip_matches}
           and then {native_round_trip_matches},
           "{f.vector} compression expansion property " & Label_Text);
      end Check_Compaction;
'''


def mask_position_declarations(f: Family) -> str:
    return f'''
      function Reference_First_True
        (Bits : Wide.{f.mask_bits}) return Wide.{f.count}
      is
      begin
         for Lane in Wide.{f.index} loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return {f.lanes};
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.{f.mask_bits}) return Wide.{f.count}
      is
      begin
         for Lane in reverse Wide.{f.index} loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return {f.lanes};
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.{f.mask_bits}) return Wide.{f.count}
      is
         Result : Wide.{f.count} := 0;
      begin
         for Lane in Wide.{f.index} loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.{f.mask_bits}; Label_Text : String)
      is
         Scalar_Mask : constant Wide.{f.mask} :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.{f.mask} :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.{f.count} :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.{f.count} :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.{f.count} :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "{f.vector} independent mask reductions " & Label_Text);
      end Check_Mask_Positions;
'''


def compaction_fixed_tests(f: Family, values: str, label: str = "fixed") -> str:
    return f'''
      Check_Compaction ({values}, 0, "{label} zero mask");
      Check_Compaction
        ({values}, Wide.{f.mask_bits}'Last, "{label} all mask");
      for Lane in Wide.{f.index} loop
         Check_Compaction
           ({values},
            Interfaces.Shift_Left (Wide.{f.mask_bits} (1), Lane),
            "{label} one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. {f.lanes} loop
         declare
            Prefix_Bits : constant Wide.{f.mask_bits} :=
              (if Count = {f.lanes}
               then Wide.{f.mask_bits}'Last
               else Wide.{f.mask_bits} (2 ** Count - 1));
         begin
            Check_Compaction
              ({values}, Prefix_Bits, "{label} prefix mask" & Count'Image);
            Check_Compaction
              ({values}, Wide.{f.mask_bits}'Last xor Prefix_Bits,
               "{label} suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.{f.mask_bits} :=
           Wide.{f.mask_bits} (2 ** {f.half_lanes} - 1);
         High_Half : constant Wide.{f.mask_bits} :=
           Wide.{f.mask_bits}'Last xor Low_Half;
         Across_Halves : constant Wide.{f.mask_bits} :=
           Interfaces.Shift_Left
             (Wide.{f.mask_bits} (1), {f.half_lanes - 1})
           or Interfaces.Shift_Left
             (Wide.{f.mask_bits} (1), {f.half_lanes});
      begin
         Check_Compaction ({values}, Low_Half, "{label} low-half mask");
         Check_Compaction ({values}, High_Half, "{label} high-half mask");
         Check_Compaction
           ({values}, Across_Halves, "{label} cross-half mask");
         Check_Compaction
           ({values}, Wide.{f.mask_bits} ({sum(1 << i for i in range(0, f.lanes, 2))}),
            "{label} alternating mask");
      end;
'''


def permutation_declarations(f: Family) -> str:
    if f.floating:
        scalar_one_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Wide.Extract (Scalar_One, Lane)) =
                Value_To_Bits (Expected_One (Lane)))""".format(index=f.index)
        native_one_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Native.Extract (Native_One, Lane)) =
                Value_To_Bits (Expected_One (Lane)))""".format(index=f.index)
        scalar_two_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Wide.Extract (Scalar_Two, Lane)) =
                Value_To_Bits (Expected_Two (Lane)))""".format(index=f.index)
        native_two_matches = """(for all Lane in Wide.{index} =>
              Value_To_Bits (Native.Extract (Native_Two, Lane)) =
                Value_To_Bits (Expected_Two (Lane)))""".format(index=f.index)
    else:
        scalar_one_matches = "Wide.To_Lanes (Scalar_One) = Expected_One"
        native_one_matches = "Native.To_Lanes (Native_One) = Expected_One"
        scalar_two_matches = "Wide.To_Lanes (Scalar_Two) = Expected_Two"
        native_two_matches = "Native.To_Lanes (Native_Two) = Expected_Two"

    return f'''
      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.{f.values};
         One_Selectors : Wide.{f.selectors};
         Two_Selectors : Wide.{f.two_selectors};
         Expected_One, Expected_Two : Wide.{f.values};
         Label_Text : String)
      is
         Scalar_Left : constant Wide.{f.vector} := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.{f.vector} := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.{f.vector} := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.{f.vector} := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.{f.vector} := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.{f.vector} := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.{f.vector} := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.{f.vector} := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check ({scalar_one_matches} and then {native_one_matches},
           "{f.vector} independent one-source permutation " & Label_Text);
         Check ({scalar_two_matches} and then {native_two_matches},
           "{f.vector} independent two-source permutation " & Label_Text);
      end Check_Permutations;
'''


def movement_declarations(f: Family) -> str:
    """Independent lane-array oracle for every fixed Wide movement."""
    if f.floating:
        match = f'''(for all Lane in Wide.{f.index} =>
              Value_To_Bits (Wide.Extract (Scalar_Result, Lane)) =
                Value_To_Bits (Expected (Lane)))
            and then (for all Lane in Wide.{f.index} =>
              Value_To_Bits (Native.Extract (Native_Result, Lane)) =
                Value_To_Bits (Expected (Lane)))'''
    else:
        match = (
            "Wide.To_Lanes (Scalar_Result) = Expected and then "
            "Native.To_Lanes (Native_Result) = Expected"
        )
    return f'''
      procedure Check_Movements
        (Left_Values, Right_Values : Wide.{f.values}; Label_Text : String)
      is
         Left : constant Wide.{f.vector} := Wide.From_Lanes (Left_Values);
         Right : constant Wide.{f.vector} := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.{f.vector};
            Expected : Wide.{f.values}; Operation : String)
         is
         begin
            Check ({match},
              "{f.vector} independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.{f.index} => Left_Values ({f.lanes - 1} - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.{f.index} =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.{f.index} =>
               (if Lane mod 2 = 0
                then Left_Values ({f.half_lanes} + Lane / 2)
                else Right_Values ({f.half_lanes} + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.{f.index} =>
               (if Lane < {f.half_lanes}
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - {f.half_lanes})))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.{f.index} =>
               (if Lane < {f.half_lanes}
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - {f.half_lanes}) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. {f.lanes + 2} loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.{f.index} =>
                  (if Count < {f.lanes} and then Lane < {f.lanes} - Count
                   then Left_Values (Lane + Count) else {('0.0' if f.floating else '0')})],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.{f.index} =>
                  (if Count < {f.lanes} and then Lane >= Count
                   then Left_Values (Lane - Count) else {('0.0' if f.floating else '0')})],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => {('0.0' if f.floating else '0')}],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => {('0.0' if f.floating else '0')}],
            "slide high Natural'Last");
      end Check_Movements;
'''


def memory_declarations(f: Family) -> str:
    """Independent full/partial array oracle for one Wide shape."""
    zero = "0.0" if f.floating else "0"
    fill = f"{f.scalar} (3.25)" if f.floating else f"{f.scalar}'Last"
    same = (
        "Value_To_Bits (Left) = Value_To_Bits (Right)"
        if f.floating else "Left = Right"
    )
    return f'''
      procedure Check_Memory
        (Values : Wide.{f.values}; Context : String)
      is
         Value : constant Wide.{f.vector} := Wide.From_Lanes (Values);
         Fill : constant {f.scalar} := {fill};
         Scalar_Data : {f.array} (3 .. {f.lanes + 10}) := [others => Fill];
         Native_Data : {f.array} (3 .. {f.lanes + 10}) := [others => Fill];
         Scalar_Aligned : {f.array} (0 .. {f.lanes - 1}) := [others => Fill]
           with Alignment => 32;
         Native_Aligned : {f.array} (0 .. {f.lanes - 1}) := [others => Fill]
           with Alignment => 32;
         Start : constant Natural := Scalar_Data'First + 1;
         function Same (Left, Right : {f.scalar}) return Boolean is
           ({same});
         function Array_Matches
           (Data : {f.array}; First : Natural; Count : Natural)
            return Boolean
         is
         begin
            for Index in Data'Range loop
               if Index >= First and then Index - First < Count then
                  if not Same (Data (Index), Values (Index - First)) then
                     return False;
                  end if;
               elsif not Same (Data (Index), Fill) then
                  return False;
               end if;
            end loop;
            return True;
         end Array_Matches;
         function Vector_Matches
           (Actual : Wide.{f.vector}; Count : Natural) return Boolean
         is
         begin
            for Lane in Wide.{f.index} loop
               if not Same
                 (Wide.Extract (Actual, Lane),
                  (if Lane < Count then Values (Lane) else {zero}))
               then
                  return False;
               end if;
            end loop;
            return True;
         end Vector_Matches;
      begin
         Wide.Store (Scalar_Data, Start, Value);
         Native.Store (Native_Data, Start, Value);
         Check (Array_Matches (Scalar_Data, Start, {f.lanes})
           and then Array_Matches (Native_Data, Start, {f.lanes})
           and then Vector_Matches (Wide.Load (Scalar_Data, Start), {f.lanes})
           and then Vector_Matches (Native.Load (Native_Data, Start), {f.lanes}),
           "{f.vector} independent ordinary memory " & Context);

         Scalar_Data := [others => Fill];
         Native_Data := [others => Fill];
         Wide.Store_Unaligned (Scalar_Data, Start, Value);
         Native.Store_Unaligned (Native_Data, Start, Value);
         Check (Array_Matches (Scalar_Data, Start, {f.lanes})
           and then Array_Matches (Native_Data, Start, {f.lanes})
           and then Vector_Matches
             (Wide.Load_Unaligned (Scalar_Data, Start), {f.lanes})
           and then Vector_Matches
             (Native.Load_Unaligned (Native_Data, Start), {f.lanes}),
           "{f.vector} independent unaligned memory " & Context);

         Wide.Store_Aligned (Scalar_Aligned, Scalar_Aligned'First, Value);
         Native.Store_Aligned (Native_Aligned, Native_Aligned'First, Value);
         Check (Array_Matches (Scalar_Aligned, Scalar_Aligned'First, {f.lanes})
           and then Array_Matches
             (Native_Aligned, Native_Aligned'First, {f.lanes})
           and then Vector_Matches
             (Wide.Load_Aligned (Scalar_Aligned, Scalar_Aligned'First), {f.lanes})
           and then Vector_Matches
             (Native.Load_Aligned (Native_Aligned, Native_Aligned'First), {f.lanes}),
           "{f.vector} independent aligned memory " & Context);

         for Count in Wide.{f.count} loop
            Scalar_Data := [others => Fill];
            Native_Data := [others => Fill];
            Wide.Store_Partial (Scalar_Data, Start, Count, Value);
            Native.Store_Partial (Native_Data, Start, Count, Value);
            Check (Array_Matches (Scalar_Data, Start, Count)
              and then Array_Matches (Native_Data, Start, Count)
              and then Vector_Matches
                (Wide.Load_Partial (Scalar_Data, Start, Count), Count)
              and then Vector_Matches
                (Native.Load_Partial (Native_Data, Start, Count), Count),
              "{f.vector} independent partial memory " & Context & Count'Image);
         end loop;

         Scalar_Data := [others => Fill];
         Native_Data := [others => Fill];
         Wide.Store_Partial
           (Scalar_Data, Natural'Last, Wide.{f.count}'First, Value);
         Native.Store_Partial
           (Native_Data, Natural'Last, Wide.{f.count}'First, Value);
         Check (Array_Matches (Scalar_Data, Start, 0)
           and then Array_Matches (Native_Data, Start, 0)
           and then Vector_Matches
             (Wide.Load_Partial
                (Scalar_Data, Natural'Last, Wide.{f.count}'First), 0)
           and then Vector_Matches
             (Native.Load_Partial
                (Native_Data, Natural'Last, Wide.{f.count}'First), 0),
           "{f.vector} zero-count memory avoids element addresses " & Context);
      end Check_Memory;
'''


def construction_declarations(f: Family) -> str:
    """Independent construction/access oracle using verified array memory."""
    zero = "0.0" if f.floating else "0"
    fill = f"{f.scalar} (3.25)" if f.floating else f"{f.scalar}'Last"
    same = (
        "Value_To_Bits (Left) = Value_To_Bits (Right)"
        if f.floating else "Left = Right"
    )
    return f'''
      procedure Check_Construction
        (Values : Wide.{f.values}; Context : String)
      is
         Scalar_Data : {f.array} (0 .. {f.lanes - 1}) := [others => {fill}];
         Native_Data : {f.array} (0 .. {f.lanes - 1}) := [others => {fill}];
         Scalar_Value : Wide.{f.vector};
         Native_Value : Wide.{f.vector};
         function Same (Left, Right : {f.scalar}) return Boolean is
           ({same});
         procedure Check_Array
           (Actual : {f.array}; Expected : Wide.{f.values}; Label : String)
         is
         begin
            for Lane in Wide.{f.index} loop
               Check (Same (Actual (Lane), Expected (Lane)),
                 "{f.vector} independent construction " & Label & Context
                 & Lane'Image);
            end loop;
         end Check_Array;
      begin
         Scalar_Value := Wide.Zero;
         Native_Value := Native.Zero;
         Wide.Store (Scalar_Data, 0, Scalar_Value);
         Native.Store (Native_Data, 0, Native_Value);
         Check_Array (Scalar_Data, [others => {zero}], "scalar zero ");
         Check_Array (Native_Data, [others => {zero}], "native zero ");

         Scalar_Value := Wide.Splat (Values (Values'First));
         Native_Value := Native.Splat (Values (Values'First));
         Wide.Store (Scalar_Data, 0, Scalar_Value);
         Native.Store (Native_Data, 0, Native_Value);
         Check_Array
           (Scalar_Data, [others => Values (Values'First)], "scalar splat ");
         Check_Array
           (Native_Data, [others => Values (Values'First)], "native splat ");

         Scalar_Value := Wide.From_Lanes (Values);
         Native_Value := Native.From_Lanes (Values);
         Wide.Store (Scalar_Data, 0, Scalar_Value);
         Native.Store (Native_Data, 0, Native_Value);
         Check_Array (Scalar_Data, Values, "scalar from-lanes ");
         Check_Array (Native_Data, Values, "native from-lanes ");

         Scalar_Value := Wide.Load (Scalar_Data, 0);
         Native_Value := Native.Load (Native_Data, 0);
         declare
            Scalar_Lanes : constant Wide.{f.values} :=
              Wide.To_Lanes (Scalar_Value);
            Native_Lanes : constant Wide.{f.values} :=
              Native.To_Lanes (Native_Value);
         begin
            for Lane in Wide.{f.index} loop
               Check (Same (Scalar_Lanes (Lane), Values (Lane))
                 and then Same (Native_Lanes (Lane), Values (Lane)),
                 "{f.vector} independent to-lanes " & Context & Lane'Image);
               Check (Same (Wide.Extract (Scalar_Value, Lane), Values (Lane))
                 and then Same (Native.Extract (Native_Value, Lane), Values (Lane)),
                 "{f.vector} independent extract " & Context & Lane'Image);
            end loop;
         end;

         for Lane in Wide.{f.index} loop
            declare
               Replacement : constant {f.scalar} :=
                 Values (Wide.{f.index}'Last - Lane);
               Expected : Wide.{f.values} := Values;
            begin
               Expected (Lane) := Replacement;
               Scalar_Value := Wide.Replace (Wide.Load (Scalar_Data, 0), Lane,
                                             Replacement);
               Native_Value := Native.Replace (Native.Load (Native_Data, 0), Lane,
                                               Replacement);
               Wide.Store (Scalar_Data, 0, Scalar_Value);
               Native.Store (Native_Data, 0, Native_Value);
               Check_Array (Scalar_Data, Expected, "scalar replace ");
               Check_Array (Native_Data, Expected, "native replace ");
               Scalar_Data := [for Position in Wide.{f.index} => Values (Position)];
               Native_Data := [for Position in Wide.{f.index} => Values (Position)];
            end;
         end loop;
      end Check_Construction;
'''


def random_conversion_helpers() -> str:
    out: list[str] = []
    for family in FAMILIES:
        if family.floating:
            continue
        unsigned = f"U{family.bits}"
        conversion = ""
        if family.signed:
            conversion = (
                f"      function Bits_To_{family.scalar} is new Ada.Unchecked_Conversion "
                f"({unsigned}, {family.scalar});\n"
            )
            raw = "Next_U64" if family.bits == 64 else f"{unsigned} (Next_U64 mod 2 ** {family.bits})"
            value = f"Bits_To_{family.scalar} ({raw})"
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


def numeric_conversion_oracle_declarations() -> str:
    return r'''
      function I32_To_Bits is new Ada.Unchecked_Conversion (I32, U32);
      function Oracle_Bits_To_I8 is new Ada.Unchecked_Conversion (U8, I8);
      function I16_To_Bits is new Ada.Unchecked_Conversion (I16, U16);
      function Oracle_Bits_To_I16 is new Ada.Unchecked_Conversion (U16, I16);
      function Oracle_Bits_To_I32 is new Ada.Unchecked_Conversion (U32, I32);
      function I64_To_Bits is new Ada.Unchecked_Conversion (I64, U64);
      function Oracle_Bits_To_I64 is new Ada.Unchecked_Conversion (U64, I64);
      function F32_To_Bits_Oracle is new Ada.Unchecked_Conversion (F32, U32);
      function Bits_To_F32_Oracle is new Ada.Unchecked_Conversion (U32, F32);
      function F64_To_Bits_Oracle is new Ada.Unchecked_Conversion (F64, U64);
      function Bits_To_F64_Oracle is new Ada.Unchecked_Conversion (U64, F64);

      function Same_F32_Conversion (Actual, Expected : F32) return Boolean is
         Actual_Bits : constant U32 := F32_To_Bits_Oracle (Actual);
         Expected_Bits : constant U32 := F32_To_Bits_Oracle (Expected);
         Actual_NaN : constant Boolean :=
           (Actual_Bits and 16#7F80_0000#) = 16#7F80_0000#
           and then (Actual_Bits and 16#007F_FFFF#) /= 0;
         Expected_NaN : constant Boolean :=
           (Expected_Bits and 16#7F80_0000#) = 16#7F80_0000#
           and then (Expected_Bits and 16#007F_FFFF#) /= 0;
      begin
         return Actual_Bits = Expected_Bits
           or else (Actual_NaN and then Expected_NaN);
      end Same_F32_Conversion;

      function Same_F64_Conversion (Actual, Expected : F64) return Boolean is
         Actual_Bits : constant U64 := F64_To_Bits_Oracle (Actual);
         Expected_Bits : constant U64 := F64_To_Bits_Oracle (Expected);
         Actual_NaN : constant Boolean :=
           (Actual_Bits and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#
           and then (Actual_Bits and 16#000F_FFFF_FFFF_FFFF#) /= 0;
         Expected_NaN : constant Boolean :=
           (Expected_Bits and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#
           and then (Expected_Bits and 16#000F_FFFF_FFFF_FFFF#) /= 0;
      begin
         return Actual_Bits = Expected_Bits
           or else (Actual_NaN and then Expected_NaN);
      end Same_F64_Conversion;

      function Oracle_Widen_F32 (Item : F32) return F64 is
         Bits : constant U32 := F32_To_Bits_Oracle (Item);
         Sign : constant U64 :=
           (if (Bits and 16#8000_0000#) = 0
            then 0 else 16#8000_0000_0000_0000#);
         Encoded_Exponent : constant Natural := Natural
           (Interfaces.Shift_Right (Bits, 23) and 16#FF#);
         Fraction : constant U32 := Bits and 16#007F_FFFF#;
         Highest : Natural := 0;
         Scan : U32 := Fraction;
      begin
         if Encoded_Exponent = 255 then
            return Bits_To_F64_Oracle
              (if Fraction = 0 then Sign or 16#7FF0_0000_0000_0000#
               else Sign or 16#7FF8_0000_0000_0000#);
         elsif Encoded_Exponent /= 0 then
            return Bits_To_F64_Oracle
              (Sign
               or Interfaces.Shift_Left
                 (U64 (Encoded_Exponent - 127 + 1_023), 52)
               or Interfaces.Shift_Left (U64 (Fraction), 29));
         elsif Fraction = 0 then
            return Bits_To_F64_Oracle (Sign);
         end if;
         while Interfaces.Shift_Right (Scan, 1) /= 0 loop
            Scan := Interfaces.Shift_Right (Scan, 1);
            Highest := Highest + 1;
         end loop;
         return Bits_To_F64_Oracle
           (Sign
            or Interfaces.Shift_Left
              (U64 (Integer (Highest) - 149 + 1_023), 52)
            or Interfaces.Shift_Left
              (U64 (Fraction - Interfaces.Shift_Left (1, Highest)),
               52 - Highest));
      end Oracle_Widen_F32;

      function Oracle_Narrow_Round (Item : F64) return F32 is
         Bits : constant U64 := F64_To_Bits_Oracle (Item);
         Sign : constant U32 :=
           (if (Bits and 16#8000_0000_0000_0000#) = 0
            then 0 else 16#8000_0000#);
         Encoded_Exponent : constant Natural := Natural
           (Interfaces.Shift_Right (Bits, 52) and 16#7FF#);
         Fraction : constant U64 := Bits and 16#000F_FFFF_FFFF_FFFF#;

         function Round_Right (Value : U64; Count : Positive) return U64 is
            Quotient : constant U64 := Interfaces.Shift_Right (Value, Count);
            Half : constant U64 := Interfaces.Shift_Left (1, Count - 1);
            Remainder : constant U64 :=
              Value and (Interfaces.Shift_Left (1, Count) - 1);
         begin
            return
              (if Remainder > Half
                 or else (Remainder = Half and then (Quotient and 1) /= 0)
               then Quotient + 1 else Quotient);
         end Round_Right;

         Exponent : Integer;
         Significant, Rounded : U64;
      begin
         if Encoded_Exponent = 0 then
            return Bits_To_F32_Oracle (Sign);
         elsif Encoded_Exponent = 16#7FF# then
            return Bits_To_F32_Oracle
              (if Fraction = 0 then Sign or 16#7F80_0000#
               else Sign or 16#7FC0_0000#);
         end if;
         Exponent := Encoded_Exponent - 1_023;
         Significant := 16#0010_0000_0000_0000# or Fraction;
         if Exponent >= -126 then
            Rounded := Round_Right (Significant, 29);
            if Rounded = 16#0100_0000# then
               Rounded := 16#0080_0000#;
               Exponent := Exponent + 1;
            end if;
            if Exponent > 127 then
               return Bits_To_F32_Oracle (Sign or 16#7F80_0000#);
            end if;
            return Bits_To_F32_Oracle
              (Sign or Interfaces.Shift_Left (U32 (Exponent + 127), 23)
               or U32 (Rounded - 16#0080_0000#));
         end if;
         declare
            Shift : constant Positive := -Exponent - 97;
         begin
            if Shift > 53 then
               return Bits_To_F32_Oracle (Sign);
            end if;
            return Bits_To_F32_Oracle
              (Sign or U32 (Round_Right (Significant, Shift)));
         end;
      end Oracle_Narrow_Round;

      function Oracle_Integer_To_Float_Bits
        (Magnitude : U64; Sign : U64; Fraction_Bits, Bias : Natural)
         return U64
      is
         function Round_Right (Value : U64; Count : Positive) return U64 is
            Quotient : constant U64 := Interfaces.Shift_Right (Value, Count);
            Half : constant U64 := Interfaces.Shift_Left (1, Count - 1);
            Remainder : constant U64 :=
              Value and (Interfaces.Shift_Left (1, Count) - 1);
         begin
            if Remainder > Half
              or else (Remainder = Half and then (Quotient and 1) /= 0)
            then
               return Quotient + 1;
            else
               return Quotient;
            end if;
         end Round_Right;

         Highest : Natural := 0;
         Scan : U64 := Magnitude;
         Significant : U64;
         Exponent : Natural;
      begin
         if Magnitude = 0 then
            return Sign;
         end if;
         while Interfaces.Shift_Right (Scan, 1) /= 0 loop
            Scan := Interfaces.Shift_Right (Scan, 1);
            Highest := Highest + 1;
         end loop;
         Exponent := Highest;
         if Highest <= Fraction_Bits then
            Significant := Interfaces.Shift_Left
              (Magnitude, Fraction_Bits - Highest);
         else
            Significant := Round_Right (Magnitude, Highest - Fraction_Bits);
            if Significant = Interfaces.Shift_Left (1, Fraction_Bits + 1) then
               Significant := Interfaces.Shift_Right (Significant, 1);
               Exponent := Exponent + 1;
            end if;
         end if;
         return Sign
           or Interfaces.Shift_Left (U64 (Exponent + Bias), Fraction_Bits)
           or (Significant - Interfaces.Shift_Left (1, Fraction_Bits));
      end Oracle_Integer_To_Float_Bits;

      function Oracle_Convert_Round_I32 (Item : I32) return F32 is
         Bits : constant U32 := I32_To_Bits (Item);
         Negative : constant Boolean := (Bits and 16#8000_0000#) /= 0;
         Magnitude : constant U64 :=
           (if Negative then U64 ((not Bits) + 1) else U64 (Bits));
         Sign : constant U64 := (if Negative then 16#8000_0000# else 0);
      begin
         return Bits_To_F32_Oracle
           (U32 (Oracle_Integer_To_Float_Bits
             (Magnitude, Sign, 23, 127)));
      end Oracle_Convert_Round_I32;

      function Oracle_Convert_Round_U32 (Item : U32) return F32 is
        (Bits_To_F32_Oracle
           (U32 (Oracle_Integer_To_Float_Bits (U64 (Item), 0, 23, 127))));

      function Oracle_Convert_Round_I64 (Item : I64) return F64 is
         Bits : constant U64 := I64_To_Bits (Item);
         Negative : constant Boolean :=
           (Bits and 16#8000_0000_0000_0000#) /= 0;
         Magnitude : constant U64 :=
           (if Negative then (not Bits) + 1 else Bits);
         Sign : constant U64 :=
           (if Negative then 16#8000_0000_0000_0000# else 0);
      begin
         return Bits_To_F64_Oracle
           (Oracle_Integer_To_Float_Bits (Magnitude, Sign, 52, 1_023));
      end Oracle_Convert_Round_I64;

      function Oracle_Convert_Round_U64 (Item : U64) return F64 is
        (Bits_To_F64_Oracle
           (Oracle_Integer_To_Float_Bits (Item, 0, 52, 1_023)));

      function Oracle_Float_To_Integer_Bits
        (Bits, Sign_Mask, Fraction_Mask : U64;
         Encoded_Exponent_Max, Fraction_Bits, Bias,
         Destination_Bits : Natural;
         Signed : Boolean) return U64
      is
         Destination_Mask : constant U64 :=
           (if Destination_Bits = 64 then U64'Last
            else Interfaces.Shift_Left (1, Destination_Bits) - 1);
         Minimum_Bits : constant U64 :=
           Interfaces.Shift_Left (1, Destination_Bits - 1);
         Maximum_Bits : constant U64 := Minimum_Bits - 1;
         Negative : constant Boolean := (Bits and Sign_Mask) /= 0;
         Fraction : constant U64 := Bits and Fraction_Mask;
         Encoded_Exponent : constant Natural := Natural
           (Interfaces.Shift_Right (Bits, Fraction_Bits)
            and U64 (Encoded_Exponent_Max));
         Exponent : Integer;
         Significant, Magnitude : U64;
      begin
         if Encoded_Exponent = Encoded_Exponent_Max and then Fraction /= 0 then
            return 0;
         elsif not Signed and then Negative then
            return 0;
         elsif Encoded_Exponent = 0 then
            return 0;
         end if;
         Exponent := Encoded_Exponent - Bias;
         if Exponent < 0 then
            return 0;
         elsif Exponent >=
           (if Signed then Destination_Bits - 1 else Destination_Bits)
         then
            if Signed then
               return (if Negative then Minimum_Bits else Maximum_Bits);
            else
               return Destination_Mask;
            end if;
         end if;
         Significant := Interfaces.Shift_Left (1, Fraction_Bits) or Fraction;
         if Exponent >= Fraction_Bits then
            Magnitude := Interfaces.Shift_Left
              (Significant, Exponent - Fraction_Bits);
         else
            Magnitude := Interfaces.Shift_Right
              (Significant, Fraction_Bits - Exponent);
         end if;
         if Signed and then Negative then
            return (0 - Magnitude) and Destination_Mask;
         else
            return Magnitude and Destination_Mask;
         end if;
      end Oracle_Float_To_Integer_Bits;

      function Oracle_Convert_F32_To_I32 (Item : F32) return I32 is
        (Oracle_Bits_To_I32 (U32 (Oracle_Float_To_Integer_Bits
           (U64 (F32_To_Bits_Oracle (Item)), 16#8000_0000#,
            16#007F_FFFF#, 255, 23, 127, 32, True))));
      function Oracle_Convert_F32_To_U32 (Item : F32) return U32 is
        (U32 (Oracle_Float_To_Integer_Bits
           (U64 (F32_To_Bits_Oracle (Item)), 16#8000_0000#,
            16#007F_FFFF#, 255, 23, 127, 32, False)));
      function Oracle_Convert_F64_To_I64 (Item : F64) return I64 is
        (Oracle_Bits_To_I64 (Oracle_Float_To_Integer_Bits
           (F64_To_Bits_Oracle (Item), 16#8000_0000_0000_0000#,
            16#000F_FFFF_FFFF_FFFF#, 2_047, 52, 1_023, 64, True)));
      function Oracle_Convert_F64_To_U64 (Item : F64) return U64 is
        (Oracle_Float_To_Integer_Bits
           (F64_To_Bits_Oracle (Item), 16#8000_0000_0000_0000#,
            16#000F_FFFF_FFFF_FFFF#, 2_047, 52, 1_023, 64, False));

      function Random_Raw_F32_Lanes return Wide.Lane_Values_F32x8 is
        ([for Lane in Wide.Lane_Index_32x8 =>
           Bits_To_F32_Oracle (U32 (Next_U64 mod 2 ** 32))]);
      function Random_Raw_F64_Lanes return Wide.Lane_Values_F64x4 is
        ([for Lane in Wide.Lane_Index_64x4 =>
           Bits_To_F64_Oracle (Next_U64)]);
'''


def conversion_tests() -> str:
    blocks: list[str] = []

    signed_bits = {
        "I8": ("I8_To_Bits", "Oracle_Bits_To_I8"),
        "I16": ("I16_To_Bits", "Oracle_Bits_To_I16"),
        "I32": ("I32_To_Bits", "Oracle_Bits_To_I32"),
        "I64": ("I64_To_Bits", "Oracle_Bits_To_I64"),
    }

    def widen_lane(source: Family, target: Family, value: str) -> str:
        if source.floating:
            return f"Oracle_Widen_F32 ({value})"
        return f"{target.scalar} ({value})"

    def truncate_lane(source: Family, target: Family, value: str) -> str:
        if source.signed:
            to_bits, from_bits = signed_bits[source.scalar][0], signed_bits[target.scalar][1]
            return (
                f"{from_bits} ({target.scalar.replace('I', 'U', 1)} "
                f"({to_bits} ({value}) and {source.scalar.replace('I', 'U', 1)} "
                f"({target.scalar.replace('I', 'U', 1)}'Last)))"
            )
        return f"{target.scalar} ({value} and {source.scalar} ({target.scalar}'Last))"

    def saturate_lane(source: Family, target: Family, value: str) -> str:
        if target.scalar.startswith("U") and source.signed:
            return (
                f"(if {value} < 0 then 0 elsif {value} > {source.scalar} "
                f"({target.scalar}'Last) then {target.scalar}'Last else {target.scalar} ({value}))"
            )
        if target.signed:
            return (
                f"(if {value} < {source.scalar} ({target.scalar}'First) then {target.scalar}'First "
                f"elsif {value} > {source.scalar} ({target.scalar}'Last) then {target.scalar}'Last "
                f"else {target.scalar} ({value}))"
            )
        return (
            f"(if {value} > {source.scalar} ({target.scalar}'Last) "
            f"then {target.scalar}'Last else {target.scalar} ({value}))"
        )

    def convert_saturate_lane(source: Family, target: Family, value: str) -> str:
        if source.signed:
            return f"(if {value} < 0 then 0 else {target.scalar} ({value}))"
        return (
            f"(if {value} > {source.scalar} ({target.scalar}'Last) "
            f"then {target.scalar}'Last else {target.scalar} ({value}))"
        )

    for source_half, _, target_half, *_ in (*WIDENINGS, *FLOAT_WIDENINGS):
        source = BY_HALF[source_half]
        target = BY_HALF[target_half]
        values = lane_values(source.scalar, source.lanes)
        random_source = (
            f"Random_Raw_{source.scalar}_Lanes"
            if source.floating else f"Random_{source.values}"
        )
        for operation, offset in (("Widen_Low", 0), ("Widen_High", source.half_lanes)):
            expected = (
                f"[for Lane in Wide.{target.index} => "
                f"{widen_lane(source, target, f'Source_Lanes (Lane + {offset})')}]"
            )
            matches = (
                f"(for all Lane in Wide.{target.index} => "
                f"Same_F64_Conversion (Wide.Extract (Scalar_Result, Lane), Expected (Lane)) "
                f"and then Same_F64_Conversion (Native.Extract (Native_Result, Lane), Expected (Lane)))"
                if source.floating else
                "Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected"
            )
            blocks.append(f'''      declare
         Source_Lanes : constant Wide.{source.values} := [{values}];
         Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
         Expected : constant Wide.{target.values} := {expected};
         Scalar_Result : constant Wide.{target.vector} := Wide.{operation} (Value);
         Native_Result : constant Wide.{target.vector} := Native.{operation} (Value);
      begin
         Check ({matches},
           "wide {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 128 loop
         declare
            Source_Lanes : constant Wide.{source.values} := {random_source};
            Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
            Expected : constant Wide.{target.values} := {expected};
            Scalar_Result : constant Wide.{target.vector} := Wide.{operation} (Value);
            Native_Result : constant Wide.{target.vector} := Native.{operation} (Value);
         begin
            Check ({matches},
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
        random_source = (
            f"Random_Raw_{source.scalar}_Lanes"
            if source.floating else f"Random_{source.values}"
        )
        lane_oracle = (
            (lambda value: truncate_lane(source, target, value))
            if operation == "Narrow_Truncate"
            else ((lambda value: f"Oracle_Narrow_Round ({value})")
                  if operation == "Narrow_Round"
                  else (lambda value: saturate_lane(source, target, value)))
        )
        expected = (
            f"[for Lane in Wide.{target.index} => "
            f"{lane_oracle(f'(if Lane < {source.lanes} then Low_Lanes (Lane) else High_Lanes (Lane - {source.lanes}))')}]"
        )
        matches = (
            f"(for all Lane in Wide.{target.index} => "
            f"Same_F32_Conversion (Wide.Extract (Scalar_Result, Lane), Expected (Lane)) "
            f"and then Same_F32_Conversion (Native.Extract (Native_Result, Lane), Expected (Lane)))"
            if operation == "Narrow_Round" else
            "Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected"
        )
        blocks.append(f'''      declare
         Low_Lanes : constant Wide.{source.values} := [{low_values}];
         High_Lanes : constant Wide.{source.values} := [{high_values}];
         Low_Value : constant Wide.{source.vector} := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.{source.vector} := Wide.From_Lanes (High_Lanes);
         Expected : constant Wide.{target.values} := {expected};
         Scalar_Result : constant Wide.{target.vector} := Wide.{operation} (Low_Value, High_Value);
         Native_Result : constant Wide.{target.vector} := Native.{operation} (Low_Value, High_Value);
      begin
         Check ({matches},
           "wide {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 128 loop
         declare
            Low_Lanes : constant Wide.{source.values} := {random_source};
            High_Lanes : constant Wide.{source.values} := {random_source};
            Low_Value : constant Wide.{source.vector} := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.{source.vector} := Wide.From_Lanes (High_Lanes);
            Expected : constant Wide.{target.values} := {expected};
            Scalar_Result : constant Wide.{target.vector} := Wide.{operation} (Low_Value, High_Value);
            Native_Result : constant Wide.{target.vector} := Native.{operation} (Low_Value, High_Value);
         begin
            Check ({matches},
              "wide randomized {operation} {source.vector} to {target.vector}" & Iteration'Image);
         end;
      end loop;
''')

    numeric_conversion_groups = (
        [("Convert_Round", item) for item in INTEGER_TO_FLOAT_CONVERSIONS]
        + [("Convert_Truncate_Saturate", item) for item in FLOAT_TO_INTEGER_CONVERSIONS]
    )
    oracle_names = {
        ("Convert_Round", "I32"): "Oracle_Convert_Round_I32",
        ("Convert_Round", "U32"): "Oracle_Convert_Round_U32",
        ("Convert_Round", "I64"): "Oracle_Convert_Round_I64",
        ("Convert_Round", "U64"): "Oracle_Convert_Round_U64",
        ("Convert_Truncate_Saturate", "F32", "I32"): "Oracle_Convert_F32_To_I32",
        ("Convert_Truncate_Saturate", "F32", "U32"): "Oracle_Convert_F32_To_U32",
        ("Convert_Truncate_Saturate", "F64", "I64"): "Oracle_Convert_F64_To_I64",
        ("Convert_Truncate_Saturate", "F64", "U64"): "Oracle_Convert_F64_To_U64",
    }
    for operation, (source_half, _, target_half, *_) in numeric_conversion_groups:
        source = BY_HALF[source_half]
        target = BY_HALF[target_half]
        values = lane_values(source.scalar, source.lanes)
        oracle = oracle_names.get(
            (operation, source.scalar, target.scalar),
            oracle_names.get((operation, source.scalar)),
        )
        random_lanes = (
            f"Random_Raw_{source.scalar}_Lanes"
            if source.floating
            else f"Random_{source.values}"
        )
        expected = (
            f"[for Lane in Wide.{source.index} => {oracle} (Source_Lanes (Lane))]"
        )
        if target.floating:
            scalar_matches = (
                f"(for all Lane in Wide.{target.index} => "
                f"{target.scalar}_To_Bits_Oracle (Wide.Extract (Scalar_Result, Lane)) = "
                f"{target.scalar}_To_Bits_Oracle (Expected (Lane)))"
            )
            native_matches = (
                f"(for all Lane in Wide.{target.index} => "
                f"{target.scalar}_To_Bits_Oracle (Native.Extract (Native_Result, Lane)) = "
                f"{target.scalar}_To_Bits_Oracle (Expected (Lane)))"
            )
        else:
            scalar_matches = "Wide.To_Lanes (Scalar_Result) = Expected"
            native_matches = "Native.To_Lanes (Native_Result) = Expected"
        blocks.append(f'''      declare
         Source_Lanes : constant Wide.{source.values} := [{values}];
         Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
         Expected : constant Wide.{target.values} := {expected};
         Scalar_Result : constant Wide.{target.vector} := Wide.{operation} (Value);
         Native_Result : constant Wide.{target.vector} := Native.{operation} (Value);
      begin
         Check ({scalar_matches} and then {native_matches},
           "wide independent {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 128 loop
         declare
            Source_Lanes : constant Wide.{source.values} := {random_lanes};
            Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
            Expected : constant Wide.{target.values} := {expected};
            Scalar_Result : constant Wide.{target.vector} := Wide.{operation} (Value);
            Native_Result : constant Wide.{target.vector} := Native.{operation} (Value);
         begin
            Check ({scalar_matches} and then {native_matches},
              "wide independent randomized {operation} {source.vector} to {target.vector}" & Iteration'Image);
         end;
      end loop;
''')

    for operation, (source_half, _, target_half, *_) in [
        ("Convert_Saturate", item) for item in SIGNED_UNSIGNED_CONVERSIONS
    ]:
        source = BY_HALF[source_half]
        target = BY_HALF[target_half]
        values = lane_values(source.scalar, source.lanes)
        expected = (
            f"[for Lane in Wide.{target.index} => "
            f"{convert_saturate_lane(source, target, 'Source_Lanes (Lane)')}]"
        )
        blocks.append(f'''      declare
         Source_Lanes : constant Wide.{source.values} := [{values}];
         Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
         Expected : constant Wide.{target.values} := {expected};
      begin
         Check (Wide.To_Lanes (Wide.{operation} (Value)) = Expected
           and then Native.To_Lanes (Native.{operation} (Value)) = Expected,
           "wide {operation} {source.vector} to {target.vector}");
      end;
      for Iteration in 1 .. 128 loop
         declare
            Source_Lanes : constant Wide.{source.values} := Random_{source.values};
            Value : constant Wide.{source.vector} := Wide.From_Lanes (Source_Lanes);
            Expected : constant Wide.{target.values} := {expected};
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
         Native_F32_Bounds_To_I32 : constant Wide.I32x8 :=
           Native.Convert_Truncate_Saturate (F32_Integer_Bounds);
         F32_Bounds_To_U32 : constant Wide.U32x8 :=
           Wide.Convert_Truncate_Saturate (F32_Integer_Bounds);
         Native_F32_Bounds_To_U32 : constant Wide.U32x8 :=
           Native.Convert_Truncate_Saturate (F32_Integer_Bounds);
         F64_Bounds_To_I64 : constant Wide.I64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Integer_Bounds);
         Native_F64_Bounds_To_I64 : constant Wide.I64x4 :=
           Native.Convert_Truncate_Saturate (F64_Integer_Bounds);
         F64_Bounds_To_U64 : constant Wide.U64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Unsigned_Bounds);
         Native_F64_Bounds_To_U64 : constant Wide.U64x4 :=
           Native.Convert_Truncate_Saturate (F64_Unsigned_Bounds);
         F64_Edges_To_I64 : constant Wide.I64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Edges);
         Native_F64_Edges_To_I64 : constant Wide.I64x4 :=
           Native.Convert_Truncate_Saturate (F64_Edges);
         F64_Edges_To_U64 : constant Wide.U64x4 :=
           Wide.Convert_Truncate_Saturate (F64_Edges);
         Native_F64_Edges_To_U64 : constant Wide.U64x4 :=
           Native.Convert_Truncate_Saturate (F64_Edges);
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
         Check (Native.To_Lanes (Native_F32_Bounds_To_I32) =
           [2_147_483_520, I32'Last, -2_147_483_520, I32'First,
            I32'Last, I32'Last, 1, -1],
           "wide Native F32 to I32 boundary results");
         Check (Wide.To_Lanes (F32_Bounds_To_U32) =
           [2_147_483_520, 2_147_483_648, 0, 0,
            4_294_967_040, U32'Last, 1, 0],
           "wide F32 to U32 boundary results");
         Check (Native.To_Lanes (Native_F32_Bounds_To_U32) =
           [2_147_483_520, 2_147_483_648, 0, 0,
            4_294_967_040, U32'Last, 1, 0],
           "wide Native F32 to U32 boundary results");
         Check (Wide.To_Lanes (F64_Bounds_To_I64) =
           [9_223_372_036_854_774_784, I64'Last,
            -9_223_372_036_854_774_784, I64'First],
           "wide F64 to I64 boundary results");
         Check (Native.To_Lanes (Native_F64_Bounds_To_I64) =
           [9_223_372_036_854_774_784, I64'Last,
            -9_223_372_036_854_774_784, I64'First],
           "wide Native F64 to I64 boundary results");
         Check (Wide.To_Lanes (F64_Bounds_To_U64) =
           [18_446_744_073_709_549_568, U64'Last, 0, 1],
           "wide F64 to U64 boundary results");
         Check (Native.To_Lanes (Native_F64_Bounds_To_U64) =
           [18_446_744_073_709_549_568, U64'Last, 0, 1],
           "wide Native F64 to U64 boundary results");
         Check (Wide.To_Lanes (F64_Edges_To_I64) = [0, 0, I64'Last, I64'First]
           and then Wide.To_Lanes (F64_Edges_To_U64) = [0, 0, U64'Last, 0],
           "wide F64 infinity and signed-zero integer results");
         Check (Native.To_Lanes (Native_F64_Edges_To_I64) =
             [0, 0, I64'Last, I64'First]
           and then Native.To_Lanes (Native_F64_Edges_To_U64) =
             [0, 0, U64'Last, 0],
           "wide Native F64 infinity and signed-zero integer results");
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
        + numeric_conversion_oracle_declarations()
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
    reduction_add_type = unsigned if f.signed else f.scalar
    reduction_add_value = (
        "Value_To_Bits (Values (Lane))" if f.signed else "Values (Lane)"
    )
    reduction_add_result = "Bits_To_Value (Result)" if f.signed else "Result"
    reduction_edges = []
    for lane in range(f.lanes):
        if lane in (0, f.half_lanes):
            reduction_edges.append(f"{f.scalar}'First")
        elif lane in (f.half_lanes - 1, f.lanes - 1):
            reduction_edges.append(f"{f.scalar}'Last")
        elif f.signed and lane % 2 == 0:
            reduction_edges.append("-1")
        else:
            reduction_edges.append("1")
    reduction_edge_values = ", ".join(reduction_edges)
    reduction_declarations = f'''
      function Reference_Reduce_Add_Wrap
        (Values : Wide.{f.values}) return {f.scalar}
      is
         Result : {reduction_add_type} := 0;
      begin
         for Lane in Wide.{f.index} loop
            Result := Result + {reduction_add_value};
         end loop;
         return {reduction_add_result};
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.{f.values}) return {f.scalar}
      is
         Result : {f.scalar} := Values (Values'First);
      begin
         for Lane in Wide.{f.index} loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.{f.values}) return {f.scalar}
      is
         Result : {f.scalar} := Values (Values'First);
      begin
         for Lane in Wide.{f.index} loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;
'''
    wrapping_declarations = f'''
      function Reference_Add_Wrap
        (Left, Right : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (Value_To_Bits (Left) + Value_To_Bits (Right))' if f.signed else 'Left + Right'});

      function Reference_Subtract_Wrap
        (Left, Right : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (Value_To_Bits (Left) - Value_To_Bits (Right))' if f.signed else 'Left - Right'});

      function Reference_Multiply_Wrap
        (Left, Right : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (Value_To_Bits (Left) * Value_To_Bits (Right))' if f.signed else 'Left * Right'});
'''
    bitwise_declarations = f'''
      function Reference_Bitwise_And
        (Left, Right : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (Value_To_Bits (Left) and Value_To_Bits (Right))' if f.signed else 'Left and Right'});

      function Reference_Bitwise_Or
        (Left, Right : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (Value_To_Bits (Left) or Value_To_Bits (Right))' if f.signed else 'Left or Right'});

      function Reference_Bitwise_Xor
        (Left, Right : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (Value_To_Bits (Left) xor Value_To_Bits (Right))' if f.signed else 'Left xor Right'});

      function Reference_Bitwise_Not (Value : {f.scalar}) return {f.scalar} is
        ({'Bits_To_Value (not Value_To_Bits (Value))' if f.signed else 'not Value'});
'''
    shift_value_bits = "Value_To_Bits (Value)" if f.signed else "Value"
    shift_from_bits = "Bits_To_Value (Result)" if f.signed else "Result"
    arithmetic_declaration = f'''

      function Reference_Shift_Right_Arithmetic
        (Value : {f.scalar}; Count : Natural) return {f.scalar}
      is
         Raw : constant {unsigned} := Value_To_Bits (Value);
         Result : {unsigned};
      begin
         if Count >= {f.bits} then
            Result := (if Value < 0 then {unsigned}'Last else 0);
         elsif Count = 0 then
            Result := Raw;
         elsif Value < 0 then
            Result := Interfaces.Shift_Right (Raw, Count)
              or Interfaces.Shift_Left ({unsigned}'Last, {f.bits} - Count);
         else
            Result := Interfaces.Shift_Right (Raw, Count);
         end if;
         return Bits_To_Value (Result);
      end Reference_Shift_Right_Arithmetic;
''' if f.signed else ""
    arithmetic_check = f'''
         Arithmetic_Expected : constant Wide.{f.values} :=
           [for Lane in Wide.{f.index} =>
              Reference_Shift_Right_Arithmetic (Lanes (Lane), Count)];
''' if f.signed else ""
    arithmetic_assertion = f'''
           and then Wide.To_Lanes
             (Wide.Shift_Right_Arithmetic (Value, Count)) = Arithmetic_Expected
           and then Native.To_Lanes
             (Native.Shift_Right_Arithmetic (Value, Count)) = Arithmetic_Expected
''' if f.signed else ""
    shift_declarations = f'''
      function Reference_Shift_Left_Logical
        (Value : {f.scalar}; Count : Natural) return {f.scalar}
      is
         Result : constant {unsigned} :=
           (if Count >= {f.bits} then 0
            else Interfaces.Shift_Left ({shift_value_bits}, Count));
      begin
         return {shift_from_bits};
      end Reference_Shift_Left_Logical;

      function Reference_Shift_Right_Logical
        (Value : {f.scalar}; Count : Natural) return {f.scalar}
      is
         Result : constant {unsigned} :=
           (if Count >= {f.bits} then 0
            else Interfaces.Shift_Right ({shift_value_bits}, Count));
      begin
         return {shift_from_bits};
      end Reference_Shift_Right_Logical;
{arithmetic_declaration}
      procedure Check_Shifts
        (Value : Wide.{f.vector}; Lanes : Wide.{f.values};
         Count : Natural; Label_Text : String)
      is
         Left_Expected : constant Wide.{f.values} :=
           [for Lane in Wide.{f.index} =>
              Reference_Shift_Left_Logical (Lanes (Lane), Count)];
         Right_Expected : constant Wide.{f.values} :=
           [for Lane in Wide.{f.index} =>
              Reference_Shift_Right_Logical (Lanes (Lane), Count)];
{arithmetic_check}      begin
         Check
           (Wide.To_Lanes (Wide.Shift_Left_Logical (Value, Count)) = Left_Expected
           and then Native.To_Lanes
             (Native.Shift_Left_Logical (Value, Count)) = Left_Expected
           and then Wide.To_Lanes
             (Wide.Shift_Right_Logical (Value, Count)) = Right_Expected
           and then Native.To_Lanes
             (Native.Shift_Right_Logical (Value, Count)) = Right_Expected
{arithmetic_assertion}           , Label_Text & Count'Image);
      end Check_Shifts;
'''
    wrapping_left_bits = (
        (1 << (f.bits - 1)) - 1,
        1 << (f.bits - 1),
        (1 << f.bits) - 1,
        int("AA" * (f.bits // 8), 16),
    )
    wrapping_right_bits = (
        1,
        (1 << f.bits) - 1,
        int("00000001FFFFFFFF", 16) & ((1 << f.bits) - 1),
        int("55" * (f.bits // 8), 16),
    )
    def wrapping_value(bits: int) -> str:
        encoded = f"{unsigned} ({bits})"
        return f"Bits_To_Value ({encoded})" if f.signed else encoded

    wrapping_left = [
        wrapping_value(wrapping_left_bits[lane % len(wrapping_left_bits)])
        for lane in range(f.lanes)
    ]
    wrapping_right = [
        wrapping_value(wrapping_right_bits[lane % len(wrapping_right_bits)])
        for lane in range(f.lanes)
    ]
    wrapping_boundary_checks = f'''
      declare
         Left_Lanes : constant Wide.{f.values} := [{", ".join(wrapping_left)}];
         Right_Lanes : constant Wide.{f.values} := [{", ".join(wrapping_right)}];
         Left_Value : constant Wide.{f.vector} := Wide.From_Lanes (Left_Lanes);
         Right_Value : constant Wide.{f.vector} := Wide.From_Lanes (Right_Lanes);
         Root_Add : constant Wide.{f.vector} := Wide.Add_Wrap (Left_Value, Right_Value);
         Native_Add : constant Wide.{f.vector} := Native.Add_Wrap (Left_Value, Right_Value);
         Root_Subtract : constant Wide.{f.vector} := Wide.Subtract_Wrap (Left_Value, Right_Value);
         Native_Subtract : constant Wide.{f.vector} := Native.Subtract_Wrap (Left_Value, Right_Value);
         Root_Multiply : constant Wide.{f.vector} := Wide.Multiply_Wrap (Left_Value, Right_Value);
         Native_Multiply : constant Wide.{f.vector} := Native.Multiply_Wrap (Left_Value, Right_Value);
      begin
         for Lane in Wide.{f.index} loop
            Check (Wide.Extract (Root_Add, Lane) =
              Reference_Add_Wrap (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native_Add, Lane) =
                Reference_Add_Wrap (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Wide.Extract (Root_Subtract, Lane) =
                Reference_Subtract_Wrap (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native_Subtract, Lane) =
                Reference_Subtract_Wrap (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Wide.Extract (Root_Multiply, Lane) =
                Reference_Multiply_Wrap (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native_Multiply, Lane) =
                Reference_Multiply_Wrap (Left_Lanes (Lane), Right_Lanes (Lane)),
              "{f.vector} directed independent wrapping boundaries" & Lane'Image);
         end loop;
      end;
'''
    wrapping_randomized = f'''
            declare
               Root_Add : constant Wide.{f.vector} := Wide.Add_Wrap (R_A, R_B);
               Native_Add : constant Wide.{f.vector} := Native.Add_Wrap (R_A, R_B);
               Root_Subtract : constant Wide.{f.vector} := Wide.Subtract_Wrap (R_A, R_B);
               Native_Subtract : constant Wide.{f.vector} := Native.Subtract_Wrap (R_A, R_B);
               Root_Multiply : constant Wide.{f.vector} := Wide.Multiply_Wrap (R_A, R_B);
               Native_Multiply : constant Wide.{f.vector} := Native.Multiply_Wrap (R_A, R_B);
            begin
               for Lane in Wide.{f.index} loop
                  Check (Wide.Extract (Root_Add, Lane) =
                    Reference_Add_Wrap (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Native.Extract (Native_Add, Lane) =
                      Reference_Add_Wrap (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Wide.Extract (Root_Subtract, Lane) =
                      Reference_Subtract_Wrap (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Native.Extract (Native_Subtract, Lane) =
                      Reference_Subtract_Wrap (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Wide.Extract (Root_Multiply, Lane) =
                      Reference_Multiply_Wrap (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Native.Extract (Native_Multiply, Lane) =
                      Reference_Multiply_Wrap (R_A_Lanes (Lane), R_B_Lanes (Lane)),
                    "{f.vector} randomized independent wrapping oracle" &
                      Iteration'Image & Lane'Image);
               end loop;
            end;
'''
    bitwise_left_bits = (
        0,
        (1 << f.bits) - 1,
        int("AA" * (f.bits // 8), 16),
        1 << (f.bits - 1),
    )
    bitwise_right_bits = (
        (1 << f.bits) - 1,
        0,
        int("55" * (f.bits // 8), 16),
        (1 << (f.bits - 1)) - 1,
    )
    bitwise_left = [
        wrapping_value(bitwise_left_bits[lane % len(bitwise_left_bits)])
        for lane in range(f.lanes)
    ]
    bitwise_right = [
        wrapping_value(bitwise_right_bits[lane % len(bitwise_right_bits)])
        for lane in range(f.lanes)
    ]
    bitwise_boundary_checks = f'''
      declare
         Left_Lanes : constant Wide.{f.values} := [{", ".join(bitwise_left)}];
         Right_Lanes : constant Wide.{f.values} := [{", ".join(bitwise_right)}];
         Left_Value : constant Wide.{f.vector} := Wide.From_Lanes (Left_Lanes);
         Right_Value : constant Wide.{f.vector} := Wide.From_Lanes (Right_Lanes);
      begin
         for Lane in Wide.{f.index} loop
            Check (Wide.Extract (Wide.Bitwise_And (Left_Value, Right_Value), Lane) =
              Reference_Bitwise_And (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native.Bitwise_And (Left_Value, Right_Value), Lane) =
                Reference_Bitwise_And (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Wide.Extract (Wide.Bitwise_Or (Left_Value, Right_Value), Lane) =
                Reference_Bitwise_Or (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native.Bitwise_Or (Left_Value, Right_Value), Lane) =
                Reference_Bitwise_Or (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Wide.Extract (Wide.Bitwise_Xor (Left_Value, Right_Value), Lane) =
                Reference_Bitwise_Xor (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native.Bitwise_Xor (Left_Value, Right_Value), Lane) =
                Reference_Bitwise_Xor (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Wide.Extract (Wide.Bitwise_Not (Left_Value), Lane) =
                Reference_Bitwise_Not (Left_Lanes (Lane))
              and then Native.Extract (Native.Bitwise_Not (Left_Value), Lane) =
                Reference_Bitwise_Not (Left_Lanes (Lane)),
              "{f.vector} directed independent bitwise patterns" & Lane'Image);
         end loop;
      end;
'''
    shift_boundary_checks = f'''
      declare
         Shift_Lanes : constant Wide.{f.values} := [{", ".join(bitwise_left)}];
         Shift_Value : constant Wide.{f.vector} := Wide.From_Lanes (Shift_Lanes);
         Shift_Lanes_2 : constant Wide.{f.values} := [{", ".join(bitwise_right)}];
         Shift_Value_2 : constant Wide.{f.vector} := Wide.From_Lanes (Shift_Lanes_2);
      begin
         for Count in Natural range 0 .. {f.bits + 2} loop
            Check_Shifts
              (Shift_Value, Shift_Lanes, Count,
               "{f.vector} directed independent shifts A");
            Check_Shifts
              (Shift_Value_2, Shift_Lanes_2, Count,
               "{f.vector} directed independent shifts B");
         end loop;
         Check_Shifts
           (Shift_Value, Shift_Lanes, Natural'Last,
            "{f.vector} Natural'Last independent shifts A");
         Check_Shifts
           (Shift_Value_2, Shift_Lanes_2, Natural'Last,
            "{f.vector} Natural'Last independent shifts B");
      end;
'''
    bitwise_randomized = f'''
            for Lane in Wide.{f.index} loop
               Check (Wide.Extract (Wide.Bitwise_And (R_A, R_B), Lane) =
                 Reference_Bitwise_And (R_A_Lanes (Lane), R_B_Lanes (Lane))
                 and then Native.Extract (Native.Bitwise_And (R_A, R_B), Lane) =
                   Reference_Bitwise_And (R_A_Lanes (Lane), R_B_Lanes (Lane))
                 and then Wide.Extract (Wide.Bitwise_Or (R_A, R_B), Lane) =
                   Reference_Bitwise_Or (R_A_Lanes (Lane), R_B_Lanes (Lane))
                 and then Native.Extract (Native.Bitwise_Or (R_A, R_B), Lane) =
                   Reference_Bitwise_Or (R_A_Lanes (Lane), R_B_Lanes (Lane))
                 and then Wide.Extract (Wide.Bitwise_Xor (R_A, R_B), Lane) =
                   Reference_Bitwise_Xor (R_A_Lanes (Lane), R_B_Lanes (Lane))
                 and then Native.Extract (Native.Bitwise_Xor (R_A, R_B), Lane) =
                   Reference_Bitwise_Xor (R_A_Lanes (Lane), R_B_Lanes (Lane))
                 and then Wide.Extract (Wide.Bitwise_Not (R_A), Lane) =
                   Reference_Bitwise_Not (R_A_Lanes (Lane))
                 and then Native.Extract (Native.Bitwise_Not (R_A), Lane) =
                   Reference_Bitwise_Not (R_A_Lanes (Lane)),
                 "{f.vector} randomized independent bitwise oracle" &
                   Iteration'Image & Lane'Image);
            end loop;
'''
    if f.signed:
        saturation_declarations = f'''
      function Reference_Add_Saturate
        (Left, Right : {f.scalar}) return {f.scalar} is
        (if Right > 0 and then Left > {f.scalar}'Last - Right then {f.scalar}'Last
         elsif Right < 0 and then Left < {f.scalar}'First - Right then {f.scalar}'First
         else Left + Right);

      function Reference_Subtract_Saturate
        (Left, Right : {f.scalar}) return {f.scalar} is
        (if Right > 0 and then Left < {f.scalar}'First + Right then {f.scalar}'First
         elsif Right < 0 and then Left > {f.scalar}'Last + Right then {f.scalar}'Last
         else Left - Right);
'''
        saturation_left = [
            f"{f.scalar}'Last" if lane % 2 == 0 else f"{f.scalar}'First"
            for lane in range(f.lanes)
        ]
        saturation_right = [
            ("1", "-1", "-1", "1")[lane % 4]
            for lane in range(f.lanes)
        ]
    else:
        saturation_declarations = f'''
      function Reference_Add_Saturate
        (Left, Right : {f.scalar}) return {f.scalar} is
        (if Left > {f.scalar}'Last - Right then {f.scalar}'Last else Left + Right);

      function Reference_Subtract_Saturate
        (Left, Right : {f.scalar}) return {f.scalar} is
        (if Left < Right then 0 else Left - Right);
'''
        saturation_left = [
            f"{f.scalar}'Last" if lane % 2 == 0 else "0"
            for lane in range(f.lanes)
        ]
        saturation_right = [
            ("1", "1", f"{f.scalar}'Last", f"{f.scalar}'Last")[lane % 4]
            for lane in range(f.lanes)
        ]
    saturation_boundary_checks = f'''
      declare
         Left_Lanes : constant Wide.{f.values} := [{", ".join(saturation_left)}];
         Right_Lanes : constant Wide.{f.values} := [{", ".join(saturation_right)}];
         Left_Value : constant Wide.{f.vector} := Wide.From_Lanes (Left_Lanes);
         Right_Value : constant Wide.{f.vector} := Wide.From_Lanes (Right_Lanes);
         Root_Add : constant Wide.{f.vector} := Wide.Add_Saturate (Left_Value, Right_Value);
         Native_Add : constant Wide.{f.vector} := Native.Add_Saturate (Left_Value, Right_Value);
         Root_Subtract : constant Wide.{f.vector} := Wide.Subtract_Saturate (Left_Value, Right_Value);
         Native_Subtract : constant Wide.{f.vector} := Native.Subtract_Saturate (Left_Value, Right_Value);
      begin
         for Lane in Wide.{f.index} loop
            Check (Wide.Extract (Root_Add, Lane) =
              Reference_Add_Saturate (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native_Add, Lane) =
                Reference_Add_Saturate (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Wide.Extract (Root_Subtract, Lane) =
                Reference_Subtract_Saturate (Left_Lanes (Lane), Right_Lanes (Lane))
              and then Native.Extract (Native_Subtract, Lane) =
                Reference_Subtract_Saturate (Left_Lanes (Lane), Right_Lanes (Lane)),
              "{f.vector} directed independent saturation boundaries" & Lane'Image);
         end loop;
      end;
'''
    saturation_randomized = f'''
            declare
               Root_Add : constant Wide.{f.vector} := Wide.Add_Saturate (R_A, R_B);
               Native_Add : constant Wide.{f.vector} := Native.Add_Saturate (R_A, R_B);
               Root_Subtract : constant Wide.{f.vector} := Wide.Subtract_Saturate (R_A, R_B);
               Native_Subtract : constant Wide.{f.vector} := Native.Subtract_Saturate (R_A, R_B);
            begin
               for Lane in Wide.{f.index} loop
                  Check (Wide.Extract (Root_Add, Lane) =
                    Reference_Add_Saturate (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Native.Extract (Native_Add, Lane) =
                      Reference_Add_Saturate (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Wide.Extract (Root_Subtract, Lane) =
                      Reference_Subtract_Saturate (R_A_Lanes (Lane), R_B_Lanes (Lane))
                    and then Native.Extract (Native_Subtract, Lane) =
                      Reference_Subtract_Saturate (R_A_Lanes (Lane), R_B_Lanes (Lane)),
                    "{f.vector} randomized independent saturation oracle" &
                      Iteration'Image & Lane'Image);
               end loop;
            end;
'''
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
      function Reference_Horizontal_Sum
        (Values : Wide.Lane_Values_U8x32) return Natural
      is
         Result : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result := Result + Natural (Values (Lane));
         end loop;
         return Result;
      end Reference_Horizontal_Sum;
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
      Check (Wide.Horizontal_Sum (Wide.Splat (255)) = 8_160
        and then Native.Horizontal_Sum (Native.Splat (255)) = 8_160
        and then Wide.Horizontal_Sum (A) = Reference_Horizontal_Sum (A_Lanes)
        and then Native.Horizontal_Sum (A) = Reference_Horizontal_Sum (A_Lanes),
        "U8x32 exact horizontal sum");
'''
        lookup_randomized = '''
            Check (Wide.To_Lanes (Wide.Table_Lookup (R_A, R_B)) =
              Reference_Table_Lookup (Wide.To_Lanes (R_A), Wide.To_Lanes (R_B))
              and then Native.To_Lanes (Native.Table_Lookup (R_A, R_B)) =
                Reference_Table_Lookup (Wide.To_Lanes (R_A), Wide.To_Lanes (R_B)),
              "U8x32 randomized 32-entry table lookup" & Iteration'Image);
            Check (Wide.Horizontal_Sum (R_A) =
              Reference_Horizontal_Sum (Wide.To_Lanes (R_A))
              and then Native.Horizontal_Sum (R_A) =
                Reference_Horizontal_Sum (Wide.To_Lanes (R_A)),
              "U8x32 randomized exact horizontal sum" & Iteration'Image);
'''
    byte_oracle_checks = ""
    byte_boundary_checks = ""
    all_predicate_declarations = predicate_declarations(f)
    byte_predicate_checks = ""
    byte_predicate_randomized = ""
    if f.bits == 8:
        if f.signed:
            wrap = lambda operator: (
                f"Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) {operator} "
                "Value_To_Bits (R_B_Lanes (Lane)))"
            )
            saturate = lambda operator: (
                f"I8 (Integer'Max (Integer (I8'First), Integer'Min "
                f"(Integer (I8'Last), Integer (R_A_Lanes (Lane)) {operator} "
                "Integer (R_B_Lanes (Lane)))))"
            )
            bit = lambda operator: (
                f"Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) {operator} "
                "Value_To_Bits (R_B_Lanes (Lane)))"
            )
            complement = "Bits_To_Value (not Value_To_Bits (R_A_Lanes (Lane)))"
        else:
            wrap = lambda operator: f"R_A_Lanes (Lane) {operator} R_B_Lanes (Lane)"
            saturate = lambda operator: (
                f"U8 (Natural'Min (Natural (U8'Last), Natural (R_A_Lanes (Lane)) {operator} "
                "Natural (R_B_Lanes (Lane))))"
                if operator == "+" else
                "(if R_A_Lanes (Lane) < R_B_Lanes (Lane) then 0 "
                "else R_A_Lanes (Lane) - R_B_Lanes (Lane))"
            )
            bit = lambda operator: f"R_A_Lanes (Lane) {operator} R_B_Lanes (Lane)"
            complement = "not R_A_Lanes (Lane)"
        pair_value = (
            f"Bits_To_Value (U8 (Pair / 256))"
            if f.signed else "U8 (Pair / 256)"
        )
        right_value = (
            f"Bits_To_Value (U8 (Pair mod 256))"
            if f.signed else "U8 (Pair mod 256)"
        )
        byte_predicate_checks = f'''
      --  Cover all 65,536 ordered byte pairs. Each batch places 32
      --  consecutive pairs in distinct lanes and checks every relation
      --  against this independent lane oracle.
      for Batch in Natural range 0 .. 2_047 loop
         declare
            Left_Lanes : constant Wide.{f.values} :=
              [for Lane in Wide.{f.index} =>
                 (declare
                    Pair : constant Natural := Batch * 32 + Lane;
                  begin {pair_value})];
            Right_Lanes : constant Wide.{f.values} :=
              [for Lane in Wide.{f.index} =>
                 (declare
                    Pair : constant Natural := Batch * 32 + Lane;
                  begin {right_value})];
            Left_Value : constant Wide.{f.vector} := Wide.From_Lanes (Left_Lanes);
            Right_Value : constant Wide.{f.vector} := Wide.From_Lanes (Right_Lanes);
            Equal_Bits : constant Wide.{f.mask_bits} :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Equal);
            Less_Bits : constant Wide.{f.mask_bits} :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Less);
            Less_Equal_Bits : constant Wide.{f.mask_bits} :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Less_Equal);
            Greater_Bits : constant Wide.{f.mask_bits} :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Greater);
            Greater_Equal_Bits : constant Wide.{f.mask_bits} :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Greater_Equal);
         begin
            Check (Wide.To_Bit_Mask (Wide.Equal (Left_Value, Right_Value)) = Equal_Bits
              and then Native.To_Bit_Mask (Native.Equal (Left_Value, Right_Value)) = Equal_Bits,
              "{f.vector} exhaustive equality" & Batch'Image);
            Check (Wide.To_Bit_Mask (Wide.Less_Than (Left_Value, Right_Value)) = Less_Bits
              and then Native.To_Bit_Mask (Native.Less_Than (Left_Value, Right_Value)) = Less_Bits
              and then Wide.To_Bit_Mask (Wide.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits
              and then Native.To_Bit_Mask (Native.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits,
              "{f.vector} exhaustive less comparisons" & Batch'Image);
            Check (Wide.To_Bit_Mask (Wide.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
              and then Native.To_Bit_Mask (Native.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
              and then Wide.To_Bit_Mask (Wide.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits
              and then Native.To_Bit_Mask (Native.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits,
              "{f.vector} exhaustive greater comparisons" & Batch'Image);
         end;
      end loop;
      for Lane in Wide.{f.index} loop
         declare
            Bits : constant Wide.{f.mask_bits} := Interfaces.Shift_Left
              (Wide.{f.mask_bits} (1), Lane);
            Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask (Bits);
            Expected : constant Wide.{f.values} :=
              Reference_Select (Bits, A_Lanes, B_Lanes);
         begin
            Check (Wide.To_Lanes (Wide.Select_Value (Mask, A, B)) = Expected
              and then Native.To_Lanes (Native.Select_Value (Mask, A, B)) = Expected,
              "{f.vector} individual selection mask" & Lane'Image);
         end;
      end loop;
      declare
         Selection_Patterns : constant array (Natural range 0 .. 5) of
           Wide.{f.mask_bits} :=
             [0, Wide.{f.mask_bits}'Last, 16#0000_FFFF#, 16#FFFF_0000#,
              16#AAAA_AAAA#, 16#5555_5555#];
      begin
         for Pattern of Selection_Patterns loop
            declare
               Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask (Pattern);
               Expected : constant Wide.{f.values} :=
                 Reference_Select (Pattern, A_Lanes, B_Lanes);
            begin
               Check (Wide.To_Lanes (Wide.Select_Value (Mask, A, B)) = Expected
                 and then Native.To_Lanes (Native.Select_Value (Mask, A, B)) = Expected,
                 "{f.vector} fixed selection mask" & Pattern'Image);
            end;
         end loop;
      end;
'''
        byte_predicate_randomized = f'''
            declare
               R_A_Lanes : constant Wide.{f.values} := Wide.To_Lanes (R_A);
               R_B_Lanes : constant Wide.{f.values} := Wide.To_Lanes (R_B);
               R_Bits : constant Wide.{f.mask_bits} := Wide.To_Bit_Mask (R_Mask);
               Select_Expected : constant Wide.{f.values} :=
                 Reference_Select (R_Bits, R_A_Lanes, R_B_Lanes);
            begin
               Check (Wide.To_Bit_Mask (Wide.Equal (R_A, R_B)) =
                 Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Equal)
                 and then Native.To_Bit_Mask (Native.Equal (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Equal)
                 and then Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Less)
                 and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Less),
                 "{f.vector} independent randomized strict predicates" & Iteration'Image);
               Check (Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B)) =
                 Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Less_Equal)
                 and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Less_Equal)
                 and then Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Greater)
                 and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Greater)
                 and then Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Greater_Equal)
                 and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) =
                   Reference_Comparison (R_A_Lanes, R_B_Lanes, Is_Greater_Equal),
                 "{f.vector} independent randomized inclusive predicates" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B)) = Select_Expected
                 and then Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Select_Expected,
                 "{f.vector} independent randomized selection" & Iteration'Image);
            end;
'''
        byte_oracle_checks = f'''
            declare
               R_A_Lanes : constant Wide.{f.values} := Wide.To_Lanes (R_A);
               R_B_Lanes : constant Wide.{f.values} := Wide.To_Lanes (R_B);
               Add_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {wrap('+')}];
               Subtract_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {wrap('-')}];
               Multiply_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {wrap('*')}];
               Add_Saturate_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {saturate('+')}];
               Subtract_Saturate_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {saturate('-')}];
               And_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {bit('and')}];
               Or_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {bit('or')}];
               Xor_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {bit('xor')}];
               Not_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} => {complement}];
               Min_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} =>
                    (if R_A_Lanes (Lane) < R_B_Lanes (Lane)
                     then R_A_Lanes (Lane) else R_B_Lanes (Lane))];
               Max_Expected : constant Wide.{f.values} :=
                 [for Lane in Wide.{f.index} =>
                    (if R_A_Lanes (Lane) > R_B_Lanes (Lane)
                     then R_A_Lanes (Lane) else R_B_Lanes (Lane))];
            begin
               Check (Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B)) = Add_Expected
                 and then Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Add_Expected
                 and then Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B)) = Subtract_Expected
                 and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Subtract_Expected
                 and then Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B)) = Multiply_Expected
                 and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Multiply_Expected,
                 "{f.vector} independent randomized wrapping arithmetic" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B)) = Add_Saturate_Expected
                 and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Add_Saturate_Expected
                 and then Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)) = Subtract_Saturate_Expected
                 and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Subtract_Saturate_Expected,
                 "{f.vector} independent randomized saturating arithmetic" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B)) = And_Expected
                 and then Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = And_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B)) = Or_Expected
                 and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Or_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B)) = Xor_Expected
                 and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Xor_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Not (R_A)) = Not_Expected
                 and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Not_Expected,
                 "{f.vector} independent randomized bitwise operations" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Min (R_A, R_B)) = Min_Expected
                 and then Native.To_Lanes (Native.Min (R_A, R_B)) = Min_Expected
                 and then Wide.To_Lanes (Wide.Max (R_A, R_B)) = Max_Expected
                 and then Native.To_Lanes (Native.Max (R_A, R_B)) = Max_Expected,
                 "{f.vector} independent randomized extrema" & Iteration'Image);
            end;
'''
        if f.signed:
            edge_a_base = (-128, 127, 127, -128, 100, -100, -1, 1)
            edge_b_base = (-1, 1, 127, -128, 100, -100, -128, 127)

            def wrap_value(value: int) -> int:
                return ((value + 128) % 256) - 128

            clamp = lambda value: max(-128, min(127, value))
        else:
            edge_a_base = (0, 255, 255, 1, 128, 127, 200, 55)
            edge_b_base = (1, 1, 255, 2, 128, 129, 100, 250)
            wrap_value = lambda value: value % 256
            clamp = lambda value: max(0, min(255, value))
        edge_a = (edge_a_base * (f.lanes // len(edge_a_base)))[:f.lanes]
        edge_b = (edge_b_base * (f.lanes // len(edge_b_base)))[:f.lanes]

        def values(items: tuple[int, ...]) -> str:
            return ", ".join(str(item) for item in items)

        byte_boundary_checks = f'''
      declare
         Edge_A : constant Wide.{f.vector} := Wide.From_Lanes ([{values(edge_a)}]);
         Edge_B : constant Wide.{f.vector} := Wide.From_Lanes ([{values(edge_b)}]);
         Add_Wrap_Expected : constant Wide.{f.values} :=
           [{values(tuple(wrap_value(a + b) for a, b in zip(edge_a, edge_b)))}];
         Subtract_Wrap_Expected : constant Wide.{f.values} :=
           [{values(tuple(wrap_value(a - b) for a, b in zip(edge_a, edge_b)))}];
         Multiply_Wrap_Expected : constant Wide.{f.values} :=
           [{values(tuple(wrap_value(a * b) for a, b in zip(edge_a, edge_b)))}];
         Add_Saturate_Expected : constant Wide.{f.values} :=
           [{values(tuple(clamp(a + b) for a, b in zip(edge_a, edge_b)))}];
         Subtract_Saturate_Expected : constant Wide.{f.values} :=
           [{values(tuple(clamp(a - b) for a, b in zip(edge_a, edge_b)))}];
         Min_Expected : constant Wide.{f.values} :=
           [{values(tuple(min(a, b) for a, b in zip(edge_a, edge_b)))}];
         Max_Expected : constant Wide.{f.values} :=
           [{values(tuple(max(a, b) for a, b in zip(edge_a, edge_b)))}];
      begin
         Check (Wide.To_Lanes (Wide.Add_Wrap (Edge_A, Edge_B)) = Add_Wrap_Expected
           and then Native.To_Lanes (Native.Add_Wrap (Edge_A, Edge_B)) = Add_Wrap_Expected
           and then Wide.To_Lanes (Wide.Subtract_Wrap (Edge_A, Edge_B)) = Subtract_Wrap_Expected
           and then Native.To_Lanes (Native.Subtract_Wrap (Edge_A, Edge_B)) = Subtract_Wrap_Expected
           and then Wide.To_Lanes (Wide.Multiply_Wrap (Edge_A, Edge_B)) = Multiply_Wrap_Expected
           and then Native.To_Lanes (Native.Multiply_Wrap (Edge_A, Edge_B)) = Multiply_Wrap_Expected,
           "{f.vector} literal wrapping boundaries");
         Check (Wide.To_Lanes (Wide.Add_Saturate (Edge_A, Edge_B)) = Add_Saturate_Expected
           and then Native.To_Lanes (Native.Add_Saturate (Edge_A, Edge_B)) = Add_Saturate_Expected
           and then Wide.To_Lanes (Wide.Subtract_Saturate (Edge_A, Edge_B)) = Subtract_Saturate_Expected
           and then Native.To_Lanes (Native.Subtract_Saturate (Edge_A, Edge_B)) = Subtract_Saturate_Expected,
           "{f.vector} literal saturation boundaries");
         Check (Wide.To_Lanes (Wide.Min (Edge_A, Edge_B)) = Min_Expected
           and then Native.To_Lanes (Native.Min (Edge_A, Edge_B)) = Min_Expected
           and then Wide.To_Lanes (Wide.Max (Edge_A, Edge_B)) = Max_Expected
           and then Native.To_Lanes (Native.Max (Edge_A, Edge_B)) = Max_Expected,
           "{f.vector} literal signedness extrema");
      end;
'''
    return f"""
   procedure Test_{f.vector} is
{('      function Bits_To_Value is new Ada.Unchecked_Conversion (' + unsigned + ', ' + f.scalar + ');') if f.signed else ''}
{('      function Value_To_Bits is new Ada.Unchecked_Conversion (' + f.scalar + ', ' + unsigned + ');') if f.signed else ''}
{all_predicate_declarations}
      function Random_Lanes return Wide.{f.values} is
         Result : Wide.{f.values};
      begin
         for Lane in Wide.{f.index} loop
            Result (Lane) := {random_value};
         end loop;
         return Result;
      end Random_Lanes;
{reduction_declarations}
{wrapping_declarations}
{bitwise_declarations}
{shift_declarations}
{saturation_declarations}
{compaction_declarations(f)}
{mask_position_declarations(f)}
{permutation_declarations(f)}
{movement_declarations(f)}
{memory_declarations(f)}
{construction_declarations(f)}
{lookup_declarations}
      A_Lanes : constant Wide.{f.values} := [{a_values}];
      B_Lanes : constant Wide.{f.values} := [{b_values}];
      Bit_Lanes : constant Wide.{f.values} := [{bit_lanes}];
      Reduction_Edge_Lanes : constant Wide.{f.values} :=
        [{reduction_edge_values}];
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
      Check_Memory (Bit_Lanes, "fixed bits");
      Check_Construction (Bit_Lanes, "fixed bits");
      Check (Wide.To_Lanes (A) = A_Lanes, "{f.vector} lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.{f.values}'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.{f.values}'[others => 0],
        "{f.vector} zero construction");
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "{f.vector} splat construction");
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
{wrapping_boundary_checks}
{bitwise_boundary_checks}
{shift_boundary_checks}
{saturation_boundary_checks}
{byte_boundary_checks}
{byte_predicate_checks}
{lookup_checks}
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, {f.bits})) = Wide.{f.values}'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, {f.bits + 7})) = Wide.{f.values}'[others => 0],
        "{f.vector} oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = {all_bits},
        "{f.vector} equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.{f.index} => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "{f.vector} selection");
      Check_Predicates
        (A_Lanes, Bit_Lanes, {f.mask_bits} ({alt}), "fixed boundaries");
{compaction_fixed_tests(f, 'A_Lanes')}
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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.{f.index} => A_Lanes ({f.lanes - 1} - Lane)],
         [for Lane in Wide.{f.index} =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod {f.lanes})
             else B_Lanes ((Lane * 3 + 1) mod {f.lanes}))],
         "fixed mixed map");
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
         Identity : constant Wide.{f.selectors} :=
           [for Lane in Wide.{f.index} => Lane];
         Broadcast : constant Wide.{f.selectors} := [others => {f.half_lanes}];
         All_Left : constant Wide.{f.two_selectors} :=
           [for Lane in Wide.{f.index} => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.{f.two_selectors} :=
           [for Lane in Wide.{f.index} => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes ({f.half_lanes})], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions ({all_bits}, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** ({f.lanes} - 1), "last lane");
      Check_Mask_Positions (2 ** ({f.half_lanes} - 1), "low-half boundary");
      Check_Mask_Positions (2 ** {f.half_lanes}, "high-half boundary");
      Check_Mask_Positions ({alt}, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "{f.vector} independent fixed reductions");
      declare
         Edge_Value : constant Wide.{f.vector} :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = {f.scalar}'First
           and then Native.Reduce_Min (Edge_Value) = {f.scalar}'First
           and then Wide.Reduce_Max (Edge_Value) = {f.scalar}'Last
           and then Native.Reduce_Max (Edge_Value) = {f.scalar}'Last,
           "{f.vector} independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = {all_bits}
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = {all_bits}
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = {all_bits}
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "{f.vector} native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "{f.vector} misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "{f.vector} out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.{f.values} := Random_Lanes;
            R_B_Lanes : constant Wide.{f.values} := Random_Lanes;
            R_A : constant Wide.{f.vector} := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.{f.vector} := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.{f.selectors};
            R_Two_Selectors : Wide.{f.two_selectors};
            Expected_One : Wide.{f.values};
            Expected_Two : Wide.{f.values};
            R_Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask
              ({f.mask_bits} (Next_U64 mod 2 ** {f.lanes}));
            Shift : constant Natural := Natural (Next_U64 mod {f.bits + 3});
            Slide : constant Natural := Natural (Next_U64 mod {f.lanes + 3});
         begin
            Check_Memory (R_A_Lanes, "random" & Iteration'Image);
            Check_Construction (R_A_Lanes, "random" & Iteration'Image);
            for Lane in Wide.{f.index} loop
               declare
                  One_Lane : constant Wide.{f.index} :=
                    Wide.{f.index} (Next_U64 mod {f.lanes});
                  Two_Lane : constant Wide.{f.index} :=
                    Wide.{f.index} (Next_U64 mod {f.lanes});
                  From_Right : constant Boolean := Next_U64 mod 2 = 1;
               begin
                  R_One_Selectors (Lane) := One_Lane;
                  Expected_One (Lane) := R_A_Lanes (One_Lane);
                  R_Two_Selectors (Lane) :=
                    (if From_Right
                     then Wide.Select_Right_Lane (Two_Lane)
                     else Wide.Select_Left_Lane (Two_Lane));
                  Expected_Two (Lane) :=
                    (if From_Right
                     then R_B_Lanes (Two_Lane)
                     else R_A_Lanes (Two_Lane));
               end;
            end loop;
            Check_Permutations
              (R_A_Lanes, R_B_Lanes, R_One_Selectors, R_Two_Selectors,
               Expected_One, Expected_Two,
               "randomized" & Iteration'Image);
            Check_Movements
              (R_A_Lanes, R_B_Lanes, "randomized" & Iteration'Image);
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
{byte_oracle_checks}
{wrapping_randomized}
{bitwise_randomized}
{saturation_randomized}
{byte_predicate_randomized}
            Check_Predicates
              (R_A_Lanes, R_B_Lanes, Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
            Check_Shifts
              (R_A, R_A_Lanes, Shift,
               "{f.vector} randomized independent shifts" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "{f.vector} randomized selection and movement" & Iteration'Image);
{lookup_randomized}
            Check (Wide.Reduce_Add_Wrap (R_A) =
              Reference_Reduce_Add_Wrap (Wide.To_Lanes (R_A))
              and then Native.Reduce_Add_Wrap (R_A) =
                Reference_Reduce_Add_Wrap (Wide.To_Lanes (R_A))
              and then Wide.Reduce_Min (R_A) =
                Reference_Reduce_Min (Wide.To_Lanes (R_A))
              and then Native.Reduce_Min (R_A) =
                Reference_Reduce_Min (Wide.To_Lanes (R_A))
              and then Wide.Reduce_Max (R_A) =
                Reference_Reduce_Max (Wide.To_Lanes (R_A))
              and then Native.Reduce_Max (R_A) =
                Reference_Reduce_Max (Wide.To_Lanes (R_A)),
              "{f.vector} independent randomized reductions" & Iteration'Image);
{bit_cast_tests(f, 'R_A', 'randomized ')}
         end;
      end loop;
   end Test_{f.vector};
"""


def float_test(f: Family) -> str:
    a_values = ", ".join(f"{i + 1}.0" for i in range(f.lanes))
    all_bits = f"{f.mask_bits}'Last"
    alt = sum(1 << i for i in range(0, f.lanes, 2))
    bit_type = "Interfaces.Unsigned_32" if f.bits == 32 else "Interfaces.Unsigned_64"
    sign_bit = "16#8000_0000#" if f.bits == 32 else "16#8000_0000_0000_0000#"
    inf_bits = "16#7F80_0000#" if f.bits == 32 else "16#7FF0_0000_0000_0000#"
    qnan_bits = "16#7FC1_2345#" if f.bits == 32 else "16#7FF8_1234_5678_9ABC#"
    snan_bits = "16#7F81_2345#" if f.bits == 32 else "16#7FF0_1234_5678_9ABC#"
    negative_qnan_bits = "16#FFC1_2345#" if f.bits == 32 else "16#FFF8_1234_5678_9ABC#"
    negative_snan_bits = "16#FF81_2345#" if f.bits == 32 else "16#FFF0_1234_5678_9ABC#"
    exponent_mask = "16#7F80_0000#" if f.bits == 32 else "16#7FF0_0000_0000_0000#"
    fraction_mask = "16#007F_FFFF#" if f.bits == 32 else "16#000F_FFFF_FFFF_FFFF#"
    quiet_bit = "16#0040_0000#" if f.bits == 32 else "16#0008_0000_0000_0000#"
    negative_inf_bits = "16#FF80_0000#" if f.bits == 32 else "16#FFF0_0000_0000_0000#"
    negative_subnormal_bits = "16#8000_0001#" if f.bits == 32 else "16#8000_0000_0000_0001#"
    special_bits = ["0", sign_bit, inf_bits, qnan_bits, snan_bits]
    while len(special_bits) < f.lanes:
        special_bits.append(str(len(special_bits)))
    special_values = ", ".join(f"Bits_To_Value ({value})" for value in special_bits[:f.lanes])
    compaction_extra_bits = [negative_inf_bits, snan_bits, "1", negative_subnormal_bits]
    compaction_extra_values = ", ".join(
        f"Bits_To_Value ({compaction_extra_bits[lane % len(compaction_extra_bits)]})"
        for lane in range(f.lanes)
    )
    predicate_edge_left_bits = [
        negative_qnan_bits, negative_snan_bits, "1", negative_subnormal_bits,
        inf_bits, negative_inf_bits, "0", sign_bit,
    ]
    predicate_edge_right_bits = [
        qnan_bits, snan_bits, sign_bit, "0", negative_inf_bits, inf_bits,
        negative_subnormal_bits, "1",
    ]
    predicate_edge_left_values = ", ".join(
        f"Bits_To_Value ({predicate_edge_left_bits[lane]})"
        for lane in range(f.lanes)
    )
    predicate_edge_right_values = ", ".join(
        f"Bits_To_Value ({predicate_edge_right_bits[lane]})"
        for lane in range(f.lanes)
    )
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
      function Is_NaN (Value : {f.scalar}) return Boolean is
        ((Value_To_Bits (Value) and {exponent_mask}) = {exponent_mask}
         and then (Value_To_Bits (Value) and {fraction_mask}) /= 0);
{predicate_declarations(f)}
      function Is_Signaling_NaN (Value : {f.scalar}) return Boolean is
        (Is_NaN (Value)
         and then (Value_To_Bits (Value) and {quiet_bit}) = 0);
      function Quiet_NaN (Value : {f.scalar}) return {f.scalar} is
        (Bits_To_Value (Value_To_Bits (Value) or {quiet_bit}));
      function Reference_Min_Number
        (Left, Right : {f.scalar}) return {f.scalar}
      is
      begin
         if Is_Signaling_NaN (Left) then
            return Quiet_NaN (Left);
         elsif Is_Signaling_NaN (Right) then
            return Quiet_NaN (Right);
         elsif Is_NaN (Left) then
            return Right;
         elsif Is_NaN (Right) then
            return Left;
         elsif Left = 0.0 and then Right = 0.0 then
            return (if (Value_To_Bits (Left) and {sign_bit}) /= 0
                    then Left else Right);
         elsif Left < Right then
            return Left;
         else
            return Right;
         end if;
      end Reference_Min_Number;
      function Reference_Max_Number
        (Left, Right : {f.scalar}) return {f.scalar}
      is
      begin
         if Is_Signaling_NaN (Left) then
            return Quiet_NaN (Left);
         elsif Is_Signaling_NaN (Right) then
            return Quiet_NaN (Right);
         elsif Is_NaN (Left) then
            return Right;
         elsif Is_NaN (Right) then
            return Left;
         elsif Left = 0.0 and then Right = 0.0 then
            return (if (Value_To_Bits (Left) and {sign_bit}) = 0
                    then Left else Right);
         elsif Left > Right then
            return Left;
         else
            return Right;
         end if;
      end Reference_Max_Number;
      function Reference_Reduce_Add
        (Values : Wide.{f.values}) return {f.scalar}
      is
         Result : {f.scalar} := 0.0;
      begin
         for Lane in Wide.{f.index} loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add;
      function Reference_Reduce_Min_Number
        (Values : Wide.{f.values}) return {f.scalar}
      is
         Result : {f.scalar} := Values (Values'First);
      begin
         for Lane in Wide.{f.index} range Values'First + 1 .. Values'Last loop
            Result := Reference_Min_Number (Result, Values (Lane));
         end loop;
         return Result;
      end Reference_Reduce_Min_Number;
      function Reference_Reduce_Max_Number
        (Values : Wide.{f.values}) return {f.scalar}
      is
         Result : {f.scalar} := Values (Values'First);
      begin
         for Lane in Wide.{f.index} range Values'First + 1 .. Values'Last loop
            Result := Reference_Max_Number (Result, Values (Lane));
         end loop;
         return Result;
      end Reference_Reduce_Max_Number;
      function Same_Reduction
        (Actual, Expected : {f.scalar}) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
           and then (Value_To_Bits (Actual) and {quiet_bit}) /= 0
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Reductions
        (Values : Wide.{f.values}; Context : String)
      is
         Value : constant Wide.{f.vector} := Wide.From_Lanes (Values);
      begin
         Check (Same_Reduction (Wide.Reduce_Add (Value),
                                Reference_Reduce_Add (Values))
           and then Same_Reduction (Native.Reduce_Add (Value),
                                    Reference_Reduce_Add (Values))
           and then Same_Reduction (Wide.Reduce_Min_Number (Value),
                                    Reference_Reduce_Min_Number (Values))
           and then Same_Reduction (Native.Reduce_Min_Number (Value),
                                    Reference_Reduce_Min_Number (Values))
           and then Same_Reduction (Wide.Reduce_Max_Number (Value),
                                    Reference_Reduce_Max_Number (Values))
           and then Same_Reduction (Native.Reduce_Max_Number (Value),
                                    Reference_Reduce_Max_Number (Values)),
           "{f.vector} independent reduction oracle " & Context);
      end Check_Reductions;
      function Same_Extreme
        (Actual, Expected : {f.scalar}) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
           and then (Value_To_Bits (Actual) and {quiet_bit}) /= 0
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Extrema
        (Left_Values, Right_Values : Wide.{f.values}; Context : String)
      is
         Left_Value : constant Wide.{f.vector} :=
           Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.{f.vector} :=
           Wide.From_Lanes (Right_Values);
         Scalar_Min : constant Wide.{f.vector} :=
           Wide.Min_Number (Left_Value, Right_Value);
         Native_Min : constant Wide.{f.vector} :=
           Native.Min_Number (Left_Value, Right_Value);
         Scalar_Max : constant Wide.{f.vector} :=
           Wide.Max_Number (Left_Value, Right_Value);
         Native_Max : constant Wide.{f.vector} :=
           Native.Max_Number (Left_Value, Right_Value);
      begin
         for Lane in Wide.{f.index} loop
            Check
              (Same_Extreme
                 (Wide.Extract (Scalar_Min, Lane),
                  Reference_Min_Number
                    (Left_Values (Lane), Right_Values (Lane)))
               and then Same_Extreme
                 (Wide.Extract (Native_Min, Lane),
                  Reference_Min_Number
                    (Left_Values (Lane), Right_Values (Lane)))
               and then Same_Extreme
                 (Wide.Extract (Scalar_Max, Lane),
                  Reference_Max_Number
                    (Left_Values (Lane), Right_Values (Lane)))
               and then Same_Extreme
                 (Wide.Extract (Native_Max, Lane),
                  Reference_Max_Number
                    (Left_Values (Lane), Right_Values (Lane))),
               "{f.vector} independent extrema oracle " & Context
               & Lane'Image);
         end loop;
      end Check_Extrema;
      function Same_Arithmetic
        (Actual, Expected : {f.scalar}) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Arithmetic
        (Left_Values, Right_Values : Wide.{f.values}; Context : String)
      is
         Left_Value : constant Wide.{f.vector} :=
           Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.{f.vector} :=
           Wide.From_Lanes (Right_Values);
         Scalar_Add : constant Wide.{f.vector} :=
           Wide.Add (Left_Value, Right_Value);
         Native_Add : constant Wide.{f.vector} :=
           Native.Add (Left_Value, Right_Value);
         Scalar_Subtract : constant Wide.{f.vector} :=
           Wide.Subtract (Left_Value, Right_Value);
         Native_Subtract : constant Wide.{f.vector} :=
           Native.Subtract (Left_Value, Right_Value);
         Scalar_Multiply : constant Wide.{f.vector} :=
           Wide.Multiply (Left_Value, Right_Value);
         Native_Multiply : constant Wide.{f.vector} :=
           Native.Multiply (Left_Value, Right_Value);
         Scalar_Divide : constant Wide.{f.vector} :=
           Wide.Divide (Left_Value, Right_Value);
         Native_Divide : constant Wide.{f.vector} :=
           Native.Divide (Left_Value, Right_Value);
      begin
         for Lane in Wide.{f.index} loop
            Check
              (Same_Arithmetic
                 (Wide.Extract (Scalar_Add, Lane),
                  Left_Values (Lane) + Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Native_Add, Lane),
                  Left_Values (Lane) + Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Scalar_Subtract, Lane),
                  Left_Values (Lane) - Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Native_Subtract, Lane),
                  Left_Values (Lane) - Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Scalar_Multiply, Lane),
                  Left_Values (Lane) * Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Native_Multiply, Lane),
                  Left_Values (Lane) * Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Scalar_Divide, Lane),
                  Left_Values (Lane) / Right_Values (Lane))
               and then Same_Arithmetic
                 (Wide.Extract (Native_Divide, Lane),
                  Left_Values (Lane) / Right_Values (Lane)),
               "{f.vector} independent arithmetic oracle " & Context
               & Lane'Image);
         end loop;
      end Check_Arithmetic;
{compaction_declarations(f)}
{mask_position_declarations(f)}
{permutation_declarations(f)}
{movement_declarations(f)}
{memory_declarations(f)}
{construction_declarations(f)}
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
      Compaction_Extra_Lanes : constant Wide.{f.values} :=
        [{compaction_extra_values}];
      Predicate_Edge_Left : constant Wide.{f.values} :=
        [{predicate_edge_left_values}];
      Predicate_Edge_Right : constant Wide.{f.values} :=
        [{predicate_edge_right_values}];
      Order_Vector : constant Wide.{f.vector} := Wide.From_Lanes ([{order_lanes}]);
      Positive_Zero_First : constant Wide.{f.vector} :=
        Wide.From_Lanes ([{positive_zero_order}]);
      Negative_Zero_First : constant Wide.{f.vector} :=
        Wide.From_Lanes ([{negative_zero_order}]);
      Map_Selectors : Wide.{f.selectors};
      Two_Selectors : Wide.{f.two_selectors};
      Native_Two_Selectors : Wide.{f.two_selectors};
   begin
      Check_Memory (Special_Lanes, "fixed IEEE bits");
      Check_Construction (Special_Lanes, "fixed IEEE bits");
      Check (Wide.To_Lanes (A) = A_Lanes, "{f.vector} lane round trip");
      Check ((for all Lane in Wide.{f.index} =>
        Value_To_Bits (Wide.Extract (Wide.Splat (2.0), Lane)) =
          Value_To_Bits ({f.scalar} (2.0)))
        and then (for all Lane in Wide.{f.index} =>
          Value_To_Bits (Native.Extract (Native.Splat (2.0), Lane)) =
            Value_To_Bits ({f.scalar} (2.0))),
        "{f.vector} splat construction");
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
      Check_Arithmetic (A_Lanes, [others => 2.0], "fixed finite");
      Check_Arithmetic (Special_Lanes, Compaction_Extra_Lanes,
                        "fixed IEEE categories");
      Check_Extrema (Special_Lanes, Compaction_Extra_Lanes,
                     "fixed IEEE categories");
      Check_Extrema (Compaction_Extra_Lanes, Special_Lanes,
                     "fixed IEEE categories reversed");
      Check_Extrema (Wide.To_Lanes (Positive_Zero_First),
                     Wide.To_Lanes (Negative_Zero_First),
                     "signed zeros");
      Check_Extrema (Wide.To_Lanes (Negative_Zero_First),
                     Wide.To_Lanes (Positive_Zero_First),
                     "signed zeros reversed");
      Check_Predicates
        (Special_Lanes, Compaction_Extra_Lanes,
         {f.mask_bits} ({alt}), "fixed IEEE categories");
      Check_Predicates
        (Compaction_Extra_Lanes, Special_Lanes,
         {f.mask_bits} ({all_bits}), "fixed IEEE categories reversed");
      Check_Predicates
        (Predicate_Edge_Left, Predicate_Edge_Right,
         {f.mask_bits} ({alt}), "both-sign NaNs and subnormals");
      Check (Wide.To_Bit_Mask (Wide.Less_Than (A, Two)) = 1,
        "{f.vector} ordered comparison");
{compaction_fixed_tests(f, 'A_Lanes')}
{compaction_fixed_tests(f, 'Special_Lanes', 'special-bit')}
{compaction_fixed_tests(f, 'Compaction_Extra_Lanes', 'extra-special-bit')}
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
      Check (Same_Reduction (Wide.Reduce_Add (A), Reference_Reduce_Add (A_Lanes))
        and then Same_Reduction (Native.Reduce_Add (A), Reference_Reduce_Add (A_Lanes))
        and then Same_Reduction (Wide.Reduce_Min_Number (A), Reference_Reduce_Min_Number (A_Lanes))
        and then Same_Reduction (Native.Reduce_Min_Number (A), Reference_Reduce_Min_Number (A_Lanes))
        and then Same_Reduction (Wide.Reduce_Max_Number (A), Reference_Reduce_Max_Number (A_Lanes))
        and then Same_Reduction (Native.Reduce_Max_Number (A), Reference_Reduce_Max_Number (A_Lanes)),
        "{f.vector} independent ordinary reduction oracle");
      Check (Same_Reduction (Wide.Reduce_Add (Order_Vector),
                              Reference_Reduce_Add (Wide.To_Lanes (Order_Vector)))
        and then Same_Reduction (Native.Reduce_Add (Order_Vector),
                                 Reference_Reduce_Add (Wide.To_Lanes (Order_Vector)))
        and then Same_Reduction (Wide.Reduce_Min_Number (Order_Vector),
                                 Reference_Reduce_Min_Number (Wide.To_Lanes (Order_Vector)))
        and then Same_Reduction (Native.Reduce_Min_Number (Order_Vector),
                                 Reference_Reduce_Min_Number (Wide.To_Lanes (Order_Vector)))
        and then Same_Reduction (Wide.Reduce_Max_Number (Order_Vector),
                                 Reference_Reduce_Max_Number (Wide.To_Lanes (Order_Vector)))
        and then Same_Reduction (Native.Reduce_Max_Number (Order_Vector),
                                 Reference_Reduce_Max_Number (Wide.To_Lanes (Order_Vector))),
        "{f.vector} independent signaling-NaN reduction oracle");
      Check_Reductions (Special_Lanes, "fixed IEEE categories");
      Check_Reductions (Compaction_Extra_Lanes,
                        "fixed signaling NaN and subnormal categories");
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
         Expected_One : constant Wide.{f.values} :=
           [for Lane in Wide.{f.index} =>
              Special_Lanes ({f.lanes - 1} - Lane)];
         Expected_Two : constant Wide.{f.values} :=
           [for Lane in Wide.{f.index} =>
              (if Lane mod 2 = 0
               then Special_Lanes ((Lane * 3 + 1) mod {f.lanes})
               else A_Lanes ((Lane * 3 + 1) mod {f.lanes}))];
      begin
         Check_Permutations
           (Special_Lanes, A_Lanes, Map_Selectors, Two_Selectors,
            Expected_One, Expected_Two, "fixed special-bit maps");
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
      Check_Movements (Special_Lanes, A_Lanes, "fixed special bits");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions ({all_bits}, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** ({f.lanes} - 1), "last lane");
      Check_Mask_Positions (2 ** ({f.half_lanes} - 1), "low-half boundary");
      Check_Mask_Positions (2 ** {f.half_lanes}, "high-half boundary");
      Check_Mask_Positions ({alt}, "alternating");
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
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = {f.mask_bits}'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = {f.mask_bits}'Last,
              "{f.vector} mask algebra" & Pattern'Image);
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
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
        and then (for all Lane in Wide.{f.index} =>
          Value_To_Bits (Wide.Extract (Wide.Load_Unaligned (Data, Data'First + 1), Lane)) =
            Value_To_Bits (A_Lanes (Lane)))
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "{f.vector} native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "{f.vector} misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "{f.vector} out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.{f.values} := Random_Lanes;
            R_B_Lanes : constant Wide.{f.values} := Random_Lanes;
            R_Bit_Lanes : constant Wide.{f.values} := Random_Bit_Lanes;
            R_A : constant Wide.{f.vector} := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.{f.vector} := Wide.From_Lanes (R_B_Lanes);
            R_Bits : constant Wide.{f.vector} := Wide.From_Lanes (R_Bit_Lanes);
            R_One_Selectors : Wide.{f.selectors};
            R_Two_Selectors : Wide.{f.two_selectors};
            Expected_One : Wide.{f.values};
            Expected_Two : Wide.{f.values};
            R_Mask : constant Wide.{f.mask} := Wide.Mask_From_Bit_Mask
              ({f.mask_bits} (Next_U64 mod 2 ** {f.lanes}));
            Slide : constant Natural := Natural (Next_U64 mod {f.lanes + 3});
         begin
            Check_Memory (R_Bit_Lanes, "random raw bits" & Iteration'Image);
            Check_Construction
              (R_Bit_Lanes, "random raw bits" & Iteration'Image);
            for Lane in Wide.{f.index} loop
               declare
                  One_Lane : constant Wide.{f.index} :=
                    Wide.{f.index} (Next_U64 mod {f.lanes});
                  Two_Lane : constant Wide.{f.index} :=
                    Wide.{f.index} (Next_U64 mod {f.lanes});
                  From_Right : constant Boolean := Next_U64 mod 2 = 1;
               begin
                  R_One_Selectors (Lane) := One_Lane;
                  Expected_One (Lane) := R_Bit_Lanes (One_Lane);
                  R_Two_Selectors (Lane) :=
                    (if From_Right
                     then Wide.Select_Right_Lane (Two_Lane)
                     else Wide.Select_Left_Lane (Two_Lane));
                  Expected_Two (Lane) :=
                    (if From_Right
                     then R_A_Lanes (Two_Lane)
                     else R_Bit_Lanes (Two_Lane));
               end;
            end loop;
            Check_Permutations
              (R_Bit_Lanes, R_A_Lanes, R_One_Selectors, R_Two_Selectors,
               Expected_One, Expected_Two,
               "random special bits" & Iteration'Image);
            Check_Movements
              (R_Bit_Lanes, R_A_Lanes, "random special bits" & Iteration'Image);
            Check (Native.To_Lanes (Native.Add (R_A, R_B)) = Wide.To_Lanes (Wide.Add (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply (R_A, R_B)),
              "{f.vector} randomized arithmetic" & Iteration'Image);
            Check_Arithmetic
              (R_A_Lanes, R_B_Lanes,
               "randomized finite" & Iteration'Image);
            Check_Arithmetic
              (R_Bit_Lanes, Special_Lanes,
               "randomized raw bits" & Iteration'Image);
            Check_Extrema
              (R_A_Lanes, R_B_Lanes,
               "randomized finite" & Iteration'Image);
            Check_Extrema
              (R_Bit_Lanes, Special_Lanes,
               "randomized raw bits" & Iteration'Image);
            Check_Predicates
              (R_A_Lanes, R_B_Lanes, Wide.To_Bit_Mask (R_Mask),
               "randomized finite" & Iteration'Image);
            Check_Predicates
              (R_Bit_Lanes, Special_Lanes, Wide.To_Bit_Mask (R_Mask),
               "randomized raw bits" & Iteration'Image);
            Check_Compaction
              (Wide.To_Lanes (R_Bits), Wide.To_Bit_Mask (R_Mask),
               "random special bits" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask)),
              "{f.vector} randomized selection and compaction" & Iteration'Image);
            Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "{f.vector} randomized slides" & Iteration'Image);
            Check (Same_Reduction (Wide.Reduce_Add (R_A), Reference_Reduce_Add (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Add (R_A), Reference_Reduce_Add (R_A_Lanes))
              and then Same_Reduction (Wide.Reduce_Min_Number (R_A), Reference_Reduce_Min_Number (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Min_Number (R_A), Reference_Reduce_Min_Number (R_A_Lanes))
              and then Same_Reduction (Wide.Reduce_Max_Number (R_A), Reference_Reduce_Max_Number (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Max_Number (R_A), Reference_Reduce_Max_Number (R_A_Lanes)),
              "{f.vector} randomized finite reduction oracle" & Iteration'Image);
            Check (Same_Reduction (Wide.Reduce_Add (R_Bits), Reference_Reduce_Add (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Add (R_Bits), Reference_Reduce_Add (R_Bit_Lanes))
              and then Same_Reduction (Wide.Reduce_Min_Number (R_Bits), Reference_Reduce_Min_Number (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Min_Number (R_Bits), Reference_Reduce_Min_Number (R_Bit_Lanes))
              and then Same_Reduction (Wide.Reduce_Max_Number (R_Bits), Reference_Reduce_Max_Number (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Max_Number (R_Bits), Reference_Reduce_Max_Number (R_Bit_Lanes)),
              "{f.vector} randomized raw-bit reduction oracle" & Iteration'Image);
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
