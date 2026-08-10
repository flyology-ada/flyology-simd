with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Family_Tests is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type Interfaces.Integer_8;
   use type Interfaces.Integer_16;
   use type Interfaces.Integer_32;
   use type Interfaces.Integer_64;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.IEEE_Float_64;
   Failures : Natural := 0;
   procedure Check (Condition : Boolean; Message : String) is
   begin if not Condition then Failures := Failures + 1; Put_Line ("FAIL: " & Message); end if; end Check;

   function Same (Left, Right : I8x16) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I8x16 is
      A : constant I8x16 := From_Lanes ([I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First]);
      B : constant I8x16 := From_Lanes ([1, I8'Last, -1, I8'First, 0, 1, I8'Last, -1, I8'First, 0, 1, I8'Last, -1, I8'First, 0, 1]);
      Data, Reference : I8_Array (0 .. 21) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "I8x16 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "I8x16 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "I8x16 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "I8x16 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "I8x16 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "I8x16 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "I8x16 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "I8x16 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "I8x16 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "I8x16 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "I8x16 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "I8x16 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I8x16 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I8x16 reverse");
      for Shift in Natural range 0 .. 10 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I8x16 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I8x16 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I8x16 sar" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I8x16 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I8x16 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I8x16 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I8x16 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I8x16 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I8x16 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "I8x16 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "I8x16 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "I8x16 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I8x16 full memory");
      for N in Lane_Count_8x16 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I8x16 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I8x16 := From_Lanes ([for Lane in Lane_Index_8x16 => I8 (((Iteration * 37 + Lane * 19) mod 251) - 125)]);
            R_B : constant I8x16 := From_Lanes ([for Lane in Lane_Index_8x16 => I8 (((Iteration * 23 + Lane * 29) mod 251) - 125)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I8x16 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I8x16 randomized compare");
         end;
      end loop;
   end Test_I8x16;

   function Same (Left, Right : U16x8) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_U16x8 is
      A : constant U16x8 := From_Lanes ([0, 1, U16'Last, 2 ** (15), 17, 0, 1, U16'Last]);
      B : constant U16x8 := From_Lanes ([1, U16'Last, 2, 2 ** (15) - 1, 9, 1, U16'Last, 2]);
      Data, Reference : U16_Array (0 .. 13) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "U16x8 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "U16x8 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "U16x8 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "U16x8 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "U16x8 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "U16x8 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "U16x8 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "U16x8 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "U16x8 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "U16x8 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "U16x8 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "U16x8 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "U16x8 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "U16x8 reverse");
      for Shift in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U16x8 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U16x8 shr" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "U16x8 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "U16x8 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "U16x8 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "U16x8 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "U16x8 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U16x8 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "U16x8 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "U16x8 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "U16x8 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U16x8 full memory");
      for N in Lane_Count_16x8 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "U16x8 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant U16x8 := From_Lanes ([for Lane in Lane_Index_16x8 => U16 ((Iteration * 37 + Lane * 19) mod 251)]);
            R_B : constant U16x8 := From_Lanes ([for Lane in Lane_Index_16x8 => U16 ((Iteration * 23 + Lane * 29) mod 251)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U16x8 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "U16x8 randomized compare");
         end;
      end loop;
   end Test_U16x8;

   function Same (Left, Right : I16x8) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I16x8 is
      A : constant I16x8 := From_Lanes ([I16'First, -1, 0, 1, I16'Last, I16'First, -1, 0]);
      B : constant I16x8 := From_Lanes ([1, I16'Last, -1, I16'First, 0, 1, I16'Last, -1]);
      Data, Reference : I16_Array (0 .. 13) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "I16x8 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "I16x8 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "I16x8 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "I16x8 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "I16x8 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "I16x8 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "I16x8 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "I16x8 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "I16x8 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "I16x8 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "I16x8 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "I16x8 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I16x8 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I16x8 reverse");
      for Shift in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I16x8 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I16x8 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I16x8 sar" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I16x8 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I16x8 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I16x8 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I16x8 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I16x8 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I16x8 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "I16x8 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "I16x8 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "I16x8 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I16x8 full memory");
      for N in Lane_Count_16x8 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I16x8 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I16x8 := From_Lanes ([for Lane in Lane_Index_16x8 => I16 (((Iteration * 37 + Lane * 19) mod 251) - 125)]);
            R_B : constant I16x8 := From_Lanes ([for Lane in Lane_Index_16x8 => I16 (((Iteration * 23 + Lane * 29) mod 251) - 125)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I16x8 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I16x8 randomized compare");
         end;
      end loop;
   end Test_I16x8;

   function Same (Left, Right : U32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_U32x4 is
      A : constant U32x4 := From_Lanes ([0, 1, U32'Last, 2 ** (31)]);
      B : constant U32x4 := From_Lanes ([1, U32'Last, 2, 2 ** (31) - 1]);
      Data, Reference : U32_Array (0 .. 9) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "U32x4 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "U32x4 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "U32x4 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "U32x4 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "U32x4 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "U32x4 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "U32x4 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "U32x4 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "U32x4 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "U32x4 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "U32x4 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "U32x4 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "U32x4 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "U32x4 reverse");
      for Shift in Natural range 0 .. 34 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U32x4 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U32x4 shr" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "U32x4 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "U32x4 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "U32x4 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "U32x4 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "U32x4 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U32x4 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "U32x4 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "U32x4 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "U32x4 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U32x4 full memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "U32x4 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant U32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => U32 ((Iteration * 37 + Lane * 19) mod 251)]);
            R_B : constant U32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => U32 ((Iteration * 23 + Lane * 29) mod 251)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U32x4 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "U32x4 randomized compare");
         end;
      end loop;
   end Test_U32x4;

   function Same (Left, Right : I32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I32x4 is
      A : constant I32x4 := From_Lanes ([I32'First, -1, 0, 1]);
      B : constant I32x4 := From_Lanes ([1, I32'Last, -1, I32'First]);
      Data, Reference : I32_Array (0 .. 9) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "I32x4 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "I32x4 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "I32x4 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "I32x4 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "I32x4 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "I32x4 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "I32x4 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "I32x4 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "I32x4 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "I32x4 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "I32x4 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "I32x4 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I32x4 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I32x4 reverse");
      for Shift in Natural range 0 .. 34 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I32x4 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I32x4 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I32x4 sar" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I32x4 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I32x4 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I32x4 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I32x4 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I32x4 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I32x4 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "I32x4 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "I32x4 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "I32x4 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I32x4 full memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I32x4 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => I32 (((Iteration * 37 + Lane * 19) mod 251) - 125)]);
            R_B : constant I32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => I32 (((Iteration * 23 + Lane * 29) mod 251) - 125)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I32x4 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I32x4 randomized compare");
         end;
      end loop;
   end Test_I32x4;

   function Same (Left, Right : U64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_U64x2 is
      A : constant U64x2 := From_Lanes ([0, 1]);
      B : constant U64x2 := From_Lanes ([1, U64'Last]);
      Data, Reference : U64_Array (0 .. 7) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "U64x2 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "U64x2 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "U64x2 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "U64x2 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "U64x2 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "U64x2 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "U64x2 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "U64x2 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "U64x2 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "U64x2 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "U64x2 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "U64x2 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "U64x2 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "U64x2 reverse");
      for Shift in Natural range 0 .. 66 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U64x2 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U64x2 shr" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "U64x2 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "U64x2 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "U64x2 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "U64x2 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "U64x2 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U64x2 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "U64x2 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "U64x2 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "U64x2 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U64x2 full memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "U64x2 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant U64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => U64 ((Iteration * 37 + Lane * 19) mod 251)]);
            R_B : constant U64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => U64 ((Iteration * 23 + Lane * 29) mod 251)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U64x2 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "U64x2 randomized compare");
         end;
      end loop;
   end Test_U64x2;

   function Same (Left, Right : I64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I64x2 is
      A : constant I64x2 := From_Lanes ([I64'First, -1]);
      B : constant I64x2 := From_Lanes ([1, I64'Last]);
      Data, Reference : I64_Array (0 .. 7) := [others => 0];
   begin
      Check (Same (Backends.Native.Add_Wrap (A, B), Add_Wrap (A, B)), "I64x2 Add_Wrap");
      Check (Same (Backends.Native.Subtract_Wrap (A, B), Subtract_Wrap (A, B)), "I64x2 Subtract_Wrap");
      Check (Same (Backends.Native.Multiply_Wrap (A, B), Multiply_Wrap (A, B)), "I64x2 Multiply_Wrap");
      Check (Same (Backends.Native.Add_Saturate (A, B), Add_Saturate (A, B)), "I64x2 Add_Saturate");
      Check (Same (Backends.Native.Subtract_Saturate (A, B), Subtract_Saturate (A, B)), "I64x2 Subtract_Saturate");
      Check (Same (Backends.Native.Bitwise_And (A, B), Bitwise_And (A, B)), "I64x2 Bitwise_And");
      Check (Same (Backends.Native.Bitwise_Or (A, B), Bitwise_Or (A, B)), "I64x2 Bitwise_Or");
      Check (Same (Backends.Native.Bitwise_Xor (A, B), Bitwise_Xor (A, B)), "I64x2 Bitwise_Xor");
      Check (Same (Backends.Native.Min (A, B), Min (A, B)), "I64x2 Min");
      Check (Same (Backends.Native.Max (A, B), Max (A, B)), "I64x2 Max");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "I64x2 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "I64x2 Interleave_High");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I64x2 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I64x2 reverse");
      for Shift in Natural range 0 .. 66 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I64x2 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I64x2 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I64x2 sar" & Shift'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I64x2 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I64x2 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I64x2 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I64x2 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I64x2 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I64x2 select");
      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), "I64x2 reduce add");
      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), "I64x2 reduce min");
      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), "I64x2 reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I64x2 full memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I64x2 partial" & N'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => I64 (((Iteration * 37 + Lane * 19) mod 251) - 125)]);
            R_B : constant I64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => I64 (((Iteration * 23 + Lane * 29) mod 251) - 125)]);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I64x2 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I64x2 randomized compare");
         end;
      end loop;
   end Test_I64x2;

   function Same (Left, Right : F32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_F32x4 is
      A : constant F32x4 := From_Lanes ([0.0, -0.0, 1.5, -2.25]);
      B : constant F32x4 := From_Lanes ([2.0, -3.0, 0.5, 4.0]);
      Data, Reference : F32_Array (0 .. 9) := [others => 0.0];
   begin
      Check (Same (Backends.Native.Add (A, B), Add (A, B)), "F32x4 Add");
      Check (Same (Backends.Native.Subtract (A, B), Subtract (A, B)), "F32x4 Subtract");
      Check (Same (Backends.Native.Multiply (A, B), Multiply (A, B)), "F32x4 Multiply");
      Check (Same (Backends.Native.Divide (A, B), Divide (A, B)), "F32x4 Divide");
      Check (Same (Backends.Native.Min_Number (A, B), Min_Number (A, B)), "F32x4 Min_Number");
      Check (Same (Backends.Native.Max_Number (A, B), Max_Number (A, B)), "F32x4 Max_Number");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "F32x4 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "F32x4 Interleave_High");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "F32x4 reverse");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "F32x4 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "F32x4 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "F32x4 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "F32x4 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "F32x4 Greater_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A, B)) = Flyology_SIMD.To_Bit_Mask (Unordered (A, B)), "F32x4 Unordered");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "F32x4 select");
      Check (Backends.Native.Reduce_Add (A) = Reduce_Add (A), "F32x4 reduce");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "F32x4 full memory");
      for N in Lane_Count_32x4 loop Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B); Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "F32x4 partial" & N'Image); end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => F32 (Iteration * 37 + Lane * 19) / 7.0]);
            R_B : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => F32 (Iteration * 23 + Lane * 29 + 1) / 11.0]);
         begin
            Check (Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F32x4 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)), "F32x4 randomized compare");
         end;
      end loop;
   end Test_F32x4;

   function Same (Left, Right : F64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_F64x2 is
      A : constant F64x2 := From_Lanes ([0.0, -0.0]);
      B : constant F64x2 := From_Lanes ([2.0, -3.0]);
      Data, Reference : F64_Array (0 .. 7) := [others => 0.0];
   begin
      Check (Same (Backends.Native.Add (A, B), Add (A, B)), "F64x2 Add");
      Check (Same (Backends.Native.Subtract (A, B), Subtract (A, B)), "F64x2 Subtract");
      Check (Same (Backends.Native.Multiply (A, B), Multiply (A, B)), "F64x2 Multiply");
      Check (Same (Backends.Native.Divide (A, B), Divide (A, B)), "F64x2 Divide");
      Check (Same (Backends.Native.Min_Number (A, B), Min_Number (A, B)), "F64x2 Min_Number");
      Check (Same (Backends.Native.Max_Number (A, B), Max_Number (A, B)), "F64x2 Max_Number");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "F64x2 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "F64x2 Interleave_High");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "F64x2 reverse");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "F64x2 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "F64x2 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "F64x2 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "F64x2 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "F64x2 Greater_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A, B)) = Flyology_SIMD.To_Bit_Mask (Unordered (A, B)), "F64x2 Unordered");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "F64x2 select");
      Check (Backends.Native.Reduce_Add (A) = Reduce_Add (A), "F64x2 reduce");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "F64x2 full memory");
      for N in Lane_Count_64x2 loop Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B); Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "F64x2 partial" & N'Image); end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => F64 (Iteration * 37 + Lane * 19) / 7.0]);
            R_B : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => F64 (Iteration * 23 + Lane * 29 + 1) / 11.0]);
         begin
            Check (Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F64x2 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)), "F64x2 randomized compare");
         end;
      end loop;
   end Test_F64x2;

   function To_F32 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, F32);
   function F32_Bits is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);
   function To_F64 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, F64);
   function F64_Bits is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);
   procedure Test_Floating_Specials is
      pragma Suppress (Validity_Check);
      NaN32 : constant F32 := To_F32 (16#7FC0_0001#);
      Inf32 : constant F32 := To_F32 (16#7F80_0000#);
      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);
      A32 : constant F32x4 := From_Lanes ([NaN32, Inf32, Neg_Zero32, 0.0]);
      B32 : constant F32x4 := From_Lanes ([1.0, Inf32, 0.0, Neg_Zero32]);
      NaN64 : constant F64 := To_F64 (16#7FF8_0000_0000_0001#);
      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);
      A64 : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);
      B64 : constant F64x2 := From_Lanes ([1.0, 0.0]);
   begin
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A32, B32)) = Flyology_SIMD.To_Bit_Mask (Unordered (A32, B32)), "F32 NaN unordered");
      Check (F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0, "F32 signed zero min/max");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A64, B64)) = Flyology_SIMD.To_Bit_Mask (Unordered (A64, B64)), "F64 NaN unordered");
      Check (F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0, "F64 signed zero min/max");
   end Test_Floating_Specials;

begin
   Put_Line ("full-family differential tests seed=0x5EED0123");
   Test_I8x16;
   Test_U16x8;
   Test_I16x8;
   Test_U32x4;
   Test_I32x4;
   Test_U64x2;
   Test_I64x2;
   Test_F32x4;
   Test_F64x2;
   Test_Floating_Specials;
   if Failures = 0 then Put_Line ("PASS"); else Put_Line ("FAILURES:" & Failures'Image); Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure); end if;
exception when Error : others => Put_Line ("UNCAUGHT: " & Ada.Exceptions.Exception_Information (Error)); Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Family_Tests;
