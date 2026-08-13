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



      type Comparison_Kind is
        (Is_Equal, Is_Less, Is_Less_Equal, Is_Greater, Is_Greater_Equal);

      function Reference_Comparison
        (Left, Right : Wide.Lane_Values_U8x32; Kind : Comparison_Kind)
         return Wide.Mask_Bits_8x32
      is
         Result : Wide.Mask_Bits_8x32 := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if (case Kind is
                  when Is_Equal         => Left (Lane) = Right (Lane),
                  when Is_Less          => Left (Lane) < Right (Lane),
                  when Is_Less_Equal    => Left (Lane) <= Right (Lane),
                  when Is_Greater       => Left (Lane) > Right (Lane),
                  when Is_Greater_Equal => Left (Lane) >= Right (Lane))
            then
               Result := Result or Interfaces.Shift_Left
                 (Wide.Mask_Bits_8x32 (1), Lane);
            end if;
         end loop;
         return Result;
      end Reference_Comparison;

      function Reference_Select
        (Bits : Wide.Mask_Bits_8x32; If_True, If_False : Wide.Lane_Values_U8x32)
         return Wide.Lane_Values_U8x32
      is
        ([for Lane in Wide.Lane_Index_8x32 =>
           (if ((Bits / 2 ** Lane) mod 2) = 1
            then If_True (Lane) else If_False (Lane))]);

      function Random_Lanes return Wide.Lane_Values_U8x32 is
         Result : Wide.Lane_Values_U8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result (Lane) := U8 (Next_U64 mod 2 ** 8);
         end loop;
         return Result;
      end Random_Lanes;

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_U8x32) return U8
      is
         Result : U8 := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_U8x32) return U8
      is
         Result : U8 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_U8x32) return U8
      is
         Result : U8 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_U8x32; Bits : Wide.Mask_Bits_8x32)
         return Wide.Lane_Values_U8x32
      is
         Result : Wide.Lane_Values_U8x32 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_U8x32; Bits : Wide.Mask_Bits_8x32)
         return Wide.Lane_Values_U8x32
      is
         Result : Wide.Lane_Values_U8x32 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_U8x32;
         Bits : Wide.Mask_Bits_8x32;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_8x32 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_8x32 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.U8x32 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.U8x32 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_U8x32 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_U8x32 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_U8x32 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.U8x32 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.U8x32 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.U8x32 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.U8x32 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.U8x32 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.U8x32 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "U8x32 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "U8x32 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "U8x32 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_8x32) return Wide.Lane_Count_8x32
      is
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 32;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_8x32) return Wide.Lane_Count_8x32
      is
      begin
         for Lane in reverse Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 32;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_8x32) return Wide.Lane_Count_8x32
      is
         Result : Wide.Lane_Count_8x32 := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_8x32; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_8x32 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_8x32 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_8x32 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_8x32 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_8x32 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "U8x32 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_U8x32;
         One_Selectors : Wide.Lane_Selectors_8x32;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
         Expected_One, Expected_Two : Wide.Lane_Values_U8x32;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.U8x32 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.U8x32 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.U8x32 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.U8x32 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.U8x32 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.U8x32 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.U8x32 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.U8x32 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "U8x32 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "U8x32 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_U8x32; Label_Text : String)
      is
         Left : constant Wide.U8x32 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.U8x32 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.U8x32;
            Expected : Wide.Lane_Values_U8x32; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "U8x32 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_8x32 => Left_Values (31 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane mod 2 = 0
                then Left_Values (16 + Lane / 2)
                else Right_Values (16 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane < 16
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 16)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane < 16
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 16) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 34 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_8x32 =>
                  (if Count < 32 and then Lane < 32 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_8x32 =>
                  (if Count < 32 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


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

      A_Lanes : constant Wide.Lane_Values_U8x32 := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
      B_Lanes : constant Wide.Lane_Values_U8x32 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U8x32 := [U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#), U8 (16#00#), U8 (16#80#), U8 (16#FF#), U8 (16#AA#)];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_U8x32 :=
        [U8'First, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, U8'Last, U8'First, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, U8'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "U8x32 splat construction");
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

      declare
         Edge_A : constant Wide.U8x32 := Wide.From_Lanes ([0, 255, 255, 1, 128, 127, 200, 55, 0, 255, 255, 1, 128, 127, 200, 55, 0, 255, 255, 1, 128, 127, 200, 55, 0, 255, 255, 1, 128, 127, 200, 55]);
         Edge_B : constant Wide.U8x32 := Wide.From_Lanes ([1, 1, 255, 2, 128, 129, 100, 250, 1, 1, 255, 2, 128, 129, 100, 250, 1, 1, 255, 2, 128, 129, 100, 250, 1, 1, 255, 2, 128, 129, 100, 250]);
         Add_Wrap_Expected : constant Wide.Lane_Values_U8x32 :=
           [1, 0, 254, 3, 0, 0, 44, 49, 1, 0, 254, 3, 0, 0, 44, 49, 1, 0, 254, 3, 0, 0, 44, 49, 1, 0, 254, 3, 0, 0, 44, 49];
         Subtract_Wrap_Expected : constant Wide.Lane_Values_U8x32 :=
           [255, 254, 0, 255, 0, 254, 100, 61, 255, 254, 0, 255, 0, 254, 100, 61, 255, 254, 0, 255, 0, 254, 100, 61, 255, 254, 0, 255, 0, 254, 100, 61];
         Multiply_Wrap_Expected : constant Wide.Lane_Values_U8x32 :=
           [0, 255, 1, 2, 0, 255, 32, 182, 0, 255, 1, 2, 0, 255, 32, 182, 0, 255, 1, 2, 0, 255, 32, 182, 0, 255, 1, 2, 0, 255, 32, 182];
         Add_Saturate_Expected : constant Wide.Lane_Values_U8x32 :=
           [1, 255, 255, 3, 255, 255, 255, 255, 1, 255, 255, 3, 255, 255, 255, 255, 1, 255, 255, 3, 255, 255, 255, 255, 1, 255, 255, 3, 255, 255, 255, 255];
         Subtract_Saturate_Expected : constant Wide.Lane_Values_U8x32 :=
           [0, 254, 0, 0, 0, 0, 100, 0, 0, 254, 0, 0, 0, 0, 100, 0, 0, 254, 0, 0, 0, 0, 100, 0, 0, 254, 0, 0, 0, 0, 100, 0];
         Min_Expected : constant Wide.Lane_Values_U8x32 :=
           [0, 1, 255, 1, 128, 127, 100, 55, 0, 1, 255, 1, 128, 127, 100, 55, 0, 1, 255, 1, 128, 127, 100, 55, 0, 1, 255, 1, 128, 127, 100, 55];
         Max_Expected : constant Wide.Lane_Values_U8x32 :=
           [1, 255, 255, 2, 128, 129, 200, 250, 1, 255, 255, 2, 128, 129, 200, 250, 1, 255, 255, 2, 128, 129, 200, 250, 1, 255, 255, 2, 128, 129, 200, 250];
      begin
         Check (Wide.To_Lanes (Wide.Add_Wrap (Edge_A, Edge_B)) = Add_Wrap_Expected
           and then Native.To_Lanes (Native.Add_Wrap (Edge_A, Edge_B)) = Add_Wrap_Expected
           and then Wide.To_Lanes (Wide.Subtract_Wrap (Edge_A, Edge_B)) = Subtract_Wrap_Expected
           and then Native.To_Lanes (Native.Subtract_Wrap (Edge_A, Edge_B)) = Subtract_Wrap_Expected
           and then Wide.To_Lanes (Wide.Multiply_Wrap (Edge_A, Edge_B)) = Multiply_Wrap_Expected
           and then Native.To_Lanes (Native.Multiply_Wrap (Edge_A, Edge_B)) = Multiply_Wrap_Expected,
           "U8x32 literal wrapping boundaries");
         Check (Wide.To_Lanes (Wide.Add_Saturate (Edge_A, Edge_B)) = Add_Saturate_Expected
           and then Native.To_Lanes (Native.Add_Saturate (Edge_A, Edge_B)) = Add_Saturate_Expected
           and then Wide.To_Lanes (Wide.Subtract_Saturate (Edge_A, Edge_B)) = Subtract_Saturate_Expected
           and then Native.To_Lanes (Native.Subtract_Saturate (Edge_A, Edge_B)) = Subtract_Saturate_Expected,
           "U8x32 literal saturation boundaries");
         Check (Wide.To_Lanes (Wide.Min (Edge_A, Edge_B)) = Min_Expected
           and then Native.To_Lanes (Native.Min (Edge_A, Edge_B)) = Min_Expected
           and then Wide.To_Lanes (Wide.Max (Edge_A, Edge_B)) = Max_Expected
           and then Native.To_Lanes (Native.Max (Edge_A, Edge_B)) = Max_Expected,
           "U8x32 literal signedness extrema");
      end;


      --  Cover all 65,536 ordered byte pairs. Each batch places 32
      --  consecutive pairs in distinct lanes and checks every relation
      --  against this independent lane oracle.
      for Batch in Natural range 0 .. 2_047 loop
         declare
            Left_Lanes : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
                 (declare
                    Pair : constant Natural := Batch * 32 + Lane;
                  begin U8 (Pair / 256))];
            Right_Lanes : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
                 (declare
                    Pair : constant Natural := Batch * 32 + Lane;
                  begin U8 (Pair mod 256))];
            Left_Value : constant Wide.U8x32 := Wide.From_Lanes (Left_Lanes);
            Right_Value : constant Wide.U8x32 := Wide.From_Lanes (Right_Lanes);
            Equal_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Equal);
            Less_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Less);
            Less_Equal_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Less_Equal);
            Greater_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Greater);
            Greater_Equal_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Greater_Equal);
         begin
            Check (Wide.To_Bit_Mask (Wide.Equal (Left_Value, Right_Value)) = Equal_Bits
              and then Native.To_Bit_Mask (Native.Equal (Left_Value, Right_Value)) = Equal_Bits,
              "U8x32 exhaustive equality" & Batch'Image);
            Check (Wide.To_Bit_Mask (Wide.Less_Than (Left_Value, Right_Value)) = Less_Bits
              and then Native.To_Bit_Mask (Native.Less_Than (Left_Value, Right_Value)) = Less_Bits
              and then Wide.To_Bit_Mask (Wide.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits
              and then Native.To_Bit_Mask (Native.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits,
              "U8x32 exhaustive less comparisons" & Batch'Image);
            Check (Wide.To_Bit_Mask (Wide.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
              and then Native.To_Bit_Mask (Native.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
              and then Wide.To_Bit_Mask (Wide.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits
              and then Native.To_Bit_Mask (Native.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits,
              "U8x32 exhaustive greater comparisons" & Batch'Image);
         end;
      end loop;
      for Lane in Wide.Lane_Index_8x32 loop
         declare
            Bits : constant Wide.Mask_Bits_8x32 := Interfaces.Shift_Left
              (Wide.Mask_Bits_8x32 (1), Lane);
            Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask (Bits);
            Expected : constant Wide.Lane_Values_U8x32 :=
              Reference_Select (Bits, A_Lanes, B_Lanes);
         begin
            Check (Wide.To_Lanes (Wide.Select_Value (Mask, A, B)) = Expected
              and then Native.To_Lanes (Native.Select_Value (Mask, A, B)) = Expected,
              "U8x32 individual selection mask" & Lane'Image);
         end;
      end loop;
      declare
         Selection_Patterns : constant array (Natural range 0 .. 5) of
           Wide.Mask_Bits_8x32 :=
             [0, Wide.Mask_Bits_8x32'Last, 16#0000_FFFF#, 16#FFFF_0000#,
              16#AAAA_AAAA#, 16#5555_5555#];
      begin
         for Pattern of Selection_Patterns loop
            declare
               Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask (Pattern);
               Expected : constant Wide.Lane_Values_U8x32 :=
                 Reference_Select (Pattern, A_Lanes, B_Lanes);
            begin
               Check (Wide.To_Lanes (Wide.Select_Value (Mask, A, B)) = Expected
                 and then Native.To_Lanes (Native.Select_Value (Mask, A, B)) = Expected,
                 "U8x32 fixed selection mask" & Pattern'Image);
            end;
         end loop;
      end;


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

      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 8)) = Wide.Lane_Values_U8x32'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 15)) = Wide.Lane_Values_U8x32'[others => 0],
        "U8x32 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_8x32'Last,
        "U8x32 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "U8x32 selection");

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_8x32'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_8x32 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_8x32 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 32 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_8x32 :=
              (if Count = 32
               then Wide.Mask_Bits_8x32'Last
               else Wide.Mask_Bits_8x32 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_8x32'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_8x32 :=
           Wide.Mask_Bits_8x32 (2 ** 16 - 1);
         High_Half : constant Wide.Mask_Bits_8x32 :=
           Wide.Mask_Bits_8x32'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_8x32 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_8x32 (1), 15)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_8x32 (1), 16);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_8x32 (1431655765),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_8x32 => A_Lanes (31 - Lane)],
         [for Lane in Wide.Lane_Index_8x32 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 32)
             else B_Lanes ((Lane * 3 + 1) mod 32))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_8x32 :=
           [for Lane in Wide.Lane_Index_8x32 => Lane];
         Broadcast : constant Wide.Lane_Selectors_8x32 := [others => 16];
         All_Left : constant Wide.Two_Source_Lane_Selectors_8x32 :=
           [for Lane in Wide.Lane_Index_8x32 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_8x32 :=
           [for Lane in Wide.Lane_Index_8x32 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (16)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_8x32'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (32 - 1), "last lane");
      Check_Mask_Positions (2 ** (16 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 16, "high-half boundary");
      Check_Mask_Positions (1431655765, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "U8x32 independent fixed reductions");
      declare
         Edge_Value : constant Wide.U8x32 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = U8'First
           and then Native.Reduce_Min (Edge_Value) = U8'First
           and then Wide.Reduce_Max (Edge_Value) = U8'Last
           and then Native.Reduce_Max (Edge_Value) = U8'Last,
           "U8x32 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_8x32'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_8x32'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_8x32'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U8x32 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "U8x32 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "U8x32 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_U8x32 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_U8x32 := Random_Lanes;
            R_A : constant Wide.U8x32 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.U8x32 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_8x32;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
            Expected_One : Wide.Lane_Values_U8x32;
            Expected_Two : Wide.Lane_Values_U8x32;
            R_Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_8x32 (Next_U64 mod 2 ** 32));
            Shift : constant Natural := Natural (Next_U64 mod 11);
            Slide : constant Natural := Natural (Next_U64 mod 35);
         begin
            for Lane in Wide.Lane_Index_8x32 loop
               declare
                  One_Lane : constant Wide.Lane_Index_8x32 :=
                    Wide.Lane_Index_8x32 (Next_U64 mod 32);
                  Two_Lane : constant Wide.Lane_Index_8x32 :=
                    Wide.Lane_Index_8x32 (Next_U64 mod 32);
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
              "U8x32 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U8x32 randomized bitwise extrema" & Iteration'Image);

            declare
               R_A_Lanes : constant Wide.Lane_Values_U8x32 := Wide.To_Lanes (R_A);
               R_B_Lanes : constant Wide.Lane_Values_U8x32 := Wide.To_Lanes (R_B);
               Add_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => R_A_Lanes (Lane) + R_B_Lanes (Lane)];
               Subtract_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => R_A_Lanes (Lane) - R_B_Lanes (Lane)];
               Multiply_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => R_A_Lanes (Lane) * R_B_Lanes (Lane)];
               Add_Saturate_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => U8 (Natural'Min (Natural (U8'Last), Natural (R_A_Lanes (Lane)) + Natural (R_B_Lanes (Lane))))];
               Subtract_Saturate_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => (if R_A_Lanes (Lane) < R_B_Lanes (Lane) then 0 else R_A_Lanes (Lane) - R_B_Lanes (Lane))];
               And_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => R_A_Lanes (Lane) and R_B_Lanes (Lane)];
               Or_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => R_A_Lanes (Lane) or R_B_Lanes (Lane)];
               Xor_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => R_A_Lanes (Lane) xor R_B_Lanes (Lane)];
               Not_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => not R_A_Lanes (Lane)];
               Min_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 =>
                    (if R_A_Lanes (Lane) < R_B_Lanes (Lane)
                     then R_A_Lanes (Lane) else R_B_Lanes (Lane))];
               Max_Expected : constant Wide.Lane_Values_U8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 =>
                    (if R_A_Lanes (Lane) > R_B_Lanes (Lane)
                     then R_A_Lanes (Lane) else R_B_Lanes (Lane))];
            begin
               Check (Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B)) = Add_Expected
                 and then Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Add_Expected
                 and then Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B)) = Subtract_Expected
                 and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Subtract_Expected
                 and then Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B)) = Multiply_Expected
                 and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Multiply_Expected,
                 "U8x32 independent randomized wrapping arithmetic" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B)) = Add_Saturate_Expected
                 and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Add_Saturate_Expected
                 and then Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)) = Subtract_Saturate_Expected
                 and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Subtract_Saturate_Expected,
                 "U8x32 independent randomized saturating arithmetic" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B)) = And_Expected
                 and then Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = And_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B)) = Or_Expected
                 and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Or_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B)) = Xor_Expected
                 and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Xor_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Not (R_A)) = Not_Expected
                 and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Not_Expected,
                 "U8x32 independent randomized bitwise operations" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Min (R_A, R_B)) = Min_Expected
                 and then Native.To_Lanes (Native.Min (R_A, R_B)) = Min_Expected
                 and then Wide.To_Lanes (Wide.Max (R_A, R_B)) = Max_Expected
                 and then Native.To_Lanes (Native.Max (R_A, R_B)) = Max_Expected,
                 "U8x32 independent randomized extrema" & Iteration'Image);
            end;


            declare
               R_A_Lanes : constant Wide.Lane_Values_U8x32 := Wide.To_Lanes (R_A);
               R_B_Lanes : constant Wide.Lane_Values_U8x32 := Wide.To_Lanes (R_B);
               R_Bits : constant Wide.Mask_Bits_8x32 := Wide.To_Bit_Mask (R_Mask);
               Select_Expected : constant Wide.Lane_Values_U8x32 :=
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
                 "U8x32 independent randomized strict predicates" & Iteration'Image);
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
                 "U8x32 independent randomized inclusive predicates" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B)) = Select_Expected
                 and then Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Select_Expected,
                 "U8x32 independent randomized selection" & Iteration'Image);
            end;

            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U8x32 randomized selection and movement" & Iteration'Image);

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
              "U8x32 independent randomized reductions" & Iteration'Image);
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

      type Comparison_Kind is
        (Is_Equal, Is_Less, Is_Less_Equal, Is_Greater, Is_Greater_Equal);

      function Reference_Comparison
        (Left, Right : Wide.Lane_Values_I8x32; Kind : Comparison_Kind)
         return Wide.Mask_Bits_8x32
      is
         Result : Wide.Mask_Bits_8x32 := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if (case Kind is
                  when Is_Equal         => Left (Lane) = Right (Lane),
                  when Is_Less          => Left (Lane) < Right (Lane),
                  when Is_Less_Equal    => Left (Lane) <= Right (Lane),
                  when Is_Greater       => Left (Lane) > Right (Lane),
                  when Is_Greater_Equal => Left (Lane) >= Right (Lane))
            then
               Result := Result or Interfaces.Shift_Left
                 (Wide.Mask_Bits_8x32 (1), Lane);
            end if;
         end loop;
         return Result;
      end Reference_Comparison;

      function Reference_Select
        (Bits : Wide.Mask_Bits_8x32; If_True, If_False : Wide.Lane_Values_I8x32)
         return Wide.Lane_Values_I8x32
      is
        ([for Lane in Wide.Lane_Index_8x32 =>
           (if ((Bits / 2 ** Lane) mod 2) = 1
            then If_True (Lane) else If_False (Lane))]);

      function Random_Lanes return Wide.Lane_Values_I8x32 is
         Result : Wide.Lane_Values_I8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result (Lane) := Bits_To_Value (U8 (Next_U64 mod 2 ** 8));
         end loop;
         return Result;
      end Random_Lanes;

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_I8x32) return I8
      is
         Result : U8 := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result := Result + Value_To_Bits (Values (Lane));
         end loop;
         return Bits_To_Value (Result);
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_I8x32) return I8
      is
         Result : I8 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_I8x32) return I8
      is
         Result : I8 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_I8x32; Bits : Wide.Mask_Bits_8x32)
         return Wide.Lane_Values_I8x32
      is
         Result : Wide.Lane_Values_I8x32 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_I8x32; Bits : Wide.Mask_Bits_8x32)
         return Wide.Lane_Values_I8x32
      is
         Result : Wide.Lane_Values_I8x32 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_I8x32;
         Bits : Wide.Mask_Bits_8x32;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_8x32 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_8x32 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.I8x32 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.I8x32 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_I8x32 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_I8x32 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_I8x32 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.I8x32 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.I8x32 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.I8x32 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.I8x32 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.I8x32 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.I8x32 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "I8x32 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "I8x32 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "I8x32 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_8x32) return Wide.Lane_Count_8x32
      is
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 32;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_8x32) return Wide.Lane_Count_8x32
      is
      begin
         for Lane in reverse Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 32;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_8x32) return Wide.Lane_Count_8x32
      is
         Result : Wide.Lane_Count_8x32 := 0;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_8x32; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_8x32 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_8x32 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_8x32 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_8x32 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_8x32 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "I8x32 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_I8x32;
         One_Selectors : Wide.Lane_Selectors_8x32;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
         Expected_One, Expected_Two : Wide.Lane_Values_I8x32;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.I8x32 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.I8x32 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.I8x32 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.I8x32 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.I8x32 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.I8x32 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.I8x32 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.I8x32 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "I8x32 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "I8x32 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_I8x32; Label_Text : String)
      is
         Left : constant Wide.I8x32 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.I8x32 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.I8x32;
            Expected : Wide.Lane_Values_I8x32; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "I8x32 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_8x32 => Left_Values (31 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane mod 2 = 0
                then Left_Values (16 + Lane / 2)
                else Right_Values (16 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane < 16
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 16)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_8x32 =>
               (if Lane < 16
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 16) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 34 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_8x32 =>
                  (if Count < 32 and then Lane < 32 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_8x32 =>
                  (if Count < 32 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_I8x32 := [-16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
      B_Lanes : constant Wide.Lane_Values_I8x32 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I8x32 := [Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#)), Bits_To_Value (U8 (16#00#)), Bits_To_Value (U8 (16#80#)), Bits_To_Value (U8 (16#FF#)), Bits_To_Value (U8 (16#AA#))];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_I8x32 :=
        [I8'First, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, I8'Last, I8'First, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, I8'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "I8x32 splat construction");
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

      declare
         Edge_A : constant Wide.I8x32 := Wide.From_Lanes ([-128, 127, 127, -128, 100, -100, -1, 1, -128, 127, 127, -128, 100, -100, -1, 1, -128, 127, 127, -128, 100, -100, -1, 1, -128, 127, 127, -128, 100, -100, -1, 1]);
         Edge_B : constant Wide.I8x32 := Wide.From_Lanes ([-1, 1, 127, -128, 100, -100, -128, 127, -1, 1, 127, -128, 100, -100, -128, 127, -1, 1, 127, -128, 100, -100, -128, 127, -1, 1, 127, -128, 100, -100, -128, 127]);
         Add_Wrap_Expected : constant Wide.Lane_Values_I8x32 :=
           [127, -128, -2, 0, -56, 56, 127, -128, 127, -128, -2, 0, -56, 56, 127, -128, 127, -128, -2, 0, -56, 56, 127, -128, 127, -128, -2, 0, -56, 56, 127, -128];
         Subtract_Wrap_Expected : constant Wide.Lane_Values_I8x32 :=
           [-127, 126, 0, 0, 0, 0, 127, -126, -127, 126, 0, 0, 0, 0, 127, -126, -127, 126, 0, 0, 0, 0, 127, -126, -127, 126, 0, 0, 0, 0, 127, -126];
         Multiply_Wrap_Expected : constant Wide.Lane_Values_I8x32 :=
           [-128, 127, 1, 0, 16, 16, -128, 127, -128, 127, 1, 0, 16, 16, -128, 127, -128, 127, 1, 0, 16, 16, -128, 127, -128, 127, 1, 0, 16, 16, -128, 127];
         Add_Saturate_Expected : constant Wide.Lane_Values_I8x32 :=
           [-128, 127, 127, -128, 127, -128, -128, 127, -128, 127, 127, -128, 127, -128, -128, 127, -128, 127, 127, -128, 127, -128, -128, 127, -128, 127, 127, -128, 127, -128, -128, 127];
         Subtract_Saturate_Expected : constant Wide.Lane_Values_I8x32 :=
           [-127, 126, 0, 0, 0, 0, 127, -126, -127, 126, 0, 0, 0, 0, 127, -126, -127, 126, 0, 0, 0, 0, 127, -126, -127, 126, 0, 0, 0, 0, 127, -126];
         Min_Expected : constant Wide.Lane_Values_I8x32 :=
           [-128, 1, 127, -128, 100, -100, -128, 1, -128, 1, 127, -128, 100, -100, -128, 1, -128, 1, 127, -128, 100, -100, -128, 1, -128, 1, 127, -128, 100, -100, -128, 1];
         Max_Expected : constant Wide.Lane_Values_I8x32 :=
           [-1, 127, 127, -128, 100, -100, -1, 127, -1, 127, 127, -128, 100, -100, -1, 127, -1, 127, 127, -128, 100, -100, -1, 127, -1, 127, 127, -128, 100, -100, -1, 127];
      begin
         Check (Wide.To_Lanes (Wide.Add_Wrap (Edge_A, Edge_B)) = Add_Wrap_Expected
           and then Native.To_Lanes (Native.Add_Wrap (Edge_A, Edge_B)) = Add_Wrap_Expected
           and then Wide.To_Lanes (Wide.Subtract_Wrap (Edge_A, Edge_B)) = Subtract_Wrap_Expected
           and then Native.To_Lanes (Native.Subtract_Wrap (Edge_A, Edge_B)) = Subtract_Wrap_Expected
           and then Wide.To_Lanes (Wide.Multiply_Wrap (Edge_A, Edge_B)) = Multiply_Wrap_Expected
           and then Native.To_Lanes (Native.Multiply_Wrap (Edge_A, Edge_B)) = Multiply_Wrap_Expected,
           "I8x32 literal wrapping boundaries");
         Check (Wide.To_Lanes (Wide.Add_Saturate (Edge_A, Edge_B)) = Add_Saturate_Expected
           and then Native.To_Lanes (Native.Add_Saturate (Edge_A, Edge_B)) = Add_Saturate_Expected
           and then Wide.To_Lanes (Wide.Subtract_Saturate (Edge_A, Edge_B)) = Subtract_Saturate_Expected
           and then Native.To_Lanes (Native.Subtract_Saturate (Edge_A, Edge_B)) = Subtract_Saturate_Expected,
           "I8x32 literal saturation boundaries");
         Check (Wide.To_Lanes (Wide.Min (Edge_A, Edge_B)) = Min_Expected
           and then Native.To_Lanes (Native.Min (Edge_A, Edge_B)) = Min_Expected
           and then Wide.To_Lanes (Wide.Max (Edge_A, Edge_B)) = Max_Expected
           and then Native.To_Lanes (Native.Max (Edge_A, Edge_B)) = Max_Expected,
           "I8x32 literal signedness extrema");
      end;


      --  Cover all 65,536 ordered byte pairs. Each batch places 32
      --  consecutive pairs in distinct lanes and checks every relation
      --  against this independent lane oracle.
      for Batch in Natural range 0 .. 2_047 loop
         declare
            Left_Lanes : constant Wide.Lane_Values_I8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
                 (declare
                    Pair : constant Natural := Batch * 32 + Lane;
                  begin Bits_To_Value (U8 (Pair / 256)))];
            Right_Lanes : constant Wide.Lane_Values_I8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
                 (declare
                    Pair : constant Natural := Batch * 32 + Lane;
                  begin Bits_To_Value (U8 (Pair mod 256)))];
            Left_Value : constant Wide.I8x32 := Wide.From_Lanes (Left_Lanes);
            Right_Value : constant Wide.I8x32 := Wide.From_Lanes (Right_Lanes);
            Equal_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Equal);
            Less_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Less);
            Less_Equal_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Less_Equal);
            Greater_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Greater);
            Greater_Equal_Bits : constant Wide.Mask_Bits_8x32 :=
              Reference_Comparison (Left_Lanes, Right_Lanes, Is_Greater_Equal);
         begin
            Check (Wide.To_Bit_Mask (Wide.Equal (Left_Value, Right_Value)) = Equal_Bits
              and then Native.To_Bit_Mask (Native.Equal (Left_Value, Right_Value)) = Equal_Bits,
              "I8x32 exhaustive equality" & Batch'Image);
            Check (Wide.To_Bit_Mask (Wide.Less_Than (Left_Value, Right_Value)) = Less_Bits
              and then Native.To_Bit_Mask (Native.Less_Than (Left_Value, Right_Value)) = Less_Bits
              and then Wide.To_Bit_Mask (Wide.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits
              and then Native.To_Bit_Mask (Native.Less_Equal (Left_Value, Right_Value)) = Less_Equal_Bits,
              "I8x32 exhaustive less comparisons" & Batch'Image);
            Check (Wide.To_Bit_Mask (Wide.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
              and then Native.To_Bit_Mask (Native.Greater_Than (Left_Value, Right_Value)) = Greater_Bits
              and then Wide.To_Bit_Mask (Wide.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits
              and then Native.To_Bit_Mask (Native.Greater_Equal (Left_Value, Right_Value)) = Greater_Equal_Bits,
              "I8x32 exhaustive greater comparisons" & Batch'Image);
         end;
      end loop;
      for Lane in Wide.Lane_Index_8x32 loop
         declare
            Bits : constant Wide.Mask_Bits_8x32 := Interfaces.Shift_Left
              (Wide.Mask_Bits_8x32 (1), Lane);
            Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask (Bits);
            Expected : constant Wide.Lane_Values_I8x32 :=
              Reference_Select (Bits, A_Lanes, B_Lanes);
         begin
            Check (Wide.To_Lanes (Wide.Select_Value (Mask, A, B)) = Expected
              and then Native.To_Lanes (Native.Select_Value (Mask, A, B)) = Expected,
              "I8x32 individual selection mask" & Lane'Image);
         end;
      end loop;
      declare
         Selection_Patterns : constant array (Natural range 0 .. 5) of
           Wide.Mask_Bits_8x32 :=
             [0, Wide.Mask_Bits_8x32'Last, 16#0000_FFFF#, 16#FFFF_0000#,
              16#AAAA_AAAA#, 16#5555_5555#];
      begin
         for Pattern of Selection_Patterns loop
            declare
               Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask (Pattern);
               Expected : constant Wide.Lane_Values_I8x32 :=
                 Reference_Select (Pattern, A_Lanes, B_Lanes);
            begin
               Check (Wide.To_Lanes (Wide.Select_Value (Mask, A, B)) = Expected
                 and then Native.To_Lanes (Native.Select_Value (Mask, A, B)) = Expected,
                 "I8x32 fixed selection mask" & Pattern'Image);
            end;
         end loop;
      end;


      Check (Wide.To_Lanes (Wide.Shift_Left_Logical (A, 8)) = Wide.Lane_Values_I8x32'[others => 0]
        and then Wide.To_Lanes (Wide.Shift_Right_Logical (A, 15)) = Wide.Lane_Values_I8x32'[others => 0],
        "I8x32 oversized shifts");
      Check (Wide.To_Bit_Mask (Wide.Equal (A, A)) = Mask_Bits_8x32'Last,
        "I8x32 equality mask");
      Check (Wide.To_Lanes (Wide.Select_Value (Alternating, A, B)) =
        [for Lane in Wide.Lane_Index_8x32 => (if Lane mod 2 = 0 then A_Lanes (Lane) else 2)],
        "I8x32 selection");

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_8x32'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_8x32 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_8x32 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 32 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_8x32 :=
              (if Count = 32
               then Wide.Mask_Bits_8x32'Last
               else Wide.Mask_Bits_8x32 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_8x32'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_8x32 :=
           Wide.Mask_Bits_8x32 (2 ** 16 - 1);
         High_Half : constant Wide.Mask_Bits_8x32 :=
           Wide.Mask_Bits_8x32'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_8x32 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_8x32 (1), 15)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_8x32 (1), 16);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_8x32 (1431655765),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_8x32 => A_Lanes (31 - Lane)],
         [for Lane in Wide.Lane_Index_8x32 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 32)
             else B_Lanes ((Lane * 3 + 1) mod 32))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_8x32 :=
           [for Lane in Wide.Lane_Index_8x32 => Lane];
         Broadcast : constant Wide.Lane_Selectors_8x32 := [others => 16];
         All_Left : constant Wide.Two_Source_Lane_Selectors_8x32 :=
           [for Lane in Wide.Lane_Index_8x32 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_8x32 :=
           [for Lane in Wide.Lane_Index_8x32 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (16)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_8x32'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (32 - 1), "last lane");
      Check_Mask_Positions (2 ** (16 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 16, "high-half boundary");
      Check_Mask_Positions (1431655765, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "I8x32 independent fixed reductions");
      declare
         Edge_Value : constant Wide.I8x32 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = I8'First
           and then Native.Reduce_Min (Edge_Value) = I8'First
           and then Wide.Reduce_Max (Edge_Value) = I8'Last
           and then Native.Reduce_Max (Edge_Value) = I8'Last,
           "I8x32 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_8x32'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_8x32'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_8x32'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I8x32 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "I8x32 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "I8x32 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_I8x32 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_I8x32 := Random_Lanes;
            R_A : constant Wide.I8x32 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.I8x32 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_8x32;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_8x32;
            Expected_One : Wide.Lane_Values_I8x32;
            Expected_Two : Wide.Lane_Values_I8x32;
            R_Mask : constant Wide.Mask_8x32 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_8x32 (Next_U64 mod 2 ** 32));
            Shift : constant Natural := Natural (Next_U64 mod 11);
            Slide : constant Natural := Natural (Next_U64 mod 35);
         begin
            for Lane in Wide.Lane_Index_8x32 loop
               declare
                  One_Lane : constant Wide.Lane_Index_8x32 :=
                    Wide.Lane_Index_8x32 (Next_U64 mod 32);
                  Two_Lane : constant Wide.Lane_Index_8x32 :=
                    Wide.Lane_Index_8x32 (Next_U64 mod 32);
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
              "I8x32 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I8x32 randomized bitwise extrema" & Iteration'Image);

            declare
               R_A_Lanes : constant Wide.Lane_Values_I8x32 := Wide.To_Lanes (R_A);
               R_B_Lanes : constant Wide.Lane_Values_I8x32 := Wide.To_Lanes (R_B);
               Add_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) + Value_To_Bits (R_B_Lanes (Lane)))];
               Subtract_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) - Value_To_Bits (R_B_Lanes (Lane)))];
               Multiply_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) * Value_To_Bits (R_B_Lanes (Lane)))];
               Add_Saturate_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => I8 (Integer'Max (Integer (I8'First), Integer'Min (Integer (I8'Last), Integer (R_A_Lanes (Lane)) + Integer (R_B_Lanes (Lane)))))];
               Subtract_Saturate_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => I8 (Integer'Max (Integer (I8'First), Integer'Min (Integer (I8'Last), Integer (R_A_Lanes (Lane)) - Integer (R_B_Lanes (Lane)))))];
               And_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) and Value_To_Bits (R_B_Lanes (Lane)))];
               Or_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) or Value_To_Bits (R_B_Lanes (Lane)))];
               Xor_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (Value_To_Bits (R_A_Lanes (Lane)) xor Value_To_Bits (R_B_Lanes (Lane)))];
               Not_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 => Bits_To_Value (not Value_To_Bits (R_A_Lanes (Lane)))];
               Min_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 =>
                    (if R_A_Lanes (Lane) < R_B_Lanes (Lane)
                     then R_A_Lanes (Lane) else R_B_Lanes (Lane))];
               Max_Expected : constant Wide.Lane_Values_I8x32 :=
                 [for Lane in Wide.Lane_Index_8x32 =>
                    (if R_A_Lanes (Lane) > R_B_Lanes (Lane)
                     then R_A_Lanes (Lane) else R_B_Lanes (Lane))];
            begin
               Check (Wide.To_Lanes (Wide.Add_Wrap (R_A, R_B)) = Add_Expected
                 and then Native.To_Lanes (Native.Add_Wrap (R_A, R_B)) = Add_Expected
                 and then Wide.To_Lanes (Wide.Subtract_Wrap (R_A, R_B)) = Subtract_Expected
                 and then Native.To_Lanes (Native.Subtract_Wrap (R_A, R_B)) = Subtract_Expected
                 and then Wide.To_Lanes (Wide.Multiply_Wrap (R_A, R_B)) = Multiply_Expected
                 and then Native.To_Lanes (Native.Multiply_Wrap (R_A, R_B)) = Multiply_Expected,
                 "I8x32 independent randomized wrapping arithmetic" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Add_Saturate (R_A, R_B)) = Add_Saturate_Expected
                 and then Native.To_Lanes (Native.Add_Saturate (R_A, R_B)) = Add_Saturate_Expected
                 and then Wide.To_Lanes (Wide.Subtract_Saturate (R_A, R_B)) = Subtract_Saturate_Expected
                 and then Native.To_Lanes (Native.Subtract_Saturate (R_A, R_B)) = Subtract_Saturate_Expected,
                 "I8x32 independent randomized saturating arithmetic" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B)) = And_Expected
                 and then Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = And_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B)) = Or_Expected
                 and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Or_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B)) = Xor_Expected
                 and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Xor_Expected
                 and then Wide.To_Lanes (Wide.Bitwise_Not (R_A)) = Not_Expected
                 and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Not_Expected,
                 "I8x32 independent randomized bitwise operations" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Min (R_A, R_B)) = Min_Expected
                 and then Native.To_Lanes (Native.Min (R_A, R_B)) = Min_Expected
                 and then Wide.To_Lanes (Wide.Max (R_A, R_B)) = Max_Expected
                 and then Native.To_Lanes (Native.Max (R_A, R_B)) = Max_Expected,
                 "I8x32 independent randomized extrema" & Iteration'Image);
            end;


            declare
               R_A_Lanes : constant Wide.Lane_Values_I8x32 := Wide.To_Lanes (R_A);
               R_B_Lanes : constant Wide.Lane_Values_I8x32 := Wide.To_Lanes (R_B);
               R_Bits : constant Wide.Mask_Bits_8x32 := Wide.To_Bit_Mask (R_Mask);
               Select_Expected : constant Wide.Lane_Values_I8x32 :=
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
                 "I8x32 independent randomized strict predicates" & Iteration'Image);
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
                 "I8x32 independent randomized inclusive predicates" & Iteration'Image);
               Check (Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B)) = Select_Expected
                 and then Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Select_Expected,
                 "I8x32 independent randomized selection" & Iteration'Image);
            end;

            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I8x32 randomized selection and movement" & Iteration'Image);

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
              "I8x32 independent randomized reductions" & Iteration'Image);
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

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_U16x16) return U16
      is
         Result : U16 := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_U16x16) return U16
      is
         Result : U16 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_U16x16) return U16
      is
         Result : U16 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_U16x16; Bits : Wide.Mask_Bits_16x16)
         return Wide.Lane_Values_U16x16
      is
         Result : Wide.Lane_Values_U16x16 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_U16x16; Bits : Wide.Mask_Bits_16x16)
         return Wide.Lane_Values_U16x16
      is
         Result : Wide.Lane_Values_U16x16 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_U16x16;
         Bits : Wide.Mask_Bits_16x16;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_16x16 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_16x16 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.U16x16 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.U16x16 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_U16x16 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_U16x16 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_U16x16 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.U16x16 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.U16x16 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.U16x16 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.U16x16 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.U16x16 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.U16x16 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "U16x16 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "U16x16 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "U16x16 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_16x16) return Wide.Lane_Count_16x16
      is
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 16;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_16x16) return Wide.Lane_Count_16x16
      is
      begin
         for Lane in reverse Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 16;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_16x16) return Wide.Lane_Count_16x16
      is
         Result : Wide.Lane_Count_16x16 := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_16x16; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_16x16 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_16x16 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_16x16 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_16x16 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_16x16 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "U16x16 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_U16x16;
         One_Selectors : Wide.Lane_Selectors_16x16;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
         Expected_One, Expected_Two : Wide.Lane_Values_U16x16;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.U16x16 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.U16x16 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.U16x16 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.U16x16 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.U16x16 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.U16x16 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.U16x16 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.U16x16 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "U16x16 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "U16x16 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_U16x16; Label_Text : String)
      is
         Left : constant Wide.U16x16 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.U16x16 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.U16x16;
            Expected : Wide.Lane_Values_U16x16; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "U16x16 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_16x16 => Left_Values (15 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane mod 2 = 0
                then Left_Values (8 + Lane / 2)
                else Right_Values (8 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane < 8
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 8)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane < 8
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 8) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 18 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_16x16 =>
                  (if Count < 16 and then Lane < 16 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_16x16 =>
                  (if Count < 16 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
      B_Lanes : constant Wide.Lane_Values_U16x16 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U16x16 := [U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#), U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#), U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#), U16 (16#0000#), U16 (16#8000#), U16 (16#FFFF#), U16 (16#AAAA#)];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_U16x16 :=
        [U16'First, 1, 1, 1, 1, 1, 1, U16'Last, U16'First, 1, 1, 1, 1, 1, 1, U16'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "U16x16 splat construction");
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

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_16x16'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_16x16 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_16x16 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 16 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_16x16 :=
              (if Count = 16
               then Wide.Mask_Bits_16x16'Last
               else Wide.Mask_Bits_16x16 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_16x16'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_16x16 :=
           Wide.Mask_Bits_16x16 (2 ** 8 - 1);
         High_Half : constant Wide.Mask_Bits_16x16 :=
           Wide.Mask_Bits_16x16'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_16x16 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_16x16 (1), 7)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_16x16 (1), 8);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_16x16 (21845),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_16x16 => A_Lanes (15 - Lane)],
         [for Lane in Wide.Lane_Index_16x16 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 16)
             else B_Lanes ((Lane * 3 + 1) mod 16))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_16x16 :=
           [for Lane in Wide.Lane_Index_16x16 => Lane];
         Broadcast : constant Wide.Lane_Selectors_16x16 := [others => 8];
         All_Left : constant Wide.Two_Source_Lane_Selectors_16x16 :=
           [for Lane in Wide.Lane_Index_16x16 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_16x16 :=
           [for Lane in Wide.Lane_Index_16x16 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (8)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_16x16'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (16 - 1), "last lane");
      Check_Mask_Positions (2 ** (8 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 8, "high-half boundary");
      Check_Mask_Positions (21845, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "U16x16 independent fixed reductions");
      declare
         Edge_Value : constant Wide.U16x16 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = U16'First
           and then Native.Reduce_Min (Edge_Value) = U16'First
           and then Wide.Reduce_Max (Edge_Value) = U16'Last
           and then Native.Reduce_Max (Edge_Value) = U16'Last,
           "U16x16 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_16x16'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_16x16'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_16x16'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U16x16 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "U16x16 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "U16x16 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lanes;
            R_A : constant Wide.U16x16 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.U16x16 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_16x16;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
            Expected_One : Wide.Lane_Values_U16x16;
            Expected_Two : Wide.Lane_Values_U16x16;
            R_Mask : constant Wide.Mask_16x16 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_16x16 (Next_U64 mod 2 ** 16));
            Shift : constant Natural := Natural (Next_U64 mod 19);
            Slide : constant Natural := Natural (Next_U64 mod 19);
         begin
            for Lane in Wide.Lane_Index_16x16 loop
               declare
                  One_Lane : constant Wide.Lane_Index_16x16 :=
                    Wide.Lane_Index_16x16 (Next_U64 mod 16);
                  Two_Lane : constant Wide.Lane_Index_16x16 :=
                    Wide.Lane_Index_16x16 (Next_U64 mod 16);
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
              "U16x16 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U16x16 randomized bitwise extrema" & Iteration'Image);


            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U16x16 randomized selection and movement" & Iteration'Image);

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
              "U16x16 independent randomized reductions" & Iteration'Image);
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

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_I16x16) return I16
      is
         Result : U16 := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Result := Result + Value_To_Bits (Values (Lane));
         end loop;
         return Bits_To_Value (Result);
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_I16x16) return I16
      is
         Result : I16 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_I16x16) return I16
      is
         Result : I16 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_I16x16; Bits : Wide.Mask_Bits_16x16)
         return Wide.Lane_Values_I16x16
      is
         Result : Wide.Lane_Values_I16x16 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_I16x16; Bits : Wide.Mask_Bits_16x16)
         return Wide.Lane_Values_I16x16
      is
         Result : Wide.Lane_Values_I16x16 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_I16x16;
         Bits : Wide.Mask_Bits_16x16;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_16x16 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_16x16 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.I16x16 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.I16x16 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_I16x16 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_I16x16 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_I16x16 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.I16x16 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.I16x16 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.I16x16 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.I16x16 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.I16x16 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.I16x16 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "I16x16 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "I16x16 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "I16x16 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_16x16) return Wide.Lane_Count_16x16
      is
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 16;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_16x16) return Wide.Lane_Count_16x16
      is
      begin
         for Lane in reverse Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 16;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_16x16) return Wide.Lane_Count_16x16
      is
         Result : Wide.Lane_Count_16x16 := 0;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_16x16; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_16x16 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_16x16 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_16x16 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_16x16 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_16x16 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "I16x16 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_I16x16;
         One_Selectors : Wide.Lane_Selectors_16x16;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
         Expected_One, Expected_Two : Wide.Lane_Values_I16x16;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.I16x16 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.I16x16 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.I16x16 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.I16x16 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.I16x16 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.I16x16 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.I16x16 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.I16x16 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "I16x16 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "I16x16 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_I16x16; Label_Text : String)
      is
         Left : constant Wide.I16x16 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.I16x16 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.I16x16;
            Expected : Wide.Lane_Values_I16x16; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "I16x16 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_16x16 => Left_Values (15 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane mod 2 = 0
                then Left_Values (8 + Lane / 2)
                else Right_Values (8 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane < 8
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 8)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_16x16 =>
               (if Lane < 8
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 8) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 18 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_16x16 =>
                  (if Count < 16 and then Lane < 16 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_16x16 =>
                  (if Count < 16 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_I16x16 := [-8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7];
      B_Lanes : constant Wide.Lane_Values_I16x16 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I16x16 := [Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#)), Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#)), Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#)), Bits_To_Value (U16 (16#0000#)), Bits_To_Value (U16 (16#8000#)), Bits_To_Value (U16 (16#FFFF#)), Bits_To_Value (U16 (16#AAAA#))];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_I16x16 :=
        [I16'First, 1, -1, 1, -1, 1, -1, I16'Last, I16'First, 1, -1, 1, -1, 1, -1, I16'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "I16x16 splat construction");
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

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_16x16'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_16x16 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_16x16 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 16 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_16x16 :=
              (if Count = 16
               then Wide.Mask_Bits_16x16'Last
               else Wide.Mask_Bits_16x16 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_16x16'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_16x16 :=
           Wide.Mask_Bits_16x16 (2 ** 8 - 1);
         High_Half : constant Wide.Mask_Bits_16x16 :=
           Wide.Mask_Bits_16x16'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_16x16 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_16x16 (1), 7)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_16x16 (1), 8);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_16x16 (21845),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_16x16 => A_Lanes (15 - Lane)],
         [for Lane in Wide.Lane_Index_16x16 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 16)
             else B_Lanes ((Lane * 3 + 1) mod 16))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_16x16 :=
           [for Lane in Wide.Lane_Index_16x16 => Lane];
         Broadcast : constant Wide.Lane_Selectors_16x16 := [others => 8];
         All_Left : constant Wide.Two_Source_Lane_Selectors_16x16 :=
           [for Lane in Wide.Lane_Index_16x16 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_16x16 :=
           [for Lane in Wide.Lane_Index_16x16 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (8)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_16x16'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (16 - 1), "last lane");
      Check_Mask_Positions (2 ** (8 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 8, "high-half boundary");
      Check_Mask_Positions (21845, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "I16x16 independent fixed reductions");
      declare
         Edge_Value : constant Wide.I16x16 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = I16'First
           and then Native.Reduce_Min (Edge_Value) = I16'First
           and then Wide.Reduce_Max (Edge_Value) = I16'Last
           and then Native.Reduce_Max (Edge_Value) = I16'Last,
           "I16x16 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_16x16'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_16x16'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_16x16'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I16x16 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "I16x16 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "I16x16 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lanes;
            R_A : constant Wide.I16x16 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.I16x16 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_16x16;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_16x16;
            Expected_One : Wide.Lane_Values_I16x16;
            Expected_Two : Wide.Lane_Values_I16x16;
            R_Mask : constant Wide.Mask_16x16 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_16x16 (Next_U64 mod 2 ** 16));
            Shift : constant Natural := Natural (Next_U64 mod 19);
            Slide : constant Natural := Natural (Next_U64 mod 19);
         begin
            for Lane in Wide.Lane_Index_16x16 loop
               declare
                  One_Lane : constant Wide.Lane_Index_16x16 :=
                    Wide.Lane_Index_16x16 (Next_U64 mod 16);
                  Two_Lane : constant Wide.Lane_Index_16x16 :=
                    Wide.Lane_Index_16x16 (Next_U64 mod 16);
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
              "I16x16 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I16x16 randomized bitwise extrema" & Iteration'Image);


            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I16x16 randomized selection and movement" & Iteration'Image);

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
              "I16x16 independent randomized reductions" & Iteration'Image);
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

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_U32x8) return U32
      is
         Result : U32 := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_U32x8) return U32
      is
         Result : U32 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_U32x8) return U32
      is
         Result : U32 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_U32x8; Bits : Wide.Mask_Bits_32x8)
         return Wide.Lane_Values_U32x8
      is
         Result : Wide.Lane_Values_U32x8 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_U32x8; Bits : Wide.Mask_Bits_32x8)
         return Wide.Lane_Values_U32x8
      is
         Result : Wide.Lane_Values_U32x8 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_U32x8;
         Bits : Wide.Mask_Bits_32x8;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_32x8 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_32x8 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.U32x8 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.U32x8 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_U32x8 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_U32x8 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_U32x8 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.U32x8 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.U32x8 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.U32x8 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.U32x8 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.U32x8 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.U32x8 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "U32x8 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "U32x8 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "U32x8 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 8;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
      begin
         for Lane in reverse Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 8;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
         Result : Wide.Lane_Count_32x8 := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_32x8; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_32x8 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_32x8 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_32x8 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_32x8 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_32x8 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "U32x8 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_U32x8;
         One_Selectors : Wide.Lane_Selectors_32x8;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
         Expected_One, Expected_Two : Wide.Lane_Values_U32x8;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.U32x8 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.U32x8 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.U32x8 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.U32x8 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.U32x8 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.U32x8 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.U32x8 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.U32x8 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "U32x8 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "U32x8 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_U32x8; Label_Text : String)
      is
         Left : constant Wide.U32x8 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.U32x8 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.U32x8;
            Expected : Wide.Lane_Values_U32x8; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "U32x8 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_32x8 => Left_Values (7 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane mod 2 = 0
                then Left_Values (4 + Lane / 2)
                else Right_Values (4 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane < 4
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 4)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane < 4
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 4) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 10 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_32x8 =>
                  (if Count < 8 and then Lane < 8 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_32x8 =>
                  (if Count < 8 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 2, 3, 4, 5, 6, 7];
      B_Lanes : constant Wide.Lane_Values_U32x8 := [2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U32x8 := [U32 (16#00000000#), U32 (16#80000000#), U32 (16#FFFFFFFF#), U32 (16#AAAAAAAA#), U32 (16#00000000#), U32 (16#80000000#), U32 (16#FFFFFFFF#), U32 (16#AAAAAAAA#)];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_U32x8 :=
        [U32'First, 1, 1, U32'Last, U32'First, 1, 1, U32'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "U32x8 splat construction");
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

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_32x8'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_32x8 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_32x8 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 8 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_32x8 :=
              (if Count = 8
               then Wide.Mask_Bits_32x8'Last
               else Wide.Mask_Bits_32x8 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_32x8'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8 (2 ** 4 - 1);
         High_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_32x8 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 3)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 4);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_32x8 (85),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_32x8 => A_Lanes (7 - Lane)],
         [for Lane in Wide.Lane_Index_32x8 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 8)
             else B_Lanes ((Lane * 3 + 1) mod 8))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_32x8 :=
           [for Lane in Wide.Lane_Index_32x8 => Lane];
         Broadcast : constant Wide.Lane_Selectors_32x8 := [others => 4];
         All_Left : constant Wide.Two_Source_Lane_Selectors_32x8 :=
           [for Lane in Wide.Lane_Index_32x8 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_32x8 :=
           [for Lane in Wide.Lane_Index_32x8 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (4)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_32x8'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (8 - 1), "last lane");
      Check_Mask_Positions (2 ** (4 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 4, "high-half boundary");
      Check_Mask_Positions (85, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "U32x8 independent fixed reductions");
      declare
         Edge_Value : constant Wide.U32x8 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = U32'First
           and then Native.Reduce_Min (Edge_Value) = U32'First
           and then Wide.Reduce_Max (Edge_Value) = U32'Last
           and then Native.Reduce_Max (Edge_Value) = U32'Last,
           "U32x8 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U32x8 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "U32x8 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "U32x8 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lanes;
            R_A : constant Wide.U32x8 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.U32x8 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_32x8;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
            Expected_One : Wide.Lane_Values_U32x8;
            Expected_Two : Wide.Lane_Values_U32x8;
            R_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Shift : constant Natural := Natural (Next_U64 mod 35);
            Slide : constant Natural := Natural (Next_U64 mod 11);
         begin
            for Lane in Wide.Lane_Index_32x8 loop
               declare
                  One_Lane : constant Wide.Lane_Index_32x8 :=
                    Wide.Lane_Index_32x8 (Next_U64 mod 8);
                  Two_Lane : constant Wide.Lane_Index_32x8 :=
                    Wide.Lane_Index_32x8 (Next_U64 mod 8);
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
              "U32x8 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U32x8 randomized bitwise extrema" & Iteration'Image);


            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U32x8 randomized selection and movement" & Iteration'Image);

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
              "U32x8 independent randomized reductions" & Iteration'Image);
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

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_I32x8) return I32
      is
         Result : U32 := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result := Result + Value_To_Bits (Values (Lane));
         end loop;
         return Bits_To_Value (Result);
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_I32x8) return I32
      is
         Result : I32 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_I32x8) return I32
      is
         Result : I32 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_I32x8; Bits : Wide.Mask_Bits_32x8)
         return Wide.Lane_Values_I32x8
      is
         Result : Wide.Lane_Values_I32x8 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_I32x8; Bits : Wide.Mask_Bits_32x8)
         return Wide.Lane_Values_I32x8
      is
         Result : Wide.Lane_Values_I32x8 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_I32x8;
         Bits : Wide.Mask_Bits_32x8;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_32x8 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_32x8 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.I32x8 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.I32x8 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_I32x8 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_I32x8 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_I32x8 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.I32x8 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.I32x8 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.I32x8 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.I32x8 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.I32x8 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.I32x8 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "I32x8 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "I32x8 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "I32x8 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 8;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
      begin
         for Lane in reverse Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 8;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
         Result : Wide.Lane_Count_32x8 := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_32x8; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_32x8 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_32x8 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_32x8 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_32x8 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_32x8 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "I32x8 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_I32x8;
         One_Selectors : Wide.Lane_Selectors_32x8;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
         Expected_One, Expected_Two : Wide.Lane_Values_I32x8;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.I32x8 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.I32x8 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.I32x8 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.I32x8 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.I32x8 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.I32x8 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.I32x8 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.I32x8 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "I32x8 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "I32x8 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_I32x8; Label_Text : String)
      is
         Left : constant Wide.I32x8 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.I32x8 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.I32x8;
            Expected : Wide.Lane_Values_I32x8; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "I32x8 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_32x8 => Left_Values (7 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane mod 2 = 0
                then Left_Values (4 + Lane / 2)
                else Right_Values (4 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane < 4
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 4)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane < 4
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 4) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 10 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_32x8 =>
                  (if Count < 8 and then Lane < 8 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_32x8 =>
                  (if Count < 8 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_I32x8 := [-4, -3, -2, -1, 0, 1, 2, 3];
      B_Lanes : constant Wide.Lane_Values_I32x8 := [2, 2, 2, 2, 2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I32x8 := [Bits_To_Value (U32 (16#00000000#)), Bits_To_Value (U32 (16#80000000#)), Bits_To_Value (U32 (16#FFFFFFFF#)), Bits_To_Value (U32 (16#AAAAAAAA#)), Bits_To_Value (U32 (16#00000000#)), Bits_To_Value (U32 (16#80000000#)), Bits_To_Value (U32 (16#FFFFFFFF#)), Bits_To_Value (U32 (16#AAAAAAAA#))];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_I32x8 :=
        [I32'First, 1, -1, I32'Last, I32'First, 1, -1, I32'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "I32x8 splat construction");
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

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_32x8'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_32x8 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_32x8 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 8 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_32x8 :=
              (if Count = 8
               then Wide.Mask_Bits_32x8'Last
               else Wide.Mask_Bits_32x8 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_32x8'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8 (2 ** 4 - 1);
         High_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_32x8 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 3)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 4);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_32x8 (85),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_32x8 => A_Lanes (7 - Lane)],
         [for Lane in Wide.Lane_Index_32x8 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 8)
             else B_Lanes ((Lane * 3 + 1) mod 8))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_32x8 :=
           [for Lane in Wide.Lane_Index_32x8 => Lane];
         Broadcast : constant Wide.Lane_Selectors_32x8 := [others => 4];
         All_Left : constant Wide.Two_Source_Lane_Selectors_32x8 :=
           [for Lane in Wide.Lane_Index_32x8 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_32x8 :=
           [for Lane in Wide.Lane_Index_32x8 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (4)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_32x8'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (8 - 1), "last lane");
      Check_Mask_Positions (2 ** (4 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 4, "high-half boundary");
      Check_Mask_Positions (85, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "I32x8 independent fixed reductions");
      declare
         Edge_Value : constant Wide.I32x8 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = I32'First
           and then Native.Reduce_Min (Edge_Value) = I32'First
           and then Wide.Reduce_Max (Edge_Value) = I32'Last
           and then Native.Reduce_Max (Edge_Value) = I32'Last,
           "I32x8 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I32x8 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "I32x8 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "I32x8 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lanes;
            R_A : constant Wide.I32x8 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.I32x8 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_32x8;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
            Expected_One : Wide.Lane_Values_I32x8;
            Expected_Two : Wide.Lane_Values_I32x8;
            R_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Shift : constant Natural := Natural (Next_U64 mod 35);
            Slide : constant Natural := Natural (Next_U64 mod 11);
         begin
            for Lane in Wide.Lane_Index_32x8 loop
               declare
                  One_Lane : constant Wide.Lane_Index_32x8 :=
                    Wide.Lane_Index_32x8 (Next_U64 mod 8);
                  Two_Lane : constant Wide.Lane_Index_32x8 :=
                    Wide.Lane_Index_32x8 (Next_U64 mod 8);
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
              "I32x8 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I32x8 randomized bitwise extrema" & Iteration'Image);


            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I32x8 randomized selection and movement" & Iteration'Image);

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
              "I32x8 independent randomized reductions" & Iteration'Image);
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

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_U64x4) return U64
      is
         Result : U64 := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_U64x4) return U64
      is
         Result : U64 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_U64x4) return U64
      is
         Result : U64 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_U64x4; Bits : Wide.Mask_Bits_64x4)
         return Wide.Lane_Values_U64x4
      is
         Result : Wide.Lane_Values_U64x4 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_U64x4; Bits : Wide.Mask_Bits_64x4)
         return Wide.Lane_Values_U64x4
      is
         Result : Wide.Lane_Values_U64x4 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_U64x4;
         Bits : Wide.Mask_Bits_64x4;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_64x4 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_64x4 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.U64x4 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.U64x4 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_U64x4 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_U64x4 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_U64x4 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.U64x4 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.U64x4 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.U64x4 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.U64x4 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.U64x4 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.U64x4 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "U64x4 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "U64x4 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "U64x4 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 4;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
      begin
         for Lane in reverse Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 4;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
         Result : Wide.Lane_Count_64x4 := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_64x4; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_64x4 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_64x4 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_64x4 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_64x4 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_64x4 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "U64x4 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_U64x4;
         One_Selectors : Wide.Lane_Selectors_64x4;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
         Expected_One, Expected_Two : Wide.Lane_Values_U64x4;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.U64x4 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.U64x4 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.U64x4 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.U64x4 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.U64x4 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.U64x4 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.U64x4 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.U64x4 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "U64x4 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "U64x4 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_U64x4; Label_Text : String)
      is
         Left : constant Wide.U64x4 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.U64x4 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.U64x4;
            Expected : Wide.Lane_Values_U64x4; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "U64x4 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_64x4 => Left_Values (3 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane mod 2 = 0
                then Left_Values (2 + Lane / 2)
                else Right_Values (2 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane < 2
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 2)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane < 2
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 2) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 6 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_64x4 =>
                  (if Count < 4 and then Lane < 4 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_64x4 =>
                  (if Count < 4 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_U64x4 := [0, 1, 2, 3];
      B_Lanes : constant Wide.Lane_Values_U64x4 := [2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_U64x4 := [U64 (16#0000000000000000#), U64 (16#8000000000000000#), U64 (16#FFFFFFFFFFFFFFFF#), U64 (16#AAAAAAAAAAAAAAAA#)];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_U64x4 :=
        [U64'First, U64'Last, U64'First, U64'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "U64x4 splat construction");
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

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_64x4'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_64x4 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_64x4 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 4 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_64x4 :=
              (if Count = 4
               then Wide.Mask_Bits_64x4'Last
               else Wide.Mask_Bits_64x4 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_64x4'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4 (2 ** 2 - 1);
         High_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_64x4 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 1)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 2);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_64x4 (5),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_64x4 => A_Lanes (3 - Lane)],
         [for Lane in Wide.Lane_Index_64x4 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 4)
             else B_Lanes ((Lane * 3 + 1) mod 4))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_64x4 :=
           [for Lane in Wide.Lane_Index_64x4 => Lane];
         Broadcast : constant Wide.Lane_Selectors_64x4 := [others => 2];
         All_Left : constant Wide.Two_Source_Lane_Selectors_64x4 :=
           [for Lane in Wide.Lane_Index_64x4 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_64x4 :=
           [for Lane in Wide.Lane_Index_64x4 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (2)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_64x4'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (4 - 1), "last lane");
      Check_Mask_Positions (2 ** (2 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 2, "high-half boundary");
      Check_Mask_Positions (5, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "U64x4 independent fixed reductions");
      declare
         Edge_Value : constant Wide.U64x4 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = U64'First
           and then Native.Reduce_Min (Edge_Value) = U64'First
           and then Wide.Reduce_Max (Edge_Value) = U64'Last
           and then Native.Reduce_Max (Edge_Value) = U64'Last,
           "U64x4 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "U64x4 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "U64x4 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "U64x4 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lanes;
            R_A : constant Wide.U64x4 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.U64x4 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_64x4;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
            Expected_One : Wide.Lane_Values_U64x4;
            Expected_Two : Wide.Lane_Values_U64x4;
            R_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Shift : constant Natural := Natural (Next_U64 mod 67);
            Slide : constant Natural := Natural (Next_U64 mod 7);
         begin
            for Lane in Wide.Lane_Index_64x4 loop
               declare
                  One_Lane : constant Wide.Lane_Index_64x4 :=
                    Wide.Lane_Index_64x4 (Next_U64 mod 4);
                  Two_Lane : constant Wide.Lane_Index_64x4 :=
                    Wide.Lane_Index_64x4 (Next_U64 mod 4);
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
              "U64x4 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "U64x4 randomized bitwise extrema" & Iteration'Image);


            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "U64x4 randomized selection and movement" & Iteration'Image);

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
              "U64x4 independent randomized reductions" & Iteration'Image);
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

      function Reference_Reduce_Add_Wrap
        (Values : Wide.Lane_Values_I64x4) return I64
      is
         Result : U64 := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result := Result + Value_To_Bits (Values (Lane));
         end loop;
         return Bits_To_Value (Result);
      end Reference_Reduce_Add_Wrap;

      function Reference_Reduce_Min
        (Values : Wide.Lane_Values_I64x4) return I64
      is
         Result : I64 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if Values (Lane) < Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Min;

      function Reference_Reduce_Max
        (Values : Wide.Lane_Values_I64x4) return I64
      is
         Result : I64 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if Values (Lane) > Result then
               Result := Values (Lane);
            end if;
         end loop;
         return Result;
      end Reference_Reduce_Max;


      function Reference_Compress
        (Values : Wide.Lane_Values_I64x4; Bits : Wide.Mask_Bits_64x4)
         return Wide.Lane_Values_I64x4
      is
         Result : Wide.Lane_Values_I64x4 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_I64x4; Bits : Wide.Mask_Bits_64x4)
         return Wide.Lane_Values_I64x4
      is
         Result : Wide.Lane_Values_I64x4 := [others => 0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_I64x4;
         Bits : Wide.Mask_Bits_64x4;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_64x4 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_64x4 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.I64x4 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.I64x4 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_I64x4 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_I64x4 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_I64x4 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.I64x4 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.I64x4 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.I64x4 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.I64x4 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.I64x4 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.I64x4 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check (Wide.To_Lanes (Scalar_Packed) = Expected_Packed
           and then Native.To_Lanes (Native_Packed) = Expected_Packed,
           "I64x4 independent compression " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Direct) = Expected_Direct
           and then Native.To_Lanes (Native_Direct) = Expected_Direct,
           "I64x4 independent direct expansion " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Round_Trip) = Expected_Round_Trip
           and then Native.To_Lanes (Native_Round_Trip) = Expected_Round_Trip,
           "I64x4 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 4;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
      begin
         for Lane in reverse Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 4;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
         Result : Wide.Lane_Count_64x4 := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_64x4; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_64x4 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_64x4 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_64x4 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_64x4 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_64x4 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "I64x4 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_I64x4;
         One_Selectors : Wide.Lane_Selectors_64x4;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
         Expected_One, Expected_Two : Wide.Lane_Values_I64x4;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.I64x4 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.I64x4 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.I64x4 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.I64x4 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.I64x4 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.I64x4 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.I64x4 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.I64x4 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check (Wide.To_Lanes (Scalar_One) = Expected_One and then Native.To_Lanes (Native_One) = Expected_One,
           "I64x4 independent one-source permutation " & Label_Text);
         Check (Wide.To_Lanes (Scalar_Two) = Expected_Two and then Native.To_Lanes (Native_Two) = Expected_Two,
           "I64x4 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_I64x4; Label_Text : String)
      is
         Left : constant Wide.I64x4 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.I64x4 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.I64x4;
            Expected : Wide.Lane_Values_I64x4; Operation : String)
         is
         begin
            Check (Wide.To_Lanes (Scalar_Result) = Expected and then Native.To_Lanes (Native_Result) = Expected,
              "I64x4 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_64x4 => Left_Values (3 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane mod 2 = 0
                then Left_Values (2 + Lane / 2)
                else Right_Values (2 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane < 2
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 2)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane < 2
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 2) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 6 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_64x4 =>
                  (if Count < 4 and then Lane < 4 - Count
                   then Left_Values (Lane + Count) else 0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_64x4 =>
                  (if Count < 4 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0],
            "slide high Natural'Last");
      end Check_Movements;


      A_Lanes : constant Wide.Lane_Values_I64x4 := [-2, -1, 0, 1];
      B_Lanes : constant Wide.Lane_Values_I64x4 := [2, 2, 2, 2];
      Bit_Lanes : constant Wide.Lane_Values_I64x4 := [Bits_To_Value (U64 (16#0000000000000000#)), Bits_To_Value (U64 (16#8000000000000000#)), Bits_To_Value (U64 (16#FFFFFFFFFFFFFFFF#)), Bits_To_Value (U64 (16#AAAAAAAAAAAAAAAA#))];
      Reduction_Edge_Lanes : constant Wide.Lane_Values_I64x4 :=
        [I64'First, I64'Last, I64'First, I64'Last];
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
      Check (Wide.To_Lanes (Wide.Splat (B_Lanes (0))) = B_Lanes
        and then Native.To_Lanes (Native.Splat (B_Lanes (0))) = B_Lanes,
        "I64x4 splat construction");
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

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_64x4'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_64x4 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_64x4 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 4 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_64x4 :=
              (if Count = 4
               then Wide.Mask_Bits_64x4'Last
               else Wide.Mask_Bits_64x4 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_64x4'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4 (2 ** 2 - 1);
         High_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_64x4 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 1)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 2);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_64x4 (5),
            "fixed alternating mask");
      end;

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
      Check_Permutations
        (A_Lanes, B_Lanes, Map_Selectors, Two_Selectors,
         [for Lane in Wide.Lane_Index_64x4 => A_Lanes (3 - Lane)],
         [for Lane in Wide.Lane_Index_64x4 =>
            (if Lane mod 2 = 0
             then A_Lanes ((Lane * 3 + 1) mod 4)
             else B_Lanes ((Lane * 3 + 1) mod 4))],
         "fixed mixed map");
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
         Identity : constant Wide.Lane_Selectors_64x4 :=
           [for Lane in Wide.Lane_Index_64x4 => Lane];
         Broadcast : constant Wide.Lane_Selectors_64x4 := [others => 2];
         All_Left : constant Wide.Two_Source_Lane_Selectors_64x4 :=
           [for Lane in Wide.Lane_Index_64x4 => Wide.Select_Left_Lane (Lane)];
         All_Right : constant Wide.Two_Source_Lane_Selectors_64x4 :=
           [for Lane in Wide.Lane_Index_64x4 => Wide.Select_Right_Lane (Lane)];
      begin
         Check_Permutations
           (A_Lanes, B_Lanes, Identity, All_Left,
            A_Lanes, A_Lanes, "fixed identity and all-left map");
         Check_Permutations
           (A_Lanes, B_Lanes, Broadcast, All_Right,
            [others => A_Lanes (2)], B_Lanes,
            "fixed broadcast and all-right map");
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
      Check_Movements (A_Lanes, B_Lanes, "fixed lanes");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_64x4'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (4 - 1), "last lane");
      Check_Mask_Positions (2 ** (2 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 2, "high-half boundary");
      Check_Mask_Positions (5, "alternating");
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
      Check (Wide.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_Wrap (A_Lanes)
        and then Wide.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Native.Reduce_Min (A) = Reference_Reduce_Min (A_Lanes)
        and then Wide.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes)
        and then Native.Reduce_Max (A) = Reference_Reduce_Max (A_Lanes),
        "I64x4 independent fixed reductions");
      declare
         Edge_Value : constant Wide.I64x4 :=
           Wide.From_Lanes (Reduction_Edge_Lanes);
      begin
         Check (Wide.Reduce_Add_Wrap (Edge_Value) =
           Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Native.Reduce_Add_Wrap (Edge_Value) =
             Reference_Reduce_Add_Wrap (Reduction_Edge_Lanes)
           and then Wide.Reduce_Min (Edge_Value) = I64'First
           and then Native.Reduce_Min (Edge_Value) = I64'First
           and then Wide.Reduce_Max (Edge_Value) = I64'Last
           and then Native.Reduce_Max (Edge_Value) = I64'Last,
           "I64x4 independent reduction boundaries");
      end;
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
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
            Check (Native.To_Bit_Mask (Native.Mask_Xor (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last
              and then Wide.To_Bit_Mask (Wide.Mask_Xor (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
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
        and then Wide.To_Lanes (Wide.Load_Unaligned (Data, Data'First + 1)) = A_Lanes
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "I64x4 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "I64x4 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "I64x4 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lanes;
            R_A : constant Wide.I64x4 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.I64x4 := Wide.From_Lanes (R_B_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_64x4;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
            Expected_One : Wide.Lane_Values_I64x4;
            Expected_Two : Wide.Lane_Values_I64x4;
            R_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Shift : constant Natural := Natural (Next_U64 mod 67);
            Slide : constant Natural := Natural (Next_U64 mod 7);
         begin
            for Lane in Wide.Lane_Index_64x4 loop
               declare
                  One_Lane : constant Wide.Lane_Index_64x4 :=
                    Wide.Lane_Index_64x4 (Next_U64 mod 4);
                  Two_Lane : constant Wide.Lane_Index_64x4 :=
                    Wide.Lane_Index_64x4 (Next_U64 mod 4);
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
              "I64x4 randomized arithmetic" & Iteration'Image);
            Check (Native.To_Lanes (Native.Bitwise_And (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_And (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Or (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Or (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Xor (R_A, R_B)) = Wide.To_Lanes (Wide.Bitwise_Xor (R_A, R_B))
              and then Native.To_Lanes (Native.Bitwise_Not (R_A)) = Wide.To_Lanes (Wide.Bitwise_Not (R_A))
              and then Native.To_Lanes (Native.Min (R_A, R_B)) = Wide.To_Lanes (Wide.Min (R_A, R_B))
              and then Native.To_Lanes (Native.Max (R_A, R_B)) = Wide.To_Lanes (Wide.Max (R_A, R_B)),
              "I64x4 randomized bitwise extrema" & Iteration'Image);


            Check_Compaction
              (Wide.To_Lanes (R_A), Wide.To_Bit_Mask (R_Mask),
               "randomized" & Iteration'Image);
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
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, Native.Make_Lane_Map (R_One_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, Wide.Make_Lane_Map (R_One_Selectors)))
              and then Native.To_Lanes (Native.Permute_Lanes (R_A, R_B, Native.Make_Two_Source_Lane_Map (R_Two_Selectors))) = Wide.To_Lanes (Wide.Permute_Lanes (R_A, R_B, Wide.Make_Two_Source_Lane_Map (R_Two_Selectors)))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "I64x4 randomized selection and movement" & Iteration'Image);

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
              "I64x4 independent randomized reductions" & Iteration'Image);
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
      function Is_NaN (Value : F32) return Boolean is
        ((Value_To_Bits (Value) and 16#7F80_0000#) = 16#7F80_0000#
         and then (Value_To_Bits (Value) and 16#007F_FFFF#) /= 0);
      function Is_Signaling_NaN (Value : F32) return Boolean is
        (Is_NaN (Value)
         and then (Value_To_Bits (Value) and 16#0040_0000#) = 0);
      function Quiet_NaN (Value : F32) return F32 is
        (Bits_To_Value (Value_To_Bits (Value) or 16#0040_0000#));
      function Reference_Min_Number
        (Left, Right : F32) return F32
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
            return (if (Value_To_Bits (Left) and 16#8000_0000#) /= 0
                    then Left else Right);
         elsif Left < Right then
            return Left;
         else
            return Right;
         end if;
      end Reference_Min_Number;
      function Reference_Max_Number
        (Left, Right : F32) return F32
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
            return (if (Value_To_Bits (Left) and 16#8000_0000#) = 0
                    then Left else Right);
         elsif Left > Right then
            return Left;
         else
            return Right;
         end if;
      end Reference_Max_Number;
      function Reference_Reduce_Add
        (Values : Wide.Lane_Values_F32x8) return F32
      is
         Result : F32 := 0.0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add;
      function Reference_Reduce_Min_Number
        (Values : Wide.Lane_Values_F32x8) return F32
      is
         Result : F32 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_32x8 range Values'First + 1 .. Values'Last loop
            Result := Reference_Min_Number (Result, Values (Lane));
         end loop;
         return Result;
      end Reference_Reduce_Min_Number;
      function Reference_Reduce_Max_Number
        (Values : Wide.Lane_Values_F32x8) return F32
      is
         Result : F32 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_32x8 range Values'First + 1 .. Values'Last loop
            Result := Reference_Max_Number (Result, Values (Lane));
         end loop;
         return Result;
      end Reference_Reduce_Max_Number;
      function Same_Reduction
        (Actual, Expected : F32) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
           and then (Value_To_Bits (Actual) and 16#0040_0000#) /= 0
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Reductions
        (Values : Wide.Lane_Values_F32x8; Context : String)
      is
         Value : constant Wide.F32x8 := Wide.From_Lanes (Values);
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
           "F32x8 independent reduction oracle " & Context);
      end Check_Reductions;
      function Same_Extreme
        (Actual, Expected : F32) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
           and then (Value_To_Bits (Actual) and 16#0040_0000#) /= 0
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Extrema
        (Left_Values, Right_Values : Wide.Lane_Values_F32x8; Context : String)
      is
         Left_Value : constant Wide.F32x8 :=
           Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.F32x8 :=
           Wide.From_Lanes (Right_Values);
         Scalar_Min : constant Wide.F32x8 :=
           Wide.Min_Number (Left_Value, Right_Value);
         Native_Min : constant Wide.F32x8 :=
           Native.Min_Number (Left_Value, Right_Value);
         Scalar_Max : constant Wide.F32x8 :=
           Wide.Max_Number (Left_Value, Right_Value);
         Native_Max : constant Wide.F32x8 :=
           Native.Max_Number (Left_Value, Right_Value);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
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
               "F32x8 independent extrema oracle " & Context
               & Lane'Image);
         end loop;
      end Check_Extrema;
      function Same_Arithmetic
        (Actual, Expected : F32) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Arithmetic
        (Left_Values, Right_Values : Wide.Lane_Values_F32x8; Context : String)
      is
         Left_Value : constant Wide.F32x8 :=
           Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.F32x8 :=
           Wide.From_Lanes (Right_Values);
         Scalar_Add : constant Wide.F32x8 :=
           Wide.Add (Left_Value, Right_Value);
         Native_Add : constant Wide.F32x8 :=
           Native.Add (Left_Value, Right_Value);
         Scalar_Subtract : constant Wide.F32x8 :=
           Wide.Subtract (Left_Value, Right_Value);
         Native_Subtract : constant Wide.F32x8 :=
           Native.Subtract (Left_Value, Right_Value);
         Scalar_Multiply : constant Wide.F32x8 :=
           Wide.Multiply (Left_Value, Right_Value);
         Native_Multiply : constant Wide.F32x8 :=
           Native.Multiply (Left_Value, Right_Value);
         Scalar_Divide : constant Wide.F32x8 :=
           Wide.Divide (Left_Value, Right_Value);
         Native_Divide : constant Wide.F32x8 :=
           Native.Divide (Left_Value, Right_Value);
      begin
         for Lane in Wide.Lane_Index_32x8 loop
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
               "F32x8 independent arithmetic oracle " & Context
               & Lane'Image);
         end loop;
      end Check_Arithmetic;

      function Reference_Compress
        (Values : Wide.Lane_Values_F32x8; Bits : Wide.Mask_Bits_32x8)
         return Wide.Lane_Values_F32x8
      is
         Result : Wide.Lane_Values_F32x8 := [others => 0.0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_F32x8; Bits : Wide.Mask_Bits_32x8)
         return Wide.Lane_Values_F32x8
      is
         Result : Wide.Lane_Values_F32x8 := [others => 0.0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_F32x8;
         Bits : Wide.Mask_Bits_32x8;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_32x8 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_32x8 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.F32x8 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.F32x8 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_F32x8 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_F32x8 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_F32x8 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.F32x8 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.F32x8 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.F32x8 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.F32x8 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.F32x8 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.F32x8 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check ((for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Wide.Extract (Scalar_Packed, Lane)) =
                Value_To_Bits (Expected_Packed (Lane)))
           and then (for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Native.Extract (Native_Packed, Lane)) =
                Value_To_Bits (Expected_Packed (Lane))),
           "F32x8 independent compression " & Label_Text);
         Check ((for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Wide.Extract (Scalar_Direct, Lane)) =
                Value_To_Bits (Expected_Direct (Lane)))
           and then (for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Native.Extract (Native_Direct, Lane)) =
                Value_To_Bits (Expected_Direct (Lane))),
           "F32x8 independent direct expansion " & Label_Text);
         Check ((for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Wide.Extract (Scalar_Round_Trip, Lane)) =
                Value_To_Bits (Expected_Round_Trip (Lane)))
           and then (for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Native.Extract (Native_Round_Trip, Lane)) =
                Value_To_Bits (Expected_Round_Trip (Lane))),
           "F32x8 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 8;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
      begin
         for Lane in reverse Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 8;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_32x8) return Wide.Lane_Count_32x8
      is
         Result : Wide.Lane_Count_32x8 := 0;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_32x8; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_32x8 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_32x8 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_32x8 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_32x8 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_32x8 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "F32x8 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_F32x8;
         One_Selectors : Wide.Lane_Selectors_32x8;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
         Expected_One, Expected_Two : Wide.Lane_Values_F32x8;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.F32x8 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.F32x8 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.F32x8 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.F32x8 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.F32x8 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.F32x8 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.F32x8 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.F32x8 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check ((for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Wide.Extract (Scalar_One, Lane)) =
                Value_To_Bits (Expected_One (Lane))) and then (for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Native.Extract (Native_One, Lane)) =
                Value_To_Bits (Expected_One (Lane))),
           "F32x8 independent one-source permutation " & Label_Text);
         Check ((for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Wide.Extract (Scalar_Two, Lane)) =
                Value_To_Bits (Expected_Two (Lane))) and then (for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Native.Extract (Native_Two, Lane)) =
                Value_To_Bits (Expected_Two (Lane))),
           "F32x8 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_F32x8; Label_Text : String)
      is
         Left : constant Wide.F32x8 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.F32x8 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.F32x8;
            Expected : Wide.Lane_Values_F32x8; Operation : String)
         is
         begin
            Check ((for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Wide.Extract (Scalar_Result, Lane)) =
                Value_To_Bits (Expected (Lane)))
            and then (for all Lane in Wide.Lane_Index_32x8 =>
              Value_To_Bits (Native.Extract (Native_Result, Lane)) =
                Value_To_Bits (Expected (Lane))),
              "F32x8 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_32x8 => Left_Values (7 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane mod 2 = 0
                then Left_Values (4 + Lane / 2)
                else Right_Values (4 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane < 4
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 4)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_32x8 =>
               (if Lane < 4
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 4) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 10 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_32x8 =>
                  (if Count < 8 and then Lane < 8 - Count
                   then Left_Values (Lane + Count) else 0.0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_32x8 =>
                  (if Count < 8 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0.0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0.0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0.0],
            "slide high Natural'Last");
      end Check_Movements;

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
      Compaction_Extra_Lanes : constant Wide.Lane_Values_F32x8 :=
        [Bits_To_Value (16#FF80_0000#), Bits_To_Value (16#7F81_2345#), Bits_To_Value (1), Bits_To_Value (16#8000_0001#), Bits_To_Value (16#FF80_0000#), Bits_To_Value (16#7F81_2345#), Bits_To_Value (1), Bits_To_Value (16#8000_0001#)];
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
      Check ((for all Lane in Wide.Lane_Index_32x8 =>
        Value_To_Bits (Wide.Extract (Wide.Splat (2.0), Lane)) =
          Value_To_Bits (F32 (2.0)))
        and then (for all Lane in Wide.Lane_Index_32x8 =>
          Value_To_Bits (Native.Extract (Native.Splat (2.0), Lane)) =
            Value_To_Bits (F32 (2.0))),
        "F32x8 splat construction");
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
      Check (Wide.To_Bit_Mask (Wide.Less_Than (A, Two)) = 1,
        "F32x8 ordered comparison");

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_32x8'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_32x8 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_32x8 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 8 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_32x8 :=
              (if Count = 8
               then Wide.Mask_Bits_32x8'Last
               else Wide.Mask_Bits_32x8 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_32x8'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8 (2 ** 4 - 1);
         High_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_32x8 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 3)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 4);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_32x8 (85),
            "fixed alternating mask");
      end;


      Check_Compaction (Special_Lanes, 0, "special-bit zero mask");
      Check_Compaction
        (Special_Lanes, Wide.Mask_Bits_32x8'Last, "special-bit all mask");
      for Lane in Wide.Lane_Index_32x8 loop
         Check_Compaction
           (Special_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_32x8 (1), Lane),
            "special-bit one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 8 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_32x8 :=
              (if Count = 8
               then Wide.Mask_Bits_32x8'Last
               else Wide.Mask_Bits_32x8 (2 ** Count - 1));
         begin
            Check_Compaction
              (Special_Lanes, Prefix_Bits, "special-bit prefix mask" & Count'Image);
            Check_Compaction
              (Special_Lanes, Wide.Mask_Bits_32x8'Last xor Prefix_Bits,
               "special-bit suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8 (2 ** 4 - 1);
         High_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_32x8 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 3)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 4);
      begin
         Check_Compaction (Special_Lanes, Low_Half, "special-bit low-half mask");
         Check_Compaction (Special_Lanes, High_Half, "special-bit high-half mask");
         Check_Compaction
           (Special_Lanes, Across_Halves, "special-bit cross-half mask");
         Check_Compaction
           (Special_Lanes, Wide.Mask_Bits_32x8 (85),
            "special-bit alternating mask");
      end;


      Check_Compaction (Compaction_Extra_Lanes, 0, "extra-special-bit zero mask");
      Check_Compaction
        (Compaction_Extra_Lanes, Wide.Mask_Bits_32x8'Last, "extra-special-bit all mask");
      for Lane in Wide.Lane_Index_32x8 loop
         Check_Compaction
           (Compaction_Extra_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_32x8 (1), Lane),
            "extra-special-bit one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 8 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_32x8 :=
              (if Count = 8
               then Wide.Mask_Bits_32x8'Last
               else Wide.Mask_Bits_32x8 (2 ** Count - 1));
         begin
            Check_Compaction
              (Compaction_Extra_Lanes, Prefix_Bits, "extra-special-bit prefix mask" & Count'Image);
            Check_Compaction
              (Compaction_Extra_Lanes, Wide.Mask_Bits_32x8'Last xor Prefix_Bits,
               "extra-special-bit suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8 (2 ** 4 - 1);
         High_Half : constant Wide.Mask_Bits_32x8 :=
           Wide.Mask_Bits_32x8'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_32x8 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 3)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_32x8 (1), 4);
      begin
         Check_Compaction (Compaction_Extra_Lanes, Low_Half, "extra-special-bit low-half mask");
         Check_Compaction (Compaction_Extra_Lanes, High_Half, "extra-special-bit high-half mask");
         Check_Compaction
           (Compaction_Extra_Lanes, Across_Halves, "extra-special-bit cross-half mask");
         Check_Compaction
           (Compaction_Extra_Lanes, Wide.Mask_Bits_32x8 (85),
            "extra-special-bit alternating mask");
      end;

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
      Check (Same_Reduction (Wide.Reduce_Add (A), Reference_Reduce_Add (A_Lanes))
        and then Same_Reduction (Native.Reduce_Add (A), Reference_Reduce_Add (A_Lanes))
        and then Same_Reduction (Wide.Reduce_Min_Number (A), Reference_Reduce_Min_Number (A_Lanes))
        and then Same_Reduction (Native.Reduce_Min_Number (A), Reference_Reduce_Min_Number (A_Lanes))
        and then Same_Reduction (Wide.Reduce_Max_Number (A), Reference_Reduce_Max_Number (A_Lanes))
        and then Same_Reduction (Native.Reduce_Max_Number (A), Reference_Reduce_Max_Number (A_Lanes)),
        "F32x8 independent ordinary reduction oracle");
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
        "F32x8 independent signaling-NaN reduction oracle");
      Check_Reductions (Special_Lanes, "fixed IEEE categories");
      Check_Reductions (Compaction_Extra_Lanes,
                        "fixed signaling NaN and subnormal categories");
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
         Expected_One : constant Wide.Lane_Values_F32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              Special_Lanes (7 - Lane)];
         Expected_Two : constant Wide.Lane_Values_F32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane mod 2 = 0
               then Special_Lanes ((Lane * 3 + 1) mod 8)
               else A_Lanes ((Lane * 3 + 1) mod 8))];
      begin
         Check_Permutations
           (Special_Lanes, A_Lanes, Map_Selectors, Two_Selectors,
            Expected_One, Expected_Two, "fixed special-bit maps");
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

      Check_Movements (Special_Lanes, A_Lanes, "fixed special bits");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_32x8'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (8 - 1), "last lane");
      Check_Mask_Positions (2 ** (4 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 4, "high-half boundary");
      Check_Mask_Positions (85, "alternating");
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
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_32x8'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_32x8'Last,
              "F32x8 mask algebra" & Pattern'Image);
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
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
        and then (for all Lane in Wide.Lane_Index_32x8 =>
          Value_To_Bits (Wide.Extract (Wide.Load_Unaligned (Data, Data'First + 1), Lane)) =
            Value_To_Bits (A_Lanes (Lane)))
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "F32x8 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "F32x8 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "F32x8 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_F32x8 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_F32x8 := Random_Lanes;
            R_Bit_Lanes : constant Wide.Lane_Values_F32x8 := Random_Bit_Lanes;
            R_A : constant Wide.F32x8 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.F32x8 := Wide.From_Lanes (R_B_Lanes);
            R_Bits : constant Wide.F32x8 := Wide.From_Lanes (R_Bit_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_32x8;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_32x8;
            Expected_One : Wide.Lane_Values_F32x8;
            Expected_Two : Wide.Lane_Values_F32x8;
            R_Mask : constant Wide.Mask_32x8 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_32x8 (Next_U64 mod 2 ** 8));
            Slide : constant Natural := Natural (Next_U64 mod 11);
         begin
            for Lane in Wide.Lane_Index_32x8 loop
               declare
                  One_Lane : constant Wide.Lane_Index_32x8 :=
                    Wide.Lane_Index_32x8 (Next_U64 mod 8);
                  Two_Lane : constant Wide.Lane_Index_32x8 :=
                    Wide.Lane_Index_32x8 (Next_U64 mod 8);
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
              "F32x8 randomized arithmetic" & Iteration'Image);
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
            Check (Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "F32x8 randomized comparisons" & Iteration'Image);
            Check_Compaction
              (Wide.To_Lanes (R_Bits), Wide.To_Bit_Mask (R_Mask),
               "random special bits" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask)),
              "F32x8 randomized selection and compaction" & Iteration'Image);
            Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "F32x8 randomized slides" & Iteration'Image);
            Check (Same_Reduction (Wide.Reduce_Add (R_A), Reference_Reduce_Add (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Add (R_A), Reference_Reduce_Add (R_A_Lanes))
              and then Same_Reduction (Wide.Reduce_Min_Number (R_A), Reference_Reduce_Min_Number (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Min_Number (R_A), Reference_Reduce_Min_Number (R_A_Lanes))
              and then Same_Reduction (Wide.Reduce_Max_Number (R_A), Reference_Reduce_Max_Number (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Max_Number (R_A), Reference_Reduce_Max_Number (R_A_Lanes)),
              "F32x8 randomized finite reduction oracle" & Iteration'Image);
            Check (Same_Reduction (Wide.Reduce_Add (R_Bits), Reference_Reduce_Add (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Add (R_Bits), Reference_Reduce_Add (R_Bit_Lanes))
              and then Same_Reduction (Wide.Reduce_Min_Number (R_Bits), Reference_Reduce_Min_Number (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Min_Number (R_Bits), Reference_Reduce_Min_Number (R_Bit_Lanes))
              and then Same_Reduction (Wide.Reduce_Max_Number (R_Bits), Reference_Reduce_Max_Number (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Max_Number (R_Bits), Reference_Reduce_Max_Number (R_Bit_Lanes)),
              "F32x8 randomized raw-bit reduction oracle" & Iteration'Image);
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
      function Is_NaN (Value : F64) return Boolean is
        ((Value_To_Bits (Value) and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#
         and then (Value_To_Bits (Value) and 16#000F_FFFF_FFFF_FFFF#) /= 0);
      function Is_Signaling_NaN (Value : F64) return Boolean is
        (Is_NaN (Value)
         and then (Value_To_Bits (Value) and 16#0008_0000_0000_0000#) = 0);
      function Quiet_NaN (Value : F64) return F64 is
        (Bits_To_Value (Value_To_Bits (Value) or 16#0008_0000_0000_0000#));
      function Reference_Min_Number
        (Left, Right : F64) return F64
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
            return (if (Value_To_Bits (Left) and 16#8000_0000_0000_0000#) /= 0
                    then Left else Right);
         elsif Left < Right then
            return Left;
         else
            return Right;
         end if;
      end Reference_Min_Number;
      function Reference_Max_Number
        (Left, Right : F64) return F64
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
            return (if (Value_To_Bits (Left) and 16#8000_0000_0000_0000#) = 0
                    then Left else Right);
         elsif Left > Right then
            return Left;
         else
            return Right;
         end if;
      end Reference_Max_Number;
      function Reference_Reduce_Add
        (Values : Wide.Lane_Values_F64x4) return F64
      is
         Result : F64 := 0.0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result := Result + Values (Lane);
         end loop;
         return Result;
      end Reference_Reduce_Add;
      function Reference_Reduce_Min_Number
        (Values : Wide.Lane_Values_F64x4) return F64
      is
         Result : F64 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_64x4 range Values'First + 1 .. Values'Last loop
            Result := Reference_Min_Number (Result, Values (Lane));
         end loop;
         return Result;
      end Reference_Reduce_Min_Number;
      function Reference_Reduce_Max_Number
        (Values : Wide.Lane_Values_F64x4) return F64
      is
         Result : F64 := Values (Values'First);
      begin
         for Lane in Wide.Lane_Index_64x4 range Values'First + 1 .. Values'Last loop
            Result := Reference_Max_Number (Result, Values (Lane));
         end loop;
         return Result;
      end Reference_Reduce_Max_Number;
      function Same_Reduction
        (Actual, Expected : F64) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
           and then (Value_To_Bits (Actual) and 16#0008_0000_0000_0000#) /= 0
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Reductions
        (Values : Wide.Lane_Values_F64x4; Context : String)
      is
         Value : constant Wide.F64x4 := Wide.From_Lanes (Values);
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
           "F64x4 independent reduction oracle " & Context);
      end Check_Reductions;
      function Same_Extreme
        (Actual, Expected : F64) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
           and then (Value_To_Bits (Actual) and 16#0008_0000_0000_0000#) /= 0
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Extrema
        (Left_Values, Right_Values : Wide.Lane_Values_F64x4; Context : String)
      is
         Left_Value : constant Wide.F64x4 :=
           Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.F64x4 :=
           Wide.From_Lanes (Right_Values);
         Scalar_Min : constant Wide.F64x4 :=
           Wide.Min_Number (Left_Value, Right_Value);
         Native_Min : constant Wide.F64x4 :=
           Native.Min_Number (Left_Value, Right_Value);
         Scalar_Max : constant Wide.F64x4 :=
           Wide.Max_Number (Left_Value, Right_Value);
         Native_Max : constant Wide.F64x4 :=
           Native.Max_Number (Left_Value, Right_Value);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
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
               "F64x4 independent extrema oracle " & Context
               & Lane'Image);
         end loop;
      end Check_Extrema;
      function Same_Arithmetic
        (Actual, Expected : F64) return Boolean is
        (if Is_NaN (Expected)
         then Is_NaN (Actual)
         else Value_To_Bits (Actual) = Value_To_Bits (Expected));
      procedure Check_Arithmetic
        (Left_Values, Right_Values : Wide.Lane_Values_F64x4; Context : String)
      is
         Left_Value : constant Wide.F64x4 :=
           Wide.From_Lanes (Left_Values);
         Right_Value : constant Wide.F64x4 :=
           Wide.From_Lanes (Right_Values);
         Scalar_Add : constant Wide.F64x4 :=
           Wide.Add (Left_Value, Right_Value);
         Native_Add : constant Wide.F64x4 :=
           Native.Add (Left_Value, Right_Value);
         Scalar_Subtract : constant Wide.F64x4 :=
           Wide.Subtract (Left_Value, Right_Value);
         Native_Subtract : constant Wide.F64x4 :=
           Native.Subtract (Left_Value, Right_Value);
         Scalar_Multiply : constant Wide.F64x4 :=
           Wide.Multiply (Left_Value, Right_Value);
         Native_Multiply : constant Wide.F64x4 :=
           Native.Multiply (Left_Value, Right_Value);
         Scalar_Divide : constant Wide.F64x4 :=
           Wide.Divide (Left_Value, Right_Value);
         Native_Divide : constant Wide.F64x4 :=
           Native.Divide (Left_Value, Right_Value);
      begin
         for Lane in Wide.Lane_Index_64x4 loop
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
               "F64x4 independent arithmetic oracle " & Context
               & Lane'Image);
         end loop;
      end Check_Arithmetic;

      function Reference_Compress
        (Values : Wide.Lane_Values_F64x4; Bits : Wide.Mask_Bits_64x4)
         return Wide.Lane_Values_F64x4
      is
         Result : Wide.Lane_Values_F64x4 := [others => 0.0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Next_Lane) := Values (Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Compress;

      function Reference_Expand
        (Packed : Wide.Lane_Values_F64x4; Bits : Wide.Mask_Bits_64x4)
         return Wide.Lane_Values_F64x4
      is
         Result : Wide.Lane_Values_F64x4 := [others => 0.0];
         Next_Lane : Natural := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result (Lane) := Packed (Next_Lane);
               Next_Lane := Next_Lane + 1;
            end if;
         end loop;
         return Result;
      end Reference_Expand;

      procedure Check_Compaction
        (Values : Wide.Lane_Values_F64x4;
         Bits : Wide.Mask_Bits_64x4;
         Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_64x4 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_64x4 :=
           Native.Mask_From_Bit_Mask (Bits);
         Scalar_Source : constant Wide.F64x4 := Wide.From_Lanes (Values);
         Native_Source : constant Wide.F64x4 := Native.From_Lanes (Values);
         Expected_Packed : constant Wide.Lane_Values_F64x4 :=
           Reference_Compress (Values, Bits);
         Expected_Direct : constant Wide.Lane_Values_F64x4 :=
           Reference_Expand (Values, Bits);
         Expected_Round_Trip : constant Wide.Lane_Values_F64x4 :=
           Reference_Expand (Expected_Packed, Bits);
         Scalar_Packed : constant Wide.F64x4 :=
           Wide.Compress (Scalar_Source, Scalar_Mask);
         Native_Packed : constant Wide.F64x4 :=
           Native.Compress (Native_Source, Native_Mask);
         Scalar_Direct : constant Wide.F64x4 :=
           Wide.Expand (Scalar_Source, Scalar_Mask);
         Native_Direct : constant Wide.F64x4 :=
           Native.Expand (Native_Source, Native_Mask);
         Scalar_Round_Trip : constant Wide.F64x4 :=
           Wide.Expand (Scalar_Packed, Scalar_Mask);
         Native_Round_Trip : constant Wide.F64x4 :=
           Native.Expand (Native_Packed, Native_Mask);
      begin
         Check ((for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Wide.Extract (Scalar_Packed, Lane)) =
                Value_To_Bits (Expected_Packed (Lane)))
           and then (for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Native.Extract (Native_Packed, Lane)) =
                Value_To_Bits (Expected_Packed (Lane))),
           "F64x4 independent compression " & Label_Text);
         Check ((for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Wide.Extract (Scalar_Direct, Lane)) =
                Value_To_Bits (Expected_Direct (Lane)))
           and then (for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Native.Extract (Native_Direct, Lane)) =
                Value_To_Bits (Expected_Direct (Lane))),
           "F64x4 independent direct expansion " & Label_Text);
         Check ((for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Wide.Extract (Scalar_Round_Trip, Lane)) =
                Value_To_Bits (Expected_Round_Trip (Lane)))
           and then (for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Native.Extract (Native_Round_Trip, Lane)) =
                Value_To_Bits (Expected_Round_Trip (Lane))),
           "F64x4 compression expansion property " & Label_Text);
      end Check_Compaction;


      function Reference_First_True
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 4;
      end Reference_First_True;

      function Reference_Last_True
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
      begin
         for Lane in reverse Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               return Lane;
            end if;
         end loop;
         return 4;
      end Reference_Last_True;

      function Reference_Population_Count
        (Bits : Wide.Mask_Bits_64x4) return Wide.Lane_Count_64x4
      is
         Result : Wide.Lane_Count_64x4 := 0;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            if ((Bits / 2 ** Lane) mod 2) = 1 then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
      end Reference_Population_Count;

      procedure Check_Mask_Positions
        (Bits : Wide.Mask_Bits_64x4; Label_Text : String)
      is
         Scalar_Mask : constant Wide.Mask_64x4 :=
           Wide.Mask_From_Bit_Mask (Bits);
         Native_Mask : constant Wide.Mask_64x4 :=
           Native.Mask_From_Bit_Mask (Bits);
         Expected_First : constant Wide.Lane_Count_64x4 :=
           Reference_First_True (Bits);
         Expected_Last : constant Wide.Lane_Count_64x4 :=
           Reference_Last_True (Bits);
         Expected_Count : constant Wide.Lane_Count_64x4 :=
           Reference_Population_Count (Bits);
      begin
         Check (Wide.First_True (Scalar_Mask) = Expected_First
           and then Native.First_True (Native_Mask) = Expected_First
           and then Wide.Last_True (Scalar_Mask) = Expected_Last
           and then Native.Last_True (Native_Mask) = Expected_Last
           and then Wide.Population_Count (Scalar_Mask) = Expected_Count
           and then Native.Population_Count (Native_Mask) = Expected_Count,
           "F64x4 independent mask reductions " & Label_Text);
      end Check_Mask_Positions;


      procedure Check_Permutations
        (Left_Values, Right_Values : Wide.Lane_Values_F64x4;
         One_Selectors : Wide.Lane_Selectors_64x4;
         Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
         Expected_One, Expected_Two : Wide.Lane_Values_F64x4;
         Label_Text : String)
      is
         Scalar_Left : constant Wide.F64x4 := Wide.From_Lanes (Left_Values);
         Scalar_Right : constant Wide.F64x4 := Wide.From_Lanes (Right_Values);
         Native_Left : constant Wide.F64x4 := Native.From_Lanes (Left_Values);
         Native_Right : constant Wide.F64x4 := Native.From_Lanes (Right_Values);
         Scalar_One : constant Wide.F64x4 := Wide.Permute_Lanes
           (Scalar_Left, Wide.Make_Lane_Map (One_Selectors));
         Native_One : constant Wide.F64x4 := Native.Permute_Lanes
           (Native_Left, Native.Make_Lane_Map (One_Selectors));
         Scalar_Two : constant Wide.F64x4 := Wide.Permute_Lanes
           (Scalar_Left, Scalar_Right,
            Wide.Make_Two_Source_Lane_Map (Two_Selectors));
         Native_Two : constant Wide.F64x4 := Native.Permute_Lanes
           (Native_Left, Native_Right,
            Native.Make_Two_Source_Lane_Map (Two_Selectors));
      begin
         Check ((for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Wide.Extract (Scalar_One, Lane)) =
                Value_To_Bits (Expected_One (Lane))) and then (for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Native.Extract (Native_One, Lane)) =
                Value_To_Bits (Expected_One (Lane))),
           "F64x4 independent one-source permutation " & Label_Text);
         Check ((for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Wide.Extract (Scalar_Two, Lane)) =
                Value_To_Bits (Expected_Two (Lane))) and then (for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Native.Extract (Native_Two, Lane)) =
                Value_To_Bits (Expected_Two (Lane))),
           "F64x4 independent two-source permutation " & Label_Text);
      end Check_Permutations;


      procedure Check_Movements
        (Left_Values, Right_Values : Wide.Lane_Values_F64x4; Label_Text : String)
      is
         Left : constant Wide.F64x4 := Wide.From_Lanes (Left_Values);
         Right : constant Wide.F64x4 := Wide.From_Lanes (Right_Values);
         procedure Check_Result
           (Scalar_Result, Native_Result : Wide.F64x4;
            Expected : Wide.Lane_Values_F64x4; Operation : String)
         is
         begin
            Check ((for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Wide.Extract (Scalar_Result, Lane)) =
                Value_To_Bits (Expected (Lane)))
            and then (for all Lane in Wide.Lane_Index_64x4 =>
              Value_To_Bits (Native.Extract (Native_Result, Lane)) =
                Value_To_Bits (Expected (Lane))),
              "F64x4 independent movement " & Operation & " " & Label_Text);
         end Check_Result;
      begin
         Check_Result
           (Wide.Reverse_Lanes (Left), Native.Reverse_Lanes (Left),
            [for Lane in Wide.Lane_Index_64x4 => Left_Values (3 - Lane)],
            "reverse");
         Check_Result
           (Wide.Interleave_Low (Left, Right), Native.Interleave_Low (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane mod 2 = 0
                then Left_Values (Lane / 2)
                else Right_Values (Lane / 2))],
            "interleave low");
         Check_Result
           (Wide.Interleave_High (Left, Right), Native.Interleave_High (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane mod 2 = 0
                then Left_Values (2 + Lane / 2)
                else Right_Values (2 + Lane / 2))],
            "interleave high");
         Check_Result
           (Wide.Deinterleave_Even (Left, Right), Native.Deinterleave_Even (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane < 2
                then Left_Values (2 * Lane)
                else Right_Values (2 * (Lane - 2)))],
            "deinterleave even");
         Check_Result
           (Wide.Deinterleave_Odd (Left, Right), Native.Deinterleave_Odd (Left, Right),
            [for Lane in Wide.Lane_Index_64x4 =>
               (if Lane < 2
                then Left_Values (2 * Lane + 1)
                else Right_Values (2 * (Lane - 2) + 1))],
            "deinterleave odd");
         for Count in Natural range 0 .. 6 loop
            Check_Result
              (Wide.Slide_Lanes_Toward_Low (Left, Count),
               Native.Slide_Lanes_Toward_Low (Left, Count),
               [for Lane in Wide.Lane_Index_64x4 =>
                  (if Count < 4 and then Lane < 4 - Count
                   then Left_Values (Lane + Count) else 0.0)],
               "slide low" & Count'Image);
            Check_Result
              (Wide.Slide_Lanes_Toward_High (Left, Count),
               Native.Slide_Lanes_Toward_High (Left, Count),
               [for Lane in Wide.Lane_Index_64x4 =>
                  (if Count < 4 and then Lane >= Count
                   then Left_Values (Lane - Count) else 0.0)],
               "slide high" & Count'Image);
         end loop;
         Check_Result
           (Wide.Slide_Lanes_Toward_Low (Left, Natural'Last),
            Native.Slide_Lanes_Toward_Low (Left, Natural'Last),
            [others => 0.0],
            "slide low Natural'Last");
         Check_Result
           (Wide.Slide_Lanes_Toward_High (Left, Natural'Last),
            Native.Slide_Lanes_Toward_High (Left, Natural'Last),
            [others => 0.0],
            "slide high Natural'Last");
      end Check_Movements;

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
      Compaction_Extra_Lanes : constant Wide.Lane_Values_F64x4 :=
        [Bits_To_Value (16#FFF0_0000_0000_0000#), Bits_To_Value (16#7FF0_1234_5678_9ABC#), Bits_To_Value (1), Bits_To_Value (16#8000_0000_0000_0001#)];
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
      Check ((for all Lane in Wide.Lane_Index_64x4 =>
        Value_To_Bits (Wide.Extract (Wide.Splat (2.0), Lane)) =
          Value_To_Bits (F64 (2.0)))
        and then (for all Lane in Wide.Lane_Index_64x4 =>
          Value_To_Bits (Native.Extract (Native.Splat (2.0), Lane)) =
            Value_To_Bits (F64 (2.0))),
        "F64x4 splat construction");
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
      Check (Wide.To_Bit_Mask (Wide.Less_Than (A, Two)) = 1,
        "F64x4 ordered comparison");

      Check_Compaction (A_Lanes, 0, "fixed zero mask");
      Check_Compaction
        (A_Lanes, Wide.Mask_Bits_64x4'Last, "fixed all mask");
      for Lane in Wide.Lane_Index_64x4 loop
         Check_Compaction
           (A_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_64x4 (1), Lane),
            "fixed one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 4 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_64x4 :=
              (if Count = 4
               then Wide.Mask_Bits_64x4'Last
               else Wide.Mask_Bits_64x4 (2 ** Count - 1));
         begin
            Check_Compaction
              (A_Lanes, Prefix_Bits, "fixed prefix mask" & Count'Image);
            Check_Compaction
              (A_Lanes, Wide.Mask_Bits_64x4'Last xor Prefix_Bits,
               "fixed suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4 (2 ** 2 - 1);
         High_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_64x4 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 1)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 2);
      begin
         Check_Compaction (A_Lanes, Low_Half, "fixed low-half mask");
         Check_Compaction (A_Lanes, High_Half, "fixed high-half mask");
         Check_Compaction
           (A_Lanes, Across_Halves, "fixed cross-half mask");
         Check_Compaction
           (A_Lanes, Wide.Mask_Bits_64x4 (5),
            "fixed alternating mask");
      end;


      Check_Compaction (Special_Lanes, 0, "special-bit zero mask");
      Check_Compaction
        (Special_Lanes, Wide.Mask_Bits_64x4'Last, "special-bit all mask");
      for Lane in Wide.Lane_Index_64x4 loop
         Check_Compaction
           (Special_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_64x4 (1), Lane),
            "special-bit one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 4 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_64x4 :=
              (if Count = 4
               then Wide.Mask_Bits_64x4'Last
               else Wide.Mask_Bits_64x4 (2 ** Count - 1));
         begin
            Check_Compaction
              (Special_Lanes, Prefix_Bits, "special-bit prefix mask" & Count'Image);
            Check_Compaction
              (Special_Lanes, Wide.Mask_Bits_64x4'Last xor Prefix_Bits,
               "special-bit suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4 (2 ** 2 - 1);
         High_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_64x4 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 1)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 2);
      begin
         Check_Compaction (Special_Lanes, Low_Half, "special-bit low-half mask");
         Check_Compaction (Special_Lanes, High_Half, "special-bit high-half mask");
         Check_Compaction
           (Special_Lanes, Across_Halves, "special-bit cross-half mask");
         Check_Compaction
           (Special_Lanes, Wide.Mask_Bits_64x4 (5),
            "special-bit alternating mask");
      end;


      Check_Compaction (Compaction_Extra_Lanes, 0, "extra-special-bit zero mask");
      Check_Compaction
        (Compaction_Extra_Lanes, Wide.Mask_Bits_64x4'Last, "extra-special-bit all mask");
      for Lane in Wide.Lane_Index_64x4 loop
         Check_Compaction
           (Compaction_Extra_Lanes,
            Interfaces.Shift_Left (Wide.Mask_Bits_64x4 (1), Lane),
            "extra-special-bit one-hot mask" & Lane'Image);
      end loop;
      for Count in Natural range 0 .. 4 loop
         declare
            Prefix_Bits : constant Wide.Mask_Bits_64x4 :=
              (if Count = 4
               then Wide.Mask_Bits_64x4'Last
               else Wide.Mask_Bits_64x4 (2 ** Count - 1));
         begin
            Check_Compaction
              (Compaction_Extra_Lanes, Prefix_Bits, "extra-special-bit prefix mask" & Count'Image);
            Check_Compaction
              (Compaction_Extra_Lanes, Wide.Mask_Bits_64x4'Last xor Prefix_Bits,
               "extra-special-bit suffix mask" & Count'Image);
         end;
      end loop;
      declare
         Low_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4 (2 ** 2 - 1);
         High_Half : constant Wide.Mask_Bits_64x4 :=
           Wide.Mask_Bits_64x4'Last xor Low_Half;
         Across_Halves : constant Wide.Mask_Bits_64x4 :=
           Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 1)
           or Interfaces.Shift_Left
             (Wide.Mask_Bits_64x4 (1), 2);
      begin
         Check_Compaction (Compaction_Extra_Lanes, Low_Half, "extra-special-bit low-half mask");
         Check_Compaction (Compaction_Extra_Lanes, High_Half, "extra-special-bit high-half mask");
         Check_Compaction
           (Compaction_Extra_Lanes, Across_Halves, "extra-special-bit cross-half mask");
         Check_Compaction
           (Compaction_Extra_Lanes, Wide.Mask_Bits_64x4 (5),
            "extra-special-bit alternating mask");
      end;

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
      Check (Same_Reduction (Wide.Reduce_Add (A), Reference_Reduce_Add (A_Lanes))
        and then Same_Reduction (Native.Reduce_Add (A), Reference_Reduce_Add (A_Lanes))
        and then Same_Reduction (Wide.Reduce_Min_Number (A), Reference_Reduce_Min_Number (A_Lanes))
        and then Same_Reduction (Native.Reduce_Min_Number (A), Reference_Reduce_Min_Number (A_Lanes))
        and then Same_Reduction (Wide.Reduce_Max_Number (A), Reference_Reduce_Max_Number (A_Lanes))
        and then Same_Reduction (Native.Reduce_Max_Number (A), Reference_Reduce_Max_Number (A_Lanes)),
        "F64x4 independent ordinary reduction oracle");
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
        "F64x4 independent signaling-NaN reduction oracle");
      Check_Reductions (Special_Lanes, "fixed IEEE categories");
      Check_Reductions (Compaction_Extra_Lanes,
                        "fixed signaling NaN and subnormal categories");
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
         Expected_One : constant Wide.Lane_Values_F64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              Special_Lanes (3 - Lane)];
         Expected_Two : constant Wide.Lane_Values_F64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane mod 2 = 0
               then Special_Lanes ((Lane * 3 + 1) mod 4)
               else A_Lanes ((Lane * 3 + 1) mod 4))];
      begin
         Check_Permutations
           (Special_Lanes, A_Lanes, Map_Selectors, Two_Selectors,
            Expected_One, Expected_Two, "fixed special-bit maps");
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

      Check_Movements (Special_Lanes, A_Lanes, "fixed special bits");
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
      Check_Mask_Positions (0, "zero");
      Check_Mask_Positions (Mask_Bits_64x4'Last, "all");
      Check_Mask_Positions (1, "first lane");
      Check_Mask_Positions (2 ** (4 - 1), "last lane");
      Check_Mask_Positions (2 ** (2 - 1), "low-half boundary");
      Check_Mask_Positions (2 ** 2, "high-half boundary");
      Check_Mask_Positions (5, "alternating");
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
              and then Wide.To_Bit_Mask (Wide.Mask_And (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = 0
              and then Wide.To_Bit_Mask (Wide.Mask_Or (Scalar_Mask, Wide.Mask_Not (Scalar_Mask))) = Mask_Bits_64x4'Last
              and then Native.To_Bit_Mask (Native.Mask_And (Native_Mask, Native.Mask_Not (Native_Mask))) = 0
              and then Native.To_Bit_Mask (Native.Mask_Or (Native_Mask, Native.Mask_Not (Native_Mask))) = Mask_Bits_64x4'Last,
              "F64x4 mask algebra" & Pattern'Image);
            Check_Mask_Positions (Bits, "pattern" & Pattern'Image);
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
        and then (for all Lane in Wide.Lane_Index_64x4 =>
          Value_To_Bits (Wide.Extract (Wide.Load_Unaligned (Data, Data'First + 1), Lane)) =
            Value_To_Bits (A_Lanes (Lane)))
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
      Check (Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First)
        and then Native.To_Lanes (Native.Load_Aligned (Aligned_Data, Aligned_Data'First)) = A_Lanes,
        "F64x4 native aligned memory");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1)
        and then not Native.Is_Aligned_32 (Aligned_Data, Aligned_Data'First + 1),
        "F64x4 misaligned address predicate");
      Check (not Wide.Is_Aligned_32 (Aligned_Data, Natural'Last)
        and then not Native.Is_Aligned_32 (Aligned_Data, Natural'Last),
        "F64x4 out-of-range maximum-index alignment predicate");
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
            R_A_Lanes : constant Wide.Lane_Values_F64x4 := Random_Lanes;
            R_B_Lanes : constant Wide.Lane_Values_F64x4 := Random_Lanes;
            R_Bit_Lanes : constant Wide.Lane_Values_F64x4 := Random_Bit_Lanes;
            R_A : constant Wide.F64x4 := Wide.From_Lanes (R_A_Lanes);
            R_B : constant Wide.F64x4 := Wide.From_Lanes (R_B_Lanes);
            R_Bits : constant Wide.F64x4 := Wide.From_Lanes (R_Bit_Lanes);
            R_One_Selectors : Wide.Lane_Selectors_64x4;
            R_Two_Selectors : Wide.Two_Source_Lane_Selectors_64x4;
            Expected_One : Wide.Lane_Values_F64x4;
            Expected_Two : Wide.Lane_Values_F64x4;
            R_Mask : constant Wide.Mask_64x4 := Wide.Mask_From_Bit_Mask
              (Mask_Bits_64x4 (Next_U64 mod 2 ** 4));
            Slide : constant Natural := Natural (Next_U64 mod 7);
         begin
            for Lane in Wide.Lane_Index_64x4 loop
               declare
                  One_Lane : constant Wide.Lane_Index_64x4 :=
                    Wide.Lane_Index_64x4 (Next_U64 mod 4);
                  Two_Lane : constant Wide.Lane_Index_64x4 :=
                    Wide.Lane_Index_64x4 (Next_U64 mod 4);
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
              "F64x4 randomized arithmetic" & Iteration'Image);
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
            Check (Native.To_Bit_Mask (Native.Less_Than (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Less_Than (R_A, R_B))
              and then Native.To_Bit_Mask (Native.Greater_Equal (R_A, R_B)) = Wide.To_Bit_Mask (Wide.Greater_Equal (R_A, R_B)),
              "F64x4 randomized comparisons" & Iteration'Image);
            Check_Compaction
              (Wide.To_Lanes (R_Bits), Wide.To_Bit_Mask (R_Mask),
               "random special bits" & Iteration'Image);
            Check (Native.To_Lanes (Native.Select_Value (R_Mask, R_A, R_B)) = Wide.To_Lanes (Wide.Select_Value (R_Mask, R_A, R_B))
              and then Native.To_Lanes (Native.Compress (R_A, R_Mask)) = Wide.To_Lanes (Wide.Compress (R_A, R_Mask))
              and then Native.To_Lanes (Native.Expand (R_A, R_Mask)) = Wide.To_Lanes (Wide.Expand (R_A, R_Mask)),
              "F64x4 randomized selection and compaction" & Iteration'Image);
            Check (Native.To_Lanes (Native.Slide_Lanes_Toward_Low (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_Low (R_A, Slide))
              and then Native.To_Lanes (Native.Slide_Lanes_Toward_High (R_A, Slide)) = Wide.To_Lanes (Wide.Slide_Lanes_Toward_High (R_A, Slide)),
              "F64x4 randomized slides" & Iteration'Image);
            Check (Same_Reduction (Wide.Reduce_Add (R_A), Reference_Reduce_Add (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Add (R_A), Reference_Reduce_Add (R_A_Lanes))
              and then Same_Reduction (Wide.Reduce_Min_Number (R_A), Reference_Reduce_Min_Number (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Min_Number (R_A), Reference_Reduce_Min_Number (R_A_Lanes))
              and then Same_Reduction (Wide.Reduce_Max_Number (R_A), Reference_Reduce_Max_Number (R_A_Lanes))
              and then Same_Reduction (Native.Reduce_Max_Number (R_A), Reference_Reduce_Max_Number (R_A_Lanes)),
              "F64x4 randomized finite reduction oracle" & Iteration'Image);
            Check (Same_Reduction (Wide.Reduce_Add (R_Bits), Reference_Reduce_Add (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Add (R_Bits), Reference_Reduce_Add (R_Bit_Lanes))
              and then Same_Reduction (Wide.Reduce_Min_Number (R_Bits), Reference_Reduce_Min_Number (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Min_Number (R_Bits), Reference_Reduce_Min_Number (R_Bit_Lanes))
              and then Same_Reduction (Wide.Reduce_Max_Number (R_Bits), Reference_Reduce_Max_Number (R_Bit_Lanes))
              and then Same_Reduction (Native.Reduce_Max_Number (R_Bits), Reference_Reduce_Max_Number (R_Bit_Lanes)),
              "F64x4 randomized raw-bit reduction oracle" & Iteration'Image);
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

   procedure Test_Wide_Conversions is
      function Random_Lane_Values_U8x32 return Wide.Lane_Values_U8x32 is
         Result : Wide.Lane_Values_U8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result (Lane) := U8 (Next_U64 mod 2 ** 8);
         end loop;
         return Result;
      end Random_Lane_Values_U8x32;
      function Bits_To_I8 is new Ada.Unchecked_Conversion (U8, I8);
      function Random_Lane_Values_I8x32 return Wide.Lane_Values_I8x32 is
         Result : Wide.Lane_Values_I8x32;
      begin
         for Lane in Wide.Lane_Index_8x32 loop
            Result (Lane) := Bits_To_I8 (U8 (Next_U64 mod 2 ** 8));
         end loop;
         return Result;
      end Random_Lane_Values_I8x32;
      function Random_Lane_Values_U16x16 return Wide.Lane_Values_U16x16 is
         Result : Wide.Lane_Values_U16x16;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Result (Lane) := U16 (Next_U64 mod 2 ** 16);
         end loop;
         return Result;
      end Random_Lane_Values_U16x16;
      function Bits_To_I16 is new Ada.Unchecked_Conversion (U16, I16);
      function Random_Lane_Values_I16x16 return Wide.Lane_Values_I16x16 is
         Result : Wide.Lane_Values_I16x16;
      begin
         for Lane in Wide.Lane_Index_16x16 loop
            Result (Lane) := Bits_To_I16 (U16 (Next_U64 mod 2 ** 16));
         end loop;
         return Result;
      end Random_Lane_Values_I16x16;
      function Random_Lane_Values_U32x8 return Wide.Lane_Values_U32x8 is
         Result : Wide.Lane_Values_U32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := U32 (Next_U64 mod 2 ** 32);
         end loop;
         return Result;
      end Random_Lane_Values_U32x8;
      function Bits_To_I32 is new Ada.Unchecked_Conversion (U32, I32);
      function Random_Lane_Values_I32x8 return Wide.Lane_Values_I32x8 is
         Result : Wide.Lane_Values_I32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := Bits_To_I32 (U32 (Next_U64 mod 2 ** 32));
         end loop;
         return Result;
      end Random_Lane_Values_I32x8;
      function Random_Lane_Values_U64x4 return Wide.Lane_Values_U64x4 is
         Result : Wide.Lane_Values_U64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := Next_U64;
         end loop;
         return Result;
      end Random_Lane_Values_U64x4;
      function Bits_To_I64 is new Ada.Unchecked_Conversion (U64, I64);
      function Random_Lane_Values_I64x4 return Wide.Lane_Values_I64x4 is
         Result : Wide.Lane_Values_I64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := Bits_To_I64 (Next_U64);
         end loop;
         return Result;
      end Random_Lane_Values_I64x4;
      function Random_Lane_Values_F32x8 return Wide.Lane_Values_F32x8 is
         Result : Wide.Lane_Values_F32x8;
      begin
         for Lane in Wide.Lane_Index_32x8 loop
            Result (Lane) := F32 (Integer (Next_U64 mod 2_000_001) - 1_000_000) / 128.0;
         end loop;
         return Result;
      end Random_Lane_Values_F32x8;
      function Random_Lane_Values_F64x4 return Wide.Lane_Values_F64x4 is
         Result : Wide.Lane_Values_F64x4;
      begin
         for Lane in Wide.Lane_Index_64x4 loop
            Result (Lane) := F64 (Integer (Next_U64 mod 2_000_001) - 1_000_000) / 128.0;
         end loop;
         return Result;
      end Random_Lane_Values_F64x4;
   begin
      declare
         Source_Lanes : constant Wide.Lane_Values_U8x32 := [0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1];
         Value : constant Wide.U8x32 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant U8x16 := U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant U16x8 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant U16x8 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_U16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low U8x32 to U16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U8x32 := Random_Lane_Values_U8x32;
            Value : constant Wide.U8x32 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant U8x16 := U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant U16x8 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant U16x8 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_U16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low U8x32 to U16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U8x32 := [0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1];
         Value : constant Wide.U8x32 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant U8x16 := U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)]));
         Expected_Low : constant U16x8 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant U16x8 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_U16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High U8x32 to U16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U8x32 := Random_Lane_Values_U8x32;
            Value : constant Wide.U8x32 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant U8x16 := U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)]));
            Expected_Low : constant U16x8 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant U16x8 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_U16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High U8x32 to U16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I8x32 := [I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0];
         Value : constant Wide.I8x32 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant I8x16 := I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant I16x8 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant I16x8 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_I16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low I8x32 to I16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I8x32 := Random_Lane_Values_I8x32;
            Value : constant Wide.I8x32 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant I8x16 := I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant I16x8 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant I16x8 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_I16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low I8x32 to I16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I8x32 := [I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0];
         Value : constant Wide.I8x32 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant I8x16 := I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)]));
         Expected_Low : constant I16x8 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant I16x8 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_I16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High I8x32 to I16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I8x32 := Random_Lane_Values_I8x32;
            Value : constant Wide.I8x32 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant I8x16 := I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)]));
            Expected_Low : constant I16x8 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant I16x8 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_I16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High I8x32 to I16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1];
         Value : constant Wide.U16x16 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant U16x8 := U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant U32x4 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant U32x4 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low U16x16 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            Value : constant Wide.U16x16 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant U16x8 := U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant U32x4 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant U32x4 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low U16x16 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1];
         Value : constant Wide.U16x16 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant U16x8 := U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)]));
         Expected_Low : constant U32x4 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant U32x4 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High U16x16 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            Value : constant Wide.U16x16 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant U16x8 := U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)]));
            Expected_Low : constant U32x4 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant U32x4 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High U16x16 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I16x16 := [I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last];
         Value : constant Wide.I16x16 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant I16x8 := I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant I32x4 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant I32x4 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_I32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low I16x16 to I32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            Value : constant Wide.I16x16 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant I16x8 := I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant I32x4 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant I32x4 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_I32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low I16x16 to I32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I16x16 := [I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last];
         Value : constant Wide.I16x16 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant I16x8 := I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)]));
         Expected_Low : constant I32x4 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant I32x4 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_I32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High I16x16 to I32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            Value : constant Wide.I16x16 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant I16x8 := I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)]));
            Expected_Low : constant I32x4 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant I32x4 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_I32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High I16x16 to I32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 65_535, 65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0];
         Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant U32x4 := U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant U64x2 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant U64x2 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_U64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low U32x8 to U64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant U32x4 := U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant U64x2 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant U64x2 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_U64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low U32x8 to U64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 65_535, 65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0];
         Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant U32x4 := U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)]));
         Expected_Low : constant U64x2 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant U64x2 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_U64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High U32x8 to U64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant U32x4 := U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)]));
            Expected_Low : constant U64x2 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant U64x2 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_U64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High U32x8 to U64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant I32x4 := I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant I64x2 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant I64x2 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_I64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low I32x8 to I64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant I32x4 := I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant I64x2 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant I64x2 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_I64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low I32x8 to I64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant I32x4 := I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)]));
         Expected_Low : constant I64x2 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant I64x2 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_I64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High I32x8 to I64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant I32x4 := I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)]));
            Expected_Low : constant I64x2 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant I64x2 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_I64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High I32x8 to I64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_F32x8 := [-F32'Last, -16_777_217.0, -2.75, -0.5, 0.0, 1.5, 16_777_217.0, F32'Last];
         Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant F32x4 := F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)]));
         Expected_Low : constant F64x2 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant F64x2 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_F64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
           "wide Widen_Low F32x8 to F64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_F32x8 := Random_Lane_Values_F32x8;
            Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant F32x4 := F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)]));
            Expected_Low : constant F64x2 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant F64x2 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_F64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_Low (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_Low (Value)) = Expected,
              "wide randomized Widen_Low F32x8 to F64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_F32x8 := [-F32'Last, -16_777_217.0, -2.75, -0.5, 0.0, 1.5, 16_777_217.0, F32'Last];
         Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
         Root_Source : constant F32x4 := F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)]));
         Expected_Low : constant F64x2 := Flyology_SIMD.Widen_Low (Root_Source);
         Expected_High : constant F64x2 := Flyology_SIMD.Widen_High (Root_Source);
         Expected : constant Wide.Lane_Values_F64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
           and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
           "wide Widen_High F32x8 to F64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_F32x8 := Random_Lane_Values_F32x8;
            Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
            Root_Source : constant F32x4 := F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)]));
            Expected_Low : constant F64x2 := Flyology_SIMD.Widen_Low (Root_Source);
            Expected_High : constant F64x2 := Flyology_SIMD.Widen_High (Root_Source);
            Expected : constant Wide.Lane_Values_F64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Widen_High (Value)) = Expected
              and then Native.To_Lanes (Native.Widen_High (Value)) = Expected,
              "wide randomized Widen_High F32x8 to F64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1];
         High_Lanes : constant Wide.Lane_Values_U16x16 := [256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767];
         Low_Value : constant Wide.U16x16 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.U16x16 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U8x16 := Flyology_SIMD.Narrow_Truncate
           (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
         Expected_High : constant U8x16 := Flyology_SIMD.Narrow_Truncate
           (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_U8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Truncate U16x16 to U8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            High_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            Low_Value : constant Wide.U16x16 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.U16x16 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U8x16 := Flyology_SIMD.Narrow_Truncate
              (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
            Expected_High : constant U8x16 := Flyology_SIMD.Narrow_Truncate
              (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Truncate U16x16 to U8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I16x16 := [I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last];
         High_Lanes : constant Wide.Lane_Values_I16x16 := [-1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129];
         Low_Value : constant Wide.I16x16 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I16x16 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant I8x16 := Flyology_SIMD.Narrow_Truncate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
         Expected_High : constant I8x16 := Flyology_SIMD.Narrow_Truncate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_I8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Truncate I16x16 to I8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            High_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            Low_Value : constant Wide.I16x16 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I16x16 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant I8x16 := Flyology_SIMD.Narrow_Truncate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
            Expected_High : constant I8x16 := Flyology_SIMD.Narrow_Truncate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_I8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Truncate I16x16 to I8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 65_535, 65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0];
         High_Lanes : constant Wide.Lane_Values_U32x8 := [65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0, 1, 65_535, 65_536];
         Low_Value : constant Wide.U32x8 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.U32x8 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U16x8 := Flyology_SIMD.Narrow_Truncate
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
         Expected_High : constant U16x8 := Flyology_SIMD.Narrow_Truncate
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_U16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Truncate U32x8 to U16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            High_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            Low_Value : constant Wide.U32x8 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.U32x8 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U16x8 := Flyology_SIMD.Narrow_Truncate
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
            Expected_High : constant U16x8 := Flyology_SIMD.Narrow_Truncate
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_U16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Truncate U32x8 to U16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         High_Lanes : constant Wide.Lane_Values_I32x8 := [-1, 0, 65_535, 65_536, I32'Last, I32'First, -2_147_483_647, -65_537];
         Low_Value : constant Wide.I32x8 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I32x8 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant I16x8 := Flyology_SIMD.Narrow_Truncate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
         Expected_High : constant I16x8 := Flyology_SIMD.Narrow_Truncate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_I16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Truncate I32x8 to I16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            High_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Low_Value : constant Wide.I32x8 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I32x8 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant I16x8 := Flyology_SIMD.Narrow_Truncate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
            Expected_High : constant I16x8 := Flyology_SIMD.Narrow_Truncate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_I16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Truncate I32x8 to I16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_U64x4 := [0, 1, 4_294_967_295, 4_294_967_296];
         High_Lanes : constant Wide.Lane_Values_U64x4 := [4_294_967_296, 9_223_372_036_854_775_807, 9_223_372_036_854_775_808, U64'Last];
         Low_Value : constant Wide.U64x4 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.U64x4 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U32x4 := Flyology_SIMD.Narrow_Truncate
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
         Expected_High : constant U32x4 := Flyology_SIMD.Narrow_Truncate
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Truncate U64x4 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lane_Values_U64x4;
            High_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lane_Values_U64x4;
            Low_Value : constant Wide.U64x4 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.U64x4 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U32x4 := Flyology_SIMD.Narrow_Truncate
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
            Expected_High : constant U32x4 := Flyology_SIMD.Narrow_Truncate
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Truncate U64x4 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I64x4 := [I64'First, -9_223_372_036_854_775_807, -4_294_967_297, -1];
         High_Lanes : constant Wide.Lane_Values_I64x4 := [-1, 0, 4_294_967_295, 4_294_967_296];
         Low_Value : constant Wide.I64x4 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I64x4 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant I32x4 := Flyology_SIMD.Narrow_Truncate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
         Expected_High : constant I32x4 := Flyology_SIMD.Narrow_Truncate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_I32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Truncate I64x4 to I32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            High_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            Low_Value : constant Wide.I64x4 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I64x4 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant I32x4 := Flyology_SIMD.Narrow_Truncate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
            Expected_High : constant I32x4 := Flyology_SIMD.Narrow_Truncate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_I32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Truncate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Truncate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Truncate I64x4 to I32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1];
         High_Lanes : constant Wide.Lane_Values_U16x16 := [256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767];
         Low_Value : constant Wide.U16x16 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.U16x16 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U8x16 := Flyology_SIMD.Narrow_Saturate
           (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
         Expected_High : constant U8x16 := Flyology_SIMD.Narrow_Saturate
           (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_U8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate U16x16 to U8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            High_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            Low_Value : constant Wide.U16x16 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.U16x16 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U8x16 := Flyology_SIMD.Narrow_Saturate
              (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
            Expected_High : constant U8x16 := Flyology_SIMD.Narrow_Saturate
              (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate U16x16 to U8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I16x16 := [I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last];
         High_Lanes : constant Wide.Lane_Values_I16x16 := [-1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129];
         Low_Value : constant Wide.I16x16 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I16x16 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant I8x16 := Flyology_SIMD.Narrow_Saturate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
         Expected_High : constant I8x16 := Flyology_SIMD.Narrow_Saturate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_I8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate I16x16 to I8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            High_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            Low_Value : constant Wide.I16x16 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I16x16 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant I8x16 := Flyology_SIMD.Narrow_Saturate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
            Expected_High : constant I8x16 := Flyology_SIMD.Narrow_Saturate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_I8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate I16x16 to I8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 65_535, 65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0];
         High_Lanes : constant Wide.Lane_Values_U32x8 := [65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0, 1, 65_535, 65_536];
         Low_Value : constant Wide.U32x8 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.U32x8 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U16x8 := Flyology_SIMD.Narrow_Saturate
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
         Expected_High : constant U16x8 := Flyology_SIMD.Narrow_Saturate
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_U16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate U32x8 to U16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            High_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            Low_Value : constant Wide.U32x8 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.U32x8 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U16x8 := Flyology_SIMD.Narrow_Saturate
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
            Expected_High : constant U16x8 := Flyology_SIMD.Narrow_Saturate
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_U16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate U32x8 to U16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         High_Lanes : constant Wide.Lane_Values_I32x8 := [-1, 0, 65_535, 65_536, I32'Last, I32'First, -2_147_483_647, -65_537];
         Low_Value : constant Wide.I32x8 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I32x8 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant I16x8 := Flyology_SIMD.Narrow_Saturate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
         Expected_High : constant I16x8 := Flyology_SIMD.Narrow_Saturate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_I16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate I32x8 to I16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            High_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Low_Value : constant Wide.I32x8 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I32x8 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant I16x8 := Flyology_SIMD.Narrow_Saturate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
            Expected_High : constant I16x8 := Flyology_SIMD.Narrow_Saturate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_I16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate I32x8 to I16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_U64x4 := [0, 1, 4_294_967_295, 4_294_967_296];
         High_Lanes : constant Wide.Lane_Values_U64x4 := [4_294_967_296, 9_223_372_036_854_775_807, 9_223_372_036_854_775_808, U64'Last];
         Low_Value : constant Wide.U64x4 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.U64x4 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U32x4 := Flyology_SIMD.Narrow_Saturate
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
         Expected_High : constant U32x4 := Flyology_SIMD.Narrow_Saturate
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate U64x4 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lane_Values_U64x4;
            High_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lane_Values_U64x4;
            Low_Value : constant Wide.U64x4 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.U64x4 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U32x4 := Flyology_SIMD.Narrow_Saturate
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
            Expected_High : constant U32x4 := Flyology_SIMD.Narrow_Saturate
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate U64x4 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I64x4 := [I64'First, -9_223_372_036_854_775_807, -4_294_967_297, -1];
         High_Lanes : constant Wide.Lane_Values_I64x4 := [-1, 0, 4_294_967_295, 4_294_967_296];
         Low_Value : constant Wide.I64x4 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I64x4 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant I32x4 := Flyology_SIMD.Narrow_Saturate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
         Expected_High : constant I32x4 := Flyology_SIMD.Narrow_Saturate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_I32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate I64x4 to I32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            High_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            Low_Value : constant Wide.I64x4 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I64x4 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant I32x4 := Flyology_SIMD.Narrow_Saturate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
            Expected_High : constant I32x4 := Flyology_SIMD.Narrow_Saturate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_I32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate I64x4 to I32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I16x16 := [I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last];
         High_Lanes : constant Wide.Lane_Values_I16x16 := [-1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129];
         Low_Value : constant Wide.I16x16 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I16x16 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U8x16 := Flyology_SIMD.Narrow_Saturate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
         Expected_High : constant U8x16 := Flyology_SIMD.Narrow_Saturate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_U8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate I16x16 to U8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            High_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            Low_Value : constant Wide.I16x16 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I16x16 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U8x16 := Flyology_SIMD.Narrow_Saturate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Low_Lanes (Lane + 8)])));
            Expected_High : constant U8x16 := Flyology_SIMD.Narrow_Saturate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 0)])), I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => High_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate I16x16 to U8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         High_Lanes : constant Wide.Lane_Values_I32x8 := [-1, 0, 65_535, 65_536, I32'Last, I32'First, -2_147_483_647, -65_537];
         Low_Value : constant Wide.I32x8 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I32x8 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U16x8 := Flyology_SIMD.Narrow_Saturate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
         Expected_High : constant U16x8 := Flyology_SIMD.Narrow_Saturate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_U16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate I32x8 to U16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            High_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Low_Value : constant Wide.I32x8 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I32x8 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U16x8 := Flyology_SIMD.Narrow_Saturate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Low_Lanes (Lane + 4)])));
            Expected_High : constant U16x8 := Flyology_SIMD.Narrow_Saturate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 0)])), I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => High_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_U16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate I32x8 to U16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_I64x4 := [I64'First, -9_223_372_036_854_775_807, -4_294_967_297, -1];
         High_Lanes : constant Wide.Lane_Values_I64x4 := [-1, 0, 4_294_967_295, 4_294_967_296];
         Low_Value : constant Wide.I64x4 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.I64x4 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant U32x4 := Flyology_SIMD.Narrow_Saturate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
         Expected_High : constant U32x4 := Flyology_SIMD.Narrow_Saturate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
           "wide Narrow_Saturate I64x4 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            High_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            Low_Value : constant Wide.I64x4 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.I64x4 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant U32x4 := Flyology_SIMD.Narrow_Saturate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
            Expected_High : constant U32x4 := Flyology_SIMD.Narrow_Saturate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Saturate (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Saturate (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Saturate I64x4 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Low_Lanes : constant Wide.Lane_Values_F64x4 := [-F64'Last, -9_007_199_254_740_993.0, -2.75, -0.5];
         High_Lanes : constant Wide.Lane_Values_F64x4 := [-0.5, 0.0, 1.5, 9_007_199_254_740_993.0];
         Low_Value : constant Wide.F64x4 := Wide.From_Lanes (Low_Lanes);
         High_Value : constant Wide.F64x4 := Wide.From_Lanes (High_Lanes);
         Expected_Low : constant F32x4 := Flyology_SIMD.Narrow_Round
           (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
         Expected_High : constant F32x4 := Flyology_SIMD.Narrow_Round
           (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_F32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Narrow_Round (Low_Value, High_Value)) = Expected
           and then Native.To_Lanes (Native.Narrow_Round (Low_Value, High_Value)) = Expected,
           "wide Narrow_Round F64x4 to F32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Low_Lanes : constant Wide.Lane_Values_F64x4 := Random_Lane_Values_F64x4;
            High_Lanes : constant Wide.Lane_Values_F64x4 := Random_Lane_Values_F64x4;
            Low_Value : constant Wide.F64x4 := Wide.From_Lanes (Low_Lanes);
            High_Value : constant Wide.F64x4 := Wide.From_Lanes (High_Lanes);
            Expected_Low : constant F32x4 := Flyology_SIMD.Narrow_Round
              (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 0)])), F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Low_Lanes (Lane + 2)])));
            Expected_High : constant F32x4 := Flyology_SIMD.Narrow_Round
              (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 0)])), F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => High_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_F32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Narrow_Round (Low_Value, High_Value)) = Expected
              and then Native.To_Lanes (Native.Narrow_Round (Low_Value, High_Value)) = Expected,
              "wide randomized Narrow_Round F64x4 to F32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant F32x4 := Flyology_SIMD.Convert_Round
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
         Expected_High : constant F32x4 := Flyology_SIMD.Convert_Round
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_F32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
           "wide Convert_Round I32x8 to F32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant F32x4 := Flyology_SIMD.Convert_Round
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
            Expected_High : constant F32x4 := Flyology_SIMD.Convert_Round
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_F32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
              "wide randomized Convert_Round I32x8 to F32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 65_535, 65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0];
         Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant F32x4 := Flyology_SIMD.Convert_Round
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
         Expected_High : constant F32x4 := Flyology_SIMD.Convert_Round
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_F32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
           "wide Convert_Round U32x8 to F32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant F32x4 := Flyology_SIMD.Convert_Round
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
            Expected_High : constant F32x4 := Flyology_SIMD.Convert_Round
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_F32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
              "wide randomized Convert_Round U32x8 to F32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I64x4 := [I64'First, -9_223_372_036_854_775_807, -4_294_967_297, -1];
         Value : constant Wide.I64x4 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant F64x2 := Flyology_SIMD.Convert_Round
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
         Expected_High : constant F64x2 := Flyology_SIMD.Convert_Round
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_F64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
           "wide Convert_Round I64x4 to F64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            Value : constant Wide.I64x4 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant F64x2 := Flyology_SIMD.Convert_Round
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
            Expected_High : constant F64x2 := Flyology_SIMD.Convert_Round
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_F64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
              "wide randomized Convert_Round I64x4 to F64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U64x4 := [0, 1, 4_294_967_295, 4_294_967_296];
         Value : constant Wide.U64x4 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant F64x2 := Flyology_SIMD.Convert_Round
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
         Expected_High : constant F64x2 := Flyology_SIMD.Convert_Round
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_F64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
           "wide Convert_Round U64x4 to F64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lane_Values_U64x4;
            Value : constant Wide.U64x4 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant F64x2 := Flyology_SIMD.Convert_Round
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
            Expected_High : constant F64x2 := Flyology_SIMD.Convert_Round
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_F64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Round (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Round (Value)) = Expected,
              "wide randomized Convert_Round U64x4 to F64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_F32x8 := [-F32'Last, -16_777_217.0, -2.75, -0.5, 0.0, 1.5, 16_777_217.0, F32'Last];
         Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant I32x4 := Flyology_SIMD.Convert_Truncate_Saturate
           (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
         Expected_High : constant I32x4 := Flyology_SIMD.Convert_Truncate_Saturate
           (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_I32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
           "wide Convert_Truncate_Saturate F32x8 to I32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_F32x8 := Random_Lane_Values_F32x8;
            Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant I32x4 := Flyology_SIMD.Convert_Truncate_Saturate
              (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
            Expected_High : constant I32x4 := Flyology_SIMD.Convert_Truncate_Saturate
              (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_I32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
              "wide randomized Convert_Truncate_Saturate F32x8 to I32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_F32x8 := [-F32'Last, -16_777_217.0, -2.75, -0.5, 0.0, 1.5, 16_777_217.0, F32'Last];
         Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant U32x4 := Flyology_SIMD.Convert_Truncate_Saturate
           (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
         Expected_High : constant U32x4 := Flyology_SIMD.Convert_Truncate_Saturate
           (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
           "wide Convert_Truncate_Saturate F32x8 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_F32x8 := Random_Lane_Values_F32x8;
            Value : constant Wide.F32x8 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant U32x4 := Flyology_SIMD.Convert_Truncate_Saturate
              (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
            Expected_High : constant U32x4 := Flyology_SIMD.Convert_Truncate_Saturate
              (F32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
              "wide randomized Convert_Truncate_Saturate F32x8 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_F64x4 := [-F64'Last, -9_007_199_254_740_993.0, -2.75, -0.5];
         Value : constant Wide.F64x4 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant I64x2 := Flyology_SIMD.Convert_Truncate_Saturate
           (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
         Expected_High : constant I64x2 := Flyology_SIMD.Convert_Truncate_Saturate
           (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_I64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
           "wide Convert_Truncate_Saturate F64x4 to I64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_F64x4 := Random_Lane_Values_F64x4;
            Value : constant Wide.F64x4 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant I64x2 := Flyology_SIMD.Convert_Truncate_Saturate
              (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
            Expected_High : constant I64x2 := Flyology_SIMD.Convert_Truncate_Saturate
              (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_I64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
              "wide randomized Convert_Truncate_Saturate F64x4 to I64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_F64x4 := [-F64'Last, -9_007_199_254_740_993.0, -2.75, -0.5];
         Value : constant Wide.F64x4 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant U64x2 := Flyology_SIMD.Convert_Truncate_Saturate
           (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
         Expected_High : constant U64x2 := Flyology_SIMD.Convert_Truncate_Saturate
           (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_U64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
           "wide Convert_Truncate_Saturate F64x4 to U64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_F64x4 := Random_Lane_Values_F64x4;
            Value : constant Wide.F64x4 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant U64x2 := Flyology_SIMD.Convert_Truncate_Saturate
              (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
            Expected_High : constant U64x2 := Flyology_SIMD.Convert_Truncate_Saturate
              (F64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_U64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Truncate_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Truncate_Saturate (Value)) = Expected,
              "wide randomized Convert_Truncate_Saturate F64x4 to U64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I8x32 := [I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0, 1, 126, I8'Last, I8'First, -127, -1, 0];
         Value : constant Wide.I8x32 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant U8x16 := Flyology_SIMD.Convert_Saturate
           (I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)])));
         Expected_High : constant U8x16 := Flyology_SIMD.Convert_Saturate
           (I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)])));
         Expected : constant Wide.Lane_Values_U8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate I8x32 to U8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I8x32 := Random_Lane_Values_I8x32;
            Value : constant Wide.I8x32 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant U8x16 := Flyology_SIMD.Convert_Saturate
              (I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)])));
            Expected_High : constant U8x16 := Flyology_SIMD.Convert_Saturate
              (I8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)])));
            Expected : constant Wide.Lane_Values_U8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate I8x32 to U8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U8x32 := [0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1, 127, 128, 254, 255, 0, 1];
         Value : constant Wide.U8x32 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant I8x16 := Flyology_SIMD.Convert_Saturate
           (U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)])));
         Expected_High : constant I8x16 := Flyology_SIMD.Convert_Saturate
           (U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)])));
         Expected : constant Wide.Lane_Values_I8x32 :=
           [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate U8x32 to I8x32");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U8x32 := Random_Lane_Values_U8x32;
            Value : constant Wide.U8x32 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant I8x16 := Flyology_SIMD.Convert_Saturate
              (U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 0)])));
            Expected_High : constant I8x16 := Flyology_SIMD.Convert_Saturate
              (U8x16'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 15 => Source_Lanes (Lane + 16)])));
            Expected : constant Wide.Lane_Values_I8x32 :=
              [for Lane in Wide.Lane_Index_8x32 =>
              (if Lane < 16
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 16))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate U8x32 to I8x32" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I16x16 := [I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last, I16'First, -32_767, -129, -1, 0, 127, 128, I16'Last];
         Value : constant Wide.I16x16 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant U16x8 := Flyology_SIMD.Convert_Saturate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)])));
         Expected_High : constant U16x8 := Flyology_SIMD.Convert_Saturate
           (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_U16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate I16x16 to U16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I16x16 := Random_Lane_Values_I16x16;
            Value : constant Wide.I16x16 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant U16x8 := Flyology_SIMD.Convert_Saturate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)])));
            Expected_High : constant U16x8 := Flyology_SIMD.Convert_Saturate
              (I16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_U16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate I16x16 to U16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U16x16 := [0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1, 255, 256, 32_767, 32_768, U16'Last, 0, 1];
         Value : constant Wide.U16x16 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant I16x8 := Flyology_SIMD.Convert_Saturate
           (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)])));
         Expected_High : constant I16x8 := Flyology_SIMD.Convert_Saturate
           (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)])));
         Expected : constant Wide.Lane_Values_I16x16 :=
           [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate U16x16 to I16x16");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U16x16 := Random_Lane_Values_U16x16;
            Value : constant Wide.U16x16 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant I16x8 := Flyology_SIMD.Convert_Saturate
              (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 0)])));
            Expected_High : constant I16x8 := Flyology_SIMD.Convert_Saturate
              (U16x8'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 7 => Source_Lanes (Lane + 8)])));
            Expected : constant Wide.Lane_Values_I16x16 :=
              [for Lane in Wide.Lane_Index_16x16 =>
              (if Lane < 8
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 8))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate U16x16 to I16x16" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I32x8 := [I32'First, -2_147_483_647, -65_537, -1, 0, 65_535, 65_536, I32'Last];
         Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant U32x4 := Flyology_SIMD.Convert_Saturate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
         Expected_High : constant U32x4 := Flyology_SIMD.Convert_Saturate
           (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_U32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate I32x8 to U32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I32x8 := Random_Lane_Values_I32x8;
            Value : constant Wide.I32x8 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant U32x4 := Flyology_SIMD.Convert_Saturate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
            Expected_High : constant U32x4 := Flyology_SIMD.Convert_Saturate
              (I32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_U32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate I32x8 to U32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U32x8 := [0, 1, 65_535, 65_536, 2_147_483_647, 2_147_483_648, U32'Last, 0];
         Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant I32x4 := Flyology_SIMD.Convert_Saturate
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
         Expected_High : constant I32x4 := Flyology_SIMD.Convert_Saturate
           (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
         Expected : constant Wide.Lane_Values_I32x8 :=
           [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate U32x8 to I32x8");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U32x8 := Random_Lane_Values_U32x8;
            Value : constant Wide.U32x8 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant I32x4 := Flyology_SIMD.Convert_Saturate
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 0)])));
            Expected_High : constant I32x4 := Flyology_SIMD.Convert_Saturate
              (U32x4'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 3 => Source_Lanes (Lane + 4)])));
            Expected : constant Wide.Lane_Values_I32x8 :=
              [for Lane in Wide.Lane_Index_32x8 =>
              (if Lane < 4
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 4))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate U32x8 to I32x8" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_I64x4 := [I64'First, -9_223_372_036_854_775_807, -4_294_967_297, -1];
         Value : constant Wide.I64x4 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant U64x2 := Flyology_SIMD.Convert_Saturate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
         Expected_High : constant U64x2 := Flyology_SIMD.Convert_Saturate
           (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_U64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate I64x4 to U64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_I64x4 := Random_Lane_Values_I64x4;
            Value : constant Wide.I64x4 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant U64x2 := Flyology_SIMD.Convert_Saturate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
            Expected_High : constant U64x2 := Flyology_SIMD.Convert_Saturate
              (I64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_U64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate I64x4 to U64x4" & Iteration'Image);
         end;
      end loop;
      declare
         Source_Lanes : constant Wide.Lane_Values_U64x4 := [0, 1, 4_294_967_295, 4_294_967_296];
         Value : constant Wide.U64x4 := Wide.From_Lanes (Source_Lanes);
         Expected_Low : constant I64x2 := Flyology_SIMD.Convert_Saturate
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
         Expected_High : constant I64x2 := Flyology_SIMD.Convert_Saturate
           (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
         Expected : constant Wide.Lane_Values_I64x4 :=
           [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
      begin
         Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
           and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
           "wide Convert_Saturate U64x4 to I64x4");
      end;
      for Iteration in 1 .. 32 loop
         declare
            Source_Lanes : constant Wide.Lane_Values_U64x4 := Random_Lane_Values_U64x4;
            Value : constant Wide.U64x4 := Wide.From_Lanes (Source_Lanes);
            Expected_Low : constant I64x2 := Flyology_SIMD.Convert_Saturate
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 0)])));
            Expected_High : constant I64x2 := Flyology_SIMD.Convert_Saturate
              (U64x2'(Flyology_SIMD.From_Lanes ([for Lane in 0 .. 1 => Source_Lanes (Lane + 2)])));
            Expected : constant Wide.Lane_Values_I64x4 :=
              [for Lane in Wide.Lane_Index_64x4 =>
              (if Lane < 2
               then Flyology_SIMD.Extract (Expected_Low, Lane)
               else Flyology_SIMD.Extract (Expected_High, Lane - 2))];
         begin
            Check (Wide.To_Lanes (Wide.Convert_Saturate (Value)) = Expected
              and then Native.To_Lanes (Native.Convert_Saturate (Value)) = Expected,
              "wide randomized Convert_Saturate U64x4 to I64x4" & Iteration'Image);
         end;
      end loop;
      declare
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
   end Test_Wide_Conversions;

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
   Test_Wide_Conversions;
   Ada.Text_IO.Put_Line ("wide-family semantic tests: PASS");
end Wide_Tests;
