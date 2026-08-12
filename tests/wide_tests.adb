with Ada.Text_IO;
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


   procedure Test_U8x32 is


      function Random_Lanes return Wide.Lane_Values_U8x32 is
         Result : Wide.Lane_Values_U8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result (Lane) := U8 (Next_U64 mod 2 ** 8);
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_8x32 is
         Selectors : Wide.Lane_Selectors_8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Selectors (Lane) := Wide.Lane_Index_8x32 (Next_U64 mod 32);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_U8x32 := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
      B_Lanes : constant Wide.Lane_Values_U8x32 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U8x32 := [U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#)];
      A : constant Wide.U8x32 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.U8x32 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.U8x32 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_8x32 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765));
      Packed : constant Wide.U8x32 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.U8x32 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_U8x32 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_U8x32 := Wide.To_Lanes (Expanded);
      Data : Byte_Array (3 .. 42) := [others => 0];
      Native_Data : Byte_Array (3 .. 42) := [others => 0];
      Aligned_Data : Byte_Array (0 .. 31) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_8x32;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "U8x32 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_U8x32'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_U8x32'[others => 0],
        "U8x32 zero construction");
      for Lane in Wide.Lane_Index_8x32 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_8x32 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_8x32 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "U8x32 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => U8 (A_Lanes (Lane) + 2)],
        "U8x32 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => U8 (A_Lanes (Lane) - 2)],
        "U8x32 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => U8 (A_Lanes (Lane) * 2)],
        "U8x32 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_U8x32'[others => 0],
        "U8x32 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_U8x32'[others => 0],
        "U8x32 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "U8x32 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 8)) = Wide.Lane_Values_U8x32'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 15)) = Wide.Lane_Values_U8x32'[others => 0],
        "U8x32 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_8x32'Last,
        "U8x32 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "U8x32 selection");
      for Lane in Wide.Lane_Index_8x32 loop
         if Lane < 16 then
            Check (P (Lane) = A_Lanes (2 * Lane), "U8x32 compression prefix");
         else
            Check (P (Lane) = 0, "U8x32 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "U8x32 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_8x32 (31 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32))
            else Wide.Select_Right_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32))
            else Native.Select_Right_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_8x32 => A_Lanes (31 - Lane)],
        "U8x32 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_8x32 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_8x32 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.U8x32 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.U8x32 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 32)
               else B_Lanes ((Lane * 3 + 1) mod 32))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "U8x32 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_8x32;
         Native_Default_Map : Wide.Two_Source_Lane_Map_8x32;
         Scalar_Default : constant Wide.U8x32 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.U8x32 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "U8x32 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I8, U8);
         Scalar_Cast : constant Wide.I8x32 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.I8x32 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.U8x32 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U8x32 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane),
              "U8x32 to I8x32 edge direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane),
              "U8x32 to I8x32 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_8x32 => A_Lanes (31 - Lane)],
        "U8x32 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 32)) = Wide.Lane_Values_U8x32'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 33)) = Wide.Lane_Values_U8x32'[others => 0],
        "U8x32 oversized slides");
      for Count in Wide.Lane_Count_8x32 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 31 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "U8x32 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_8x32 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "U8x32 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 16
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 30,
        "U8x32 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "U8x32 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "U8x32 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "U8x32 native bitwise and extrema");
      for Shift in Natural range 0 .. 10 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)),
           "U8x32 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "U8x32 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "U8x32 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765)))) = P,
        "U8x32 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765))),
         Native.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765)))) = E,
        "U8x32 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "U8x32 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "U8x32 native lane movement");
      for Slide in Natural range 0 .. 34 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "U8x32 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_8x32'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "U8x32 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 1_023 loop
         declare
            Bits : constant Wide.Mask_Bits_8x32 :=
              (if False then Wide.Mask_Bits_8x32 (Pattern)
               else Wide.Mask_Bits_8x32 (Next_U64 mod 2 ** 32));
            Scalar_Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_8x32 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "U8x32 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_8x32'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "U8x32 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_8x32'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_8x32'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_8x32'Last,
              "U8x32 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_8x32 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "U8x32 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "U8x32 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "U8x32 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U8x32 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "U8x32 scalar aligned memory");
      for Count in Wide.Lane_Count_8x32 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "U8x32 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.U8x32 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.U8x32 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_8x32 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
            R_Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_8x32 (Next_U64 mod 2 ** 32));
            Shift : constant Natural := Natural (Next_U64 mod 11);
            Slide : constant Natural := Natural (Next_U64 mod 35);
         begin
            for Lane in Wide.Lane_Index_8x32 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_8x32 (Next_U64 mod 32))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_8x32 (Next_U64 mod 32)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "U8x32 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U8x32 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)),
              "U8x32 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "U8x32 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U8x32 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "U8x32 randomized reductions" & Iteration'Image);
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I8, U8);
         Scalar_Cast : constant Wide.I8x32 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.I8x32 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.U8x32 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U8x32 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (R_A, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (R_A, Lane),
              "U8x32 to I8x32 randomized direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (R_A, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (R_A, Lane),
              "U8x32 to I8x32 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_U8x32;


   procedure Test_I8x32 is
      function Bits_To_Value is new Ada.Unchecked_Conversion (U8, I8);
      function Value_To_Bits is new Ada.Unchecked_Conversion (I8, U8);
      function Random_Lanes return Wide.Lane_Values_I8x32 is
         Result : Wide.Lane_Values_I8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result (Lane) := Bits_To_Value (U8 (Next_U64 mod 2 ** 8));
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_8x32 is
         Selectors : Wide.Lane_Selectors_8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Selectors (Lane) := Wide.Lane_Index_8x32 (Next_U64 mod 32);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_I8x32 := [-16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
      B_Lanes : constant Wide.Lane_Values_I8x32 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I8x32 := [Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#))];
      A : constant Wide.I8x32 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.I8x32 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.I8x32 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_8x32 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765));
      Packed : constant Wide.I8x32 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.I8x32 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_I8x32 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_I8x32 := Wide.To_Lanes (Expanded);
      Data : I8_Array (3 .. 42) := [others => 0];
      Native_Data : I8_Array (3 .. 42) := [others => 0];
      Aligned_Data : I8_Array (0 .. 31) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_8x32;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "I8x32 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_I8x32'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_I8x32'[others => 0],
        "I8x32 zero construction");
      for Lane in Wide.Lane_Index_8x32 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_8x32 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_8x32 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "I8x32 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => I8 (A_Lanes (Lane) + 2)],
        "I8x32 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => I8 (A_Lanes (Lane) - 2)],
        "I8x32 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => I8 (A_Lanes (Lane) * 2)],
        "I8x32 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_I8x32'[others => 0],
        "I8x32 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_I8x32'[others => 0],
        "I8x32 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "I8x32 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 8)) = Wide.Lane_Values_I8x32'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 15)) = Wide.Lane_Values_I8x32'[others => 0],
        "I8x32 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_8x32'Last,
        "I8x32 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "I8x32 selection");
      for Lane in Wide.Lane_Index_8x32 loop
         if Lane < 16 then
            Check (P (Lane) = A_Lanes (2 * Lane), "I8x32 compression prefix");
         else
            Check (P (Lane) = 0, "I8x32 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "I8x32 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_8x32 (31 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32))
            else Wide.Select_Right_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32))
            else Native.Select_Right_Lane (Wide.Lane_Index_8x32 ((Lane * 3 + 1) mod 32)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_8x32 => A_Lanes (31 - Lane)],
        "I8x32 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_8x32 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_8x32 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.I8x32 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.I8x32 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 32)
               else B_Lanes ((Lane * 3 + 1) mod 32))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "I8x32 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_8x32;
         Native_Default_Map : Wide.Two_Source_Lane_Map_8x32;
         Scalar_Default : constant Wide.I8x32 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.I8x32 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "I8x32 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Cast : constant Wide.U8x32 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.U8x32 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.I8x32 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I8x32 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I8x32 to U8x32 edge direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I8x32 to U8x32 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_8x32 => A_Lanes (31 - Lane)],
        "I8x32 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 32)) = Wide.Lane_Values_I8x32'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 33)) = Wide.Lane_Values_I8x32'[others => 0],
        "I8x32 oversized slides");
      for Count in Wide.Lane_Count_8x32 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 31 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "I8x32 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_8x32 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "I8x32 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 16
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 30,
        "I8x32 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "I8x32 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "I8x32 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "I8x32 native bitwise and extrema");
      for Shift in Natural range 0 .. 10 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (A, Shift)),
           "I8x32 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "I8x32 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "I8x32 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765)))) = P,
        "I8x32 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765))),
         Native.Mask_From_Bit_Mask (Mask_Bits_8x32 (1431655765)))) = E,
        "I8x32 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "I8x32 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "I8x32 native lane movement");
      for Slide in Natural range 0 .. 34 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "I8x32 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_8x32'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "I8x32 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 1_023 loop
         declare
            Bits : constant Wide.Mask_Bits_8x32 :=
              (if False then Wide.Mask_Bits_8x32 (Pattern)
               else Wide.Mask_Bits_8x32 (Next_U64 mod 2 ** 32));
            Scalar_Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_8x32 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "I8x32 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_8x32'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "I8x32 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_8x32'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_8x32'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_8x32'Last,
              "I8x32 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_8x32 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "I8x32 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "I8x32 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "I8x32 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I8x32 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "I8x32 scalar aligned memory");
      for Count in Wide.Lane_Count_8x32 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "I8x32 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.I8x32 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.I8x32 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_8x32 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
            R_Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_8x32 (Next_U64 mod 2 ** 32));
            Shift : constant Natural := Natural (Next_U64 mod 11);
            Slide : constant Natural := Natural (Next_U64 mod 35);
         begin
            for Lane in Wide.Lane_Index_8x32 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_8x32 (Next_U64 mod 32))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_8x32 (Next_U64 mod 32)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "I8x32 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I8x32 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (R_A, Shift)),
              "I8x32 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "I8x32 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I8x32 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "I8x32 randomized reductions" & Iteration'Image);
      declare
         Scalar_Cast : constant Wide.U8x32 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.U8x32 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.I8x32 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I8x32 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I8x32 to U8x32 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I8x32 to U8x32 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_I8x32;


   procedure Test_U16x16 is


      function Random_Lanes return Wide.Lane_Values_U16x16 is
         Result : Wide.Lane_Values_U16x16;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Result (Lane) := U16 (Next_U64 mod 2 ** 16);
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_16x16 is
         Selectors : Wide.Lane_Selectors_16x16;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Selectors (Lane) := Wide.Lane_Index_16x16 (Next_U64 mod 16);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
      B_Lanes : constant Wide.Lane_Values_U16x16 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U16x16 := [U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#), U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#), U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#), U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#)];
      A : constant Wide.U16x16 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.U16x16 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.U16x16 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_16x16 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845));
      Packed : constant Wide.U16x16 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.U16x16 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_U16x16 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_U16x16 := Wide.To_Lanes (Expanded);
      Data : U16_Array (3 .. 26) := [others => 0];
      Native_Data : U16_Array (3 .. 26) := [others => 0];
      Aligned_Data : U16_Array (0 .. 15) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_16x16;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "U16x16 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_U16x16'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_U16x16'[others => 0],
        "U16x16 zero construction");
      for Lane in Wide.Lane_Index_16x16 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_16x16 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_16x16 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "U16x16 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => U16 (A_Lanes (Lane) + 2)],
        "U16x16 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => U16 (A_Lanes (Lane) - 2)],
        "U16x16 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => U16 (A_Lanes (Lane) * 2)],
        "U16x16 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_U16x16'[others => 0],
        "U16x16 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_U16x16'[others => 0],
        "U16x16 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "U16x16 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 16)) = Wide.Lane_Values_U16x16'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 23)) = Wide.Lane_Values_U16x16'[others => 0],
        "U16x16 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_16x16'Last,
        "U16x16 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "U16x16 selection");
      for Lane in Wide.Lane_Index_16x16 loop
         if Lane < 8 then
            Check (P (Lane) = A_Lanes (2 * Lane), "U16x16 compression prefix");
         else
            Check (P (Lane) = 0, "U16x16 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "U16x16 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_16x16 (15 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16))
            else Wide.Select_Right_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16))
            else Native.Select_Right_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_16x16 => A_Lanes (15 - Lane)],
        "U16x16 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_16x16 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_16x16 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.U16x16 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.U16x16 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 16)
               else B_Lanes ((Lane * 3 + 1) mod 16))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "U16x16 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_16x16;
         Native_Default_Map : Wide.Two_Source_Lane_Map_16x16;
         Scalar_Default : constant Wide.U16x16 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.U16x16 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "U16x16 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I16, U16);
         Scalar_Cast : constant Wide.I16x16 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.I16x16 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.U16x16 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U16x16 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane),
              "U16x16 to I16x16 edge direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane),
              "U16x16 to I16x16 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_16x16 => A_Lanes (15 - Lane)],
        "U16x16 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 16)) = Wide.Lane_Values_U16x16'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 17)) = Wide.Lane_Values_U16x16'[others => 0],
        "U16x16 oversized slides");
      for Count in Wide.Lane_Count_16x16 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 15 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "U16x16 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_16x16 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "U16x16 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 8
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 14,
        "U16x16 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "U16x16 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "U16x16 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "U16x16 native bitwise and extrema");
      for Shift in Natural range 0 .. 18 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)),
           "U16x16 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "U16x16 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "U16x16 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845)))) = P,
        "U16x16 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845))),
         Native.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845)))) = E,
        "U16x16 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "U16x16 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "U16x16 native lane movement");
      for Slide in Natural range 0 .. 18 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "U16x16 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_16x16'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "U16x16 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 16 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_16x16 :=
              (if True then Wide.Mask_Bits_16x16 (Pattern)
               else Wide.Mask_Bits_16x16 (Next_U64 mod 2 ** 16));
            Scalar_Mask : constant Wide.Mask_16x16 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_16x16 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "U16x16 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_16x16'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "U16x16 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_16x16'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_16x16'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_16x16'Last,
              "U16x16 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_16x16 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "U16x16 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "U16x16 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "U16x16 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U16x16 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "U16x16 scalar aligned memory");
      for Count in Wide.Lane_Count_16x16 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "U16x16 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.U16x16 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.U16x16 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_16x16 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
            R_Mask : constant Wide.Mask_16x16 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_16x16 (Next_U64 mod 2 ** 16));
            Shift : constant Natural := Natural (Next_U64 mod 19);
            Slide : constant Natural := Natural (Next_U64 mod 19);
         begin
            for Lane in Wide.Lane_Index_16x16 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_16x16 (Next_U64 mod 16))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_16x16 (Next_U64 mod 16)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "U16x16 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U16x16 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)),
              "U16x16 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "U16x16 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U16x16 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "U16x16 randomized reductions" & Iteration'Image);
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I16, U16);
         Scalar_Cast : constant Wide.I16x16 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.I16x16 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.U16x16 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U16x16 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (R_A, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (R_A, Lane),
              "U16x16 to I16x16 randomized direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (R_A, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (R_A, Lane),
              "U16x16 to I16x16 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_U16x16;


   procedure Test_I16x16 is
      function Bits_To_Value is new Ada.Unchecked_Conversion (U16, I16);
      function Value_To_Bits is new Ada.Unchecked_Conversion (I16, U16);
      function Random_Lanes return Wide.Lane_Values_I16x16 is
         Result : Wide.Lane_Values_I16x16;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Result (Lane) := Bits_To_Value (U16 (Next_U64 mod 2 ** 16));
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_16x16 is
         Selectors : Wide.Lane_Selectors_16x16;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Selectors (Lane) := Wide.Lane_Index_16x16 (Next_U64 mod 16);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_I16x16 := [-8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7];
      B_Lanes : constant Wide.Lane_Values_I16x16 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I16x16 := [Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#)), Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#)), Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#)), Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#))];
      A : constant Wide.I16x16 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.I16x16 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.I16x16 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_16x16 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845));
      Packed : constant Wide.I16x16 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.I16x16 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_I16x16 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_I16x16 := Wide.To_Lanes (Expanded);
      Data : I16_Array (3 .. 26) := [others => 0];
      Native_Data : I16_Array (3 .. 26) := [others => 0];
      Aligned_Data : I16_Array (0 .. 15) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_16x16;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "I16x16 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_I16x16'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_I16x16'[others => 0],
        "I16x16 zero construction");
      for Lane in Wide.Lane_Index_16x16 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_16x16 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_16x16 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "I16x16 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => I16 (A_Lanes (Lane) + 2)],
        "I16x16 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => I16 (A_Lanes (Lane) - 2)],
        "I16x16 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => I16 (A_Lanes (Lane) * 2)],
        "I16x16 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_I16x16'[others => 0],
        "I16x16 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_I16x16'[others => 0],
        "I16x16 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "I16x16 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 16)) = Wide.Lane_Values_I16x16'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 23)) = Wide.Lane_Values_I16x16'[others => 0],
        "I16x16 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_16x16'Last,
        "I16x16 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_16x16 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "I16x16 selection");
      for Lane in Wide.Lane_Index_16x16 loop
         if Lane < 8 then
            Check (P (Lane) = A_Lanes (2 * Lane), "I16x16 compression prefix");
         else
            Check (P (Lane) = 0, "I16x16 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "I16x16 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_16x16 (15 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16))
            else Wide.Select_Right_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16))
            else Native.Select_Right_Lane (Wide.Lane_Index_16x16 ((Lane * 3 + 1) mod 16)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_16x16 => A_Lanes (15 - Lane)],
        "I16x16 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_16x16 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_16x16 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.I16x16 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.I16x16 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 16)
               else B_Lanes ((Lane * 3 + 1) mod 16))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "I16x16 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_16x16;
         Native_Default_Map : Wide.Two_Source_Lane_Map_16x16;
         Scalar_Default : constant Wide.I16x16 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.I16x16 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "I16x16 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Cast : constant Wide.U16x16 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.U16x16 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.I16x16 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I16x16 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I16x16 to U16x16 edge direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I16x16 to U16x16 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_16x16 => A_Lanes (15 - Lane)],
        "I16x16 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 16)) = Wide.Lane_Values_I16x16'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 17)) = Wide.Lane_Values_I16x16'[others => 0],
        "I16x16 oversized slides");
      for Count in Wide.Lane_Count_16x16 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 15 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "I16x16 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_16x16 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "I16x16 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 8
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 14,
        "I16x16 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "I16x16 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "I16x16 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "I16x16 native bitwise and extrema");
      for Shift in Natural range 0 .. 18 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (A, Shift)),
           "I16x16 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "I16x16 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "I16x16 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845)))) = P,
        "I16x16 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845))),
         Native.Mask_From_Bit_Mask (Mask_Bits_16x16 (21845)))) = E,
        "I16x16 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "I16x16 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "I16x16 native lane movement");
      for Slide in Natural range 0 .. 18 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "I16x16 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_16x16'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "I16x16 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 16 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_16x16 :=
              (if True then Wide.Mask_Bits_16x16 (Pattern)
               else Wide.Mask_Bits_16x16 (Next_U64 mod 2 ** 16));
            Scalar_Mask : constant Wide.Mask_16x16 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_16x16 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "I16x16 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_16x16'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "I16x16 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_16x16'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_16x16'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_16x16'Last,
              "I16x16 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_16x16 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "I16x16 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "I16x16 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "I16x16 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I16x16 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "I16x16 scalar aligned memory");
      for Count in Wide.Lane_Count_16x16 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "I16x16 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.I16x16 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.I16x16 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_16x16 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
            R_Mask : constant Wide.Mask_16x16 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_16x16 (Next_U64 mod 2 ** 16));
            Shift : constant Natural := Natural (Next_U64 mod 19);
            Slide : constant Natural := Natural (Next_U64 mod 19);
         begin
            for Lane in Wide.Lane_Index_16x16 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_16x16 (Next_U64 mod 16))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_16x16 (Next_U64 mod 16)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "I16x16 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I16x16 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (R_A, Shift)),
              "I16x16 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "I16x16 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I16x16 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "I16x16 randomized reductions" & Iteration'Image);
      declare
         Scalar_Cast : constant Wide.U16x16 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.U16x16 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.I16x16 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I16x16 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I16x16 to U16x16 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I16x16 to U16x16 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_I16x16;


   procedure Test_U32x8 is


      function Random_Lanes return Wide.Lane_Values_U32x8 is
         Result : Wide.Lane_Values_U32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := U32 (Next_U64 mod 2 ** 32);
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_32x8 is
         Selectors : Wide.Lane_Selectors_32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Selectors (Lane) := Wide.Lane_Index_32x8 (Next_U64 mod 8);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 2, 3, 4, 5, 6, 7];
      B_Lanes : constant Wide.Lane_Values_U32x8 := [2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U32x8 := [U32 (16#00000000#), U32 (16#80000000#), U32 (16#FFFFFFFF#), U32 (16#AAAAAAAA#), U32 (16#00000000#), U32 (16#80000000#), U32 (16#FFFFFFFF#), U32 (16#AAAAAAAA#)];
      A : constant Wide.U32x8 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.U32x8 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.U32x8 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_32x8 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_32x8 (85));
      Packed : constant Wide.U32x8 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.U32x8 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_U32x8 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_U32x8 := Wide.To_Lanes (Expanded);
      Data : U32_Array (3 .. 18) := [others => 0];
      Native_Data : U32_Array (3 .. 18) := [others => 0];
      Aligned_Data : U32_Array (0 .. 7) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_32x8;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "U32x8 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_U32x8'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_U32x8'[others => 0],
        "U32x8 zero construction");
      for Lane in Wide.Lane_Index_32x8 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_32x8 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_32x8 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "U32x8 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => U32 (A_Lanes (Lane) + 2)],
        "U32x8 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => U32 (A_Lanes (Lane) - 2)],
        "U32x8 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => U32 (A_Lanes (Lane) * 2)],
        "U32x8 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_U32x8'[others => 0],
        "U32x8 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_U32x8'[others => 0],
        "U32x8 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "U32x8 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 32)) = Wide.Lane_Values_U32x8'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 39)) = Wide.Lane_Values_U32x8'[others => 0],
        "U32x8 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_32x8'Last,
        "U32x8 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "U32x8 selection");
      for Lane in Wide.Lane_Index_32x8 loop
         if Lane < 4 then
            Check (P (Lane) = A_Lanes (2 * Lane), "U32x8 compression prefix");
         else
            Check (P (Lane) = 0, "U32x8 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "U32x8 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_32x8 (7 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8))
            else Wide.Select_Right_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8))
            else Native.Select_Right_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_32x8 => A_Lanes (7 - Lane)],
        "U32x8 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.U32x8 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.U32x8 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 8)
               else B_Lanes ((Lane * 3 + 1) mod 8))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "U32x8 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_32x8;
         Native_Default_Map : Wide.Two_Source_Lane_Map_32x8;
         Scalar_Default : constant Wide.U32x8 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.U32x8 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "U32x8 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I32, U32);
         Scalar_Cast : constant Wide.I32x8 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.I32x8 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.U32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane),
              "U32x8 to I32x8 edge direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane),
              "U32x8 to I32x8 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F32, U32);
         Scalar_Cast : constant Wide.F32x8 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.F32x8 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.U32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane),
              "U32x8 to F32x8 edge direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane),
              "U32x8 to F32x8 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_32x8 => A_Lanes (7 - Lane)],
        "U32x8 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 8)) = Wide.Lane_Values_U32x8'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 9)) = Wide.Lane_Values_U32x8'[others => 0],
        "U32x8 oversized slides");
      for Count in Wide.Lane_Count_32x8 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 7 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "U32x8 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_32x8 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "U32x8 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 4
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 6,
        "U32x8 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "U32x8 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "U32x8 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "U32x8 native bitwise and extrema");
      for Shift in Natural range 0 .. 34 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)),
           "U32x8 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "U32x8 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "U32x8 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85)))) = P,
        "U32x8 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85))),
         Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85)))) = E,
        "U32x8 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "U32x8 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "U32x8 native lane movement");
      for Slide in Natural range 0 .. 10 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "U32x8 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_32x8'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "U32x8 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 8 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_32x8 :=
              (if True then Wide.Mask_Bits_32x8 (Pattern)
               else Wide.Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Scalar_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_32x8 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "U32x8 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_32x8'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "U32x8 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last,
              "U32x8 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_32x8 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "U32x8 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "U32x8 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "U32x8 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U32x8 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "U32x8 scalar aligned memory");
      for Count in Wide.Lane_Count_32x8 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "U32x8 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.U32x8 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.U32x8 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_32x8 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
            R_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Shift : constant Natural := Natural (Next_U64 mod 35);
            Slide : constant Natural := Natural (Next_U64 mod 11);
         begin
            for Lane in Wide.Lane_Index_32x8 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_32x8 (Next_U64 mod 8))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_32x8 (Next_U64 mod 8)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "U32x8 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U32x8 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)),
              "U32x8 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "U32x8 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U32x8 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "U32x8 randomized reductions" & Iteration'Image);
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I32, U32);
         Scalar_Cast : constant Wide.I32x8 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.I32x8 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.U32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (R_A, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (R_A, Lane),
              "U32x8 to I32x8 randomized direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (R_A, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (R_A, Lane),
              "U32x8 to I32x8 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F32, U32);
         Scalar_Cast : constant Wide.F32x8 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.F32x8 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.U32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (R_A, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (R_A, Lane),
              "U32x8 to F32x8 randomized direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (R_A, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (R_A, Lane),
              "U32x8 to F32x8 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_U32x8;


   procedure Test_I32x8 is
      function Bits_To_Value is new Ada.Unchecked_Conversion (U32, I32);
      function Value_To_Bits is new Ada.Unchecked_Conversion (I32, U32);
      function Random_Lanes return Wide.Lane_Values_I32x8 is
         Result : Wide.Lane_Values_I32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := Bits_To_Value (U32 (Next_U64 mod 2 ** 32));
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_32x8 is
         Selectors : Wide.Lane_Selectors_32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Selectors (Lane) := Wide.Lane_Index_32x8 (Next_U64 mod 8);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_I32x8 := [-4, -3, -2, -1, 0, 1, 2, 3];
      B_Lanes : constant Wide.Lane_Values_I32x8 := [2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I32x8 := [Bits_To_Value (U32 (16#00000000#)), Bits_To_Value (U32 (16#80000000#)), Bits_To_Value (U32 (16#FFFFFFFF#)), Bits_To_Value (U32 (16#AAAAAAAA#)), Bits_To_Value (U32 (16#00000000#)), Bits_To_Value (U32 (16#80000000#)), Bits_To_Value (U32 (16#FFFFFFFF#)), Bits_To_Value (U32 (16#AAAAAAAA#))];
      A : constant Wide.I32x8 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.I32x8 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.I32x8 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_32x8 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_32x8 (85));
      Packed : constant Wide.I32x8 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.I32x8 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_I32x8 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_I32x8 := Wide.To_Lanes (Expanded);
      Data : I32_Array (3 .. 18) := [others => 0];
      Native_Data : I32_Array (3 .. 18) := [others => 0];
      Aligned_Data : I32_Array (0 .. 7) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_32x8;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "I32x8 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_I32x8'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_I32x8'[others => 0],
        "I32x8 zero construction");
      for Lane in Wide.Lane_Index_32x8 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_32x8 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_32x8 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "I32x8 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => I32 (A_Lanes (Lane) + 2)],
        "I32x8 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => I32 (A_Lanes (Lane) - 2)],
        "I32x8 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => I32 (A_Lanes (Lane) * 2)],
        "I32x8 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_I32x8'[others => 0],
        "I32x8 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_I32x8'[others => 0],
        "I32x8 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "I32x8 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 32)) = Wide.Lane_Values_I32x8'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 39)) = Wide.Lane_Values_I32x8'[others => 0],
        "I32x8 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_32x8'Last,
        "I32x8 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_32x8 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "I32x8 selection");
      for Lane in Wide.Lane_Index_32x8 loop
         if Lane < 4 then
            Check (P (Lane) = A_Lanes (2 * Lane), "I32x8 compression prefix");
         else
            Check (P (Lane) = 0, "I32x8 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "I32x8 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_32x8 (7 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8))
            else Wide.Select_Right_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8))
            else Native.Select_Right_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_32x8 => A_Lanes (7 - Lane)],
        "I32x8 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.I32x8 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.I32x8 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 8)
               else B_Lanes ((Lane * 3 + 1) mod 8))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "I32x8 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_32x8;
         Native_Default_Map : Wide.Two_Source_Lane_Map_32x8;
         Scalar_Default : constant Wide.I32x8 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.I32x8 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "I32x8 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Cast : constant Wide.U32x8 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.U32x8 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.I32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I32x8 to U32x8 edge direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I32x8 to U32x8 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F32, U32);
         Scalar_Cast : constant Wide.F32x8 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.F32x8 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.I32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I32x8 to F32x8 edge direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I32x8 to F32x8 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_32x8 => A_Lanes (7 - Lane)],
        "I32x8 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 8)) = Wide.Lane_Values_I32x8'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 9)) = Wide.Lane_Values_I32x8'[others => 0],
        "I32x8 oversized slides");
      for Count in Wide.Lane_Count_32x8 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 7 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "I32x8 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_32x8 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "I32x8 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 4
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 6,
        "I32x8 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "I32x8 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "I32x8 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "I32x8 native bitwise and extrema");
      for Shift in Natural range 0 .. 34 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (A, Shift)),
           "I32x8 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "I32x8 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "I32x8 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85)))) = P,
        "I32x8 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85))),
         Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85)))) = E,
        "I32x8 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "I32x8 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "I32x8 native lane movement");
      for Slide in Natural range 0 .. 10 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "I32x8 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_32x8'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "I32x8 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 8 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_32x8 :=
              (if True then Wide.Mask_Bits_32x8 (Pattern)
               else Wide.Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Scalar_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_32x8 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "I32x8 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_32x8'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "I32x8 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last,
              "I32x8 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_32x8 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "I32x8 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "I32x8 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "I32x8 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I32x8 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "I32x8 scalar aligned memory");
      for Count in Wide.Lane_Count_32x8 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "I32x8 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.I32x8 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.I32x8 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_32x8 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
            R_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Shift : constant Natural := Natural (Next_U64 mod 35);
            Slide : constant Natural := Natural (Next_U64 mod 11);
         begin
            for Lane in Wide.Lane_Index_32x8 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_32x8 (Next_U64 mod 8))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_32x8 (Next_U64 mod 8)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "I32x8 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I32x8 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (R_A, Shift)),
              "I32x8 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "I32x8 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I32x8 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "I32x8 randomized reductions" & Iteration'Image);
      declare
         Scalar_Cast : constant Wide.U32x8 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.U32x8 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.I32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I32x8 to U32x8 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I32x8 to U32x8 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F32, U32);
         Scalar_Cast : constant Wide.F32x8 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.F32x8 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.I32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I32x8 to F32x8 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I32x8 to F32x8 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_I32x8;


   procedure Test_U64x4 is


      function Random_Lanes return Wide.Lane_Values_U64x4 is
         Result : Wide.Lane_Values_U64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := Next_U64;
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_64x4 is
         Selectors : Wide.Lane_Selectors_64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Selectors (Lane) := Wide.Lane_Index_64x4 (Next_U64 mod 4);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_U64x4 := [0, 1, 2, 3];
      B_Lanes : constant Wide.Lane_Values_U64x4 := [2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U64x4 := [U64 (16#0000000000000000#), U64 (16#8000000000000000#), U64 (16#FFFFFFFFFFFFFFFF#), U64 (16#AAAAAAAAAAAAAAAA#)];
      A : constant Wide.U64x4 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.U64x4 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.U64x4 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_64x4 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_64x4 (5));
      Packed : constant Wide.U64x4 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.U64x4 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_U64x4 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_U64x4 := Wide.To_Lanes (Expanded);
      Data : U64_Array (3 .. 14) := [others => 0];
      Native_Data : U64_Array (3 .. 14) := [others => 0];
      Aligned_Data : U64_Array (0 .. 3) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_64x4;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "U64x4 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_U64x4'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_U64x4'[others => 0],
        "U64x4 zero construction");
      for Lane in Wide.Lane_Index_64x4 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_64x4 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_64x4 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "U64x4 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => U64 (A_Lanes (Lane) + 2)],
        "U64x4 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => U64 (A_Lanes (Lane) - 2)],
        "U64x4 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => U64 (A_Lanes (Lane) * 2)],
        "U64x4 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_U64x4'[others => 0],
        "U64x4 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_U64x4'[others => 0],
        "U64x4 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "U64x4 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 64)) = Wide.Lane_Values_U64x4'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 71)) = Wide.Lane_Values_U64x4'[others => 0],
        "U64x4 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_64x4'Last,
        "U64x4 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "U64x4 selection");
      for Lane in Wide.Lane_Index_64x4 loop
         if Lane < 2 then
            Check (P (Lane) = A_Lanes (2 * Lane), "U64x4 compression prefix");
         else
            Check (P (Lane) = 0, "U64x4 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "U64x4 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_64x4 (3 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4))
            else Wide.Select_Right_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4))
            else Native.Select_Right_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_64x4 => A_Lanes (3 - Lane)],
        "U64x4 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_64x4 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_64x4 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.U64x4 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.U64x4 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 4)
               else B_Lanes ((Lane * 3 + 1) mod 4))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "U64x4 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_64x4;
         Native_Default_Map : Wide.Two_Source_Lane_Map_64x4;
         Scalar_Default : constant Wide.U64x4 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.U64x4 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "U64x4 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I64, U64);
         Scalar_Cast : constant Wide.I64x4 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.I64x4 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.U64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane),
              "U64x4 to I64x4 edge direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane),
              "U64x4 to I64x4 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F64, U64);
         Scalar_Cast : constant Wide.F64x4 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.F64x4 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.U64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (Bit_Vector, Lane),
              "U64x4 to F64x4 edge direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (Bit_Vector, Lane),
              "U64x4 to F64x4 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_64x4 => A_Lanes (3 - Lane)],
        "U64x4 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 4)) = Wide.Lane_Values_U64x4'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 5)) = Wide.Lane_Values_U64x4'[others => 0],
        "U64x4 oversized slides");
      for Count in Wide.Lane_Count_64x4 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 3 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "U64x4 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_64x4 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "U64x4 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 2
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 2,
        "U64x4 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "U64x4 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "U64x4 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "U64x4 native bitwise and extrema");
      for Shift in Natural range 0 .. 66 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)),
           "U64x4 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "U64x4 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "U64x4 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5)))) = P,
        "U64x4 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5))),
         Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5)))) = E,
        "U64x4 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "U64x4 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "U64x4 native lane movement");
      for Slide in Natural range 0 .. 6 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "U64x4 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_64x4'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "U64x4 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 4 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_64x4 :=
              (if True then Wide.Mask_Bits_64x4 (Pattern)
               else Wide.Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Scalar_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_64x4 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "U64x4 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_64x4'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "U64x4 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last,
              "U64x4 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_64x4 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "U64x4 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "U64x4 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "U64x4 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U64x4 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "U64x4 scalar aligned memory");
      for Count in Wide.Lane_Count_64x4 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "U64x4 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.U64x4 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.U64x4 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_64x4 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
            R_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Shift : constant Natural := Natural (Next_U64 mod 67);
            Slide : constant Natural := Natural (Next_U64 mod 7);
         begin
            for Lane in Wide.Lane_Index_64x4 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_64x4 (Next_U64 mod 4))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_64x4 (Next_U64 mod 4)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "U64x4 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U64x4 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)),
              "U64x4 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "U64x4 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U64x4 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "U64x4 randomized reductions" & Iteration'Image);
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I64, U64);
         Scalar_Cast : constant Wide.I64x4 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.I64x4 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.U64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (R_A, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (R_A, Lane),
              "U64x4 to I64x4 randomized direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (R_A, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (R_A, Lane),
              "U64x4 to I64x4 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F64, U64);
         Scalar_Cast : constant Wide.F64x4 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.F64x4 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.U64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.U64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Wide.Extract (R_A, Lane)
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Wide.Extract (R_A, Lane),
              "U64x4 to F64x4 randomized direct bit cast" & Lane'Image);
            Check (Wide.Extract (Round_Trip, Lane) = Wide.Extract (R_A, Lane)
              and then Wide.Extract (Native_Round_Trip, Lane) = Wide.Extract (R_A, Lane),
              "U64x4 to F64x4 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_U64x4;


   procedure Test_I64x4 is
      function Bits_To_Value is new Ada.Unchecked_Conversion (U64, I64);
      function Value_To_Bits is new Ada.Unchecked_Conversion (I64, U64);
      function Random_Lanes return Wide.Lane_Values_I64x4 is
         Result : Wide.Lane_Values_I64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := Bits_To_Value (Next_U64);
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Map return Wide.Lane_Map_64x4 is
         Selectors : Wide.Lane_Selectors_64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Selectors (Lane) := Wide.Lane_Index_64x4 (Next_U64 mod 4);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_I64x4 := [-2, -1, 0, 1];
      B_Lanes : constant Wide.Lane_Values_I64x4 := [2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I64x4 := [Bits_To_Value (U64 (16#0000000000000000#)), Bits_To_Value (U64 (16#8000000000000000#)), Bits_To_Value (U64 (16#FFFFFFFFFFFFFFFF#)), Bits_To_Value (U64 (16#AAAAAAAAAAAAAAAA#))];
      A : constant Wide.I64x4 := Wide.From_Lanes (A_Lanes);
      B : constant Wide.I64x4 := Wide.From_Lanes (B_Lanes);
      Bit_Vector : constant Wide.I64x4 := Wide.From_Lanes (Bit_Lanes);
      Alternating : constant Wide.Mask_64x4 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_64x4 (5));
      Packed : constant Wide.I64x4 := Wide.Compress (A, Alternating);
      Expanded : constant Wide.I64x4 := Wide.Expand (Packed, Alternating);
      P : constant Wide.Lane_Values_I64x4 := Wide.To_Lanes (Packed);
      E : constant Wide.Lane_Values_I64x4 := Wide.To_Lanes (Expanded);
      Data : I64_Array (3 .. 14) := [others => 0];
      Native_Data : I64_Array (3 .. 14) := [others => 0];
      Aligned_Data : I64_Array (0 .. 3) := [others => 0]
        with Alignment => 32;
      Map_Selectors : Wide.Lane_Selectors_64x4;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "I64x4 lane round trip");
      Check (Wide.To_Lanes (Wide.Zero) = Wide.Lane_Values_I64x4'[others => 0]
        and then Native.To_Lanes (Native.Zero) = Wide.Lane_Values_I64x4'[others => 0],
        "I64x4 zero construction");
      for Lane in Wide.Lane_Index_64x4 loop
         Check (Wide.To_Lanes (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_64x4 => (if Position = Lane then A_Lanes (Lane) else 0)]
           and then Native.To_Lanes (Native.Replace (Native.Zero, Lane, A_Lanes (Lane))) =
           [for Position in Wide.Lane_Index_64x4 => (if Position = Lane then A_Lanes (Lane) else 0)],
           "I64x4 lane replacement" & Lane'Image);
      end loop;
      Check (Wide.To_Lanes (Wide.Add_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => I64 (A_Lanes (Lane) + 2)],
        "I64x4 add");
      Check (Wide.To_Lanes (Wide.Subtract_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => I64 (A_Lanes (Lane) - 2)],
        "I64x4 subtract");
      Check (Wide.To_Lanes (Wide.Multiply_Wrap (A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => I64 (A_Lanes (Lane) * 2)],
        "I64x4 multiply");
      Check (Wide.To_Lanes (Wide.Bitwise_Xor (A, A)) = Wide.Lane_Values_I64x4'[others => 0],
        "I64x4 xor identity");
      Check (Wide.To_Lanes (Wide.Bitwise_And (A, Wide.Bitwise_Not (A))) = Wide.Lane_Values_I64x4'[others => 0],
        "I64x4 complement");
      Check (Wide.To_Lanes (Wide.Bitwise_Not (Wide.Bitwise_Not (A))) = A_Lanes,
        "I64x4 double complement");
      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 64)) = Wide.Lane_Values_I64x4'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 71)) = Wide.Lane_Values_I64x4'[others => 0],
        "I64x4 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_64x4'Last,
        "I64x4 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_64x4 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "I64x4 selection");
      for Lane in Wide.Lane_Index_64x4 loop
         if Lane < 2 then
            Check (P (Lane) = A_Lanes (2 * Lane), "I64x4 compression prefix");
         else
            Check (P (Lane) = 0, "I64x4 compression zero fill");
         end if;
         Check (E (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0),
           "I64x4 expansion position");
         Map_Selectors (Lane) := Wide.Lane_Index_64x4 (3 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4))
            else Wide.Select_Right_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4))
            else Native.Select_Right_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4)));
      end loop;
      Check (Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) =
        [for Lane in Wide.Lane_Index_64x4 => A_Lanes (3 - Lane)],
        "I64x4 lane map");
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_64x4 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_64x4 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.I64x4 :=
           Wide.Permute_Lanes (A, B, Scalar_Map);
         Native_Result : constant Wide.I64x4 :=
           Native.Permute_Lanes (A, B, Native_Map);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Result, Lane) =
              (if Lane mod 2 = 0
               then A_Lanes ((Lane * 3 + 1) mod 4)
               else B_Lanes ((Lane * 3 + 1) mod 4))
              and then Native.Extract (Native_Result, Lane) = Wide.Extract (Scalar_Result, Lane),
              "I64x4 two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_64x4;
         Native_Default_Map : Wide.Two_Source_Lane_Map_64x4;
         Scalar_Default : constant Wide.I64x4 :=
           Wide.Permute_Lanes (A, B, Scalar_Default_Map);
         Native_Default : constant Wide.I64x4 :=
           Native.Permute_Lanes (A, B, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Default, Lane) = A_Lanes (0)
              and then Wide.Extract (Native_Default, Lane) = A_Lanes (0),
              "I64x4 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Cast : constant Wide.U64x4 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.U64x4 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.I64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I64x4 to U64x4 edge direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I64x4 to U64x4 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F64, U64);
         Scalar_Cast : constant Wide.F64x4 := Wide.Bit_Cast (Bit_Vector);
         Native_Cast : constant Wide.F64x4 := Native.Bit_Cast (Bit_Vector);
         Round_Trip : constant Wide.I64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I64x4 to F64x4 edge direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Bit_Vector, Lane)),
              "I64x4 to F64x4 edge bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Wide.To_Lanes (Wide.Reverse_Lanes (A)) =
        [for Lane in Wide.Lane_Index_64x4 => A_Lanes (3 - Lane)],
        "I64x4 reverse");
      Check (Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, 4)) = Wide.Lane_Values_I64x4'[others => 0]
        and then Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, 5)) = Wide.Lane_Values_I64x4'[others => 0],
        "I64x4 oversized slides");
      for Count in Wide.Lane_Count_64x4 loop
         Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         for Offset in 0 .. 3 loop
            Check (Data (Data'First + Offset) =
              (if Offset < Count then A_Lanes (Offset) else 0),
              "I64x4 partial store");
         end loop;
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_64x4 => (if Lane < Count then A_Lanes (Lane) else 0)],
           "I64x4 partial load");
      end loop;
      Check (Wide.Population_Count (Alternating) = 2
        and then Wide.First_True (Alternating) = 0
        and then Wide.Last_True (Alternating) = 2,
        "I64x4 mask positions");
      Check (Native.To_Lanes (Native.Add_Wrap
        (Native.From_Lanes (A_Lanes), Native.From_Lanes (B_Lanes))) =
        Wide.To_Lanes (Wide.Add_Wrap (A, B)), "I64x4 native add");
      Check (Native.To_Lanes (Native.Subtract_Wrap (A, B)) = Wide.To_Lanes (Wide.Subtract_Wrap (A, B))
        and then Native.To_Lanes (Native.Multiply_Wrap (A, B)) = Wide.To_Lanes (Wide.Multiply_Wrap (A, B))
        and then Native.To_Lanes (Native.Add_Saturate (A, B)) = Wide.To_Lanes (Wide.Add_Saturate (A, B))
        and then Native.To_Lanes (Native.Subtract_Saturate (A, B)) = Wide.To_Lanes (Wide.Subtract_Saturate (A, B)),
        "I64x4 native integer arithmetic");
      Check (Native.To_Lanes (Native.Bitwise_And (A, B)) = Wide.To_Lanes (Wide.Bitwise_And (A, B))
        and then Native.To_Lanes (Native.Bitwise_Or (A, B)) = Wide.To_Lanes (Wide.Bitwise_Or (A, B))
        and then Native.To_Lanes (Native.Bitwise_Xor (A, B)) = Wide.To_Lanes (Wide.Bitwise_Xor (A, B))
        and then Native.To_Lanes (Native.Bitwise_Not (A)) = Wide.To_Lanes (Wide.Bitwise_Not (A))
        and then Native.To_Lanes (Native.Min (A, B)) = Wide.To_Lanes (Wide.Min (A, B))
        and then Native.To_Lanes (Native.Max (A, B)) = Wide.To_Lanes (Wide.Max (A, B)),
        "I64x4 native bitwise and extrema");
      for Shift in Natural range 0 .. 66 loop
         Check (Native.To_Lanes (Native.Shift_Left_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (A, Shift))
           and then Native.To_Lanes (Native.Shift_Right_Logical (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (A, Shift)),
           "I64x4 native shifts" & Shift'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Equal (A, B)) = Wide.To_Bit_Mask (Wide.Equal (A, B))
        and then Native.To_Bit_Mask (Native.Less_Than (A, B)) = Wide.To_Bit_Mask (Wide.Less_Than (A, B))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, B))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, B)),
        "I64x4 native comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, B)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)),
        "I64x4 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5)))) = P,
        "I64x4 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5))),
         Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5)))) = E,
        "I64x4 native expansion");
      Check (Native.Reduce_Add_Wrap (A) = Wide.Reduce_Add_Wrap (A)
        and then Native.Reduce_Min (A) = Wide.Reduce_Min (A)
        and then Native.Reduce_Max (A) = Wide.Reduce_Max (A),
        "I64x4 native reductions");
      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, B)) = Wide.To_Lanes (Wide.Interleave_Low (A, B))
        and then Native.To_Lanes (Native.Interleave_High (A, B)) = Wide.To_Lanes (Wide.Interleave_High (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, B))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, B)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, B)),
        "I64x4 native lane movement");
      for Slide in Natural range 0 .. 6 loop
         Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (A, Slide))
           and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (A, Slide)),
           "I64x4 native slides" & Slide'Image);
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.To_Bit_Mask (Native.Mask_Or (Alternating, Native.Mask_Not (Alternating))) = Mask_Bits_64x4'Last
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "I64x4 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 4 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_64x4 :=
              (if True then Wide.Mask_Bits_64x4 (Pattern)
               else Wide.Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Scalar_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_64x4 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits,
              "I64x4 mask round trip" & Pattern'Image);
            Check (Wide.Any_True (Scalar_Mask) = (Bits /= 0)
              and then Wide.None_True (Scalar_Mask) = (Bits = 0)
              and then Wide.All_True (Scalar_Mask) = (Bits = Mask_Bits_64x4'Last)
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask),
              "I64x4 mask predicates" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last,
              "I64x4 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_64x4 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "I64x4 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0];
      Native_Data := [others => 0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "I64x4 native unaligned memory");
      Data := [others => 0];
      Native_Data := [others => 0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "I64x4 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I64x4 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, B);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = B_Lanes,
        "I64x4 scalar aligned memory");
      for Count in Wide.Lane_Count_64x4 loop
         Data := [others => 0];
         Native_Data := [others => 0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "I64x4 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.I64x4 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.I64x4 := Wide.From_Lanes (Random_Lanes);
            R_Map : constant Wide.Lane_Map_64x4 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
            R_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Shift : constant Natural := Natural (Next_U64 mod 67);
            Slide : constant Natural := Natural (Next_U64 mod 7);
         begin
            for Lane in Wide.Lane_Index_64x4 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_64x4 (Next_U64 mod 4))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_64x4 (Next_U64 mod 4)));
            end loop;
            Check (Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B))
              and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)),
              "I64x4 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I64x4 randomized bitwise extrema" & Iteration'Image);
            Check (Native.To_Lanes (Native.Shift_Left_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Left_Logical (R_A, Shift))
              and then Native.To_Lanes (Native.Shift_Right_Logical (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Logical (R_A, Shift)) and then Native.To_Lanes (Native.Shift_Right_Arithmetic (R_A, Shift)) = Wide.To_Lanes (Wide.Shift_Right_Arithmetic (R_A, Shift)),
              "I64x4 randomized shifts" & Iteration'Image);
            Check (Native.To_Bit_Mask (Native.Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Equal (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "I64x4 randomized comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I64x4 randomized selection and movement" & Iteration'Image);
            Check (Native.Reduce_Add_Wrap (R_A) = Wide.Reduce_Add_Wrap (R_A)
              and then Native.Reduce_Min (R_A) = Wide.Reduce_Min (R_A)
              and then Native.Reduce_Max (R_A) = Wide.Reduce_Max (R_A),
              "I64x4 randomized reductions" & Iteration'Image);
      declare
         Scalar_Cast : constant Wide.U64x4 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.U64x4 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.I64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I64x4 to U64x4 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I64x4 to U64x4 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (F64, U64);
         Scalar_Cast : constant Wide.F64x4 := Wide.Bit_Cast (R_A);
         Native_Cast : constant Wide.F64x4 := Native.Bit_Cast (R_A);
         Round_Trip : constant Wide.I64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.I64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I64x4 to F64x4 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_A, Lane)),
              "I64x4 to F64x4 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_I64x4;


   procedure Test_F32x8 is
      function Bits_To_Value is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, F32);
      function Value_To_Bits is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);
      function Random_Lanes return Wide.Lane_Values_F32x8 is
         Result : Wide.Lane_Values_F32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := F32 (Integer (Next_U64 mod 2_000_001) - 1_000_000) / 128.0;
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Bit_Lanes return Wide.Lane_Values_F32x8 is
         Result : Wide.Lane_Values_F32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := Bits_To_Value
              (Interfaces.Unsigned_32 (Next_U64 mod 2 ** 32));
         end loop;
         return Result;
      end Random_Bit_Lanes;
      function Random_Map return Wide.Lane_Map_32x8 is
         Selectors : Wide.Lane_Selectors_32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Selectors (Lane) := Wide.Lane_Index_32x8 (Next_U64 mod 8);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_F32x8 := [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
      A : constant Wide.F32x8 := Wide.From_Lanes (A_Lanes);
      Two : constant Wide.F32x8 := Wide.Splat (2.0);
      Alternating : constant Wide.Mask_32x8 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_32x8 (85));
      Packed : constant Wide.Lane_Values_F32x8 := Wide.To_Lanes (Wide.Compress (A, Alternating));
      Expanded : constant Wide.Lane_Values_F32x8 := Wide.To_Lanes
        (Wide.Expand (Wide.Compress (A, Alternating), Alternating));
      Data : F32_Array (5 .. 20) := [others => 0.0];
      Native_Data : F32_Array (5 .. 20) := [others => 0.0];
      Aligned_Data : F32_Array (0 .. 7) := [others => 0.0]
        with Alignment => 32;
      Special_Lanes : constant Wide.Lane_Values_F32x8 := [Bits_To_Value (0), Bits_To_Value (16#8000_0000#), Bits_To_Value (16#7F80_0000#), Bits_To_Value (16#7FC1_2345#), Bits_To_Value (16#7F81_2345#), Bits_To_Value (5), Bits_To_Value (6), Bits_To_Value (7)];
      Specials : constant Wide.F32x8 := Wide.From_Lanes (Special_Lanes);
      Order_Vector : constant Wide.F32x8 := Wide.From_Lanes ([2.0, 1.0, Bits_To_Value (16#7F81_2345#), 3.0, 3.0, 3.0, 3.0, 3.0]);
      Positive_Zero_First : constant Wide.F32x8 :=
        Wide.From_Lanes ([0.0, Bits_To_Value (16#8000_0000#), 0.0, Bits_To_Value (16#8000_0000#), 0.0, Bits_To_Value (16#8000_0000#), 0.0, Bits_To_Value (16#8000_0000#)]);
      Negative_Zero_First : constant Wide.F32x8 :=
        Wide.From_Lanes ([Bits_To_Value (16#8000_0000#), 0.0, Bits_To_Value (16#8000_0000#), 0.0, Bits_To_Value (16#8000_0000#), 0.0, Bits_To_Value (16#8000_0000#), 0.0]);
      Map_Selectors : Wide.Lane_Selectors_32x8;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "F32x8 lane round trip");
      for Lane in Wide.Lane_Index_32x8 loop
         Check (Value_To_Bits (Wide.Extract (Wide.Zero, Lane)) = 0
           and then Value_To_Bits (Native.Extract (Native.Zero, Lane)) = 0,
           "F32x8 zero construction" & Lane'Image);
         for Position in Wide.Lane_Index_32x8 loop
            Check (Value_To_Bits (Wide.Extract (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane)), Position)) =
              (if Position = Lane then Value_To_Bits (A_Lanes (Lane)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Replace (Native.Zero, Lane, A_Lanes (Lane)), Position)) =
              (if Position = Lane then Value_To_Bits (A_Lanes (Lane)) else 0),
              "F32x8 lane replacement" & Lane'Image & Position'Image);
         end loop;
      end loop;
      Check (Wide.To_Lanes (Wide.Add (A, Two)) =
        [for Lane in Wide.Lane_Index_32x8 => A_Lanes (Lane) + 2.0], "F32x8 add");
      Check (Wide.To_Lanes (Wide.Multiply (A, Two)) =
        [for Lane in Wide.Lane_Index_32x8 => A_Lanes (Lane) * 2.0], "F32x8 multiply");
      Check (Wide.To_Bit_Mask (Wide.Less_Than (A, Two)) = 1,
        "F32x8 ordered comparison");
      for Lane in Wide.Lane_Index_32x8 loop
         Check (Packed (Lane) = (if Lane < 4 then A_Lanes (2 * Lane) else 0.0),
           "F32x8 compression");
         Check (Expanded (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0.0),
           "F32x8 expansion");
      end loop;
      Check (Wide.Reduce_Add (A) = 36.0,
        "F32x8 reduction");
      Check (Wide.Reduce_Min_Number (A) = F32 (1.0)
        and then Wide.Reduce_Max_Number (Wide.Splat (-1.0)) = F32 (-1.0),
        "F32x8 min and max reductions");
      Check (Wide.Reduce_Min_Number (Order_Vector) = 3.0
        and then Wide.Reduce_Max_Number (Order_Vector) = 3.0
        and then Native.Reduce_Min_Number (Order_Vector) = 3.0
        and then Native.Reduce_Max_Number (Order_Vector) = 3.0,
        "F32x8 ordered signaling-NaN reductions");
      Check (Value_To_Bits (Wide.Reduce_Min_Number (Positive_Zero_First)) = 16#8000_0000#
        and then Value_To_Bits (Wide.Reduce_Max_Number (Positive_Zero_First)) = 0
        and then Value_To_Bits (Wide.Reduce_Min_Number (Negative_Zero_First)) = 16#8000_0000#
        and then Value_To_Bits (Wide.Reduce_Max_Number (Negative_Zero_First)) = 0
        and then Value_To_Bits (Native.Reduce_Min_Number (Positive_Zero_First)) = 16#8000_0000#
        and then Value_To_Bits (Native.Reduce_Max_Number (Positive_Zero_First)) = 0
        and then Value_To_Bits (Native.Reduce_Min_Number (Negative_Zero_First)) = 16#8000_0000#
        and then Value_To_Bits (Native.Reduce_Max_Number (Negative_Zero_First)) = 0,
        "F32x8 signed-zero reductions");
      Check (Value_To_Bits (Wide.Reduce_Add (Wide.Splat (Bits_To_Value (16#8000_0000#)))) = 0
        and then Value_To_Bits (Native.Reduce_Add (Native.Splat (Bits_To_Value (16#8000_0000#)))) = 0,
        "F32x8 reduction positive-zero start");
      for Count in Wide.Lane_Count_32x8 loop
         Data := [others => 0.0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_32x8 => (if Lane < Count then A_Lanes (Lane) else 0.0)],
           "F32x8 partial memory");
      end loop;
      Check (Native.To_Lanes (Native.Multiply
        (Native.From_Lanes (A_Lanes), Native.Splat (2.0))) =
        Wide.To_Lanes (Wide.Multiply (A, Two)), "F32x8 native multiply");
      Check (Native.To_Lanes (Native.Add (A, Two)) = Wide.To_Lanes (Wide.Add (A, Two))
        and then Native.To_Lanes (Native.Subtract (A, Two)) = Wide.To_Lanes (Wide.Subtract (A, Two))
        and then Native.To_Lanes (Native.Divide (A, Two)) = Wide.To_Lanes (Wide.Divide (A, Two))
        and then Native.To_Lanes (Native.Min_Number (A, Two)) = Wide.To_Lanes (Wide.Min_Number (A, Two))
        and then Native.To_Lanes (Native.Max_Number (A, Two)) = Wide.To_Lanes (Wide.Max_Number (A, Two)),
        "F32x8 native floating arithmetic");
      Check (Native.To_Bit_Mask (Native.Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Less_Than (A, Two)) = Wide.To_Bit_Mask (Wide.Less_Than (A, Two))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, Two)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, Two))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Unordered (Specials, A)) = Wide.To_Bit_Mask (Wide.Unordered (Specials, A)),
        "F32x8 native floating comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, Two)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, Two)),
        "F32x8 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85)))) = Packed,
        "F32x8 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85))),
         Native.Mask_From_Bit_Mask (Mask_Bits_32x8 (85)))) = Expanded,
        "F32x8 native expansion");
      Check (Native.Reduce_Min_Number (Native.From_Lanes (A_Lanes)) = F32 (1.0)
        and then Native.Reduce_Max_Number (Native.Splat (-1.0)) = F32 (-1.0),
        "F32x8 native min and max reductions");
      Check (Value_To_Bits (Native.Reduce_Add (A)) = Value_To_Bits (Wide.Reduce_Add (A)),
        "F32x8 native add reduction");
      for Lane in Wide.Lane_Index_32x8 loop
         Map_Selectors (Lane) := Wide.Lane_Index_32x8 (7 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8))
            else Wide.Select_Right_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8))
            else Native.Select_Right_Lane (Wide.Lane_Index_32x8 ((Lane * 3 + 1) mod 8)));
      end loop;
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.F32x8 :=
           Wide.Permute_Lanes (Specials, A, Scalar_Map);
         Native_Result : constant Wide.F32x8 :=
           Native.Permute_Lanes (Specials, A, Native_Map);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Value_To_Bits (Wide.Extract (Scalar_Result, Lane)) =
              (if Lane mod 2 = 0
               then Value_To_Bits (Special_Lanes ((Lane * 3 + 1) mod 8))
               else Value_To_Bits (A_Lanes ((Lane * 3 + 1) mod 8)))
              and then Value_To_Bits (Native.Extract (Native_Result, Lane)) =
                Value_To_Bits (Wide.Extract (Scalar_Result, Lane)),
              "F32x8 special-bit two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_32x8;
         Native_Default_Map : Wide.Two_Source_Lane_Map_32x8;
         Scalar_Default : constant Wide.F32x8 :=
           Wide.Permute_Lanes (Specials, A, Scalar_Default_Map);
         Native_Default : constant Wide.F32x8 :=
           Native.Permute_Lanes (Specials, A, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Value_To_Bits (Wide.Extract (Scalar_Default, Lane)) =
              Value_To_Bits (Special_Lanes (0))
              and then Value_To_Bits (Wide.Extract (Native_Default, Lane)) =
                Value_To_Bits (Special_Lanes (0)),
              "F32x8 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Cast : constant Wide.U32x8 := Wide.Bit_Cast (Specials);
         Native_Cast : constant Wide.U32x8 := Native.Bit_Cast (Specials);
         Round_Trip : constant Wide.F32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F32x8 to U32x8 special direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F32x8 to U32x8 special bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I32, U32);
         Scalar_Cast : constant Wide.I32x8 := Wide.Bit_Cast (Specials);
         Native_Cast : constant Wide.I32x8 := Native.Bit_Cast (Specials);
         Round_Trip : constant Wide.F32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F32x8 to I32x8 special direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F32x8 to I32x8 special bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, Two)) = Wide.To_Lanes (Wide.Interleave_Low (A, Two))
        and then Native.To_Lanes (Native.Interleave_High (A, Two)) = Wide.To_Lanes (Wide.Interleave_High (A, Two))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, Two)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, Two))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, Two)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, Two)),
        "F32x8 native lane movement");
      for Slide in Natural range 0 .. 10 loop
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Value_To_Bits (Wide.Extract (Wide.Slide_Lanes_Toward_Low (Specials, Slide), Lane)) =
              (if Slide < 8 and then Lane < 8 - Slide then Value_To_Bits (Special_Lanes (Lane + Slide)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Slide_Lanes_Toward_Low (Specials, Slide), Lane)) =
              (if Slide < 8 and then Lane < 8 - Slide then Value_To_Bits (Special_Lanes (Lane + Slide)) else 0)
              and then Value_To_Bits (Wide.Extract (Wide.Slide_Lanes_Toward_High (Specials, Slide), Lane)) =
              (if Slide < 8 and then Lane >= Slide then Value_To_Bits (Special_Lanes (Lane - Slide)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Slide_Lanes_Toward_High (Specials, Slide), Lane)) =
              (if Slide < 8 and then Lane >= Slide then Value_To_Bits (Special_Lanes (Lane - Slide)) else 0),
              "F32x8 special-bit slide oracle" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "F32x8 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 8 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_32x8 :=
              (if True then Wide.Mask_Bits_32x8 (Pattern)
               else Wide.Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Scalar_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_32x8 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask),
              "F32x8 mask predicates" & Pattern'Image);
            Check (Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
              and then Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last,
              "F32x8 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_32x8 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "F32x8 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0.0];
      Native_Data := [others => 0.0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "F32x8 native unaligned memory");
      Data := [others => 0.0];
      Native_Data := [others => 0.0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "F32x8 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "F32x8 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, Two);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = Wide.To_Lanes (Two),
        "F32x8 scalar aligned memory");
      for Count in Wide.Lane_Count_32x8 loop
         Data := [others => 0.0];
         Native_Data := [others => 0.0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "F32x8 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.F32x8 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.F32x8 := Wide.From_Lanes (Random_Lanes);
            R_Bits : constant Wide.F32x8 := Wide.From_Lanes (Random_Bit_Lanes);
            R_Map : constant Wide.Lane_Map_32x8 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
            R_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Slide : constant Natural := Natural (Next_U64 mod 11);
         begin
            for Lane in Wide.Lane_Index_32x8 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_32x8 (Next_U64 mod 8))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_32x8 (Next_U64 mod 8)));
            end loop;
            Check (Native.To_Lanes (Native.Add (R_A, R_B)) = Wide.To_Lanes (Wide.Add (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply (R_A, R_B)),
              "F32x8 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Min_Number (R_A, R_B)) = Wide.To_Lanes (Wide.Min_Number (R_A, R_B))
              and then Native.To_Lanes (Native.Max_Number (R_A, R_B)) = Wide.To_Lanes (Wide.Max_Number (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "F32x8 randomized extrema and comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "F32x8 randomized selection and movement" & Iteration'Image);
            Check (Value_To_Bits (Native.Reduce_Add (R_A)) = Value_To_Bits (Wide.Reduce_Add (R_A))
              and then Value_To_Bits (Native.Reduce_Min_Number (R_A)) = Value_To_Bits (Wide.Reduce_Min_Number (R_A))
              and then Value_To_Bits (Native.Reduce_Max_Number (R_A)) = Value_To_Bits (Wide.Reduce_Max_Number (R_A)),
              "F32x8 randomized reductions" & Iteration'Image);
      declare
         Scalar_Cast : constant Wide.U32x8 := Wide.Bit_Cast (R_Bits);
         Native_Cast : constant Wide.U32x8 := Native.Bit_Cast (R_Bits);
         Round_Trip : constant Wide.F32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F32x8 to U32x8 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F32x8 to U32x8 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I32, U32);
         Scalar_Cast : constant Wide.I32x8 := Wide.Bit_Cast (R_Bits);
         Native_Cast : constant Wide.I32x8 := Native.Bit_Cast (R_Bits);
         Round_Trip : constant Wide.F32x8 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F32x8 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F32x8 to I32x8 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F32x8 to I32x8 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_F32x8;


   procedure Test_F64x4 is
      function Bits_To_Value is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, F64);
      function Value_To_Bits is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);
      function Random_Lanes return Wide.Lane_Values_F64x4 is
         Result : Wide.Lane_Values_F64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := F64 (Integer (Next_U64 mod 2_000_001) - 1_000_000) / 128.0;
         end loop;
         return Result;
      end Random_Lanes;
      function Random_Bit_Lanes return Wide.Lane_Values_F64x4 is
         Result : Wide.Lane_Values_F64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := Bits_To_Value
              (Interfaces.Unsigned_64 (Next_U64));
         end loop;
         return Result;
      end Random_Bit_Lanes;
      function Random_Map return Wide.Lane_Map_64x4 is
         Selectors : Wide.Lane_Selectors_64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Selectors (Lane) := Wide.Lane_Index_64x4 (Next_U64 mod 4);
         end loop;
         return Wide.Make_Lane_Map (Selectors);
      end Random_Map;
      A_Lanes : constant Wide.Lane_Values_F64x4 := [1.0, 2.0, 3.0, 4.0];
      A : constant Wide.F64x4 := Wide.From_Lanes (A_Lanes);
      Two : constant Wide.F64x4 := Wide.Splat (2.0);
      Alternating : constant Wide.Mask_64x4 :=
        Wide.Mask_From_Bit_Mask (Mask_Bits_64x4 (5));
      Packed : constant Wide.Lane_Values_F64x4 := Wide.To_Lanes (Wide.Compress (A, Alternating));
      Expanded : constant Wide.Lane_Values_F64x4 := Wide.To_Lanes
        (Wide.Expand (Wide.Compress (A, Alternating), Alternating));
      Data : F64_Array (5 .. 16) := [others => 0.0];
      Native_Data : F64_Array (5 .. 16) := [others => 0.0];
      Aligned_Data : F64_Array (0 .. 3) := [others => 0.0]
        with Alignment => 32;
      Special_Lanes : constant Wide.Lane_Values_F64x4 := [Bits_To_Value (0), Bits_To_Value (16#8000_0000_0000_0000#), Bits_To_Value (16#7FF0_0000_0000_0000#), Bits_To_Value (16#7FF8_1234_5678_9ABC#)];
      Specials : constant Wide.F64x4 := Wide.From_Lanes (Special_Lanes);
      Order_Vector : constant Wide.F64x4 := Wide.From_Lanes ([2.0, 1.0, Bits_To_Value (16#7FF0_1234_5678_9ABC#), 3.0]);
      Positive_Zero_First : constant Wide.F64x4 :=
        Wide.From_Lanes ([0.0, Bits_To_Value (16#8000_0000_0000_0000#), 0.0, Bits_To_Value (16#8000_0000_0000_0000#)]);
      Negative_Zero_First : constant Wide.F64x4 :=
        Wide.From_Lanes ([Bits_To_Value (16#8000_0000_0000_0000#), 0.0, Bits_To_Value (16#8000_0000_0000_0000#), 0.0]);
      Map_Selectors : Wide.Lane_Selectors_64x4;
      Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
      Native_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
   begin
      Check (Wide.To_Lanes (A) = A_Lanes, "F64x4 lane round trip");
      for Lane in Wide.Lane_Index_64x4 loop
         Check (Value_To_Bits (Wide.Extract (Wide.Zero, Lane)) = 0
           and then Value_To_Bits (Native.Extract (Native.Zero, Lane)) = 0,
           "F64x4 zero construction" & Lane'Image);
         for Position in Wide.Lane_Index_64x4 loop
            Check (Value_To_Bits (Wide.Extract (Wide.Replace (Wide.Zero, Lane, A_Lanes (Lane)), Position)) =
              (if Position = Lane then Value_To_Bits (A_Lanes (Lane)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Replace (Native.Zero, Lane, A_Lanes (Lane)), Position)) =
              (if Position = Lane then Value_To_Bits (A_Lanes (Lane)) else 0),
              "F64x4 lane replacement" & Lane'Image & Position'Image);
         end loop;
      end loop;
      Check (Wide.To_Lanes (Wide.Add (A, Two)) =
        [for Lane in Wide.Lane_Index_64x4 => A_Lanes (Lane) + 2.0], "F64x4 add");
      Check (Wide.To_Lanes (Wide.Multiply (A, Two)) =
        [for Lane in Wide.Lane_Index_64x4 => A_Lanes (Lane) * 2.0], "F64x4 multiply");
      Check (Wide.To_Bit_Mask (Wide.Less_Than (A, Two)) = 1,
        "F64x4 ordered comparison");
      for Lane in Wide.Lane_Index_64x4 loop
         Check (Packed (Lane) = (if Lane < 2 then A_Lanes (2 * Lane) else 0.0),
           "F64x4 compression");
         Check (Expanded (Lane) = (if Lane mod 2 = 0 then A_Lanes (Lane) else 0.0),
           "F64x4 expansion");
      end loop;
      Check (Wide.Reduce_Add (A) = 10.0,
        "F64x4 reduction");
      Check (Wide.Reduce_Min_Number (A) = F64 (1.0)
        and then Wide.Reduce_Max_Number (Wide.Splat (-1.0)) = F64 (-1.0),
        "F64x4 min and max reductions");
      Check (Wide.Reduce_Min_Number (Order_Vector) = 3.0
        and then Wide.Reduce_Max_Number (Order_Vector) = 3.0
        and then Native.Reduce_Min_Number (Order_Vector) = 3.0
        and then Native.Reduce_Max_Number (Order_Vector) = 3.0,
        "F64x4 ordered signaling-NaN reductions");
      Check (Value_To_Bits (Wide.Reduce_Min_Number (Positive_Zero_First)) = 16#8000_0000_0000_0000#
        and then Value_To_Bits (Wide.Reduce_Max_Number (Positive_Zero_First)) = 0
        and then Value_To_Bits (Wide.Reduce_Min_Number (Negative_Zero_First)) = 16#8000_0000_0000_0000#
        and then Value_To_Bits (Wide.Reduce_Max_Number (Negative_Zero_First)) = 0
        and then Value_To_Bits (Native.Reduce_Min_Number (Positive_Zero_First)) = 16#8000_0000_0000_0000#
        and then Value_To_Bits (Native.Reduce_Max_Number (Positive_Zero_First)) = 0
        and then Value_To_Bits (Native.Reduce_Min_Number (Negative_Zero_First)) = 16#8000_0000_0000_0000#
        and then Value_To_Bits (Native.Reduce_Max_Number (Negative_Zero_First)) = 0,
        "F64x4 signed-zero reductions");
      Check (Value_To_Bits (Wide.Reduce_Add (Wide.Splat (Bits_To_Value (16#8000_0000_0000_0000#)))) = 0
        and then Value_To_Bits (Native.Reduce_Add (Native.Splat (Bits_To_Value (16#8000_0000_0000_0000#)))) = 0,
        "F64x4 reduction positive-zero start");
      for Count in Wide.Lane_Count_64x4 loop
         Data := [others => 0.0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Check (Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)) =
           [for Lane in Wide.Lane_Index_64x4 => (if Lane < Count then A_Lanes (Lane) else 0.0)],
           "F64x4 partial memory");
      end loop;
      Check (Native.To_Lanes (Native.Multiply
        (Native.From_Lanes (A_Lanes), Native.Splat (2.0))) =
        Wide.To_Lanes (Wide.Multiply (A, Two)), "F64x4 native multiply");
      Check (Native.To_Lanes (Native.Add (A, Two)) = Wide.To_Lanes (Wide.Add (A, Two))
        and then Native.To_Lanes (Native.Subtract (A, Two)) = Wide.To_Lanes (Wide.Subtract (A, Two))
        and then Native.To_Lanes (Native.Divide (A, Two)) = Wide.To_Lanes (Wide.Divide (A, Two))
        and then Native.To_Lanes (Native.Min_Number (A, Two)) = Wide.To_Lanes (Wide.Min_Number (A, Two))
        and then Native.To_Lanes (Native.Max_Number (A, Two)) = Wide.To_Lanes (Wide.Max_Number (A, Two)),
        "F64x4 native floating arithmetic");
      Check (Native.To_Bit_Mask (Native.Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Less_Than (A, Two)) = Wide.To_Bit_Mask (Wide.Less_Than (A, Two))
        and then Native.To_Bit_Mask (Native.Less_Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Less_Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Greater_Than (A, Two)) = Wide.To_Bit_Mask (Wide.Greater_Than (A, Two))
        and then Native.To_Bit_Mask (Native.Greater_Equal (A, Two)) = Wide.To_Bit_Mask (Wide.Greater_Equal (A, Two))
        and then Native.To_Bit_Mask (Native.Unordered (Specials, A)) = Wide.To_Bit_Mask (Wide.Unordered (Specials, A)),
        "F64x4 native floating comparisons");
      Check (Native.To_Lanes (Native.Select_Value (Alternating, A, Two)) = Wide.To_Lanes (Wide.Select_Value (Alternating, A, Two)),
        "F64x4 native select");
      Check (Native.To_Lanes (Native.Compress
        (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5)))) = Packed,
        "F64x4 native compression");
      Check (Native.To_Lanes (Native.Expand
        (Native.Compress (Native.From_Lanes (A_Lanes), Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5))),
         Native.Mask_From_Bit_Mask (Mask_Bits_64x4 (5)))) = Expanded,
        "F64x4 native expansion");
      Check (Native.Reduce_Min_Number (Native.From_Lanes (A_Lanes)) = F64 (1.0)
        and then Native.Reduce_Max_Number (Native.Splat (-1.0)) = F64 (-1.0),
        "F64x4 native min and max reductions");
      Check (Value_To_Bits (Native.Reduce_Add (A)) = Value_To_Bits (Wide.Reduce_Add (A)),
        "F64x4 native add reduction");
      for Lane in Wide.Lane_Index_64x4 loop
         Map_Selectors (Lane) := Wide.Lane_Index_64x4 (3 - Lane);
         Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Wide.Select_Left_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4))
            else Wide.Select_Right_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4)));
         Native_Two_Selectors (Lane) :=
           (if Lane mod 2 = 0
            then Native.Select_Left_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4))
            else Native.Select_Right_Lane (Wide.Lane_Index_64x4 ((Lane * 3 + 1) mod 4)));
      end loop;
      declare
         Scalar_Map : constant Wide.Two_Source_Lane_Map_64x4 :=
           Wide.Make_Two_Source_Lane_Map (Two_Selectors);
         Native_Map : constant Wide.Two_Source_Lane_Map_64x4 :=
           Native.Make_Two_Source_Lane_Map (Native_Two_Selectors);
         Scalar_Result : constant Wide.F64x4 :=
           Wide.Permute_Lanes (Specials, A, Scalar_Map);
         Native_Result : constant Wide.F64x4 :=
           Native.Permute_Lanes (Specials, A, Native_Map);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Value_To_Bits (Wide.Extract (Scalar_Result, Lane)) =
              (if Lane mod 2 = 0
               then Value_To_Bits (Special_Lanes ((Lane * 3 + 1) mod 4))
               else Value_To_Bits (A_Lanes ((Lane * 3 + 1) mod 4)))
              and then Value_To_Bits (Native.Extract (Native_Result, Lane)) =
                Value_To_Bits (Wide.Extract (Scalar_Result, Lane)),
              "F64x4 special-bit two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Default_Map : Wide.Two_Source_Lane_Map_64x4;
         Native_Default_Map : Wide.Two_Source_Lane_Map_64x4;
         Scalar_Default : constant Wide.F64x4 :=
           Wide.Permute_Lanes (Specials, A, Scalar_Default_Map);
         Native_Default : constant Wide.F64x4 :=
           Native.Permute_Lanes (Specials, A, Native_Default_Map);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Value_To_Bits (Wide.Extract (Scalar_Default, Lane)) =
              Value_To_Bits (Special_Lanes (0))
              and then Value_To_Bits (Wide.Extract (Native_Default, Lane)) =
                Value_To_Bits (Special_Lanes (0)),
              "F64x4 default two-source lane map" & Lane'Image);
         end loop;
      end;
      declare
         Scalar_Cast : constant Wide.U64x4 := Wide.Bit_Cast (Specials);
         Native_Cast : constant Wide.U64x4 := Native.Bit_Cast (Specials);
         Round_Trip : constant Wide.F64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F64x4 to U64x4 special direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F64x4 to U64x4 special bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I64, U64);
         Scalar_Cast : constant Wide.I64x4 := Wide.Bit_Cast (Specials);
         Native_Cast : constant Wide.I64x4 := Native.Bit_Cast (Specials);
         Round_Trip : constant Wide.F64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F64x4 to I64x4 special direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (Specials, Lane)),
              "F64x4 to I64x4 special bit-cast round trip" & Lane'Image);
         end loop;
      end;

      Check (Native.To_Lanes (Native.Reverse_Lanes (A)) = Wide.To_Lanes (Wide.Reverse_Lanes (A))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Permute_Lanes (A, Native.Make_Lane_Map (Map_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (A, Wide.Make_Lane_Map (Map_Selectors)))
        and then Native.To_Lanes (Native.Interleave_Low (A, Two)) = Wide.To_Lanes (Wide.Interleave_Low (A, Two))
        and then Native.To_Lanes (Native.Interleave_High (A, Two)) = Wide.To_Lanes (Wide.Interleave_High (A, Two))
        and then Native.To_Lanes (Native.Deinterleave_Even (A, Two)) = Wide.To_Lanes (Wide.Deinterleave_Even (A, Two))
        and then Native.To_Lanes (Native.Deinterleave_Odd (A, Two)) = Wide.To_Lanes (Wide.Deinterleave_Odd (A, Two)),
        "F64x4 native lane movement");
      for Slide in Natural range 0 .. 6 loop
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Value_To_Bits (Wide.Extract (Wide.Slide_Lanes_Toward_Low (Specials, Slide), Lane)) =
              (if Slide < 4 and then Lane < 4 - Slide then Value_To_Bits (Special_Lanes (Lane + Slide)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Slide_Lanes_Toward_Low (Specials, Slide), Lane)) =
              (if Slide < 4 and then Lane < 4 - Slide then Value_To_Bits (Special_Lanes (Lane + Slide)) else 0)
              and then Value_To_Bits (Wide.Extract (Wide.Slide_Lanes_Toward_High (Specials, Slide), Lane)) =
              (if Slide < 4 and then Lane >= Slide then Value_To_Bits (Special_Lanes (Lane - Slide)) else 0)
              and then Value_To_Bits (Native.Extract (Native.Slide_Lanes_Toward_High (Specials, Slide), Lane)) =
              (if Slide < 4 and then Lane >= Slide then Value_To_Bits (Special_Lanes (Lane - Slide)) else 0),
              "F64x4 special-bit slide oracle" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Native.To_Bit_Mask (Native.Mask_And (Alternating, Native.Mask_Not (Alternating))) = 0
        and then Native.Population_Count (Alternating) = Wide.Population_Count (Alternating)
        and then Native.First_True (Alternating) = Wide.First_True (Alternating)
        and then Native.Last_True (Alternating) = Wide.Last_True (Alternating),
        "F64x4 native mask algebra and reductions");
      for Pattern in Natural range 0 .. 2 ** 4 - 1 loop
         declare
            Bits : constant Wide.Mask_Bits_64x4 :=
              (if True then Wide.Mask_Bits_64x4 (Pattern)
               else Wide.Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Scalar_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask (Bits);
            Native_Mask : constant Wide.Mask_64x4 := Native.Mask_From_Bit_Mask (Bits);
         begin
            Check (Wide.To_Bit_Mask (Scalar_Mask) = Bits
              and then Native.To_Bit_Mask (Native_Mask) = Bits
              and then Native.Any_True (Native_Mask) = Wide.Any_True (Scalar_Mask)
              and then Native.All_True (Native_Mask) = Wide.All_True (Scalar_Mask)
              and then Native.None_True (Native_Mask) = Wide.None_True (Scalar_Mask),
              "F64x4 mask predicates" & Pattern'Image);
            Check (Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
              and then Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last,
              "F64x4 mask algebra" & Pattern'Image);
            for Lane in Wide.Lane_Index_64x4 loop
               Check (Wide.Test (Scalar_Mask, Lane) = (((Bits / 2 ** Lane) mod 2) = 1)
                 and then Native.Test (Native_Mask, Lane) = Wide.Test (Scalar_Mask, Lane),
                 "F64x4 mask lane" & Pattern'Image & Lane'Image);
            end loop;
         end;
      end loop;
      Data := [others => 0.0];
      Native_Data := [others => 0.0];
      Native.Store_Unaligned (Native_Data, Native_Data'First + 1, A);
      Wide.Store_Unaligned (Data, Data'First + 1, A);
      Check (Native_Data = Data
        and then Native.To_Lanes (Native.Load_Unaligned (Native_Data, Native_Data'First + 1)) = A_Lanes,
        "F64x4 native unaligned memory");
      Data := [others => 0.0];
      Native_Data := [others => 0.0];
      Wide.Store (Data, Data'First, A);
      Native.Store (Native_Data, Native_Data'First, A);
      Check (Native_Data = Data
        and then Wide.To_Lanes (Wide.Load (Data, Data'First)) = A_Lanes
        and then Native.To_Lanes (Native.Load (Native_Data, Native_Data'First)) = A_Lanes,
        "F64x4 ordinary memory");
      Native.Store_Aligned (Aligned_Data, Aligned_Data'First, A);
      Check (Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "F64x4 native aligned memory");
      Wide.Store_Aligned (Aligned_Data, Aligned_Data'First, Two);
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Wide.To_Lanes (Wide.Load_Aligned (Aligned_Data, Aligned_Data'First)) = Wide.To_Lanes (Two),
        "F64x4 scalar aligned memory");
      for Count in Wide.Lane_Count_64x4 loop
         Data := [others => 0.0];
         Native_Data := [others => 0.0];
         Wide.Store_Partial (Data, Data'First, Count, A);
         Native.Store_Partial (Native_Data, Native_Data'First, Count, A);
         Check (Native_Data = Data
           and then Native.To_Lanes (Native.Load_Partial (Native_Data, Native_Data'First, Count)) =
             Wide.To_Lanes (Wide.Load_Partial (Data, Data'First, Count)),
           "F64x4 native partial memory" & Count'Image);
      end loop;
      for Iteration in 1 .. 128 loop
         declare
            R_A : constant Wide.F64x4 := Wide.From_Lanes (Random_Lanes);
            R_B : constant Wide.F64x4 := Wide.From_Lanes (Random_Lanes);
            R_Bits : constant Wide.F64x4 := Wide.From_Lanes (Random_Bit_Lanes);
            R_Map : constant Wide.Lane_Map_64x4 := Random_Map;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
            R_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Slide : constant Natural := Natural (Next_U64 mod 7);
         begin
            for Lane in Wide.Lane_Index_64x4 loop
               R_Two_Selectors (Lane) :=
                 (if Next_U64 mod 2 = 0
                  then Wide.Select_Left_Lane (Wide.Lane_Index_64x4 (Next_U64 mod 4))
                  else Wide.Select_Right_Lane (Wide.Lane_Index_64x4 (Next_U64 mod 4)));
            end loop;
            Check (Native.To_Lanes (Native.Add (R_A, R_B)) = Wide.To_Lanes (Wide.Add (R_A, R_B))
              and then Native.To_Lanes (Native.Subtract (R_A, R_B)) = Wide.To_Lanes (Wide.Subtract (R_A, R_B))
              and then Native.To_Lanes (Native.Multiply (R_A, R_B)) = Wide.To_Lanes (Wide.Multiply (R_A, R_B)),
              "F64x4 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Min_Number (R_A, R_B)) = Wide.To_Lanes (Wide.Min_Number (R_A, R_B))
              and then Native.To_Lanes (Native.Max_Number (R_A, R_B)) = Wide.To_Lanes (Wide.Max_Number (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "F64x4 randomized extrema and comparisons" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_Map)) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_Map))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "F64x4 randomized selection and movement" & Iteration'Image);
            Check (Value_To_Bits (Native.Reduce_Add (R_A)) = Value_To_Bits (Wide.Reduce_Add (R_A))
              and then Value_To_Bits (Native.Reduce_Min_Number (R_A)) = Value_To_Bits (Wide.Reduce_Min_Number (R_A))
              and then Value_To_Bits (Native.Reduce_Max_Number (R_A)) = Value_To_Bits (Wide.Reduce_Max_Number (R_A)),
              "F64x4 randomized reductions" & Iteration'Image);
      declare
         Scalar_Cast : constant Wide.U64x4 := Wide.Bit_Cast (R_Bits);
         Native_Cast : constant Wide.U64x4 := Native.Bit_Cast (R_Bits);
         Round_Trip : constant Wide.F64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Wide.Extract (Scalar_Cast, Lane) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Wide.Extract (Native_Cast, Lane) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F64x4 to U64x4 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F64x4 to U64x4 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;
      declare
         function Target_To_Bits is new Ada.Unchecked_Conversion (I64, U64);
         Scalar_Cast : constant Wide.I64x4 := Wide.Bit_Cast (R_Bits);
         Native_Cast : constant Wide.I64x4 := Native.Bit_Cast (R_Bits);
         Round_Trip : constant Wide.F64x4 := Wide.Bit_Cast (Scalar_Cast);
         Native_Round_Trip : constant Wide.F64x4 := Native.Bit_Cast (Native_Cast);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Check (Target_To_Bits (Wide.Extract (Scalar_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Target_To_Bits (Wide.Extract (Native_Cast, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F64x4 to I64x4 randomized direct bit cast" & Lane'Image);
            Check (Value_To_Bits (Wide.Extract (Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane))
              and then Value_To_Bits (Wide.Extract (Native_Round_Trip, Lane)) = Value_To_Bits (Wide.Extract (R_Bits, Lane)),
              "F64x4 to I64x4 randomized bit-cast round trip" & Lane'Image);
         end loop;
      end;

         end;
      end loop;
   end Test_F64x4;

begin
   Ada.Text_IO.Put_Line ("wide-family differential tests seed=0xA5C371D94E82B60F");
   Test_U8x32;
   Test_I8x32;
   Test_U16x16;
   Test_I16x16;
   Test_U32x8;
   Test_I32x8;
   Test_U64x4;
   Test_I64x4;
   Test_F32x8;
   Test_F64x4;
   Ada.Text_IO.Put_Line ("wide-family semantic tests: PASS");
end Wide_Tests;
