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
   Seed : constant Interfaces.Unsigned_64 := 16#5EED_0123_D15C_A11A#;
   State : Interfaces.Unsigned_64 := Seed;
   Failures : Natural := 0;
   procedure Check (Condition : Boolean; Message : String) is
   begin if not Condition then Failures := Failures + 1; Put_Line ("FAIL: " & Message); end if; end Check;

   function Next_U64 return Interfaces.Unsigned_64 is
   begin
      State := State xor Interfaces.Shift_Left (State, 13);
      State := State xor Interfaces.Shift_Right (State, 7);
      State := State xor Interfaces.Shift_Left (State, 17);
      return State;
   end Next_U64;

   function Reference_Popcount (Value : Natural) return Natural is
      Bits : Natural := Value;
      Count : Natural := 0;
   begin
      while Bits /= 0 loop Count := Count + Bits mod 2; Bits := Bits / 2; end loop;
      return Count;
   end Reference_Popcount;

   function Bits_To_I8x16 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_8, I8);
   function I8x16_To_Bits is new Ada.Unchecked_Conversion (I8, Interfaces.Unsigned_8);
   function Reference_Add_Saturate_I8x16 (Left, Right : I8) return I8 is
   begin
      if Right > 0 and then Left > I8'Last - Right then return I8'Last;
      elsif Right < 0 and then Left < I8'First - Right then return I8'First;
      else return Left + Right; end if;
   end Reference_Add_Saturate_I8x16;
   function Reference_Subtract_Saturate_I8x16 (Left, Right : I8) return I8 is
   begin
      if Right < 0 and then Left > I8'Last + Right then return I8'Last;
      elsif Right > 0 and then Left < I8'First + Right then return I8'First;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_I8x16;
   function Reference_Reduce_Add_I8x16 (Value : I8x16) return I8 is
      Accumulator : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_8x16 loop Accumulator := Accumulator + I8x16_To_Bits (Extract (Value, Lane)); end loop;
      return Bits_To_I8x16 (Accumulator);
   end Reference_Reduce_Add_I8x16;
   function Reference_Reduce_Min_I8x16 (Value : I8x16) return I8 is
      Result : I8 := Extract (Value, Lane_Index_8x16'First);
   begin
      for Lane in Lane_Index_8x16 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_I8x16;
   function Reference_Reduce_Max_I8x16 (Value : I8x16) return I8 is
      Result : I8 := Extract (Value, Lane_Index_8x16'First);
   begin
      for Lane in Lane_Index_8x16 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_I8x16;
   function Random_I8x16_Lanes return Lane_Values_I8x16 is
      Result : Lane_Values_I8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result (Lane) := Bits_To_I8x16 (Interfaces.Unsigned_8 (Next_U64 and 16#FF#)); end loop;
      return Result;
   end Random_I8x16_Lanes;
   function Same (Left, Right : I8x16) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I8x16 is
      A : constant I8x16 := From_Lanes ([I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First]);
      B : constant I8x16 := From_Lanes ([1, I8'Last, -1, I8'First, 0, 1, I8'Last, -1, I8'First, 0, 1, I8'Last, -1, I8'First, 0, 1]);
      Data, Reference : I8_Array (0 .. 21) := [others => 0];
      Aligned_Data : I8_Array (0 .. 15) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First], "I8x16 scalar lane construction");
      Check (Same (I8x16'(Backends.Native.Zero), I8x16'(Zero)) and then Same (I8x16'(Backends.Native.Splat (To_Lanes (A) (0))), I8x16'(Splat (To_Lanes (A) (0)))), "I8x16 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I8x16 native lane roundtrip");
      for Lane in Lane_Index_8x16 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I8x16 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I8x16 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "I8x16 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "I8x16 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "I8x16 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I8x16 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I8x16 reverse");
      for Shift in Natural range 0 .. 10 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I8x16 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I8x16 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I8x16 sar" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 8), Zero) and then Same (Shift_Right_Logical (A, 8), Zero), "I8x16 independent oversized logical shifts");
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I8x16 (Interfaces.Shift_Left (I8x16_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I8x16 (Interfaces.Shift_Right (I8x16_To_Bits (Extract (A, Lane)), 1)), "I8x16 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I8x16 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 8), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I8x16 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_8x16 (15 - Lane)), "I8x16 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (Lane / 2)) else Extract (B, Lane_Index_8x16 (Lane / 2))), "I8x16 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (B, Lane_Index_8x16 (8 + Lane / 2))), "I8x16 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8)))), "I8x16 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8) + 1))), "I8x16 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I8x16 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I8x16 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I8x16 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I8x16 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I8x16 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I8x16 select");
      for Pattern in Natural range 0 .. 2 ** 16 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Interfaces.Unsigned_16 (Pattern), "I8x16 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern = 0) and then All_True (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern = 2 ** 16 - 1), "I8x16 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_Popcount (Pattern), "I8x16 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))))) = Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern), "I8x16 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1) and then To_Bit_Mask (Mask_Xor (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1), "I8x16 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern = 2 ** 16 - 1) and then Backends.Native.Population_Count (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_Popcount (Pattern), "I8x16 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))))) = Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern), "I8x16 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1), "I8x16 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_8x16 loop Check (Backends.Native.Test (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Lane) = Test (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Lane), "I8x16 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B)), "I8x16 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_8x16 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I8x16 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I8x16 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I8x16 (A), "I8x16 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I8x16 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I8x16 (A), "I8x16 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I8x16 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I8x16 (A), "I8x16 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I8x16 full memory");
      for Lane in Lane_Index_8x16 loop Check (Data (1 + Lane) = Extract (A, Lane), "I8x16 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I8x16 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I8x16 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I8x16 aligned memory");
      for N in Lane_Count_8x16 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_8x16 (Index - 2)) else 0), "I8x16 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I8x16 partial" & N'Image);
         declare
            Exact : I8_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "I8x16 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I8x16 := From_Lanes (Random_I8x16_Lanes);
            R_B : constant I8x16 := From_Lanes (Random_I8x16_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I8x16 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I8x16 randomized compare");
            for Lane in Lane_Index_8x16 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) + I8x16_To_Bits (Extract (R_B, Lane))), "I8x16 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) - I8x16_To_Bits (Extract (R_B, Lane))), "I8x16 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) * I8x16_To_Bits (Extract (R_B, Lane))), "I8x16 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I8x16 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I8x16 (Extract (R_A, Lane), Extract (R_B, Lane)), "I8x16 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) and I8x16_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) or I8x16_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) xor I8x16_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Not (R_A), Lane) = (Bits_To_I8x16 (not I8x16_To_Bits (Extract (R_A, Lane)))), "I8x16 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "I8x16 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "I8x16 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_I8x16;

   function Reference_Add_Saturate_U16x8 (Left, Right : U16) return U16 is
   begin
      if Left > U16'Last - Right then return U16'Last;
      else return Left + Right; end if;
   end Reference_Add_Saturate_U16x8;
   function Reference_Subtract_Saturate_U16x8 (Left, Right : U16) return U16 is
   begin
      if Left < Right then return 0;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_U16x8;
   function Reference_Reduce_Add_U16x8 (Value : U16x8) return U16 is
      Accumulator : Interfaces.Unsigned_16 := 0;
   begin
      for Lane in Lane_Index_16x8 loop Accumulator := Accumulator + Interfaces.Unsigned_16 (Extract (Value, Lane)); end loop;
      return U16 (Accumulator);
   end Reference_Reduce_Add_U16x8;
   function Reference_Reduce_Min_U16x8 (Value : U16x8) return U16 is
      Result : U16 := Extract (Value, Lane_Index_16x8'First);
   begin
      for Lane in Lane_Index_16x8 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_U16x8;
   function Reference_Reduce_Max_U16x8 (Value : U16x8) return U16 is
      Result : U16 := Extract (Value, Lane_Index_16x8'First);
   begin
      for Lane in Lane_Index_16x8 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_U16x8;
   function Random_U16x8_Lanes return Lane_Values_U16x8 is
      Result : Lane_Values_U16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result (Lane) := Interfaces.Unsigned_16 (Next_U64 and 16#FFFF#); end loop;
      return Result;
   end Random_U16x8_Lanes;
   function Same (Left, Right : U16x8) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_U16x8 is
      A : constant U16x8 := From_Lanes ([0, 1, U16'Last, 2 ** (15), 17, 0, 1, U16'Last]);
      B : constant U16x8 := From_Lanes ([1, U16'Last, 2, 2 ** (15) - 1, 9, 1, U16'Last, 2]);
      Data, Reference : U16_Array (0 .. 13) := [others => 0];
      Aligned_Data : U16_Array (0 .. 7) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [0, 1, U16'Last, 2 ** (15), 17, 0, 1, U16'Last], "U16x8 scalar lane construction");
      Check (Same (U16x8'(Backends.Native.Zero), U16x8'(Zero)) and then Same (U16x8'(Backends.Native.Splat (To_Lanes (A) (0))), U16x8'(Splat (To_Lanes (A) (0)))), "U16x8 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "U16x8 native lane roundtrip");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "U16x8 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "U16x8 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "U16x8 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "U16x8 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "U16x8 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "U16x8 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "U16x8 reverse");
      for Shift in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U16x8 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U16x8 shr" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 16), Zero) and then Same (Shift_Right_Logical (A, 16), Zero), "U16x8 independent oversized logical shifts");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U16 (Interfaces.Shift_Left (Interfaces.Unsigned_16 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U16 (Interfaces.Shift_Right (Interfaces.Unsigned_16 (Extract (A, Lane)), 1)), "U16x8 independent logical shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)), "U16x8 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))), "U16x8 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))), "U16x8 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))), "U16x8 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))), "U16x8 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "U16x8 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "U16x8 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "U16x8 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "U16x8 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "U16x8 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U16x8 select");
      for Pattern in Natural range 0 .. 2 ** 8 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "U16x8 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 8 - 1), "U16x8 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U16x8 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "U16x8 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then To_Bit_Mask (Mask_Xor (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "U16x8 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 8 - 1) and then Backends.Native.Population_Count (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U16x8 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "U16x8 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "U16x8 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Backends.Native.Test (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "U16x8 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U16x8 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "U16x8 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_U16x8 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U16x8 (A), "U16x8 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_U16x8 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_U16x8 (A), "U16x8 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_U16x8 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_U16x8 (A), "U16x8 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U16x8 full memory");
      for Lane in Lane_Index_16x8 loop Check (Data (1 + Lane) = Extract (A, Lane), "U16x8 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "U16x8 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "U16x8 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "U16x8 aligned memory");
      for N in Lane_Count_16x8 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_16x8 (Index - 2)) else 0), "U16x8 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "U16x8 partial" & N'Image);
         declare
            Exact : U16_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "U16x8 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant U16x8 := From_Lanes (Random_U16x8_Lanes);
            R_B : constant U16x8 := From_Lanes (Random_U16x8_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U16x8 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "U16x8 randomized compare");
            for Lane in Lane_Index_16x8 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane), "U16x8 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane), "U16x8 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane), "U16x8 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U16x8 (Extract (R_A, Lane), Extract (R_B, Lane)), "U16x8 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Extract (R_A, Lane) and Extract (R_B, Lane)) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Extract (R_A, Lane) or Extract (R_B, Lane)) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Extract (R_A, Lane) xor Extract (R_B, Lane)) and then Extract (Bitwise_Not (R_A), Lane) = (not Extract (R_A, Lane)), "U16x8 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "U16x8 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "U16x8 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_U16x8;

   function Bits_To_I16x8 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_16, I16);
   function I16x8_To_Bits is new Ada.Unchecked_Conversion (I16, Interfaces.Unsigned_16);
   function Reference_Add_Saturate_I16x8 (Left, Right : I16) return I16 is
   begin
      if Right > 0 and then Left > I16'Last - Right then return I16'Last;
      elsif Right < 0 and then Left < I16'First - Right then return I16'First;
      else return Left + Right; end if;
   end Reference_Add_Saturate_I16x8;
   function Reference_Subtract_Saturate_I16x8 (Left, Right : I16) return I16 is
   begin
      if Right < 0 and then Left > I16'Last + Right then return I16'Last;
      elsif Right > 0 and then Left < I16'First + Right then return I16'First;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_I16x8;
   function Reference_Reduce_Add_I16x8 (Value : I16x8) return I16 is
      Accumulator : Interfaces.Unsigned_16 := 0;
   begin
      for Lane in Lane_Index_16x8 loop Accumulator := Accumulator + I16x8_To_Bits (Extract (Value, Lane)); end loop;
      return Bits_To_I16x8 (Accumulator);
   end Reference_Reduce_Add_I16x8;
   function Reference_Reduce_Min_I16x8 (Value : I16x8) return I16 is
      Result : I16 := Extract (Value, Lane_Index_16x8'First);
   begin
      for Lane in Lane_Index_16x8 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_I16x8;
   function Reference_Reduce_Max_I16x8 (Value : I16x8) return I16 is
      Result : I16 := Extract (Value, Lane_Index_16x8'First);
   begin
      for Lane in Lane_Index_16x8 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_I16x8;
   function Random_I16x8_Lanes return Lane_Values_I16x8 is
      Result : Lane_Values_I16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result (Lane) := Bits_To_I16x8 (Interfaces.Unsigned_16 (Next_U64 and 16#FFFF#)); end loop;
      return Result;
   end Random_I16x8_Lanes;
   function Same (Left, Right : I16x8) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I16x8 is
      A : constant I16x8 := From_Lanes ([I16'First, -1, 0, 1, I16'Last, I16'First, -1, 0]);
      B : constant I16x8 := From_Lanes ([1, I16'Last, -1, I16'First, 0, 1, I16'Last, -1]);
      Data, Reference : I16_Array (0 .. 13) := [others => 0];
      Aligned_Data : I16_Array (0 .. 7) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [I16'First, -1, 0, 1, I16'Last, I16'First, -1, 0], "I16x8 scalar lane construction");
      Check (Same (I16x8'(Backends.Native.Zero), I16x8'(Zero)) and then Same (I16x8'(Backends.Native.Splat (To_Lanes (A) (0))), I16x8'(Splat (To_Lanes (A) (0)))), "I16x8 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I16x8 native lane roundtrip");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I16x8 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I16x8 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "I16x8 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "I16x8 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "I16x8 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I16x8 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I16x8 reverse");
      for Shift in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I16x8 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I16x8 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I16x8 sar" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 16), Zero) and then Same (Shift_Right_Logical (A, 16), Zero), "I16x8 independent oversized logical shifts");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I16x8 (Interfaces.Shift_Left (I16x8_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I16x8 (Interfaces.Shift_Right (I16x8_To_Bits (Extract (A, Lane)), 1)), "I16x8 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I16x8 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 16), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I16x8 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)), "I16x8 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))), "I16x8 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))), "I16x8 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))), "I16x8 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))), "I16x8 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I16x8 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I16x8 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I16x8 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I16x8 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I16x8 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I16x8 select");
      for Pattern in Natural range 0 .. 2 ** 8 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "I16x8 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 8 - 1), "I16x8 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I16x8 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "I16x8 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then To_Bit_Mask (Mask_Xor (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "I16x8 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 8 - 1) and then Backends.Native.Population_Count (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I16x8 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "I16x8 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "I16x8 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Backends.Native.Test (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "I16x8 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I16x8 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I16x8 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I16x8 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I16x8 (A), "I16x8 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I16x8 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I16x8 (A), "I16x8 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I16x8 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I16x8 (A), "I16x8 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I16x8 full memory");
      for Lane in Lane_Index_16x8 loop Check (Data (1 + Lane) = Extract (A, Lane), "I16x8 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I16x8 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I16x8 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I16x8 aligned memory");
      for N in Lane_Count_16x8 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_16x8 (Index - 2)) else 0), "I16x8 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I16x8 partial" & N'Image);
         declare
            Exact : I16_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "I16x8 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I16x8 := From_Lanes (Random_I16x8_Lanes);
            R_B : constant I16x8 := From_Lanes (Random_I16x8_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I16x8 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I16x8 randomized compare");
            for Lane in Lane_Index_16x8 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) + I16x8_To_Bits (Extract (R_B, Lane))), "I16x8 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) - I16x8_To_Bits (Extract (R_B, Lane))), "I16x8 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) * I16x8_To_Bits (Extract (R_B, Lane))), "I16x8 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I16x8 (Extract (R_A, Lane), Extract (R_B, Lane)), "I16x8 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) and I16x8_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) or I16x8_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) xor I16x8_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Not (R_A), Lane) = (Bits_To_I16x8 (not I16x8_To_Bits (Extract (R_A, Lane)))), "I16x8 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "I16x8 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "I16x8 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_I16x8;

   function Reference_Add_Saturate_U32x4 (Left, Right : U32) return U32 is
   begin
      if Left > U32'Last - Right then return U32'Last;
      else return Left + Right; end if;
   end Reference_Add_Saturate_U32x4;
   function Reference_Subtract_Saturate_U32x4 (Left, Right : U32) return U32 is
   begin
      if Left < Right then return 0;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_U32x4;
   function Reference_Reduce_Add_U32x4 (Value : U32x4) return U32 is
      Accumulator : Interfaces.Unsigned_32 := 0;
   begin
      for Lane in Lane_Index_32x4 loop Accumulator := Accumulator + Interfaces.Unsigned_32 (Extract (Value, Lane)); end loop;
      return U32 (Accumulator);
   end Reference_Reduce_Add_U32x4;
   function Reference_Reduce_Min_U32x4 (Value : U32x4) return U32 is
      Result : U32 := Extract (Value, Lane_Index_32x4'First);
   begin
      for Lane in Lane_Index_32x4 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_U32x4;
   function Reference_Reduce_Max_U32x4 (Value : U32x4) return U32 is
      Result : U32 := Extract (Value, Lane_Index_32x4'First);
   begin
      for Lane in Lane_Index_32x4 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_U32x4;
   function Random_U32x4_Lanes return Lane_Values_U32x4 is
      Result : Lane_Values_U32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result (Lane) := Interfaces.Unsigned_32 (Next_U64 and 16#FFFFFFFF#); end loop;
      return Result;
   end Random_U32x4_Lanes;
   function Same (Left, Right : U32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_U32x4 is
      A : constant U32x4 := From_Lanes ([0, 1, U32'Last, 2 ** (31)]);
      B : constant U32x4 := From_Lanes ([1, U32'Last, 2, 2 ** (31) - 1]);
      Data, Reference : U32_Array (0 .. 9) := [others => 0];
      Aligned_Data : U32_Array (0 .. 3) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [0, 1, U32'Last, 2 ** (31)], "U32x4 scalar lane construction");
      Check (Same (U32x4'(Backends.Native.Zero), U32x4'(Zero)) and then Same (U32x4'(Backends.Native.Splat (To_Lanes (A) (0))), U32x4'(Splat (To_Lanes (A) (0)))), "U32x4 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "U32x4 native lane roundtrip");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "U32x4 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "U32x4 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "U32x4 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "U32x4 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "U32x4 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "U32x4 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "U32x4 reverse");
      for Shift in Natural range 0 .. 34 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U32x4 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U32x4 shr" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 32), Zero) and then Same (Shift_Right_Logical (A, 32), Zero), "U32x4 independent oversized logical shifts");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U32 (Interfaces.Shift_Left (Interfaces.Unsigned_32 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U32 (Interfaces.Shift_Right (Interfaces.Unsigned_32 (Extract (A, Lane)), 1)), "U32x4 independent logical shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)), "U32x4 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))), "U32x4 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))), "U32x4 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))), "U32x4 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "U32x4 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "U32x4 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "U32x4 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "U32x4 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "U32x4 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "U32x4 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U32x4 select");
      for Pattern in Natural range 0 .. 2 ** 4 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "U32x4 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1), "U32x4 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U32x4 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "U32x4 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then To_Bit_Mask (Mask_Xor (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "U32x4 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1) and then Backends.Native.Population_Count (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U32x4 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "U32x4 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "U32x4 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "U32x4 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U32x4 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "U32x4 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_U32x4 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U32x4 (A), "U32x4 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_U32x4 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_U32x4 (A), "U32x4 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_U32x4 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_U32x4 (A), "U32x4 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U32x4 full memory");
      for Lane in Lane_Index_32x4 loop Check (Data (1 + Lane) = Extract (A, Lane), "U32x4 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "U32x4 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "U32x4 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "U32x4 aligned memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_32x4 (Index - 2)) else 0), "U32x4 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "U32x4 partial" & N'Image);
         declare
            Exact : U32_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "U32x4 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant U32x4 := From_Lanes (Random_U32x4_Lanes);
            R_B : constant U32x4 := From_Lanes (Random_U32x4_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U32x4 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "U32x4 randomized compare");
            for Lane in Lane_Index_32x4 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane), "U32x4 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane), "U32x4 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane), "U32x4 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U32x4 (Extract (R_A, Lane), Extract (R_B, Lane)), "U32x4 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Extract (R_A, Lane) and Extract (R_B, Lane)) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Extract (R_A, Lane) or Extract (R_B, Lane)) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Extract (R_A, Lane) xor Extract (R_B, Lane)) and then Extract (Bitwise_Not (R_A), Lane) = (not Extract (R_A, Lane)), "U32x4 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "U32x4 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "U32x4 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_U32x4;

   function Bits_To_I32x4 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, I32);
   function I32x4_To_Bits is new Ada.Unchecked_Conversion (I32, Interfaces.Unsigned_32);
   function Reference_Add_Saturate_I32x4 (Left, Right : I32) return I32 is
   begin
      if Right > 0 and then Left > I32'Last - Right then return I32'Last;
      elsif Right < 0 and then Left < I32'First - Right then return I32'First;
      else return Left + Right; end if;
   end Reference_Add_Saturate_I32x4;
   function Reference_Subtract_Saturate_I32x4 (Left, Right : I32) return I32 is
   begin
      if Right < 0 and then Left > I32'Last + Right then return I32'Last;
      elsif Right > 0 and then Left < I32'First + Right then return I32'First;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_I32x4;
   function Reference_Reduce_Add_I32x4 (Value : I32x4) return I32 is
      Accumulator : Interfaces.Unsigned_32 := 0;
   begin
      for Lane in Lane_Index_32x4 loop Accumulator := Accumulator + I32x4_To_Bits (Extract (Value, Lane)); end loop;
      return Bits_To_I32x4 (Accumulator);
   end Reference_Reduce_Add_I32x4;
   function Reference_Reduce_Min_I32x4 (Value : I32x4) return I32 is
      Result : I32 := Extract (Value, Lane_Index_32x4'First);
   begin
      for Lane in Lane_Index_32x4 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_I32x4;
   function Reference_Reduce_Max_I32x4 (Value : I32x4) return I32 is
      Result : I32 := Extract (Value, Lane_Index_32x4'First);
   begin
      for Lane in Lane_Index_32x4 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_I32x4;
   function Random_I32x4_Lanes return Lane_Values_I32x4 is
      Result : Lane_Values_I32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result (Lane) := Bits_To_I32x4 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFFFFFF#)); end loop;
      return Result;
   end Random_I32x4_Lanes;
   function Same (Left, Right : I32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I32x4 is
      A : constant I32x4 := From_Lanes ([I32'First, -1, 0, 1]);
      B : constant I32x4 := From_Lanes ([1, I32'Last, -1, I32'First]);
      Data, Reference : I32_Array (0 .. 9) := [others => 0];
      Aligned_Data : I32_Array (0 .. 3) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [I32'First, -1, 0, 1], "I32x4 scalar lane construction");
      Check (Same (I32x4'(Backends.Native.Zero), I32x4'(Zero)) and then Same (I32x4'(Backends.Native.Splat (To_Lanes (A) (0))), I32x4'(Splat (To_Lanes (A) (0)))), "I32x4 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I32x4 native lane roundtrip");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I32x4 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I32x4 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "I32x4 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "I32x4 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "I32x4 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I32x4 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I32x4 reverse");
      for Shift in Natural range 0 .. 34 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I32x4 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I32x4 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I32x4 sar" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 32), Zero) and then Same (Shift_Right_Logical (A, 32), Zero), "I32x4 independent oversized logical shifts");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I32x4 (Interfaces.Shift_Left (I32x4_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I32x4 (Interfaces.Shift_Right (I32x4_To_Bits (Extract (A, Lane)), 1)), "I32x4 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I32x4 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 32), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I32x4 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)), "I32x4 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))), "I32x4 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))), "I32x4 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))), "I32x4 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "I32x4 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I32x4 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I32x4 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I32x4 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I32x4 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I32x4 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I32x4 select");
      for Pattern in Natural range 0 .. 2 ** 4 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "I32x4 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1), "I32x4 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I32x4 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "I32x4 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then To_Bit_Mask (Mask_Xor (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "I32x4 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1) and then Backends.Native.Population_Count (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I32x4 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "I32x4 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "I32x4 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "I32x4 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I32x4 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I32x4 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I32x4 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I32x4 (A), "I32x4 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I32x4 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I32x4 (A), "I32x4 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I32x4 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I32x4 (A), "I32x4 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I32x4 full memory");
      for Lane in Lane_Index_32x4 loop Check (Data (1 + Lane) = Extract (A, Lane), "I32x4 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I32x4 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I32x4 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I32x4 aligned memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_32x4 (Index - 2)) else 0), "I32x4 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I32x4 partial" & N'Image);
         declare
            Exact : I32_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "I32x4 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I32x4 := From_Lanes (Random_I32x4_Lanes);
            R_B : constant I32x4 := From_Lanes (Random_I32x4_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I32x4 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I32x4 randomized compare");
            for Lane in Lane_Index_32x4 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) + I32x4_To_Bits (Extract (R_B, Lane))), "I32x4 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) - I32x4_To_Bits (Extract (R_B, Lane))), "I32x4 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) * I32x4_To_Bits (Extract (R_B, Lane))), "I32x4 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I32x4 (Extract (R_A, Lane), Extract (R_B, Lane)), "I32x4 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) and I32x4_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) or I32x4_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) xor I32x4_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Not (R_A), Lane) = (Bits_To_I32x4 (not I32x4_To_Bits (Extract (R_A, Lane)))), "I32x4 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "I32x4 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "I32x4 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_I32x4;

   function Reference_Add_Saturate_U64x2 (Left, Right : U64) return U64 is
   begin
      if Left > U64'Last - Right then return U64'Last;
      else return Left + Right; end if;
   end Reference_Add_Saturate_U64x2;
   function Reference_Subtract_Saturate_U64x2 (Left, Right : U64) return U64 is
   begin
      if Left < Right then return 0;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_U64x2;
   function Reference_Reduce_Add_U64x2 (Value : U64x2) return U64 is
      Accumulator : Interfaces.Unsigned_64 := 0;
   begin
      for Lane in Lane_Index_64x2 loop Accumulator := Accumulator + Interfaces.Unsigned_64 (Extract (Value, Lane)); end loop;
      return U64 (Accumulator);
   end Reference_Reduce_Add_U64x2;
   function Reference_Reduce_Min_U64x2 (Value : U64x2) return U64 is
      Result : U64 := Extract (Value, Lane_Index_64x2'First);
   begin
      for Lane in Lane_Index_64x2 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_U64x2;
   function Reference_Reduce_Max_U64x2 (Value : U64x2) return U64 is
      Result : U64 := Extract (Value, Lane_Index_64x2'First);
   begin
      for Lane in Lane_Index_64x2 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_U64x2;
   function Random_U64x2_Lanes return Lane_Values_U64x2 is
      Result : Lane_Values_U64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result (Lane) := Next_U64; end loop;
      return Result;
   end Random_U64x2_Lanes;
   function Same (Left, Right : U64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_U64x2 is
      A : constant U64x2 := From_Lanes ([0, 1]);
      B : constant U64x2 := From_Lanes ([1, U64'Last]);
      Data, Reference : U64_Array (0 .. 7) := [others => 0];
      Aligned_Data : U64_Array (0 .. 1) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [0, 1], "U64x2 scalar lane construction");
      Check (Same (U64x2'(Backends.Native.Zero), U64x2'(Zero)) and then Same (U64x2'(Backends.Native.Splat (To_Lanes (A) (0))), U64x2'(Splat (To_Lanes (A) (0)))), "U64x2 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "U64x2 native lane roundtrip");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "U64x2 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "U64x2 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "U64x2 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "U64x2 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "U64x2 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "U64x2 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "U64x2 reverse");
      for Shift in Natural range 0 .. 66 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U64x2 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U64x2 shr" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 64), Zero) and then Same (Shift_Right_Logical (A, 64), Zero), "U64x2 independent oversized logical shifts");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U64 (Interfaces.Shift_Left (Interfaces.Unsigned_64 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U64 (Interfaces.Shift_Right (Interfaces.Unsigned_64 (Extract (A, Lane)), 1)), "U64x2 independent logical shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)), "U64x2 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))), "U64x2 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))), "U64x2 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))), "U64x2 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "U64x2 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "U64x2 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "U64x2 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "U64x2 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "U64x2 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "U64x2 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U64x2 select");
      for Pattern in Natural range 0 .. 2 ** 2 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "U64x2 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1), "U64x2 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U64x2 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "U64x2 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then To_Bit_Mask (Mask_Xor (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "U64x2 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1) and then Backends.Native.Population_Count (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U64x2 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "U64x2 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "U64x2 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "U64x2 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U64x2 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "U64x2 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_U64x2 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U64x2 (A), "U64x2 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_U64x2 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_U64x2 (A), "U64x2 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_U64x2 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_U64x2 (A), "U64x2 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U64x2 full memory");
      for Lane in Lane_Index_64x2 loop Check (Data (1 + Lane) = Extract (A, Lane), "U64x2 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "U64x2 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "U64x2 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "U64x2 aligned memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_64x2 (Index - 2)) else 0), "U64x2 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "U64x2 partial" & N'Image);
         declare
            Exact : U64_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "U64x2 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant U64x2 := From_Lanes (Random_U64x2_Lanes);
            R_B : constant U64x2 := From_Lanes (Random_U64x2_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U64x2 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "U64x2 randomized compare");
            for Lane in Lane_Index_64x2 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane), "U64x2 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane), "U64x2 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane), "U64x2 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U64x2 (Extract (R_A, Lane), Extract (R_B, Lane)), "U64x2 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Extract (R_A, Lane) and Extract (R_B, Lane)) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Extract (R_A, Lane) or Extract (R_B, Lane)) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Extract (R_A, Lane) xor Extract (R_B, Lane)) and then Extract (Bitwise_Not (R_A), Lane) = (not Extract (R_A, Lane)), "U64x2 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "U64x2 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "U64x2 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_U64x2;

   function Bits_To_I64x2 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, I64);
   function I64x2_To_Bits is new Ada.Unchecked_Conversion (I64, Interfaces.Unsigned_64);
   function Reference_Add_Saturate_I64x2 (Left, Right : I64) return I64 is
   begin
      if Right > 0 and then Left > I64'Last - Right then return I64'Last;
      elsif Right < 0 and then Left < I64'First - Right then return I64'First;
      else return Left + Right; end if;
   end Reference_Add_Saturate_I64x2;
   function Reference_Subtract_Saturate_I64x2 (Left, Right : I64) return I64 is
   begin
      if Right < 0 and then Left > I64'Last + Right then return I64'Last;
      elsif Right > 0 and then Left < I64'First + Right then return I64'First;
      else return Left - Right; end if;
   end Reference_Subtract_Saturate_I64x2;
   function Reference_Reduce_Add_I64x2 (Value : I64x2) return I64 is
      Accumulator : Interfaces.Unsigned_64 := 0;
   begin
      for Lane in Lane_Index_64x2 loop Accumulator := Accumulator + I64x2_To_Bits (Extract (Value, Lane)); end loop;
      return Bits_To_I64x2 (Accumulator);
   end Reference_Reduce_Add_I64x2;
   function Reference_Reduce_Min_I64x2 (Value : I64x2) return I64 is
      Result : I64 := Extract (Value, Lane_Index_64x2'First);
   begin
      for Lane in Lane_Index_64x2 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_I64x2;
   function Reference_Reduce_Max_I64x2 (Value : I64x2) return I64 is
      Result : I64 := Extract (Value, Lane_Index_64x2'First);
   begin
      for Lane in Lane_Index_64x2 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_I64x2;
   function Random_I64x2_Lanes return Lane_Values_I64x2 is
      Result : Lane_Values_I64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result (Lane) := Bits_To_I64x2 (Next_U64); end loop;
      return Result;
   end Random_I64x2_Lanes;
   function Same (Left, Right : I64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   procedure Test_I64x2 is
      A : constant I64x2 := From_Lanes ([I64'First, -1]);
      B : constant I64x2 := From_Lanes ([1, I64'Last]);
      Data, Reference : I64_Array (0 .. 7) := [others => 0];
      Aligned_Data : I64_Array (0 .. 1) := [others => 0] with Alignment => 16;
   begin
      Check (To_Lanes (A) = [I64'First, -1], "I64x2 scalar lane construction");
      Check (Same (I64x2'(Backends.Native.Zero), I64x2'(Zero)) and then Same (I64x2'(Backends.Native.Splat (To_Lanes (A) (0))), I64x2'(Splat (To_Lanes (A) (0)))), "I64x2 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I64x2 native lane roundtrip");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I64x2 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I64x2 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "I64x2 native lane access" & Lane'Image);
      end loop;
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
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "I64x2 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "I64x2 Deinterleave_Odd");
      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), "I64x2 not");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "I64x2 reverse");
      for Shift in Natural range 0 .. 66 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "I64x2 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "I64x2 shr" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), "I64x2 sar" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 64), Zero) and then Same (Shift_Right_Logical (A, 64), Zero), "I64x2 independent oversized logical shifts");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I64x2 (Interfaces.Shift_Left (I64x2_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I64x2 (Interfaces.Shift_Right (I64x2_To_Bits (Extract (A, Lane)), 1)), "I64x2 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I64x2 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 64), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I64x2 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)), "I64x2 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))), "I64x2 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))), "I64x2 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))), "I64x2 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "I64x2 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "I64x2 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "I64x2 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "I64x2 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "I64x2 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "I64x2 Greater_Equal");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I64x2 select");
      for Pattern in Natural range 0 .. 2 ** 2 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "I64x2 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1), "I64x2 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I64x2 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "I64x2 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then To_Bit_Mask (Mask_Xor (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "I64x2 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1) and then Backends.Native.Population_Count (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I64x2 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "I64x2 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "I64x2 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "I64x2 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I64x2 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I64x2 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I64x2 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I64x2 (A), "I64x2 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I64x2 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I64x2 (A), "I64x2 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I64x2 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I64x2 (A), "I64x2 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I64x2 full memory");
      for Lane in Lane_Index_64x2 loop Check (Data (1 + Lane) = Extract (A, Lane), "I64x2 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I64x2 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I64x2 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I64x2 aligned memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_64x2 (Index - 2)) else 0), "I64x2 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "I64x2 partial" & N'Image);
         declare
            Exact : I64_Array (1 .. N) := [others => 0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "I64x2 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant I64x2 := From_Lanes (Random_I64x2_Lanes);
            R_B : constant I64x2 := From_Lanes (Random_I64x2_Lanes);
         begin
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I64x2 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), "I64x2 randomized compare");
            for Lane in Lane_Index_64x2 loop
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) + I64x2_To_Bits (Extract (R_B, Lane))), "I64x2 independent add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) - I64x2_To_Bits (Extract (R_B, Lane))), "I64x2 independent subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) * I64x2_To_Bits (Extract (R_B, Lane))), "I64x2 independent multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I64x2 (Extract (R_A, Lane), Extract (R_B, Lane)), "I64x2 independent saturation oracle" & Lane'Image);
               Check (Extract (Bitwise_And (R_A, R_B), Lane) = (Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) and I64x2_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Or (R_A, R_B), Lane) = (Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) or I64x2_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Xor (R_A, R_B), Lane) = (Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) xor I64x2_To_Bits (Extract (R_B, Lane)))) and then Extract (Bitwise_Not (R_A), Lane) = (Bits_To_I64x2 (not I64x2_To_Bits (Extract (R_A, Lane)))), "I64x2 independent bitwise oracle" & Lane'Image);
               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "I64x2 independent min/max oracle" & Lane'Image);
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "I64x2 independent comparison oracle" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_I64x2;

   function Random_F32x4_Lanes return Lane_Values_F32x4 is
      Result : Lane_Values_F32x4;
      Raw : Interfaces.Integer_64;
   begin
      for Lane in Lane_Index_32x4 loop
         Raw := Interfaces.Integer_64 (Next_U64 mod 2_000_001) - 1_000_000;
         Result (Lane) := F32 (Raw) / 128.0;
      end loop;
      return Result;
   end Random_F32x4_Lanes;
   function Bits_F32x4 is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);
   function Same (Left, Right : F32x4) return Boolean is
      L : constant Lane_Values_F32x4 := To_Lanes (Left);
      R : constant Lane_Values_F32x4 := To_Lanes (Right);
   begin
      for Lane in Lane_Index_32x4 loop
         if Bits_F32x4 (L (Lane)) /= Bits_F32x4 (R (Lane)) then return False; end if;
      end loop;
      return True;
   end Same;
   function Reference_Reduce_Add_F32x4 (Value : F32x4) return F32 is
      Result : F32 := 0.0;
   begin
      for Lane in Lane_Index_32x4 loop Result := Result + Extract (Value, Lane); end loop;
      return Result;
   end Reference_Reduce_Add_F32x4;
   procedure Test_F32x4 is
      A : constant F32x4 := From_Lanes ([0.0, -0.0, 1.5, -2.25]);
      B : constant F32x4 := From_Lanes ([2.0, -3.0, 0.5, 4.0]);
      Data, Reference : F32_Array (0 .. 9) := [others => 0.0];
      Aligned_Data : F32_Array (0 .. 3) := [others => 0.0] with Alignment => 16;
   begin
      Check (Same (A, From_Lanes (To_Lanes (A))), "F32x4 scalar lane roundtrip");
      Check (Same (F32x4'(Backends.Native.Zero), F32x4'(Zero)) and then Same (F32x4'(Backends.Native.Splat (To_Lanes (A) (0))), F32x4'(Splat (To_Lanes (A) (0)))), "F32x4 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Same (Backends.Native.From_Lanes (Backends.Native.To_Lanes (A)), A), "F32x4 native lane roundtrip");
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (A, Lane)) = Bits_F32x4 (To_Lanes (A) (Lane)), "F32x4 scalar extract" & Lane'Image);
         Check (Bits_F32x4 (Backends.Native.Extract (A, Lane)) = Bits_F32x4 (Extract (A, Lane)) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "F32x4 native lane access" & Lane'Image);
      end loop;
      Check (Same (Backends.Native.Add (A, B), Add (A, B)), "F32x4 Add");
      Check (Same (Backends.Native.Subtract (A, B), Subtract (A, B)), "F32x4 Subtract");
      Check (Same (Backends.Native.Multiply (A, B), Multiply (A, B)), "F32x4 Multiply");
      Check (Same (Backends.Native.Divide (A, B), Divide (A, B)), "F32x4 Divide");
      Check (Same (Backends.Native.Min_Number (A, B), Min_Number (A, B)), "F32x4 Min_Number");
      Check (Same (Backends.Native.Max_Number (A, B), Max_Number (A, B)), "F32x4 Max_Number");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "F32x4 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "F32x4 Interleave_High");
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "F32x4 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "F32x4 Deinterleave_Odd");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "F32x4 reverse");
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (Add (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) + Extract (B, Lane)) and then Bits_F32x4 (Extract (Subtract (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) - Extract (B, Lane)) and then Bits_F32x4 (Extract (Multiply (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) * Extract (B, Lane)), "F32x4 independent arithmetic" & Lane'Image);
         Check (Bits_F32x4 (Extract (Divide (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) / Extract (B, Lane)), "F32x4 independent division" & Lane'Image);
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)), "F32x4 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))), "F32x4 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))), "F32x4 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))), "F32x4 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "F32x4 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "F32x4 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "F32x4 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "F32x4 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "F32x4 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "F32x4 Greater_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A, B)) = Flyology_SIMD.To_Bit_Mask (Unordered (A, B)), "F32x4 Unordered");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "F32x4 select");
      for Pattern in Natural range 0 .. 2 ** 4 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "F32x4 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1), "F32x4 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "F32x4 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "F32x4 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then To_Bit_Mask (Mask_Xor (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "F32x4 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1) and then Backends.Native.Population_Count (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "F32x4 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "F32x4 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "F32x4 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "F32x4 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "F32x4 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "F32x4 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Bits_F32x4 (Reduce_Add (A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (A)) and then Bits_F32x4 (Backends.Native.Reduce_Add (A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (A)), "F32x4 independent reduce");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "F32x4 full memory");
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Data (1 + Lane)) = Bits_F32x4 (Extract (A, Lane)), "F32x4 independent full store" & Lane'Image); end loop;
      Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "F32x4 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "F32x4 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "F32x4 aligned memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0.0]; Reference := [others => 0.0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Bits_F32x4 (Data (Index)) = Bits_F32x4 ((if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_32x4 (Index - 2)) else 0.0)), "F32x4 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "F32x4 partial" & N'Image);
         declare
            Exact : F32_Array (1 .. N) := [others => 0.0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "F32x4 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant F32x4 := From_Lanes (Random_F32x4_Lanes);
            R_B : constant F32x4 := From_Lanes (Random_F32x4_Lanes);
         begin
            Check (Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F32x4 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)), "F32x4 randomized compare");
            for Lane in Lane_Index_32x4 loop
               Check (Bits_F32x4 (Extract (Add (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Subtract (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Multiply (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) * Extract (R_B, Lane)), "F32x4 randomized independent arithmetic" & Lane'Image);
               if Extract (R_B, Lane) /= 0.0 then Check (Bits_F32x4 (Extract (Divide (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) / Extract (R_B, Lane)), "F32x4 randomized independent division" & Lane'Image); end if;
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "F32x4 randomized independent comparison" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_F32x4;

   function Random_F64x2_Lanes return Lane_Values_F64x2 is
      Result : Lane_Values_F64x2;
      Raw : Interfaces.Integer_64;
   begin
      for Lane in Lane_Index_64x2 loop
         Raw := Interfaces.Integer_64 (Next_U64 mod 2_000_001) - 1_000_000;
         Result (Lane) := F64 (Raw) / 128.0;
      end loop;
      return Result;
   end Random_F64x2_Lanes;
   function Bits_F64x2 is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);
   function Same (Left, Right : F64x2) return Boolean is
      L : constant Lane_Values_F64x2 := To_Lanes (Left);
      R : constant Lane_Values_F64x2 := To_Lanes (Right);
   begin
      for Lane in Lane_Index_64x2 loop
         if Bits_F64x2 (L (Lane)) /= Bits_F64x2 (R (Lane)) then return False; end if;
      end loop;
      return True;
   end Same;
   function Reference_Reduce_Add_F64x2 (Value : F64x2) return F64 is
      Result : F64 := 0.0;
   begin
      for Lane in Lane_Index_64x2 loop Result := Result + Extract (Value, Lane); end loop;
      return Result;
   end Reference_Reduce_Add_F64x2;
   procedure Test_F64x2 is
      A : constant F64x2 := From_Lanes ([0.0, -0.0]);
      B : constant F64x2 := From_Lanes ([2.0, -3.0]);
      Data, Reference : F64_Array (0 .. 7) := [others => 0.0];
      Aligned_Data : F64_Array (0 .. 1) := [others => 0.0] with Alignment => 16;
   begin
      Check (Same (A, From_Lanes (To_Lanes (A))), "F64x2 scalar lane roundtrip");
      Check (Same (F64x2'(Backends.Native.Zero), F64x2'(Zero)) and then Same (F64x2'(Backends.Native.Splat (To_Lanes (A) (0))), F64x2'(Splat (To_Lanes (A) (0)))), "F64x2 native construction");
      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Same (Backends.Native.From_Lanes (Backends.Native.To_Lanes (A)), A), "F64x2 native lane roundtrip");
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (A, Lane)) = Bits_F64x2 (To_Lanes (A) (Lane)), "F64x2 scalar extract" & Lane'Image);
         Check (Bits_F64x2 (Backends.Native.Extract (A, Lane)) = Bits_F64x2 (Extract (A, Lane)) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), "F64x2 native lane access" & Lane'Image);
      end loop;
      Check (Same (Backends.Native.Add (A, B), Add (A, B)), "F64x2 Add");
      Check (Same (Backends.Native.Subtract (A, B), Subtract (A, B)), "F64x2 Subtract");
      Check (Same (Backends.Native.Multiply (A, B), Multiply (A, B)), "F64x2 Multiply");
      Check (Same (Backends.Native.Divide (A, B), Divide (A, B)), "F64x2 Divide");
      Check (Same (Backends.Native.Min_Number (A, B), Min_Number (A, B)), "F64x2 Min_Number");
      Check (Same (Backends.Native.Max_Number (A, B), Max_Number (A, B)), "F64x2 Max_Number");
      Check (Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "F64x2 Interleave_Low");
      Check (Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "F64x2 Interleave_High");
      Check (Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "F64x2 Deinterleave_Even");
      Check (Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "F64x2 Deinterleave_Odd");
      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), "F64x2 reverse");
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (Add (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) + Extract (B, Lane)) and then Bits_F64x2 (Extract (Subtract (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) - Extract (B, Lane)) and then Bits_F64x2 (Extract (Multiply (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) * Extract (B, Lane)), "F64x2 independent arithmetic" & Lane'Image);
         Check (Bits_F64x2 (Extract (Divide (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) / Extract (B, Lane)), "F64x2 independent division" & Lane'Image);
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)), "F64x2 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))), "F64x2 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))), "F64x2 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))), "F64x2 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "F64x2 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Equal (A, B)), "F64x2 Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (A, B)), "F64x2 Less_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (A, B)), "F64x2 Less_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (A, B)), "F64x2 Greater_Than");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (A, B)), "F64x2 Greater_Equal");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A, B)) = Flyology_SIMD.To_Bit_Mask (Unordered (A, B)), "F64x2 Unordered");
      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "F64x2 select");
      for Pattern in Natural range 0 .. 2 ** 2 - 1 loop
         Check (Backends.Native.To_Bit_Mask (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), "F64x2 mask roundtrip" & Pattern'Image);
         Check (Any_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1), "F64x2 scalar mask predicates" & Pattern'Image);
         Check (Population_Count (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "F64x2 scalar mask population" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "F64x2 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then To_Bit_Mask (Mask_Xor (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "F64x2 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1) and then Backends.Native.Population_Count (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "F64x2 native mask reductions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "F64x2 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "F64x2 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "F64x2 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "F64x2 exhaustive select" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "F64x2 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Bits_F64x2 (Reduce_Add (A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (A)) and then Bits_F64x2 (Backends.Native.Reduce_Add (A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (A)), "F64x2 independent reduce");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "F64x2 full memory");
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Data (1 + Lane)) = Bits_F64x2 (Extract (A, Lane)), "F64x2 independent full store" & Lane'Image); end loop;
      Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "F64x2 ordinary memory");
      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "F64x2 native alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "F64x2 aligned memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0.0]; Reference := [others => 0.0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Bits_F64x2 (Data (Index)) = Bits_F64x2 ((if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_64x2 (Index - 2)) else 0.0)), "F64x2 independent partial store" & N'Image & Index'Image); end loop;
         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), "F64x2 partial" & N'Image);
         declare
            Exact : F64_Array (1 .. N) := [others => 0.0];
         begin
            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), "F64x2 exact-extent partial load" & N'Image);
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            R_A : constant F64x2 := From_Lanes (Random_F64x2_Lanes);
            R_B : constant F64x2 := From_Lanes (Random_F64x2_Lanes);
         begin
            Check (Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F64x2 randomized arithmetic");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)), "F64x2 randomized compare");
            for Lane in Lane_Index_64x2 loop
               Check (Bits_F64x2 (Extract (Add (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Subtract (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Multiply (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) * Extract (R_B, Lane)), "F64x2 randomized independent arithmetic" & Lane'Image);
               if Extract (R_B, Lane) /= 0.0 then Check (Bits_F64x2 (Extract (Divide (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) / Extract (R_B, Lane)), "F64x2 randomized independent division" & Lane'Image); end if;
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "F64x2 randomized independent comparison" & Lane'Image);
            end loop;
         end;
      end loop;
   end Test_F64x2;

   function To_F32 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, F32);
   function F32_Bits is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);
   function To_F64 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, F64);
   function F64_Bits is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);
   function Is_NaN (Value : F32) return Boolean is
     ((F32_Bits (Value) and 16#7F80_0000#) = 16#7F80_0000#
      and then (F32_Bits (Value) and 16#007F_FFFF#) /= 0);
   function Is_NaN (Value : F64) return Boolean is
     ((F64_Bits (Value) and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#
      and then (F64_Bits (Value) and 16#000F_FFFF_FFFF_FFFF#) /= 0);
   procedure Test_Floating_Specials is
      pragma Suppress (Validity_Check);
      NaN32 : constant F32 := To_F32 (16#7FC0_0001#);
      SNaN32 : constant F32 := To_F32 (16#7F80_0001#);
      Inf32 : constant F32 := To_F32 (16#7F80_0000#);
      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);
      A32 : constant F32x4 := From_Lanes ([NaN32, Inf32, Neg_Zero32, 0.0]);
      B32 : constant F32x4 := From_Lanes ([1.0, Inf32, 0.0, Neg_Zero32]);
      NaN64 : constant F64 := To_F64 (16#7FF8_0000_0000_0001#);
      SNaN64 : constant F64 := To_F64 (16#7FF0_0000_0000_0001#);
      Inf64 : constant F64 := To_F64 (16#7FF0_0000_0000_0000#);
      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);
      A64 : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);
      B64 : constant F64x2 := From_Lanes ([1.0, 0.0]);
      Zero32 : constant F32x4 := From_Lanes ([0.0, 0.0, 0.0, 0.0]);
      Numerator32 : constant F32x4 := From_Lanes ([1.0, 0.0, -1.0, 0.0]);
      Zero64 : constant F64x2 := From_Lanes ([0.0, 0.0]);
      Numerator64 : constant F64x2 := From_Lanes ([1.0, 0.0]);
      Infinity64 : constant F64x2 := From_Lanes ([Inf64, 0.0]);
      Twice64 : constant F64x2 := From_Lanes ([2.0, 0.0]);
   begin
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A32, B32)) = Flyology_SIMD.To_Bit_Mask (Unordered (A32, B32)), "F32 NaN unordered");
      Check (Extract (Backends.Native.Min_Number (A32, B32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A32, B32), 0) = 1.0, "F32 quiet NaN returns number");
      Check ((F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), B32), 0)) and 16#7FC0_0000#) = 16#7FC0_0000#, "F32 signaling NaN is quieted");
      Check (F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0, "F32 signed zero min/max");
      Check (Is_NaN (Extract (Add (A32, B32), 0)) and then Is_NaN (Extract (Backends.Native.Add (A32, B32), 0)), "F32 NaN addition");
      Check (Is_NaN (Extract (Subtract (A32, B32), 1)) and then Is_NaN (Extract (Backends.Native.Subtract (A32, B32), 1)), "F32 infinity subtraction");
      Check (F32_Bits (Extract (Multiply (A32, B32), 1)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Multiply (A32, B32), 1)) = 16#7F80_0000#, "F32 infinity multiplication");
      Check (F32_Bits (Extract (Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then Is_NaN (Extract (Divide (Numerator32, Zero32), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator32, Zero32), 1)), "F32 division edge cases");
      Check (Is_NaN (Reduce_Add (A32)) and then Is_NaN (Backends.Native.Reduce_Add (A32)), "F32 NaN reduction");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A64, B64)) = Flyology_SIMD.To_Bit_Mask (Unordered (A64, B64)), "F64 NaN unordered");
      Check (Extract (Backends.Native.Min_Number (A64, B64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A64, B64), 0) = 1.0, "F64 quiet NaN returns number");
      Check ((F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64, 0.0]), B64), 0)) and 16#7FF8_0000_0000_0000#) = 16#7FF8_0000_0000_0000#, "F64 signaling NaN is quieted");
      Check (F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0, "F64 signed zero min/max");
      Check (Is_NaN (Extract (Add (A64, B64), 0)) and then Is_NaN (Extract (Backends.Native.Add (A64, B64), 0)), "F64 NaN addition");
      Check (Is_NaN (Extract (Subtract (Infinity64, Infinity64), 0)) and then Is_NaN (Extract (Backends.Native.Subtract (Infinity64, Infinity64), 0)), "F64 infinity subtraction");
      Check (F64_Bits (Extract (Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000#, "F64 infinity multiplication");
      Check (F64_Bits (Extract (Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then Is_NaN (Extract (Divide (Numerator64, Zero64), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator64, Zero64), 1)), "F64 division edge cases");
      Check (Is_NaN (Reduce_Add (A64)) and then Is_NaN (Backends.Native.Reduce_Add (A64)), "F64 NaN reduction");
   end Test_Floating_Specials;

begin
   Put_Line ("full-family differential tests seed=0x5EED0123D15CA11A");
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
