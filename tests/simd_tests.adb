with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.AVX2;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Backends.Scalar;
with Flyology_SIMD.Features;

procedure SIMD_Tests is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Flyology_SIMD.Algorithms.Search_Result;

   Seed : constant Interfaces.Unsigned_32 := 16#5EED_0123#;
   State : Interfaces.Unsigned_32 := Seed;
   Failures : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Failures := Failures + 1;
         Put_Line ("FAIL: " & Message);
      end if;
   end Check;

   function Next_U8 return U8 is
   begin
      State := State xor Interfaces.Shift_Left (State, 13);
      State := State xor Interfaces.Shift_Right (State, 17);
      State := State xor Interfaces.Shift_Left (State, 5);
      return U8 (State and 16#FF#);
   end Next_U8;

   function Random_Lanes return Lane_Values_8x16 is
      Result : Lane_Values_8x16;
   begin
      for Lane in Result'Range loop
         Result (Lane) := Next_U8;
      end loop;
      return Result;
   end Random_Lanes;

   function Random_Selectors return Lane_Selectors_8x16 is
      Result : Lane_Selectors_8x16;
   begin
      for Lane in Result'Range loop
         Result (Lane) := Lane_Index_8x16 (Next_U8 mod 16);
      end loop;
      return Result;
   end Random_Selectors;

   function Same (Left, Right : U8x16) return Boolean is
     (To_Lanes (Left) = To_Lanes (Right));

   procedure Check_Value_Oracle
     (Portable_Result : U8x16;
      Scalar_Result   : U8x16;
      Native_Result   : U8x16;
      Expected        : Lane_Values_8x16;
      Message         : String)
   is
   begin
      Check
        (To_Lanes (Portable_Result) = Expected
         and then Flyology_SIMD.Backends.Scalar.To_Lanes (Scalar_Result) =
           Expected
         and then Flyology_SIMD.Backends.Native.To_Lanes (Native_Result) =
           Expected,
         Message);
   end Check_Value_Oracle;

   procedure Check_Mask_Oracle
     (Portable_Result : Mask_8x16;
      Scalar_Result   : Mask_8x16;
      Native_Result   : Mask_8x16;
      Expected        : Interfaces.Unsigned_16;
      Message         : String)
   is
   begin
      Check
        (To_Bit_Mask (Portable_Result) = Expected
         and then Flyology_SIMD.Backends.Scalar.To_Bit_Mask (Scalar_Result) =
           Expected
         and then Flyology_SIMD.Backends.Native.To_Bit_Mask (Native_Result) =
           Expected,
         Message);
   end Check_Mask_Oracle;

   type Comparison_Kind is
     (Compare_Equal,
      Compare_Less,
      Compare_Less_Equal,
      Compare_Greater,
      Compare_Greater_Equal);

   function Reference_Comparison
     (Left, Right : Lane_Values_8x16;
      Kind        : Comparison_Kind) return Interfaces.Unsigned_16
   is
      Result : Interfaces.Unsigned_16 := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         if (case Kind is
               when Compare_Equal         => Left (Lane) = Right (Lane),
               when Compare_Less          => Left (Lane) < Right (Lane),
               when Compare_Less_Equal    => Left (Lane) <= Right (Lane),
               when Compare_Greater       => Left (Lane) > Right (Lane),
               when Compare_Greater_Equal => Left (Lane) >= Right (Lane))
         then
            Result := Result or Interfaces.Shift_Left
              (Interfaces.Unsigned_16'(1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison;

   function Reference_Horizontal_Sum
     (Values : Lane_Values_8x16) return Natural
   is
      Result : Natural := 0;
   begin
      for Value of Values loop
         Result := Result + Natural (Value);
      end loop;
      return Result;
   end Reference_Horizontal_Sum;

   function Reference_Add_Saturate (Left, Right : U8) return U8 is
     (if Left > U8'Last - Right then U8'Last else Left + Right);

   function Reference_Subtract_Saturate (Left, Right : U8) return U8 is
     (if Left < Right then 0 else Left - Right);

   function Reference_Reduce_Add (Values : Lane_Values_8x16) return U8 is
      Result : U8 := 0;
   begin
      for Value of Values loop
         Result := Result + Value;
      end loop;
      return Result;
   end Reference_Reduce_Add;

   function Reference_Reduce_Min (Values : Lane_Values_8x16) return U8 is
      Result : U8 := Values (Values'First);
   begin
      for Value of Values loop
         if Value < Result then
            Result := Value;
         end if;
      end loop;
      return Result;
   end Reference_Reduce_Min;

   function Reference_Reduce_Max (Values : Lane_Values_8x16) return U8 is
      Result : U8 := Values (Values'First);
   begin
      for Value of Values loop
         if Value > Result then
            Result := Value;
         end if;
      end loop;
      return Result;
   end Reference_Reduce_Max;

   function Reference_Shift_Left_Logical
     (Value : U8x16; Count : Natural) return U8x16
   is
      Result : U8x16 := Zero;
   begin
      for Lane in Lane_Index_8x16 loop
         Result := Replace
           (Result, Lane,
            (if Count >= 8 then 0
             else Interfaces.Shift_Left (Extract (Value, Lane), Count)));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical;

   function Reference_Shift_Right_Logical
     (Value : U8x16; Count : Natural) return U8x16
   is
      Result : U8x16 := Zero;
   begin
      for Lane in Lane_Index_8x16 loop
         Result := Replace
           (Result, Lane,
            (if Count >= 8 then 0
             else Interfaces.Shift_Right (Extract (Value, Lane), Count)));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical;

   function Reference_Popcount (Bits : Interfaces.Unsigned_16) return Natural is
      Value : constant Interfaces.Unsigned_16 := Bits;
      Count : Natural := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         if (Value and Interfaces.Shift_Left
               (Interfaces.Unsigned_16'(1), Lane)) /= 0
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Reference_Popcount;

   function Reference_First_True
     (Bits : Interfaces.Unsigned_16) return Lane_Count_8x16
   is
   begin
      for Lane in Lane_Index_8x16 loop
         if (Bits and Interfaces.Shift_Left
               (Interfaces.Unsigned_16'(1), Lane)) /= 0
         then
            return Lane;
         end if;
      end loop;
      return Lane_Count_8x16'Last;
   end Reference_First_True;

   function Reference_Last_True
     (Bits : Interfaces.Unsigned_16) return Lane_Count_8x16
   is
   begin
      for Lane in reverse Lane_Index_8x16 loop
         if (Bits and Interfaces.Shift_Left
               (Interfaces.Unsigned_16'(1), Lane)) /= 0
         then
            return Lane;
         end if;
      end loop;
      return Lane_Count_8x16'Last;
   end Reference_Last_True;

   function Reference_Compress
     (Value : U8x16; Mask : Mask_8x16) return U8x16
   is
      Result      : U8x16 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_8x16 loop
         if Test (Mask, Source_Lane) then
            Result := Replace
              (Result, Lane_Index_8x16 (Result_Lane),
               Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress;

   function Reference_Expand
     (Value : U8x16; Mask : Mask_8x16) return U8x16
   is
      Result      : U8x16 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_8x16 loop
         if Test (Mask, Result_Lane) then
            Result := Replace
              (Result, Result_Lane,
               Extract (Value, Lane_Index_8x16 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand;

   procedure Test_Core_Semantics is
      A_Lanes : constant Lane_Values_8x16 :=
        [0, 1, 2, 3, 16#7F#, 16#80#, 16#FE#, 16#FF#,
         16#AA#, 16#55#, 10, 20, 30, 40, 50, 60];
      B_Lanes : constant Lane_Values_8x16 :=
        [0, 2, 1, 3, 1, 16#80#, 2, 1,
         16#55#, 16#AA#, 250, 240, 230, 220, 210, 200];
      A : constant U8x16 := From_Lanes (A_Lanes);
      B : constant U8x16 := From_Lanes (B_Lanes);
      Min_Expected : constant Lane_Values_8x16 :=
        [for Lane in Lane_Index_8x16 =>
           (if A_Lanes (Lane) < B_Lanes (Lane)
            then A_Lanes (Lane) else B_Lanes (Lane))];
      Max_Expected : constant Lane_Values_8x16 :=
        [for Lane in Lane_Index_8x16 =>
           (if A_Lanes (Lane) > B_Lanes (Lane)
            then A_Lanes (Lane) else B_Lanes (Lane))];
      Added : constant Lane_Values_8x16 := To_Lanes (Add_Wrap (A, B));
      Saturated : constant Lane_Values_8x16 := To_Lanes (Add_Saturate (A, B));
      Lookup_Table : constant U8x16 := From_Lanes
        ([16#A0#, 16#A1#, 16#A2#, 16#A3#,
          16#A4#, 16#A5#, 16#A6#, 16#A7#,
          16#A8#, 16#A9#, 16#AA#, 16#AB#,
          16#AC#, 16#AD#, 16#AE#, 16#AF#]);
      Lookup_Indices : constant U8x16 := From_Lanes
        ([15, 0, 7, 16, 1, 14, 255, 8, 3, 128, 12, 2, 31, 5, 9, 4]);
      Lookup_Expected : constant U8x16 := From_Lanes
        ([16#AF#, 16#A0#, 16#A7#, 0,
          16#A1#, 16#AE#, 0, 16#A8#,
          16#A3#, 0, 16#AC#, 16#A2#,
          0, 16#A5#, 16#A9#, 16#A4#]);
      Selectors : constant Lane_Selectors_8x16 :=
        [15, 0, 7, 7, 1, 14, 2, 8, 3, 3, 12, 2, 6, 5, 9, 4];
      Map : constant Lane_Map_8x16 := Make_Lane_Map (Selectors);
      Two_Source_Map : constant Two_Source_Lane_Map_8x16 :=
        Make_Two_Source_Lane_Map
          ([Select_Left_Lane (15), Select_Right_Lane (0),
            Select_Left_Lane (7), Select_Right_Lane (7),
            Select_Left_Lane (1), Select_Right_Lane (14),
            Select_Left_Lane (2), Select_Right_Lane (8),
            Select_Left_Lane (3), Select_Right_Lane (3),
            Select_Left_Lane (12), Select_Right_Lane (2),
            Select_Left_Lane (6), Select_Right_Lane (5),
            Select_Left_Lane (9), Select_Right_Lane (4)]);
      Two_Source_Expected : constant U8x16 := From_Lanes
        ([60, 0, 16#FF#, 1, 1, 210, 2, 16#55#,
          3, 3, 30, 1, 16#FE#, 16#80#, 16#55#, 1]);
   begin
      Check
        (Extract (U8x16'(Zero), 0) = 0
         and Extract (U8x16'(Zero), 15) = 0,
         "zero");
      Check (Extract (U8x16'(Splat (U8'(77))), 9) = 77, "splat");
      Check (Extract (Replace (A, 5, 42), 5) = 42, "replace");
      Check (Added (6) = 0 and Added (7) = 0, "wrapping addition");
      Check (Extract (Subtract_Wrap (A, B), 1) = 255,
             "wrapping subtraction");
      Check (Extract (Multiply_Wrap (A, B), 6) = 252
             and Extract (Multiply_Wrap (A, B), 7) = 255,
             "wrapping multiplication");
      Check (Saturated (6) = 255 and Saturated (7) = 255,
             "saturating addition");
      Check (Extract (Subtract_Saturate (A, B), 1) = 0,
             "saturating subtraction");
      Check (Extract (Bitwise_And (A, B), 8) = 0
             and Extract (Bitwise_Or (A, B), 8) = 255
             and Extract (Bitwise_Xor (A, B), 8) = 255
             and Extract (Bitwise_Not (A), 0) = 255,
             "bitwise operations");
      Check (Same (Shift_Left_Logical (Splat (255), 8), Zero),
             "oversized left shift");
      Check (Same (Shift_Right_Logical (Splat (255), 100), Zero),
             "oversized right shift");
      Check
        (Same
           (Flyology_SIMD.Backends.Native.Shift_Left_Logical
              (Splat (255), Natural'Last),
            Zero)
         and then Same
           (Flyology_SIMD.Backends.Native.Shift_Right_Logical
              (Splat (255), Natural'Last),
            Zero),
         "native maximum-count logical shifts");
      Check (To_Bit_Mask (Equal (A, B)) = 16#0029#, "equality lane mask");
      Check (Test (Less_Than (A, B), 1) and not Test (Less_Than (A, B), 2),
             "unsigned ordered comparison");
      Check (Test (Less_Equal (A, B), 0)
             and Test (Greater_Than (A, B), 2)
             and Test (Greater_Equal (A, B), 3),
             "all ordered comparisons");
      Check (Same (Select_Value (Equal (A, B), A, B), B), "select semantics");
      Check_Value_Oracle
        (Min (A, B),
         Flyology_SIMD.Backends.Scalar.Min (A, B),
         Flyology_SIMD.Backends.Native.Min (A, B),
         Min_Expected,
         "fixed independent unsigned minimum");
      Check_Value_Oracle
        (Max (A, B),
         Flyology_SIMD.Backends.Scalar.Max (A, B),
         Flyology_SIMD.Backends.Native.Max (A, B),
         Max_Expected,
         "fixed independent unsigned maximum");
      Check
        (Horizontal_Sum (Splat (255)) =
           Reference_Horizontal_Sum ([others => 255])
         and then Flyology_SIMD.Backends.Native.Horizontal_Sum (Splat (255)) =
           Reference_Horizontal_Sum ([others => 255]),
         "horizontal sum");
      Check (Extract (Reverse_Bytes (A), 0) = Extract (A, 15), "reverse");
      Check (Same (Reverse_Lanes (A), Reverse_Bytes (A)),
             "reverse lanes compatibility");
      Check (Extract (Interleave_Low (A, B), 2) = Extract (A, 1)
             and Extract (Interleave_Low (A, B), 3) = Extract (B, 1),
             "interleave low");
      Check (Extract (Interleave_High (A, B), 0) = Extract (A, 8),
             "interleave high");
      Check (Extract (Deinterleave_Even (A, B), 1) = Extract (A, 2)
             and Extract (Deinterleave_Even (A, B), 9) = Extract (B, 2),
             "deinterleave even");
      Check (Extract (Deinterleave_Odd (A, B), 1) = Extract (A, 3)
             and Extract (Deinterleave_Odd (A, B), 9) = Extract (B, 3),
             "deinterleave odd");
      Check (Same (Table_Lookup (Lookup_Table, Lookup_Indices), Lookup_Expected),
             "table lookup literal semantics");
      Check
        (Same
           (Flyology_SIMD.Backends.Scalar.Table_Lookup
              (Lookup_Table, Lookup_Indices),
            Lookup_Expected),
         "scalar backend table lookup literal semantics");
      Check
        (Same
           (Flyology_SIMD.Backends.Native.Table_Lookup
              (Lookup_Table, Lookup_Indices),
            Lookup_Expected),
         "native table lookup literal semantics");
      for Lane in Lane_Index_8x16 loop
         Check
           (Extract (Permute_Lanes (A, Map), Lane) =
              Extract (A, Selectors (Lane)),
            "byte fixed lane permutation" & Lane'Image);
      end loop;
      Check
        (Same
           (Flyology_SIMD.Backends.Scalar.Permute_Lanes (A, Map),
            Permute_Lanes (A, Map))
         and then Same
           (Flyology_SIMD.Backends.Native.Permute_Lanes (A, Map),
            Permute_Lanes (A, Map)),
         "byte fixed lane permutation backends");
      Check
        (Same (Permute_Lanes (A, B, Two_Source_Map), Two_Source_Expected)
         and then Same
           (Flyology_SIMD.Backends.Scalar.Permute_Lanes
              (A, B, Two_Source_Map),
            Two_Source_Expected)
         and then Same
           (Flyology_SIMD.Backends.Native.Permute_Lanes
              (A, B, Two_Source_Map),
            Two_Source_Expected),
         "byte fixed two-source lane permutation");
   end Test_Core_Semantics;

   procedure Test_All_Table_Indices is
      Table : constant U8x16 := From_Lanes
        ([16#31#, 16#72#, 16#B4#, 16#05#,
          16#E6#, 16#27#, 16#68#, 16#A9#,
          16#4A#, 16#8B#, 16#CC#, 16#0D#,
          16#EE#, 16#2F#, 16#70#, 16#B1#]);
   begin
      for Batch in Natural range 0 .. 15 loop
         declare
            Indices : constant U8x16 := From_Lanes
              ([for Lane in Lane_Index_8x16 => U8 (Batch * 16 + Lane)]);
            Expected : constant U8x16 :=
              (if Batch = 0 then Table else Zero);
         begin
            Check
              (Same (Table_Lookup (Table, Indices), Expected),
               "table lookup index batch" & Batch'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Table_Lookup (Table, Indices),
                  Expected),
               "native table lookup index batch" & Batch'Image);
         end;
      end loop;
   end Test_All_Table_Indices;

   procedure Test_Lane_Slides is
      Value : constant U8x16 := From_Lanes
        ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
   begin
      for Count in Natural range 0 .. 18 loop
         Check
           (Same
              (Flyology_SIMD.Backends.Scalar.Slide_Lanes_Toward_Low
                 (Value, Count),
               Slide_Lanes_Toward_Low (Value, Count))
            and then Same
              (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low
                 (Value, Count),
               Slide_Lanes_Toward_Low (Value, Count))
            and then Same
              (Flyology_SIMD.Backends.Scalar.Slide_Lanes_Toward_High
                 (Value, Count),
               Slide_Lanes_Toward_High (Value, Count))
            and then Same
              (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High
                 (Value, Count),
               Slide_Lanes_Toward_High (Value, Count)),
            "byte lane-slide backends" & Count'Image);
         for Lane in Lane_Index_8x16 loop
            Check
              (Extract (Slide_Lanes_Toward_Low (Value, Count), Lane) =
                 (if Count < 16 and then Lane < 16 - Count
                  then Extract (Value, Lane_Index_8x16 (Lane + Count))
                  else 0)
               and then Extract
                 (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low
                    (Value, Count), Lane) =
                 (if Count < 16 and then Lane < 16 - Count
                  then Extract (Value, Lane_Index_8x16 (Lane + Count))
                  else 0),
               "byte slide toward low" & Count'Image & Lane'Image);
            Check
              (Extract (Slide_Lanes_Toward_High (Value, Count), Lane) =
                 (if Count < 16 and then Lane >= Count
                  then Extract (Value, Lane_Index_8x16 (Lane - Count))
                  else 0)
               and then Extract
                 (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High
                    (Value, Count), Lane) =
                 (if Count < 16 and then Lane >= Count
                  then Extract (Value, Lane_Index_8x16 (Lane - Count))
                  else 0),
               "byte slide toward high" & Count'Image & Lane'Image);
         end loop;
      end loop;
      Check
        (Same (Slide_Lanes_Toward_Low (Value, Natural'Last), Zero)
         and then Same
           (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low
              (Value, Natural'Last), Zero)
         and then Same (Slide_Lanes_Toward_High (Value, Natural'Last), Zero)
         and then Same
           (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High
              (Value, Natural'Last), Zero),
         "byte maximum-count lane slides");
   end Test_Lane_Slides;

   procedure Test_All_Masks is
      Value : constant U8x16 := From_Lanes
        ([16#80#, 1, 16#FD#, 3, 4, 16#AA#, 6, 7,
          8, 16#55#, 10, 11, 12, 13, 14, 16#FF#]);
      Other : constant U8x16 := From_Lanes
        ([0, 16#FE#, 2, 16#FC#, 5, 16#FA#, 7, 16#F8#,
          9, 16#F6#, 11, 16#F4#, 13, 16#F2#, 15, 16#F0#]);
      Value_Lanes : constant Lane_Values_8x16 := To_Lanes (Value);
      Other_Lanes : constant Lane_Values_8x16 := To_Lanes (Other);
   begin
      for Raw in Natural range 0 .. 65_535 loop
         declare
            Bits : constant Interfaces.Unsigned_16 := Interfaces.Unsigned_16 (Raw);
            Mask : constant Mask_8x16 := Mask_From_Bit_Mask (Bits);
         begin
            Check (To_Bit_Mask (Mask) = Bits, "mask round trip" & Raw'Image);
            Check
              (To_Bit_Mask (Mask_Not (Mask)) = not Bits,
               "mask not" & Raw'Image);
            Check
              (To_Bit_Mask (Mask_And (Mask, Mask_Not (Mask))) = 0
               and then To_Bit_Mask (Mask_Or (Mask, Mask_Not (Mask))) =
                 Interfaces.Unsigned_16'Last
               and then To_Bit_Mask (Mask_Xor (Mask, Mask_Not (Mask))) =
                 Interfaces.Unsigned_16'Last,
               "mask algebra" & Raw'Image);
            Check
              (Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits)) = Bits,
               "native mask round trip" & Raw'Image);
            Check (Population_Count (Mask) = Reference_Popcount (Bits),
                   "mask popcount" & Raw'Image);
            Check
              (Flyology_SIMD.Backends.Native.Population_Count (Mask) =
                 Reference_Popcount (Bits),
               "native mask popcount" & Raw'Image);
            Check
              (First_True (Mask) = Reference_First_True (Bits)
               and then Last_True (Mask) = Reference_Last_True (Bits),
               "mask positions" & Raw'Image);
            Check
              (Flyology_SIMD.Backends.Native.First_True (Mask) =
                 Reference_First_True (Bits)
               and then Flyology_SIMD.Backends.Native.Last_True (Mask) =
                 Reference_Last_True (Bits),
               "native mask positions" & Raw'Image);
            Check
              (Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Mask_Not (Mask)) = not Bits,
               "native mask not" & Raw'Image);
            Check
              (Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Mask_And
                    (Mask, Flyology_SIMD.Backends.Native.Mask_Not (Mask))) = 0
               and then Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Mask_Or
                    (Mask, Flyology_SIMD.Backends.Native.Mask_Not (Mask))) =
                   Interfaces.Unsigned_16'Last
               and then Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Mask_Xor
                    (Mask, Flyology_SIMD.Backends.Native.Mask_Not (Mask))) =
                   Interfaces.Unsigned_16'Last,
               "native mask algebra" & Raw'Image);
            Check (Any_True (Mask) = (Raw /= 0), "mask any" & Raw'Image);
            Check (None_True (Mask) = (Raw = 0), "mask none" & Raw'Image);
            Check (All_True (Mask) = (Raw = 65_535), "mask all" & Raw'Image);
            Check
              (Flyology_SIMD.Backends.Native.Any_True (Mask) = (Raw /= 0)
               and then Flyology_SIMD.Backends.Native.None_True (Mask) = (Raw = 0)
               and then Flyology_SIMD.Backends.Native.All_True (Mask) =
                 (Raw = 65_535),
               "native mask reductions" & Raw'Image);
            Check
              (Same (Compress (Value, Mask), Reference_Compress (Value, Mask))
               and then Same
                 (Flyology_SIMD.Backends.Scalar.Compress (Value, Mask),
                  Reference_Compress (Value, Mask))
               and then Same
                 (Flyology_SIMD.Backends.Native.Compress (Value, Mask),
                  Reference_Compress (Value, Mask)),
               "compression semantics" & Raw'Image);
            Check
              (Same (Expand (Value, Mask), Reference_Expand (Value, Mask))
               and then Same
                 (Flyology_SIMD.Backends.Scalar.Expand (Value, Mask),
                  Reference_Expand (Value, Mask))
               and then Same
                 (Flyology_SIMD.Backends.Native.Expand (Value, Mask),
                  Reference_Expand (Value, Mask)),
               "expansion semantics" & Raw'Image);
            declare
               Expected : Lane_Values_8x16;
            begin
               for Lane in Lane_Index_8x16 loop
                  Expected (Lane) :=
                    (if (Raw / 2 ** Lane) mod 2 = 1
                     then Value_Lanes (Lane)
                     else Other_Lanes (Lane));
               end loop;
               Check_Value_Oracle
                 (Select_Value (Mask, Value, Other),
                  Flyology_SIMD.Backends.Scalar.Select_Value
                    (Mask, Value, Other),
                  Flyology_SIMD.Backends.Native.Select_Value
                    (Mask, Value, Other),
                  Expected,
                  "exhaustive independent selection semantics" & Raw'Image);
            end;
         end;
      end loop;
   end Test_All_Masks;

   procedure Test_Memory is
      Data : Byte_Array (0 .. 95) := [others => 16#CC#];
      for Data'Alignment use 16;
      Value : constant U8x16 := From_Lanes
        ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
      Private_Storage : Byte_Array (0 .. 16) := [others => 0]
        with Alignment => 16;
      Misaligned_Value : U8x16;
      for Misaligned_Value'Address use Private_Storage (1)'Address;
      Aligned_Start : Natural := 0;
      High_Data : constant Byte_Array (Natural'Last - 3 .. Natural'Last) :=
        [others => 0];
   begin
      Check (Has_Extent (Data, Natural'Last, 0)
        and then Has_Extent (Data, Data'First, Data'Length)
        and then Has_Extent (Data, Data'Last, 1)
        and then not Has_Extent (Data, Data'Last, 2)
        and then not Has_Extent (Data, Data'Last + 1, 1)
        and then Has_Extent (High_Data, High_Data'First, High_Data'Length)
        and then Has_Extent (High_Data, High_Data'Last, 1)
        and then not Has_Extent (High_Data, High_Data'Last, 2),
        "byte extent boundaries");
      while not Is_Aligned_16 (Data, Aligned_Start) loop
         Aligned_Start := Aligned_Start + 1;
      end loop;
      Store_Aligned (Data, Aligned_Start, Value);
      Check (Same (Load_Aligned (Data, Aligned_Start), Value), "aligned memory");
      Misaligned_Value := Value;
      Flyology_SIMD.Backends.Native.Store_Aligned
        (Data, Aligned_Start, Misaligned_Value);
      Check (Same (Flyology_SIMD.Backends.Native.Load_Aligned
                     (Data, Aligned_Start), Value),
             "aligned memory does not assume private vector alignment");
      Store (Data, Aligned_Start, Value);
      Check (Same (Load (Data, Aligned_Start), Value), "ordinary full memory");
      Store_Unaligned (Data, Aligned_Start + 1, Value);
      Check (Same (Load_Unaligned (Data, Aligned_Start + 1), Value),
             "deliberately unaligned memory");

      for Backend in Natural range 0 .. 2 loop
         Data := [others => 16#CC#];
         case Backend is
            when 0 => Store (Data, Aligned_Start, Value);
            when 1 => Flyology_SIMD.Backends.Scalar.Store
              (Data, Aligned_Start, Value);
            when 2 => Flyology_SIMD.Backends.Native.Store
              (Data, Aligned_Start, Value);
         end case;
         for Offset in Data'Range loop
            Check
              (Data (Offset) =
                 (if Offset in Aligned_Start .. Aligned_Start + 15
                  then U8 (Offset - Aligned_Start) else 16#CC#),
               "independent U8 ordinary store" & Backend'Image & Offset'Image);
         end loop;
         declare
            Loaded : constant U8x16 :=
              (case Backend is
                 when 0 => Load (Data, Aligned_Start),
                 when 1 => Flyology_SIMD.Backends.Scalar.Load
                   (Data, Aligned_Start),
                 when 2 => Flyology_SIMD.Backends.Native.Load
                   (Data, Aligned_Start));
         begin
            Check (To_Lanes (Loaded) = To_Lanes (Value),
                   "independent U8 ordinary load" & Backend'Image);
         end;

         Data := [others => 16#CC#];
         case Backend is
            when 0 => Store_Unaligned (Data, Aligned_Start + 1, Value);
            when 1 => Flyology_SIMD.Backends.Scalar.Store_Unaligned
              (Data, Aligned_Start + 1, Value);
            when 2 => Flyology_SIMD.Backends.Native.Store_Unaligned
              (Data, Aligned_Start + 1, Value);
         end case;
         for Offset in Data'Range loop
            Check
              (Data (Offset) =
                 (if Offset in Aligned_Start + 1 .. Aligned_Start + 16
                  then U8 (Offset - Aligned_Start - 1) else 16#CC#),
               "independent U8 unaligned store" & Backend'Image & Offset'Image);
         end loop;
         declare
            Loaded : constant U8x16 :=
              (case Backend is
                 when 0 => Load_Unaligned (Data, Aligned_Start + 1),
                 when 1 => Flyology_SIMD.Backends.Scalar.Load_Unaligned
                   (Data, Aligned_Start + 1),
                 when 2 => Flyology_SIMD.Backends.Native.Load_Unaligned
                   (Data, Aligned_Start + 1));
         begin
            Check (To_Lanes (Loaded) = To_Lanes (Value),
                   "independent U8 unaligned load" & Backend'Image);
         end;

         Data := [others => 16#CC#];
         case Backend is
            when 0 => Store_Aligned (Data, Aligned_Start, Value);
            when 1 => Flyology_SIMD.Backends.Scalar.Store_Aligned
              (Data, Aligned_Start, Value);
            when 2 => Flyology_SIMD.Backends.Native.Store_Aligned
              (Data, Aligned_Start, Value);
         end case;
         for Offset in Data'Range loop
            Check
              (Data (Offset) =
                 (if Offset in Aligned_Start .. Aligned_Start + 15
                  then U8 (Offset - Aligned_Start) else 16#CC#),
               "independent U8 aligned store" & Backend'Image & Offset'Image);
         end loop;
         declare
            Loaded : constant U8x16 :=
              (case Backend is
                 when 0 => Load_Aligned (Data, Aligned_Start),
                 when 1 => Flyology_SIMD.Backends.Scalar.Load_Aligned
                   (Data, Aligned_Start),
                 when 2 => Flyology_SIMD.Backends.Native.Load_Aligned
                   (Data, Aligned_Start));
         begin
            Check (To_Lanes (Loaded) = To_Lanes (Value),
                   "independent U8 aligned load" & Backend'Image);
         end;
      end loop;

      for Iteration in 1 .. 250 loop
         declare
            Lanes : constant Lane_Values_8x16 := Random_Lanes;
            Random_Value : constant U8x16 := From_Lanes (Lanes);
         begin
            for Backend in Natural range 0 .. 2 loop
               Data := [others => 16#CC#];
               case Backend is
                  when 0 => Store (Data, Aligned_Start, Random_Value);
                  when 1 => Flyology_SIMD.Backends.Scalar.Store
                    (Data, Aligned_Start, Random_Value);
                  when 2 => Flyology_SIMD.Backends.Native.Store
                    (Data, Aligned_Start, Random_Value);
               end case;
               for Offset in Data'Range loop
                  Check
                    (Data (Offset) =
                       (if Offset in Aligned_Start .. Aligned_Start + 15
                        then Lanes (Lane_Index_8x16
                          (Offset - Aligned_Start)) else 16#CC#),
                     "random independent U8 ordinary store" &
                       Iteration'Image & Backend'Image & Offset'Image);
               end loop;
               declare
                  Loaded : constant U8x16 :=
                    (case Backend is
                       when 0 => Load (Data, Aligned_Start),
                       when 1 => Flyology_SIMD.Backends.Scalar.Load
                         (Data, Aligned_Start),
                       when 2 => Flyology_SIMD.Backends.Native.Load
                         (Data, Aligned_Start));
               begin
                  Check (To_Lanes (Loaded) = Lanes,
                         "random independent U8 ordinary load" &
                           Iteration'Image & Backend'Image);
               end;

               Data := [others => 16#CC#];
               case Backend is
                  when 0 => Store_Unaligned
                    (Data, Aligned_Start + 1, Random_Value);
                  when 1 => Flyology_SIMD.Backends.Scalar.Store_Unaligned
                    (Data, Aligned_Start + 1, Random_Value);
                  when 2 => Flyology_SIMD.Backends.Native.Store_Unaligned
                    (Data, Aligned_Start + 1, Random_Value);
               end case;
               for Offset in Data'Range loop
                  Check
                    (Data (Offset) =
                       (if Offset in Aligned_Start + 1 .. Aligned_Start + 16
                        then Lanes (Lane_Index_8x16
                          (Offset - Aligned_Start - 1)) else 16#CC#),
                     "random independent U8 unaligned store" &
                       Iteration'Image & Backend'Image & Offset'Image);
               end loop;
               declare
                  Loaded : constant U8x16 :=
                    (case Backend is
                       when 0 => Load_Unaligned (Data, Aligned_Start + 1),
                       when 1 => Flyology_SIMD.Backends.Scalar.Load_Unaligned
                         (Data, Aligned_Start + 1),
                       when 2 => Flyology_SIMD.Backends.Native.Load_Unaligned
                         (Data, Aligned_Start + 1));
               begin
                  Check (To_Lanes (Loaded) = Lanes,
                         "random independent U8 unaligned load" &
                           Iteration'Image & Backend'Image);
               end;

               Data := [others => 16#CC#];
               case Backend is
                  when 0 => Store_Aligned
                    (Data, Aligned_Start, Random_Value);
                  when 1 => Flyology_SIMD.Backends.Scalar.Store_Aligned
                    (Data, Aligned_Start, Random_Value);
                  when 2 => Flyology_SIMD.Backends.Native.Store_Aligned
                    (Data, Aligned_Start, Random_Value);
               end case;
               for Offset in Data'Range loop
                  Check
                    (Data (Offset) =
                       (if Offset in Aligned_Start .. Aligned_Start + 15
                        then Lanes (Lane_Index_8x16
                          (Offset - Aligned_Start)) else 16#CC#),
                     "random independent U8 aligned store" &
                       Iteration'Image & Backend'Image & Offset'Image);
               end loop;
               declare
                  Loaded : constant U8x16 :=
                    (case Backend is
                       when 0 => Load_Aligned (Data, Aligned_Start),
                       when 1 => Flyology_SIMD.Backends.Scalar.Load_Aligned
                         (Data, Aligned_Start),
                       when 2 => Flyology_SIMD.Backends.Native.Load_Aligned
                         (Data, Aligned_Start));
               begin
                  Check (To_Lanes (Loaded) = Lanes,
                         "random independent U8 aligned load" &
                           Iteration'Image & Backend'Image);
               end;
            end loop;
         end;
      end loop;

      for Count in Lane_Count_8x16 loop
         Data := [others => 16#CC#];
         Store_Partial (Data, 17, Count, Value);
         for Offset in Data'Range loop
            if Count > 0 and then Offset in 17 .. 17 + Count - 1 then
               Check (Data (Offset) = U8 (Offset - 17),
                      "partial store content" & Count'Image);
            else
               Check (Data (Offset) = 16#CC#,
                      "partial store boundary" & Count'Image);
            end if;
         end loop;
         Check (Same
                  (Load_Partial (Data, 17, Count),
                   From_Lanes
                     ([for Lane in Lane_Index_8x16 =>
                        (if Lane < Count then U8 (Lane) else 0)])),
                "partial load zero fill" & Count'Image);
      end loop;
      Store_Partial (Data, Natural'Last, 0, Value);
      Check (Same (Load_Partial (Data, Natural'Last, 0), Zero),
             "zero partial operation touches no address");
   end Test_Memory;

   procedure Test_Native_Differential is
   begin
      for Iteration in 0 .. 2_000 loop
         declare
            A_Lanes : constant Lane_Values_8x16 :=
              (if Iteration = 0
               then [0, 1, 127, 128, 254, 255, 16#AA#, 16#55#,
                     0, 1, 127, 128, 254, 255, 16#F0#, 16#0F#]
               else Random_Lanes);
            A : constant U8x16 := From_Lanes (A_Lanes);
            B_Lanes : constant Lane_Values_8x16 :=
              (if Iteration = 0
               then [0, 255, 1, 128, 2, 1, 16#55#, 16#AA#,
                     255, 0, 128, 127, 1, 254, 16#0F#, 16#F0#]
               else Random_Lanes);
            B : constant U8x16 := From_Lanes (B_Lanes);
            Buffer : Byte_Array (0 .. 32) := [others => 0];
            Reference_Buffer : Byte_Array (0 .. 32) := [others => 0];
            Count : constant Lane_Count_8x16 := Iteration mod 17;
            Shift : constant Natural := Iteration mod 13;
            Slide : constant Natural := Iteration mod 19;
            Selectors : constant Lane_Selectors_8x16 := Random_Selectors;
            Map : constant Lane_Map_8x16 := Make_Lane_Map (Selectors);
            Two_Source_Map : constant Two_Source_Lane_Map_8x16 :=
              Make_Two_Source_Lane_Map
                ([for Lane in Lane_Index_8x16 =>
                   (if (Iteration + Lane) mod 2 = 0
                    then Select_Left_Lane
                      (Lane_Index_8x16
                         ((Iteration * 3 + Lane * 5) mod 16))
                    else Select_Right_Lane
                      (Lane_Index_8x16
                         ((Iteration * 3 + Lane * 5) mod 16)))]);
            Expected_Add : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane) + B_Lanes (Lane)];
            Expected_Subtract : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane) - B_Lanes (Lane)];
            Expected_Multiply : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane) * B_Lanes (Lane)];
            Expected_Add_Saturate : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 Reference_Add_Saturate (A_Lanes (Lane), B_Lanes (Lane))];
            Expected_Subtract_Saturate : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 Reference_Subtract_Saturate
                   (A_Lanes (Lane), B_Lanes (Lane))];
            Expected_And : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane) and B_Lanes (Lane)];
            Expected_Or : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane) or B_Lanes (Lane)];
            Expected_Xor : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane) xor B_Lanes (Lane)];
            Expected_Not : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 => not A_Lanes (Lane)];
            Expected_Min : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 U8'Min (A_Lanes (Lane), B_Lanes (Lane))];
            Expected_Max : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 U8'Max (A_Lanes (Lane), B_Lanes (Lane))];
            Expected_Reverse : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 A_Lanes (Lane_Index_8x16'Last - Lane)];
            Expected_Interleave_Low : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 (if Lane mod 2 = 0
                  then A_Lanes (Lane / 2)
                  else B_Lanes (Lane / 2))];
            Expected_Interleave_High : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 (if Lane mod 2 = 0
                  then A_Lanes (8 + Lane / 2)
                  else B_Lanes (8 + Lane / 2))];
            Expected_Deinterleave_Even : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 (if Lane < 8
                  then A_Lanes (2 * Lane)
                  else B_Lanes (2 * (Lane - 8)))];
            Expected_Deinterleave_Odd : constant Lane_Values_8x16 :=
              [for Lane in Lane_Index_8x16 =>
                 (if Lane < 8
                  then A_Lanes (2 * Lane + 1)
                  else B_Lanes (2 * (Lane - 8) + 1))];
         begin
            --  Iteration zero supplies explicit wrap, saturation, equality,
            --  unsigned-ordering, and high-bit boundaries.  The remaining
            --  2,000 iterations use full-width deterministic byte values.
            for Lane in Lane_Index_8x16 loop
               Check
                 (Flyology_SIMD.Backends.Native.Extract
                    (U8x16'(Flyology_SIMD.Backends.Native.Zero), Lane) = 0,
                  "independent native zero" & Iteration'Image & Lane'Image);
               Check
                 (Flyology_SIMD.Backends.Native.Extract
                    (Flyology_SIMD.Backends.Native.Splat
                       (U8 (Iteration mod 256)),
                     Lane) = U8 (Iteration mod 256),
                  "independent native splat" & Iteration'Image & Lane'Image);
            end loop;
            declare
               Native_From : constant U8x16 :=
                 Flyology_SIMD.Backends.Native.From_Lanes (A_Lanes);
               Native_To : constant Lane_Values_8x16 :=
                 Flyology_SIMD.Backends.Native.To_Lanes (A);
               Replaced_Lane : constant Lane_Index_8x16 := Count mod 16;
               Replacement : constant U8 := U8 (Iteration mod 256);
               Native_Replaced : constant U8x16 :=
                 Flyology_SIMD.Backends.Native.Replace
                   (A, Replaced_Lane, Replacement);
            begin
               for Lane in Lane_Index_8x16 loop
                  Check
                    (Flyology_SIMD.Backends.Native.Extract
                       (Native_From, Lane) = A_Lanes (Lane)
                     and then Native_To (Lane) = A_Lanes (Lane)
                     and then Flyology_SIMD.Backends.Native.Extract
                       (A, Lane) = A_Lanes (Lane),
                     "independent native lane access" &
                       Iteration'Image & Lane'Image);
                  Check
                    (Flyology_SIMD.Backends.Native.Extract
                       (Native_Replaced, Lane) =
                         (if Lane = Replaced_Lane
                          then Replacement
                          else A_Lanes (Lane)),
                     "independent native replace" &
                       Iteration'Image & Lane'Image);
               end loop;
            end;
            Check_Value_Oracle
              (Add_Wrap (A, B),
               Flyology_SIMD.Backends.Scalar.Add_Wrap (A, B),
               Flyology_SIMD.Backends.Native.Add_Wrap (A, B),
               Expected_Add,
               "independent wrapping-add oracle" & Iteration'Image);
            Check_Value_Oracle
              (Subtract_Wrap (A, B),
               Flyology_SIMD.Backends.Scalar.Subtract_Wrap (A, B),
               Flyology_SIMD.Backends.Native.Subtract_Wrap (A, B),
               Expected_Subtract,
               "independent wrapping-subtract oracle" & Iteration'Image);
            Check_Value_Oracle
              (Multiply_Wrap (A, B),
               Flyology_SIMD.Backends.Scalar.Multiply_Wrap (A, B),
               Flyology_SIMD.Backends.Native.Multiply_Wrap (A, B),
               Expected_Multiply,
               "independent wrapping-multiply oracle" & Iteration'Image);
            Check_Value_Oracle
              (Add_Saturate (A, B),
               Flyology_SIMD.Backends.Scalar.Add_Saturate (A, B),
               Flyology_SIMD.Backends.Native.Add_Saturate (A, B),
               Expected_Add_Saturate,
               "independent saturating-add oracle" & Iteration'Image);
            Check_Value_Oracle
              (Subtract_Saturate (A, B),
               Flyology_SIMD.Backends.Scalar.Subtract_Saturate (A, B),
               Flyology_SIMD.Backends.Native.Subtract_Saturate (A, B),
               Expected_Subtract_Saturate,
               "independent saturating-subtract oracle" & Iteration'Image);
            Check_Value_Oracle
              (Bitwise_And (A, B),
               Flyology_SIMD.Backends.Scalar.Bitwise_And (A, B),
               Flyology_SIMD.Backends.Native.Bitwise_And (A, B),
               Expected_And,
               "independent bitwise-and oracle" & Iteration'Image);
            Check_Value_Oracle
              (Bitwise_Or (A, B),
               Flyology_SIMD.Backends.Scalar.Bitwise_Or (A, B),
               Flyology_SIMD.Backends.Native.Bitwise_Or (A, B),
               Expected_Or,
               "independent bitwise-or oracle" & Iteration'Image);
            Check_Value_Oracle
              (Bitwise_Xor (A, B),
               Flyology_SIMD.Backends.Scalar.Bitwise_Xor (A, B),
               Flyology_SIMD.Backends.Native.Bitwise_Xor (A, B),
               Expected_Xor,
               "independent bitwise-xor oracle" & Iteration'Image);
            Check_Value_Oracle
              (Bitwise_Not (A),
               Flyology_SIMD.Backends.Scalar.Bitwise_Not (A),
               Flyology_SIMD.Backends.Native.Bitwise_Not (A),
               Expected_Not,
               "independent bitwise-not oracle" & Iteration'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Table_Lookup (A, B),
                  Table_Lookup (A, B)),
               "native table lookup" & Iteration'Image);
            for Lane in Lane_Index_8x16 loop
               Check
                 (Extract (Table_Lookup (A, B), Lane) =
                    (if Extract (B, Lane) < 16
                     then Extract (A, Natural (Extract (B, Lane)))
                     else 0),
                  "scalar table lookup lane" & Lane'Image);
            end loop;
            Check
              (Same (Shift_Left_Logical (A, Shift),
                     Reference_Shift_Left_Logical (A, Shift))
               and then Same
                 (Flyology_SIMD.Backends.Native.Shift_Left_Logical (A, Shift),
                  Reference_Shift_Left_Logical (A, Shift)),
               "native left shift" & Iteration'Image);
            Check
              (Same (Shift_Right_Logical (A, Shift),
                     Reference_Shift_Right_Logical (A, Shift))
               and then Same
                 (Flyology_SIMD.Backends.Native.Shift_Right_Logical (A, Shift),
                  Reference_Shift_Right_Logical (A, Shift)),
               "native right shift" & Iteration'Image);
            Check_Mask_Oracle
              (Equal (A, B),
               Flyology_SIMD.Backends.Scalar.Equal (A, B),
               Flyology_SIMD.Backends.Native.Equal (A, B),
               Reference_Comparison (A_Lanes, B_Lanes, Compare_Equal),
               "independent equality oracle" & Iteration'Image);
            Check_Mask_Oracle
              (Less_Than (A, B),
               Flyology_SIMD.Backends.Scalar.Less_Than (A, B),
               Flyology_SIMD.Backends.Native.Less_Than (A, B),
               Reference_Comparison (A_Lanes, B_Lanes, Compare_Less),
               "independent less-than oracle" & Iteration'Image);
            Check_Mask_Oracle
              (Less_Equal (A, B),
               Flyology_SIMD.Backends.Scalar.Less_Equal (A, B),
               Flyology_SIMD.Backends.Native.Less_Equal (A, B),
               Reference_Comparison (A_Lanes, B_Lanes, Compare_Less_Equal),
               "independent less-equal oracle" & Iteration'Image);
            Check_Mask_Oracle
              (Greater_Than (A, B),
               Flyology_SIMD.Backends.Scalar.Greater_Than (A, B),
               Flyology_SIMD.Backends.Native.Greater_Than (A, B),
               Reference_Comparison (A_Lanes, B_Lanes, Compare_Greater),
               "independent greater-than oracle" & Iteration'Image);
            Check_Mask_Oracle
              (Greater_Equal (A, B),
               Flyology_SIMD.Backends.Scalar.Greater_Equal (A, B),
               Flyology_SIMD.Backends.Native.Greater_Equal (A, B),
               Reference_Comparison
                 (A_Lanes, B_Lanes, Compare_Greater_Equal),
               "independent greater-equal oracle" & Iteration'Image);
            Check_Value_Oracle
              (Min (A, B),
               Flyology_SIMD.Backends.Scalar.Min (A, B),
               Flyology_SIMD.Backends.Native.Min (A, B),
               Expected_Min,
               "independent minimum oracle" & Iteration'Image);
            Check_Value_Oracle
              (Max (A, B),
               Flyology_SIMD.Backends.Scalar.Max (A, B),
               Flyology_SIMD.Backends.Native.Max (A, B),
               Expected_Max,
               "independent maximum oracle" & Iteration'Image);
            Check_Value_Oracle
              (Reverse_Bytes (A),
               Flyology_SIMD.Backends.Scalar.Reverse_Bytes (A),
               Flyology_SIMD.Backends.Native.Reverse_Bytes (A),
               Expected_Reverse,
               "independent byte-reversal oracle" & Iteration'Image);
            Check_Value_Oracle
              (Reverse_Lanes (A),
               Flyology_SIMD.Backends.Scalar.Reverse_Lanes (A),
               Flyology_SIMD.Backends.Native.Reverse_Lanes (A),
               Expected_Reverse,
               "independent lane-reversal oracle" & Iteration'Image);
            Check_Value_Oracle
              (Interleave_Low (A, B),
               Flyology_SIMD.Backends.Scalar.Interleave_Low (A, B),
               Flyology_SIMD.Backends.Native.Interleave_Low (A, B),
               Expected_Interleave_Low,
               "independent low-interleave oracle" & Iteration'Image);
            Check_Value_Oracle
              (Interleave_High (A, B),
               Flyology_SIMD.Backends.Scalar.Interleave_High (A, B),
               Flyology_SIMD.Backends.Native.Interleave_High (A, B),
               Expected_Interleave_High,
               "independent high-interleave oracle" & Iteration'Image);
            Check_Value_Oracle
              (Deinterleave_Even (A, B),
               Flyology_SIMD.Backends.Scalar.Deinterleave_Even (A, B),
               Flyology_SIMD.Backends.Native.Deinterleave_Even (A, B),
               Expected_Deinterleave_Even,
               "independent even-deinterleave oracle" & Iteration'Image);
            Check_Value_Oracle
              (Deinterleave_Odd (A, B),
               Flyology_SIMD.Backends.Scalar.Deinterleave_Odd (A, B),
               Flyology_SIMD.Backends.Native.Deinterleave_Odd (A, B),
               Expected_Deinterleave_Odd,
               "independent odd-deinterleave oracle" & Iteration'Image);
            Check
              (Horizontal_Sum (A) = Reference_Horizontal_Sum (A_Lanes)
               and then Flyology_SIMD.Backends.Native.Horizontal_Sum (A) =
                 Reference_Horizontal_Sum (A_Lanes),
               "horizontal sum oracle" & Iteration'Image);
            Check
              (Reduce_Add_Wrap (A) = Reference_Reduce_Add (A_Lanes)
               and then Flyology_SIMD.Backends.Scalar.Reduce_Add_Wrap (A) =
                 Reference_Reduce_Add (A_Lanes)
               and then Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (A) =
                 Reference_Reduce_Add (A_Lanes)
               and then Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
               and then Flyology_SIMD.Backends.Scalar.Reduce_Min (A) =
                 Reference_Reduce_Min (A_Lanes)
               and then Flyology_SIMD.Backends.Native.Reduce_Min (A) =
                 Reference_Reduce_Min (A_Lanes)
               and then Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
               and then Flyology_SIMD.Backends.Scalar.Reduce_Max (A) =
                 Reference_Reduce_Max (A_Lanes)
               and then Flyology_SIMD.Backends.Native.Reduce_Max (A) =
                 Reference_Reduce_Max (A_Lanes),
               "independent scalar and native byte reductions" &
                 Iteration'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low
                    (A, Slide),
                  Slide_Lanes_Toward_Low (A, Slide))
               and then Same
                 (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High
                    (A, Slide),
                  Slide_Lanes_Toward_High (A, Slide)),
               "native lane slides" & Iteration'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Permute_Lanes (A, Map),
                  Permute_Lanes (A, Map)),
               "native lane permutation" & Iteration'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Permute_Lanes
                    (A, B, Two_Source_Map),
                  Permute_Lanes (A, B, Two_Source_Map)),
               "native two-source lane permutation" & Iteration'Image);
            for Lane in Lane_Index_8x16 loop
               Check
                 (Extract
                    (Flyology_SIMD.Backends.Native.Table_Lookup (A, B), Lane) =
                    (if Extract (B, Lane) <= 15
                     then Extract (A, Lane_Index_8x16 (Extract (B, Lane)))
                     else 0),
                  "native independent table lookup lane" & Lane'Image);
               Check
                 (Extract (Permute_Lanes (A, Map), Lane) =
                    Extract (A, Selectors (Lane))
                  and then Flyology_SIMD.Backends.Native.Extract
                    (Flyology_SIMD.Backends.Native.Permute_Lanes (A, Map),
                     Lane) = Extract (A, Selectors (Lane)),
                  "randomized independent scalar and native lane permutation" &
                    Lane'Image);
               Check
                 (Extract (Permute_Lanes (A, B, Two_Source_Map), Lane) =
                    Extract
                      ((if (Iteration + Lane) mod 2 = 0
                        then A else B),
                       Lane_Index_8x16
                         ((Iteration * 3 + Lane * 5) mod 16))
                  and then Flyology_SIMD.Backends.Native.Extract
                    (Flyology_SIMD.Backends.Native.Permute_Lanes
                       (A, B, Two_Source_Map),
                     Lane) =
                    Extract
                      ((if (Iteration + Lane) mod 2 = 0
                        then A else B),
                       Lane_Index_8x16
                         ((Iteration * 3 + Lane * 5) mod 16)),
                  "varied independent scalar and native two-source lane permutation" &
                    Lane'Image);
               Check (Extract (Shift_Left_Logical (A, Shift), Lane) =
                        (if Shift >= 8 then 0
                         else Interfaces.Shift_Left (Extract (A, Lane), Shift)),
                      "scalar left shift" & Shift'Image);
               Check (Extract (Shift_Right_Logical (A, Shift), Lane) =
                        (if Shift >= 8 then 0
                         else Interfaces.Shift_Right (Extract (A, Lane), Shift)),
                      "scalar right shift" & Shift'Image);
               Check (Test (Less_Than (A, B), Lane) =
                        (Extract (A, Lane) < Extract (B, Lane)),
                      "scalar comparison lane" & Lane'Image);
               Check
                 (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) =
                    (if Slide < 16 and then Lane < 16 - Slide
                     then Extract (A, Lane_Index_8x16 (Lane + Slide))
                     else 0)
                  and then
                    Extract (Slide_Lanes_Toward_High (A, Slide), Lane) =
                      (if Slide < 16 and then Lane >= Slide
                       then Extract (A, Lane_Index_8x16 (Lane - Slide))
                       else 0)
                  and then
                    Extract
                      (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low
                         (A, Slide), Lane) =
                      (if Slide < 16 and then Lane < 16 - Slide
                       then Extract (A, Lane_Index_8x16 (Lane + Slide))
                       else 0)
                  and then
                    Extract
                      (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High
                         (A, Slide), Lane) =
                      (if Slide < 16 and then Lane >= Slide
                       then Extract (A, Lane_Index_8x16 (Lane - Slide))
                       else 0),
                  "randomized independent lane slides" & Lane'Image);
            end loop;
            Store_Unaligned (Buffer, 1, A);
            Check
              (Same (Flyology_SIMD.Backends.Native.Load (Buffer, 1), A),
               "native ordinary load" & Iteration'Image);
            Check (Same
                     (Flyology_SIMD.Backends.Native.Load_Unaligned (Buffer, 1), A),
                   "native unaligned load" & Iteration'Image);
            Flyology_SIMD.Backends.Native.Store_Unaligned
              (Buffer, 1, B);
            Store_Unaligned (Reference_Buffer, 1, B);
            Check (Buffer = Reference_Buffer,
                   "native unaligned store" & Iteration'Image);
            Buffer := [others => 0];
            Reference_Buffer := [others => 0];
            Flyology_SIMD.Backends.Native.Store (Buffer, 1, B);
            Store (Reference_Buffer, 1, B);
            Check (Buffer = Reference_Buffer,
                   "native ordinary store" & Iteration'Image);
            Buffer := [others => 16#CC#];
            Reference_Buffer := [others => 16#CC#];
            Flyology_SIMD.Backends.Native.Store_Partial
              (Buffer, 3, Count, A);
            Store_Partial (Reference_Buffer, 3, Count, A);
            Check (Buffer = Reference_Buffer,
                   "native partial store" & Iteration'Image);
            declare
               Loaded : constant U8x16 :=
                 Flyology_SIMD.Backends.Native.Load_Partial
                   (Buffer, 3, Count);
            begin
               for Lane in Lane_Index_8x16 loop
                  Check
                    (Extract (Loaded, Lane) =
                       (if Lane < Count then Extract (A, Lane) else 0),
                     "independent native partial load" & Iteration'Image &
                       Lane'Image);
               end loop;
            end;
         end;
      end loop;
      declare
         Maximum_Index_Data : Byte_Array
           (Natural'Last .. Natural'Last) := [others => 1];
      begin
         Check
           (Same
              (Flyology_SIMD.Backends.Native.Load_Partial
                 (Maximum_Index_Data, Natural'Last, 0),
               Zero),
            "native maximum-index zero-count partial load");
         Flyology_SIMD.Backends.Native.Store_Partial
           (Maximum_Index_Data, Natural'Last, 0, Zero);
         Check
           (Maximum_Index_Data (Natural'Last) = 1,
            "native maximum-index zero-count partial store");
      end;
   end Test_Native_Differential;

   procedure Test_Algorithms_For_Length (Length : Natural) is
      Data : Byte_Array (1 .. Length);
      Reference_Find, Native_Find, Runtime_Find : Algorithms.Search_Result;
      Needles : constant Byte_Array := [0, 42, 128, 255];
      Reference_Of : Algorithms.Search_Result := (Found => False, Index => 0);
   begin
      for Index in Data'Range loop
         Data (Index) := Next_U8;
      end loop;
      if Length > 0 then
         Data (Data'Last) := 42;
      end if;
      Reference_Find := Algorithms.Scalar.Find_First (Data, 42);
      Native_Find := Algorithms.Native.Find_First (Data, 42);
      Runtime_Find := Algorithms.Runtime.Find_First (Data, 42);
      Check (Native_Find = Reference_Find, "native find length" & Length'Image);
      Check (Runtime_Find = Reference_Find, "runtime find length" & Length'Image);
      for Index in Data'Range loop
         for Needle of Needles loop
            if Data (Index) = Needle then
               Reference_Of := (Found => True, Index => Index);
               exit;
            end if;
         end loop;
         exit when Reference_Of.Found;
      end loop;
      Check
        (Algorithms.Scalar.Find_First_Of (Data, Needles) = Reference_Of,
         "scalar find-first-of length" & Length'Image);
      Check
        (Algorithms.Native.Find_First_Of (Data, Needles) = Reference_Of,
         "native find-first-of length" & Length'Image);
      Check
        (Algorithms.Runtime.Find_First_Of (Data, Needles) = Reference_Of,
         "runtime find-first-of length" & Length'Image);
      Check
        (Algorithms.Runtime.Find_First_Of
           (Data, Needles, Features.Scalar) = Reference_Of,
         "forced scalar find-first-of length" & Length'Image);
      Check (Algorithms.Native.Count (Data, 42) = Algorithms.Scalar.Count (Data, 42),
             "native count length" & Length'Image);
      Check (Algorithms.Runtime.Count (Data, 42) = Algorithms.Scalar.Count (Data, 42),
             "runtime count length" & Length'Image);
      Check (Algorithms.Native.Is_ASCII (Data) = Algorithms.Scalar.Is_ASCII (Data),
             "native ASCII length" & Length'Image);
      Check (Algorithms.Runtime.Is_ASCII (Data) = Algorithms.Scalar.Is_ASCII (Data),
             "runtime ASCII length" & Length'Image);
      if Features.Available (Features.AVX2) then
         Check (Algorithms.AVX2.Find_First (Data, 42) = Reference_Find,
                "AVX2 find length" & Length'Image);
         Check
           (Algorithms.AVX2.Find_First_Of (Data, Needles) = Reference_Of,
            "AVX2 find-first-of length" & Length'Image);
         Check
           (Algorithms.Runtime.Find_First_Of
              (Data, Needles, Features.AVX2) = Reference_Of,
            "runtime AVX2 find-first-of length" & Length'Image);
         Check (Algorithms.AVX2.Count (Data, 42) = Algorithms.Scalar.Count (Data, 42),
                "AVX2 count length" & Length'Image);
         Check (Algorithms.AVX2.Is_ASCII (Data) = Algorithms.Scalar.Is_ASCII (Data),
                "AVX2 ASCII length" & Length'Image);
      end if;
   end Test_Algorithms_For_Length;

   procedure Test_Algorithms is
      Lane_Data : Byte_Array (1 .. 64) := [others => 0];
      Empty_Data : constant Byte_Array (1 .. 0) := [];
      Empty_Set : constant Byte_Array (1 .. 0) := [];
      Four_Set : constant Byte_Array := [9, 10, 13, 32];
      Duplicate_Set : constant Byte_Array := [32, 9, 32, 10];
      Large_Set : constant Byte_Array := [1, 3, 5, 7, 9, 11];
   begin
      for Length in Natural range 0 .. 80 loop
         Test_Algorithms_For_Length (Length);
      end loop;
      Test_Algorithms_For_Length (4_096);
      Check
        (Algorithms.Scalar.Find_First_Of (Empty_Data, Four_Set) =
           (Found => False, Index => 0),
         "find-first-of empty data");
      Check
        (Algorithms.Native.Find_First_Of (Lane_Data, Empty_Set) =
           (Found => False, Index => 0),
         "find-first-of empty set");
      Lane_Data := [others => 65];
      Lane_Data (37) := 32;
      Check
        (Algorithms.Native.Find_First_Of (Lane_Data, Duplicate_Set) =
           (Found => True, Index => 37),
         "find-first-of duplicate set");
      Lane_Data := [others => 2];
      Lane_Data (51) := 11;
      Check
        (Algorithms.Native.Find_First_Of (Lane_Data, Large_Set) =
           (Found => True, Index => 51),
         "find-first-of large-set fallback");
      declare
         Offset_Data : Byte_Array (37 .. 196) := [others => 65];
      begin
         for Position in Offset_Data'Range loop
            Offset_Data := [others => 65];
            Offset_Data (Position) := 13;
            Check
              (Algorithms.Scalar.Find_First_Of (Offset_Data, Four_Set) =
                 (Found => True, Index => Position),
               "scalar find-first-of offset" & Position'Image);
            Check
              (Algorithms.Native.Find_First_Of (Offset_Data, Four_Set) =
                 (Found => True, Index => Position),
               "native find-first-of offset" & Position'Image);
            Check
              (Algorithms.Runtime.Find_First_Of (Offset_Data, Four_Set) =
                 (Found => True, Index => Position),
               "runtime find-first-of offset" & Position'Image);
            if Features.Available (Features.AVX2) then
               Check
                 (Algorithms.AVX2.Find_First_Of (Offset_Data, Four_Set) =
                    (Found => True, Index => Position),
                  "AVX2 find-first-of offset" & Position'Image);
            end if;
         end loop;
      end;
      if Features.Available (Features.AVX2) then
         for Lane in Natural range 0 .. 31 loop
            Lane_Data := [others => 0];
            Lane_Data (Lane_Data'First + Lane) := 42;
            Check
              (Algorithms.AVX2.Find_First (Lane_Data, 42) =
                 (Found => True, Index => Lane_Data'First + Lane),
               "AVX2 first-set-bit lane" & Lane'Image);
         end loop;
      end if;
   end Test_Algorithms;

   procedure Test_Unavailable_Rejection is
      Data : constant Byte_Array (1 .. 1) := [1 => 0];
      Result : Natural;
      Search : Algorithms.Search_Result;
   begin
      if not Features.Available (Features.AVX2) then
         begin
            Result := Algorithms.Runtime.Count (Data, 0, Features.AVX2);
            Check (False, "unavailable AVX2 accepted" & Result'Image);
         exception
            when Features.Backend_Unavailable => null;
         end;
         begin
            Result := Algorithms.AVX2.Count (Data, 0);
            Check (False, "direct unavailable AVX2 accepted" & Result'Image);
         exception
            when Features.Backend_Unavailable => null;
         end;
         begin
            Search := Algorithms.Runtime.Find_First_Of
              (Data, Data, Features.AVX2);
            Check (False, "unavailable runtime AVX2 find-first-of accepted" &
                   Search.Index'Image);
         exception
            when Features.Backend_Unavailable => null;
         end;
         begin
            Search := Algorithms.AVX2.Find_First_Of (Data, Data);
            Check (False, "unavailable direct AVX2 find-first-of accepted" &
                   Search.Index'Image);
         exception
            when Features.Backend_Unavailable => null;
         end;
      end if;
   end Test_Unavailable_Rejection;
begin
   Put_Line ("flyology_simd deterministic seed:" & Seed'Image);
   Put_Line ("architecture: " & Features.Architecture_Name &
             "; best backend: " & Features.Name (Features.Best_Available));
   if Ada.Command_Line.Argument_Count > 0
     and then Ada.Command_Line.Argument (1) = "--require-avx2"
   then
      Check (Features.Compiled (Features.AVX2),
             "AVX2 was required but not compiled");
      Check (Features.Available (Features.AVX2),
             "AVX2 was required but is not available");
   end if;
   if Features.Compiled (Features.AVX2) and then not Features.Available (Features.AVX2)
   then
      Put_Line ("SKIP avx2 execution: compiled, but CPU/OS AVX state is unavailable");
   elsif not Features.Compiled (Features.AVX2) then
      Put_Line ("SKIP avx2 execution: backend was not compiled in this configuration");
   end if;
   Test_Core_Semantics;
   Test_All_Table_Indices;
   Test_Lane_Slides;
   Test_All_Masks;
   Test_Memory;
   Test_Native_Differential;
   Test_Algorithms;
   Test_Unavailable_Rejection;
   if Failures = 0 then
      Put_Line ("PASS");
   else
      Put_Line ("FAILURES:" & Failures'Image);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
exception
   when Error : others =>
      Put_Line ("UNCAUGHT: " & Ada.Exceptions.Exception_Information (Error));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end SIMD_Tests;
