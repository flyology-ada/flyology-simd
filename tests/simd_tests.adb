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
      A : constant U8x16 := From_Lanes
        ([0, 1, 2, 3, 16#7F#, 16#80#, 16#FE#, 16#FF#,
          16#AA#, 16#55#, 10, 20, 30, 40, 50, 60]);
      B : constant U8x16 := From_Lanes
        ([0, 2, 1, 3, 1, 16#80#, 2, 1,
          16#55#, 16#AA#, 250, 240, 230, 220, 210, 200]);
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
      Check (To_Bit_Mask (Equal (A, B)) = 16#0029#, "equality lane mask");
      Check (Test (Less_Than (A, B), 1) and not Test (Less_Than (A, B), 2),
             "unsigned ordered comparison");
      Check (Test (Less_Equal (A, B), 0)
             and Test (Greater_Than (A, B), 2)
             and Test (Greater_Equal (A, B), 3),
             "all ordered comparisons");
      Check (Same (Select_Value (Equal (A, B), A, B), B), "select semantics");
      Check (Extract (Min (A, B), 6) = 2 and Extract (Max (A, B), 6) = 254,
             "unsigned min/max");
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
                  else 0),
               "byte slide toward low" & Count'Image & Lane'Image);
            Check
              (Extract (Slide_Lanes_Toward_High (Value, Count), Lane) =
                 (if Count < 16 and then Lane >= Count
                  then Extract (Value, Lane_Index_8x16 (Lane - Count))
                  else 0),
               "byte slide toward high" & Count'Image & Lane'Image);
         end loop;
      end loop;
   end Test_Lane_Slides;

   procedure Test_All_Masks is
      Value : constant U8x16 := From_Lanes
        ([16#80#, 1, 16#FE#, 3, 4, 16#AA#, 6, 7,
          8, 16#55#, 10, 11, 12, 13, 14, 16#FF#]);
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
      for Iteration in 1 .. 2_000 loop
         declare
            A_Lanes : constant Lane_Values_8x16 := Random_Lanes;
            A : constant U8x16 := From_Lanes (A_Lanes);
            B : constant U8x16 := From_Lanes (Random_Lanes);
            M : constant Mask_8x16 := Equal (A, B);
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
         begin
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
            Check (Same (Flyology_SIMD.Backends.Native.Add_Wrap (A, B),
                         Add_Wrap (A, B)), "native add" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Subtract_Wrap (A, B),
                         Subtract_Wrap (A, B)),
                   "native subtract" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Multiply_Wrap (A, B),
                         Multiply_Wrap (A, B)),
                   "native multiply" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Add_Saturate (A, B),
                         Add_Saturate (A, B)), "native saturate" & Iteration'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Subtract_Saturate (A, B),
                  Subtract_Saturate (A, B)),
               "native subtract saturate" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Bitwise_And (A, B),
                         Bitwise_And (A, B)), "native and" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Bitwise_Or (A, B),
                         Bitwise_Or (A, B)), "native or" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Bitwise_Xor (A, B),
                         Bitwise_Xor (A, B)), "native xor" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Bitwise_Not (A),
                         Bitwise_Not (A)), "native not" & Iteration'Image);
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
              (Same
                 (Flyology_SIMD.Backends.Native.Shift_Left_Logical (A, Shift),
                  Shift_Left_Logical (A, Shift)),
               "native left shift" & Iteration'Image);
            Check
              (Same
                 (Flyology_SIMD.Backends.Native.Shift_Right_Logical (A, Shift),
                  Shift_Right_Logical (A, Shift)),
               "native right shift" & Iteration'Image);
            Check (Flyology_SIMD.Backends.Native.To_Bit_Mask
                     (Flyology_SIMD.Backends.Native.Equal (A, B)) =
                   To_Bit_Mask (M), "native compare/mask" & Iteration'Image);
            Check
              (Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Less_Than (A, B)) =
                 To_Bit_Mask (Less_Than (A, B))
               and then Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Less_Equal (A, B)) =
                 To_Bit_Mask (Less_Equal (A, B))
               and then Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Greater_Than (A, B)) =
                 To_Bit_Mask (Greater_Than (A, B))
               and then Flyology_SIMD.Backends.Native.To_Bit_Mask
                 (Flyology_SIMD.Backends.Native.Greater_Equal (A, B)) =
                 To_Bit_Mask (Greater_Equal (A, B)),
               "native ordered comparisons" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Select_Value (M, A, B),
                         Select_Value (M, A, B)), "native select" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Min (A, B), Min (A, B)),
                   "native min" & Iteration'Image);
            Check (Same (Flyology_SIMD.Backends.Native.Max (A, B), Max (A, B)),
                   "native max" & Iteration'Image);
            Check
              (Horizontal_Sum (A) = Reference_Horizontal_Sum (A_Lanes)
               and then Flyology_SIMD.Backends.Native.Horizontal_Sum (A) =
                 Reference_Horizontal_Sum (A_Lanes),
               "horizontal sum oracle" & Iteration'Image);
            Check
              (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (A) =
                 Reduce_Add_Wrap (A)
               and then Flyology_SIMD.Backends.Native.Reduce_Min (A) =
                 Reduce_Min (A)
               and then Flyology_SIMD.Backends.Native.Reduce_Max (A) =
                 Reduce_Max (A),
               "native byte reductions" & Iteration'Image);
            Check
              (Same (Flyology_SIMD.Backends.Native.Reverse_Bytes (A),
                     Reverse_Bytes (A)),
               "native reverse" & Iteration'Image);
            Check
              (Same (Flyology_SIMD.Backends.Native.Interleave_Low (A, B),
                     Interleave_Low (A, B))
               and then Same
                 (Flyology_SIMD.Backends.Native.Interleave_High (A, B),
                  Interleave_High (A, B)),
               "native interleave" & Iteration'Image);
            Check
              (Same (Flyology_SIMD.Backends.Native.Deinterleave_Even (A, B),
                     Deinterleave_Even (A, B))
               and then Same
                 (Flyology_SIMD.Backends.Native.Deinterleave_Odd (A, B),
                  Deinterleave_Odd (A, B)),
               "native deinterleave" & Iteration'Image);
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
                 (Extract (Permute_Lanes (A, Map), Lane) =
                    Extract (A, Selectors (Lane)),
                  "randomized independent lane permutation" & Lane'Image);
               Check
                 (Extract (Permute_Lanes (A, B, Two_Source_Map), Lane) =
                    Extract
                      ((if (Iteration + Lane) mod 2 = 0
                        then A else B),
                       Lane_Index_8x16
                         ((Iteration * 3 + Lane * 5) mod 16)),
                  "varied independent two-source lane permutation" &
                    Lane'Image);
               Check (Extract (Subtract_Wrap (A, B), Lane) =
                        Extract (A, Lane) - Extract (B, Lane),
                      "scalar subtract lane" & Lane'Image);
               Check (Extract (Multiply_Wrap (A, B), Lane) =
                        Extract (A, Lane) * Extract (B, Lane),
                      "scalar multiply lane" & Lane'Image);
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
            Check (Same
                     (Flyology_SIMD.Backends.Native.Load_Partial
                        (Buffer, 3, Count),
                      Load_Partial (Buffer, 3, Count)),
                   "native partial load" & Iteration'Image);
         end;
      end loop;
   end Test_Native_Differential;

   procedure Test_Algorithms_For_Length (Length : Natural) is
      Data : Byte_Array (1 .. Length);
      Reference_Find, Native_Find, Runtime_Find : Algorithms.Search_Result;
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
         Check (Algorithms.AVX2.Count (Data, 42) = Algorithms.Scalar.Count (Data, 42),
                "AVX2 count length" & Length'Image);
         Check (Algorithms.AVX2.Is_ASCII (Data) = Algorithms.Scalar.Is_ASCII (Data),
                "AVX2 ASCII length" & Length'Image);
      end if;
   end Test_Algorithms_For_Length;

   procedure Test_Algorithms is
      Lane_Data : Byte_Array (1 .. 64) := [others => 0];
   begin
      for Length in Natural range 0 .. 80 loop
         Test_Algorithms_For_Length (Length);
      end loop;
      Test_Algorithms_For_Length (4_096);
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
