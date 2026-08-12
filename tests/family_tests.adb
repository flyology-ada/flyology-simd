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

   function Reference_First_True (Value, Lanes : Natural) return Natural is
   begin
      for Lane in Natural range 0 .. Lanes - 1 loop
         if (Value / 2 ** Lane) mod 2 = 1 then return Lane; end if;
      end loop;
      return Lanes;
   end Reference_First_True;

   function Reference_Last_True (Value, Lanes : Natural) return Natural is
   begin
      for Lane in reverse Natural range 0 .. Lanes - 1 loop
         if (Value / 2 ** Lane) mod 2 = 1 then return Lane; end if;
      end loop;
      return Lanes;
   end Reference_Last_True;

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
   function Random_I8x16_Selectors return Lane_Selectors_8x16 is
      Result : Lane_Selectors_8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result (Lane) := Lane_Index_8x16 (Next_U64 mod 16); end loop;
      return Result;
   end Random_I8x16_Selectors;
   function Same (Left, Right : I8x16) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_I8x16 (Value : I8x16; Mask : Mask_8x16) return I8x16 is
      Result : I8x16 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_8x16 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_8x16 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_I8x16;
   function Reference_Expand_I8x16 (Value : I8x16; Mask : Mask_8x16) return I8x16 is
      Result : I8x16 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_8x16 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_8x16 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_I8x16;
   procedure Test_I8x16 is
      A : constant I8x16 := From_Lanes ([I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First]);
      B : constant I8x16 := From_Lanes ([1, I8'Last, -1, I8'First, 0, 1, I8'Last, -1, I8'First, 0, 1, I8'Last, -1, I8'First, 0, 1]);
      Fixed_Selectors : constant Lane_Selectors_8x16 := [1, 4, 7, 10, 13, 0, 3, 6, 9, 12, 15, 2, 5, 8, 11, 14];
      Fixed_Map : constant Lane_Map_8x16 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_8x16 := Make_Lane_Map ([others => 15]);
      Default_Map : Lane_Map_8x16;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_8x16 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_8x16 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_8x16 ((Lane * 3 + 1) mod 16)) else Select_Right_Lane (Lane_Index_8x16 ((Lane * 3 + 1) mod 16)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_8x16;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "I8x16 native fixed lane permutation");
      for Lane in Lane_Index_8x16 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "I8x16 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 15))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 15))), "I8x16 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "I8x16 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "I8x16 native fixed two-source lane permutation");
      for Lane in Lane_Index_8x16 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_8x16 ((Lane * 3 + 1) mod 16)), "I8x16 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "I8x16 default two-source lane map");
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
      for Slide in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I8x16 native lane slides" & Slide'Image);
         for Lane in Lane_Index_8x16 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 16 and then Lane < 16 - Slide then Extract (A, Lane_Index_8x16 (Lane + Slide)) else 0), "I8x16 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 16 and then Lane >= Slide then Extract (A, Lane_Index_8x16 (Lane - Slide)) else 0), "I8x16 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_First_True (Pattern, 16) and then Last_True (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_Last_True (Pattern, 16), "I8x16 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))))) = Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern), "I8x16 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1) and then To_Bit_Mask (Mask_Xor (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1), "I8x16 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = (Pattern = 2 ** 16 - 1) and then Backends.Native.Population_Count (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_Popcount (Pattern), "I8x16 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_First_True (Pattern, 16) and then Backends.Native.Last_True (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) = Reference_Last_True (Pattern, 16), "I8x16 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))))) = Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern), "I8x16 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (2 ** 16 - 1 - Pattern)))) = Interfaces.Unsigned_16 (2 ** 16 - 1), "I8x16 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_8x16 loop Check (Backends.Native.Test (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Lane) = Test (Mask_8x16'(Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Lane), "I8x16 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B)), "I8x16 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Compress_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Compress_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))), "I8x16 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Expand_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Expand_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))), "I8x16 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_I8x16 := Random_I8x16_Lanes;
            R_A : constant I8x16 := From_Lanes (R_Lanes);
            R_B : constant I8x16 := From_Lanes (Random_I8x16_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 11);
            Tail : constant Lane_Count_8x16 := Lane_Count_8x16 (Next_U64 mod 17);
            Slide : constant Natural := Natural (Next_U64 mod 19);
            Pattern : constant Interfaces.Unsigned_16 := Interfaces.Unsigned_16 (Next_U64 mod 2 ** 16);
            R_Selectors : constant Lane_Selectors_8x16 := Random_I8x16_Selectors;
            R_Map : constant Lane_Map_8x16 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_8x16 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_8x16 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_8x16 ((Iteration * 3 + Lane * 5) mod 16)) else Select_Right_Lane (Lane_Index_8x16 ((Iteration * 3 + Lane * 5) mod 16)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "I8x16 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I8x16 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I8x16 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I8x16 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I8x16 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "I8x16 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "I8x16 randomized native logical shifts");
            Check (Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Shift_Right_Arithmetic (R_A, Shift)), "I8x16 randomized native arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I8x16 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I8x16 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I8x16 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I8x16 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I8x16 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I8x16 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I8x16 (R_A, Mask_From_Bit_Mask (Pattern))), "I8x16 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I8x16 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I8x16 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I8x16 (R_A), "I8x16 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I8x16 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "I8x16 randomized native partial memory");
            for Lane in Lane_Index_8x16 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I8x16 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_8x16 ((Iteration * 3 + Lane * 5) mod 16)), "I8x16 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I8x16 randomized native lane access" & Lane'Image);
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
   function Random_U16x8_Selectors return Lane_Selectors_16x8 is
      Result : Lane_Selectors_16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result (Lane) := Lane_Index_16x8 (Next_U64 mod 8); end loop;
      return Result;
   end Random_U16x8_Selectors;
   function Same (Left, Right : U16x8) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_U16x8 (Value : U16x8; Mask : Mask_16x8) return U16x8 is
      Result : U16x8 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_16x8 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_16x8 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_U16x8;
   function Reference_Expand_U16x8 (Value : U16x8; Mask : Mask_16x8) return U16x8 is
      Result : U16x8 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_16x8 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_16x8 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_U16x8;
   procedure Test_U16x8 is
      A : constant U16x8 := From_Lanes ([0, 1, U16'Last, 2 ** (15), 17, 0, 1, U16'Last]);
      B : constant U16x8 := From_Lanes ([1, U16'Last, 2, 2 ** (15) - 1, 9, 1, U16'Last, 2]);
      Fixed_Selectors : constant Lane_Selectors_16x8 := [1, 4, 7, 2, 5, 0, 3, 6];
      Fixed_Map : constant Lane_Map_16x8 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_16x8 := Make_Lane_Map ([others => 7]);
      Default_Map : Lane_Map_16x8;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_16x8 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_16x8 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_16x8 ((Lane * 3 + 1) mod 8)) else Select_Right_Lane (Lane_Index_16x8 ((Lane * 3 + 1) mod 8)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_16x8;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "U16x8 native fixed lane permutation");
      for Lane in Lane_Index_16x8 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "U16x8 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 7))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 7))), "U16x8 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "U16x8 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "U16x8 native fixed two-source lane permutation");
      for Lane in Lane_Index_16x8 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_16x8 ((Lane * 3 + 1) mod 8)), "U16x8 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "U16x8 default two-source lane map");
      for Shift in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U16x8 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U16x8 shr" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 16), Zero) and then Same (Shift_Right_Logical (A, 16), Zero), "U16x8 independent oversized logical shifts");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U16 (Interfaces.Shift_Left (Interfaces.Unsigned_16 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U16 (Interfaces.Shift_Right (Interfaces.Unsigned_16 (Extract (A, Lane)), 1)), "U16x8 independent logical shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 10 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "U16x8 native lane slides" & Slide'Image);
         for Lane in Lane_Index_16x8 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then Extract (A, Lane_Index_16x8 (Lane + Slide)) else 0), "U16x8 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then Extract (A, Lane_Index_16x8 (Lane - Slide)) else 0), "U16x8 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 8) and then Last_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 8), "U16x8 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "U16x8 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then To_Bit_Mask (Mask_Xor (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "U16x8 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 8 - 1) and then Backends.Native.Population_Count (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U16x8 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 8) and then Backends.Native.Last_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 8), "U16x8 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "U16x8 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "U16x8 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Backends.Native.Test (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "U16x8 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U16x8 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U16x8 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U16x8 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_U16x8 := Random_U16x8_Lanes;
            R_A : constant U16x8 := From_Lanes (R_Lanes);
            R_B : constant U16x8 := From_Lanes (Random_U16x8_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 19);
            Tail : constant Lane_Count_16x8 := Lane_Count_16x8 (Next_U64 mod 9);
            Slide : constant Natural := Natural (Next_U64 mod 11);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 8);
            R_Selectors : constant Lane_Selectors_16x8 := Random_U16x8_Selectors;
            R_Map : constant Lane_Map_16x8 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_16x8 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_16x8 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)) else Select_Right_Lane (Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "U16x8 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U16x8 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "U16x8 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "U16x8 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "U16x8 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "U16x8 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "U16x8 randomized native logical shifts");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "U16x8 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "U16x8 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "U16x8 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "U16x8 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "U16x8 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_U16x8 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_U16x8 (R_A, Mask_From_Bit_Mask (Pattern))), "U16x8 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U16x8 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_U16x8 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_U16x8 (R_A), "U16x8 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "U16x8 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "U16x8 randomized native partial memory");
            for Lane in Lane_Index_16x8 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "U16x8 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)), "U16x8 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "U16x8 randomized native lane access" & Lane'Image);
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
   function Random_I16x8_Selectors return Lane_Selectors_16x8 is
      Result : Lane_Selectors_16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result (Lane) := Lane_Index_16x8 (Next_U64 mod 8); end loop;
      return Result;
   end Random_I16x8_Selectors;
   function Same (Left, Right : I16x8) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_I16x8 (Value : I16x8; Mask : Mask_16x8) return I16x8 is
      Result : I16x8 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_16x8 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_16x8 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_I16x8;
   function Reference_Expand_I16x8 (Value : I16x8; Mask : Mask_16x8) return I16x8 is
      Result : I16x8 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_16x8 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_16x8 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_I16x8;
   procedure Test_I16x8 is
      A : constant I16x8 := From_Lanes ([I16'First, -1, 0, 1, I16'Last, I16'First, -1, 0]);
      B : constant I16x8 := From_Lanes ([1, I16'Last, -1, I16'First, 0, 1, I16'Last, -1]);
      Fixed_Selectors : constant Lane_Selectors_16x8 := [1, 4, 7, 2, 5, 0, 3, 6];
      Fixed_Map : constant Lane_Map_16x8 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_16x8 := Make_Lane_Map ([others => 7]);
      Default_Map : Lane_Map_16x8;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_16x8 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_16x8 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_16x8 ((Lane * 3 + 1) mod 8)) else Select_Right_Lane (Lane_Index_16x8 ((Lane * 3 + 1) mod 8)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_16x8;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "I16x8 native fixed lane permutation");
      for Lane in Lane_Index_16x8 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "I16x8 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 7))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 7))), "I16x8 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "I16x8 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "I16x8 native fixed two-source lane permutation");
      for Lane in Lane_Index_16x8 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_16x8 ((Lane * 3 + 1) mod 8)), "I16x8 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "I16x8 default two-source lane map");
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
      for Slide in Natural range 0 .. 10 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I16x8 native lane slides" & Slide'Image);
         for Lane in Lane_Index_16x8 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then Extract (A, Lane_Index_16x8 (Lane + Slide)) else 0), "I16x8 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then Extract (A, Lane_Index_16x8 (Lane - Slide)) else 0), "I16x8 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 8) and then Last_True (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 8), "I16x8 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "I16x8 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then To_Bit_Mask (Mask_Xor (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "I16x8 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 8 - 1) and then Backends.Native.Population_Count (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I16x8 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 8) and then Backends.Native.Last_True (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 8), "I16x8 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern), "I16x8 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 8 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "I16x8 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Backends.Native.Test (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_16x8'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "I16x8 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I16x8 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I16x8 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I16x8 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_I16x8 := Random_I16x8_Lanes;
            R_A : constant I16x8 := From_Lanes (R_Lanes);
            R_B : constant I16x8 := From_Lanes (Random_I16x8_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 19);
            Tail : constant Lane_Count_16x8 := Lane_Count_16x8 (Next_U64 mod 9);
            Slide : constant Natural := Natural (Next_U64 mod 11);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 8);
            R_Selectors : constant Lane_Selectors_16x8 := Random_I16x8_Selectors;
            R_Map : constant Lane_Map_16x8 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_16x8 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_16x8 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)) else Select_Right_Lane (Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "I16x8 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I16x8 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I16x8 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I16x8 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I16x8 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "I16x8 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "I16x8 randomized native logical shifts");
            Check (Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Shift_Right_Arithmetic (R_A, Shift)), "I16x8 randomized native arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I16x8 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I16x8 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I16x8 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I16x8 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I16x8 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I16x8 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I16x8 (R_A, Mask_From_Bit_Mask (Pattern))), "I16x8 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I16x8 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I16x8 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I16x8 (R_A), "I16x8 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I16x8 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "I16x8 randomized native partial memory");
            for Lane in Lane_Index_16x8 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I16x8 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)), "I16x8 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I16x8 randomized native lane access" & Lane'Image);
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
   function Random_U32x4_Selectors return Lane_Selectors_32x4 is
      Result : Lane_Selectors_32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result (Lane) := Lane_Index_32x4 (Next_U64 mod 4); end loop;
      return Result;
   end Random_U32x4_Selectors;
   function Same (Left, Right : U32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_U32x4 (Value : U32x4; Mask : Mask_32x4) return U32x4 is
      Result : U32x4 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_32x4 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_32x4 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_U32x4;
   function Reference_Expand_U32x4 (Value : U32x4; Mask : Mask_32x4) return U32x4 is
      Result : U32x4 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_32x4 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_32x4 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_U32x4;
   procedure Test_U32x4 is
      A : constant U32x4 := From_Lanes ([0, 1, U32'Last, 2 ** (31)]);
      B : constant U32x4 := From_Lanes ([1, U32'Last, 2, 2 ** (31) - 1]);
      Fixed_Selectors : constant Lane_Selectors_32x4 := [1, 0, 3, 2];
      Fixed_Map : constant Lane_Map_32x4 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_32x4 := Make_Lane_Map ([others => 3]);
      Default_Map : Lane_Map_32x4;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Lane * 3 + 1) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Lane * 3 + 1) mod 4)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_32x4;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "U32x4 native fixed lane permutation");
      for Lane in Lane_Index_32x4 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "U32x4 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 3))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 3))), "U32x4 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "U32x4 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "U32x4 native fixed two-source lane permutation");
      for Lane in Lane_Index_32x4 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_32x4 ((Lane * 3 + 1) mod 4)), "U32x4 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "U32x4 default two-source lane map");
      for Shift in Natural range 0 .. 34 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U32x4 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U32x4 shr" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 32), Zero) and then Same (Shift_Right_Logical (A, 32), Zero), "U32x4 independent oversized logical shifts");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U32 (Interfaces.Shift_Left (Interfaces.Unsigned_32 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U32 (Interfaces.Shift_Right (Interfaces.Unsigned_32 (Extract (A, Lane)), 1)), "U32x4 independent logical shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 6 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "U32x4 native lane slides" & Slide'Image);
         for Lane in Lane_Index_32x4 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then Extract (A, Lane_Index_32x4 (Lane + Slide)) else 0), "U32x4 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then Extract (A, Lane_Index_32x4 (Lane - Slide)) else 0), "U32x4 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 4) and then Last_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 4), "U32x4 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "U32x4 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then To_Bit_Mask (Mask_Xor (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "U32x4 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1) and then Backends.Native.Population_Count (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U32x4 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 4) and then Backends.Native.Last_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 4), "U32x4 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "U32x4 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "U32x4 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "U32x4 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U32x4 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U32x4 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U32x4 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_U32x4 := Random_U32x4_Lanes;
            R_A : constant U32x4 := From_Lanes (R_Lanes);
            R_B : constant U32x4 := From_Lanes (Random_U32x4_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 35);
            Tail : constant Lane_Count_32x4 := Lane_Count_32x4 (Next_U64 mod 5);
            Slide : constant Natural := Natural (Next_U64 mod 7);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 4);
            R_Selectors : constant Lane_Selectors_32x4 := Random_U32x4_Selectors;
            R_Map : constant Lane_Map_32x4 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "U32x4 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U32x4 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "U32x4 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "U32x4 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "U32x4 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "U32x4 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "U32x4 randomized native logical shifts");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "U32x4 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "U32x4 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "U32x4 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "U32x4 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "U32x4 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_U32x4 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_U32x4 (R_A, Mask_From_Bit_Mask (Pattern))), "U32x4 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U32x4 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_U32x4 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_U32x4 (R_A), "U32x4 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "U32x4 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "U32x4 randomized native partial memory");
            for Lane in Lane_Index_32x4 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "U32x4 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)), "U32x4 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "U32x4 randomized native lane access" & Lane'Image);
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
   function Random_I32x4_Selectors return Lane_Selectors_32x4 is
      Result : Lane_Selectors_32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result (Lane) := Lane_Index_32x4 (Next_U64 mod 4); end loop;
      return Result;
   end Random_I32x4_Selectors;
   function Same (Left, Right : I32x4) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_I32x4 (Value : I32x4; Mask : Mask_32x4) return I32x4 is
      Result : I32x4 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_32x4 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_32x4 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_I32x4;
   function Reference_Expand_I32x4 (Value : I32x4; Mask : Mask_32x4) return I32x4 is
      Result : I32x4 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_32x4 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_32x4 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_I32x4;
   procedure Test_I32x4 is
      A : constant I32x4 := From_Lanes ([I32'First, -1, 0, 1]);
      B : constant I32x4 := From_Lanes ([1, I32'Last, -1, I32'First]);
      Fixed_Selectors : constant Lane_Selectors_32x4 := [1, 0, 3, 2];
      Fixed_Map : constant Lane_Map_32x4 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_32x4 := Make_Lane_Map ([others => 3]);
      Default_Map : Lane_Map_32x4;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Lane * 3 + 1) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Lane * 3 + 1) mod 4)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_32x4;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "I32x4 native fixed lane permutation");
      for Lane in Lane_Index_32x4 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "I32x4 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 3))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 3))), "I32x4 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "I32x4 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "I32x4 native fixed two-source lane permutation");
      for Lane in Lane_Index_32x4 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_32x4 ((Lane * 3 + 1) mod 4)), "I32x4 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "I32x4 default two-source lane map");
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
      for Slide in Natural range 0 .. 6 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I32x4 native lane slides" & Slide'Image);
         for Lane in Lane_Index_32x4 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then Extract (A, Lane_Index_32x4 (Lane + Slide)) else 0), "I32x4 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then Extract (A, Lane_Index_32x4 (Lane - Slide)) else 0), "I32x4 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 4) and then Last_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 4), "I32x4 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "I32x4 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then To_Bit_Mask (Mask_Xor (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "I32x4 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1) and then Backends.Native.Population_Count (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I32x4 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 4) and then Backends.Native.Last_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 4), "I32x4 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "I32x4 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "I32x4 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "I32x4 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I32x4 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I32x4 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I32x4 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_I32x4 := Random_I32x4_Lanes;
            R_A : constant I32x4 := From_Lanes (R_Lanes);
            R_B : constant I32x4 := From_Lanes (Random_I32x4_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 35);
            Tail : constant Lane_Count_32x4 := Lane_Count_32x4 (Next_U64 mod 5);
            Slide : constant Natural := Natural (Next_U64 mod 7);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 4);
            R_Selectors : constant Lane_Selectors_32x4 := Random_I32x4_Selectors;
            R_Map : constant Lane_Map_32x4 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "I32x4 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I32x4 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I32x4 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I32x4 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I32x4 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "I32x4 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "I32x4 randomized native logical shifts");
            Check (Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Shift_Right_Arithmetic (R_A, Shift)), "I32x4 randomized native arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I32x4 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I32x4 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I32x4 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I32x4 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I32x4 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I32x4 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I32x4 (R_A, Mask_From_Bit_Mask (Pattern))), "I32x4 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I32x4 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I32x4 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I32x4 (R_A), "I32x4 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I32x4 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "I32x4 randomized native partial memory");
            for Lane in Lane_Index_32x4 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I32x4 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)), "I32x4 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I32x4 randomized native lane access" & Lane'Image);
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
   function Random_U64x2_Selectors return Lane_Selectors_64x2 is
      Result : Lane_Selectors_64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result (Lane) := Lane_Index_64x2 (Next_U64 mod 2); end loop;
      return Result;
   end Random_U64x2_Selectors;
   function Same (Left, Right : U64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_U64x2 (Value : U64x2; Mask : Mask_64x2) return U64x2 is
      Result : U64x2 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_64x2 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_64x2 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_U64x2;
   function Reference_Expand_U64x2 (Value : U64x2; Mask : Mask_64x2) return U64x2 is
      Result : U64x2 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_64x2 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_64x2 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_U64x2;
   procedure Test_U64x2 is
      A : constant U64x2 := From_Lanes ([0, 1]);
      B : constant U64x2 := From_Lanes ([1, U64'Last]);
      Fixed_Selectors : constant Lane_Selectors_64x2 := [1, 0];
      Fixed_Map : constant Lane_Map_64x2 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_64x2 := Make_Lane_Map ([others => 1]);
      Default_Map : Lane_Map_64x2;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Lane * 3 + 1) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Lane * 3 + 1) mod 2)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_64x2;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "U64x2 native fixed lane permutation");
      for Lane in Lane_Index_64x2 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "U64x2 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 1))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 1))), "U64x2 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "U64x2 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "U64x2 native fixed two-source lane permutation");
      for Lane in Lane_Index_64x2 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_64x2 ((Lane * 3 + 1) mod 2)), "U64x2 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "U64x2 default two-source lane map");
      for Shift in Natural range 0 .. 66 loop
         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), "U64x2 shl" & Shift'Image);
         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), "U64x2 shr" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 64), Zero) and then Same (Shift_Right_Logical (A, 64), Zero), "U64x2 independent oversized logical shifts");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U64 (Interfaces.Shift_Left (Interfaces.Unsigned_64 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U64 (Interfaces.Shift_Right (Interfaces.Unsigned_64 (Extract (A, Lane)), 1)), "U64x2 independent logical shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 4 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "U64x2 native lane slides" & Slide'Image);
         for Lane in Lane_Index_64x2 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then Extract (A, Lane_Index_64x2 (Lane + Slide)) else 0), "U64x2 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then Extract (A, Lane_Index_64x2 (Lane - Slide)) else 0), "U64x2 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 2) and then Last_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 2), "U64x2 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "U64x2 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then To_Bit_Mask (Mask_Xor (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "U64x2 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1) and then Backends.Native.Population_Count (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "U64x2 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 2) and then Backends.Native.Last_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 2), "U64x2 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "U64x2 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "U64x2 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "U64x2 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U64x2 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U64x2 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U64x2 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_U64x2 := Random_U64x2_Lanes;
            R_A : constant U64x2 := From_Lanes (R_Lanes);
            R_B : constant U64x2 := From_Lanes (Random_U64x2_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 67);
            Tail : constant Lane_Count_64x2 := Lane_Count_64x2 (Next_U64 mod 3);
            Slide : constant Natural := Natural (Next_U64 mod 5);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 2);
            R_Selectors : constant Lane_Selectors_64x2 := Random_U64x2_Selectors;
            R_Map : constant Lane_Map_64x2 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "U64x2 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U64x2 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "U64x2 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "U64x2 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "U64x2 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "U64x2 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "U64x2 randomized native logical shifts");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "U64x2 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "U64x2 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "U64x2 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "U64x2 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "U64x2 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_U64x2 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_U64x2 (R_A, Mask_From_Bit_Mask (Pattern))), "U64x2 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U64x2 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_U64x2 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_U64x2 (R_A), "U64x2 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "U64x2 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "U64x2 randomized native partial memory");
            for Lane in Lane_Index_64x2 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "U64x2 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)), "U64x2 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "U64x2 randomized native lane access" & Lane'Image);
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
   function Random_I64x2_Selectors return Lane_Selectors_64x2 is
      Result : Lane_Selectors_64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result (Lane) := Lane_Index_64x2 (Next_U64 mod 2); end loop;
      return Result;
   end Random_I64x2_Selectors;
   function Same (Left, Right : I64x2) return Boolean is (To_Lanes (Left) = To_Lanes (Right));
   function Reference_Compress_I64x2 (Value : I64x2; Mask : Mask_64x2) return I64x2 is
      Result : I64x2 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_64x2 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_64x2 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_I64x2;
   function Reference_Expand_I64x2 (Value : I64x2; Mask : Mask_64x2) return I64x2 is
      Result : I64x2 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_64x2 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_64x2 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_I64x2;
   procedure Test_I64x2 is
      A : constant I64x2 := From_Lanes ([I64'First, -1]);
      B : constant I64x2 := From_Lanes ([1, I64'Last]);
      Fixed_Selectors : constant Lane_Selectors_64x2 := [1, 0];
      Fixed_Map : constant Lane_Map_64x2 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_64x2 := Make_Lane_Map ([others => 1]);
      Default_Map : Lane_Map_64x2;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Lane * 3 + 1) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Lane * 3 + 1) mod 2)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_64x2;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "I64x2 native fixed lane permutation");
      for Lane in Lane_Index_64x2 loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), "I64x2 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 1))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 1))), "I64x2 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "I64x2 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "I64x2 native fixed two-source lane permutation");
      for Lane in Lane_Index_64x2 loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_64x2 ((Lane * 3 + 1) mod 2)), "I64x2 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "I64x2 default two-source lane map");
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
      for Slide in Natural range 0 .. 4 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I64x2 native lane slides" & Slide'Image);
         for Lane in Lane_Index_64x2 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then Extract (A, Lane_Index_64x2 (Lane + Slide)) else 0), "I64x2 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then Extract (A, Lane_Index_64x2 (Lane - Slide)) else 0), "I64x2 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
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
         Check (First_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 2) and then Last_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 2), "I64x2 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "I64x2 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then To_Bit_Mask (Mask_Xor (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "I64x2 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1) and then Backends.Native.Population_Count (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "I64x2 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 2) and then Backends.Native.Last_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 2), "I64x2 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "I64x2 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "I64x2 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "I64x2 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I64x2 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I64x2 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I64x2 exhaustive expand" & Pattern'Image);
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
            R_Lanes : constant Lane_Values_I64x2 := Random_I64x2_Lanes;
            R_A : constant I64x2 := From_Lanes (R_Lanes);
            R_B : constant I64x2 := From_Lanes (Random_I64x2_Lanes);
            Shift : constant Natural := Natural (Next_U64 mod 67);
            Tail : constant Lane_Count_64x2 := Lane_Count_64x2 (Next_U64 mod 3);
            Slide : constant Natural := Natural (Next_U64 mod 5);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 2);
            R_Selectors : constant Lane_Selectors_64x2 := Random_I64x2_Selectors;
            R_Map : constant Lane_Map_64x2 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "I64x2 randomized native construction");
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I64x2 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I64x2 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I64x2 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I64x2 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), "I64x2 randomized native comparisons");
            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), "I64x2 randomized native logical shifts");
            Check (Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Shift_Right_Arithmetic (R_A, Shift)), "I64x2 randomized native arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I64x2 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I64x2 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I64x2 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I64x2 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I64x2 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I64x2 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I64x2 (R_A, Mask_From_Bit_Mask (Pattern))), "I64x2 randomized native compression");
            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I64x2 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I64x2 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I64x2 (R_A), "I64x2 randomized native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I64x2 randomized native full memory");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "I64x2 randomized native partial memory");
            for Lane in Lane_Index_64x2 loop
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I64x2 randomized independent lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)), "I64x2 varied independent two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I64x2 randomized native lane access" & Lane'Image);
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
   function Random_F32x4_Selectors return Lane_Selectors_32x4 is
      Result : Lane_Selectors_32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result (Lane) := Lane_Index_32x4 (Next_U64 mod 4); end loop;
      return Result;
   end Random_F32x4_Selectors;
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
   function Reference_Compress_F32x4 (Value : F32x4; Mask : Mask_32x4) return F32x4 is
      Result : F32x4 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_32x4 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_32x4 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_F32x4;
   function Reference_Expand_F32x4 (Value : F32x4; Mask : Mask_32x4) return F32x4 is
      Result : F32x4 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_32x4 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_32x4 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_F32x4;
   function Reference_Reduce_Add_F32x4 (Value : F32x4) return F32 is
      Result : F32 := 0.0;
   begin
      for Lane in Lane_Index_32x4 loop Result := Result + Extract (Value, Lane); end loop;
      return Result;
   end Reference_Reduce_Add_F32x4;
   function Reference_Reduce_Min_F32x4 (Value : F32x4) return F32 is
      Result : F32 := Extract (Value, 0);
   begin
      for Lane in Lane_Index_32x4 range 1 .. 3 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_F32x4;
   function Reference_Reduce_Max_F32x4 (Value : F32x4) return F32 is
      Result : F32 := Extract (Value, 0);
   begin
      for Lane in Lane_Index_32x4 range 1 .. 3 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_F32x4;
   procedure Test_F32x4 is
      A : constant F32x4 := From_Lanes ([0.0, -0.0, 1.5, -2.25]);
      B : constant F32x4 := From_Lanes ([2.0, -3.0, 0.5, 4.0]);
      Fixed_Selectors : constant Lane_Selectors_32x4 := [1, 0, 3, 2];
      Fixed_Map : constant Lane_Map_32x4 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_32x4 := Make_Lane_Map ([others => 3]);
      Default_Map : Lane_Map_32x4;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Lane * 3 + 1) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Lane * 3 + 1) mod 4)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_32x4;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "F32x4 native fixed lane permutation");
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Permute_Lanes (A, Fixed_Map), Lane)) = Bits_F32x4 (Extract (A, Fixed_Selectors (Lane))), "F32x4 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 3))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 3))), "F32x4 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "F32x4 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "F32x4 native fixed two-source lane permutation");
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane)) = Bits_F32x4 (Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_32x4 ((Lane * 3 + 1) mod 4))), "F32x4 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "F32x4 default two-source lane map");
      for Slide in Natural range 0 .. 6 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "F32x4 native lane slides" & Slide'Image);
         for Lane in Lane_Index_32x4 loop
            Check (Bits_F32x4 (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < 4 and then Lane < 4 - Slide then Bits_F32x4 (Extract (A, Lane_Index_32x4 (Lane + Slide))) else 0), "F32x4 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Bits_F32x4 (Extract (Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < 4 and then Lane >= Slide then Bits_F32x4 (Extract (A, Lane_Index_32x4 (Lane - Slide))) else 0), "F32x4 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
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
         Check (First_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 4) and then Last_True (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 4), "F32x4 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "F32x4 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then To_Bit_Mask (Mask_Xor (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "F32x4 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 4 - 1) and then Backends.Native.Population_Count (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "F32x4 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 4) and then Backends.Native.Last_True (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 4), "F32x4 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern), "F32x4 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 4 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "F32x4 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_32x4'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "F32x4 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "F32x4 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F32x4 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F32x4 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "F32x4 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Bits_F32x4 (Reduce_Add (A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (A)) and then Bits_F32x4 (Backends.Native.Reduce_Add (A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (A)), "F32x4 independent reduce");
      Check (Bits_F32x4 (Reduce_Min_Number (B)) = Bits_F32x4 (Reference_Reduce_Min_F32x4 (B)) and then Bits_F32x4 (Backends.Native.Reduce_Min_Number (B)) = Bits_F32x4 (Reference_Reduce_Min_F32x4 (B)) and then Bits_F32x4 (Reduce_Max_Number (B)) = Bits_F32x4 (Reference_Reduce_Max_F32x4 (B)) and then Bits_F32x4 (Backends.Native.Reduce_Max_Number (B)) = Bits_F32x4 (Reference_Reduce_Max_F32x4 (B)), "F32x4 independent min/max reductions");
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
            R_Lanes : constant Lane_Values_F32x4 := Random_F32x4_Lanes;
            R_A : constant F32x4 := From_Lanes (R_Lanes);
            R_B : constant F32x4 := From_Lanes (Random_F32x4_Lanes);
            Tail : constant Lane_Count_32x4 := Lane_Count_32x4 (Next_U64 mod 5);
            Slide : constant Natural := Natural (Next_U64 mod 7);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 4);
            R_Selectors : constant Lane_Selectors_32x4 := Random_F32x4_Selectors;
            R_Map : constant Lane_Map_32x4 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "F32x4 randomized native construction");
            Check (Same (Backends.Native.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Native.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F32x4 randomized native arithmetic");
            Check (Same (Backends.Native.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Native.Max_Number (R_A, R_B), Max_Number (R_A, R_B)), "F32x4 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Unordered (R_A, R_B)), "F32x4 randomized native comparisons");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "F32x4 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "F32x4 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "F32x4 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "F32x4 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "F32x4 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_F32x4 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_F32x4 (R_A, Mask_From_Bit_Mask (Pattern))), "F32x4 randomized native compression");
            Check (Bits_F32x4 (Backends.Native.Reduce_Add (R_A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (R_A)) and then Bits_F32x4 (Backends.Native.Reduce_Min_Number (R_A)) = Bits_F32x4 (Reference_Reduce_Min_F32x4 (R_A)) and then Bits_F32x4 (Backends.Native.Reduce_Max_Number (R_A)) = Bits_F32x4 (Reference_Reduce_Max_F32x4 (R_A)), "F32x4 randomized native reductions");
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "F32x4 randomized native full memory");
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "F32x4 randomized native partial memory");
            for Lane in Lane_Index_32x4 loop
               Check (Bits_F32x4 (Extract (Permute_Lanes (R_A, R_Map), Lane)) = Bits_F32x4 (R_Lanes (R_Selectors (Lane))), "F32x4 randomized independent lane permutation" & Lane'Image);
               Check (Bits_F32x4 (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_F32x4 (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4))), "F32x4 varied independent two-source lane permutation" & Lane'Image);
               Check (Bits_F32x4 (Backends.Native.Extract (R_A, Lane)) = Bits_F32x4 (R_Lanes (Lane)) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "F32x4 randomized native lane access" & Lane'Image);
               Check (Bits_F32x4 (Extract (Add (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Subtract (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Multiply (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) * Extract (R_B, Lane)), "F32x4 randomized independent arithmetic" & Lane'Image);
               if Extract (R_B, Lane) /= 0.0 then Check (Bits_F32x4 (Extract (Divide (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) / Extract (R_B, Lane)), "F32x4 randomized independent division" & Lane'Image); end if;
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "F32x4 randomized independent comparison" & Lane'Image);
               Check (Extract (Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "F32x4 randomized independent min/max" & Lane'Image);
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
   function Random_F64x2_Selectors return Lane_Selectors_64x2 is
      Result : Lane_Selectors_64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result (Lane) := Lane_Index_64x2 (Next_U64 mod 2); end loop;
      return Result;
   end Random_F64x2_Selectors;
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
   function Reference_Compress_F64x2 (Value : F64x2; Mask : Mask_64x2) return F64x2 is
      Result : F64x2 := Zero;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_64x2 loop
         if Test (Mask, Source_Lane) then
            Result := Replace (Result, Lane_Index_64x2 (Result_Lane), Extract (Value, Source_Lane));
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Compress_F64x2;
   function Reference_Expand_F64x2 (Value : F64x2; Mask : Mask_64x2) return F64x2 is
      Result : F64x2 := Zero;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_64x2 loop
         if Test (Mask, Result_Lane) then
            Result := Replace (Result, Result_Lane, Extract (Value, Lane_Index_64x2 (Source_Lane)));
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Result;
   end Reference_Expand_F64x2;
   function Reference_Reduce_Add_F64x2 (Value : F64x2) return F64 is
      Result : F64 := 0.0;
   begin
      for Lane in Lane_Index_64x2 loop Result := Result + Extract (Value, Lane); end loop;
      return Result;
   end Reference_Reduce_Add_F64x2;
   function Reference_Reduce_Min_F64x2 (Value : F64x2) return F64 is
      Result : F64 := Extract (Value, 0);
   begin
      for Lane in Lane_Index_64x2 range 1 .. 1 loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Min_F64x2;
   function Reference_Reduce_Max_F64x2 (Value : F64x2) return F64 is
      Result : F64 := Extract (Value, 0);
   begin
      for Lane in Lane_Index_64x2 range 1 .. 1 loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;
      return Result;
   end Reference_Reduce_Max_F64x2;
   procedure Test_F64x2 is
      A : constant F64x2 := From_Lanes ([0.0, -0.0]);
      B : constant F64x2 := From_Lanes ([2.0, -3.0]);
      Fixed_Selectors : constant Lane_Selectors_64x2 := [1, 0];
      Fixed_Map : constant Lane_Map_64x2 := Make_Lane_Map (Fixed_Selectors);
      Broadcast_Map : constant Lane_Map_64x2 := Make_Lane_Map ([others => 1]);
      Default_Map : Lane_Map_64x2;
      Fixed_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if Lane mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Lane * 3 + 1) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Lane * 3 + 1) mod 2)))]);
      Default_Two_Source_Map : Two_Source_Lane_Map_64x2;
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
      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), "F64x2 native fixed lane permutation");
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Permute_Lanes (A, Fixed_Map), Lane)) = Bits_F64x2 (Extract (A, Fixed_Selectors (Lane))), "F64x2 independent fixed lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 1))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, 1))), "F64x2 repeated-selector broadcast");
      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), "F64x2 default lane map");
      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), "F64x2 native fixed two-source lane permutation");
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane)) = Bits_F64x2 (Extract ((if Lane mod 2 = 0 then A else B), Lane_Index_64x2 ((Lane * 3 + 1) mod 2))), "F64x2 independent fixed two-source lane permutation" & Lane'Image); end loop;
      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), "F64x2 default two-source lane map");
      for Slide in Natural range 0 .. 4 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "F64x2 native lane slides" & Slide'Image);
         for Lane in Lane_Index_64x2 loop
            Check (Bits_F64x2 (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < 2 and then Lane < 2 - Slide then Bits_F64x2 (Extract (A, Lane_Index_64x2 (Lane + Slide))) else 0), "F64x2 independent slide toward low" & Slide'Image & Lane'Image);
            Check (Bits_F64x2 (Extract (Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < 2 and then Lane >= Slide then Bits_F64x2 (Extract (A, Lane_Index_64x2 (Lane - Slide))) else 0), "F64x2 independent slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
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
         Check (First_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 2) and then Last_True (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 2), "F64x2 scalar mask positions" & Pattern'Image);
         Check (To_Bit_Mask (Mask_Not (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "F64x2 scalar mask not" & Pattern'Image);
         Check (To_Bit_Mask (Mask_And (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then To_Bit_Mask (Mask_Xor (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "F64x2 scalar mask algebra" & Pattern'Image);
         Check (Backends.Native.Any_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** 2 - 1) and then Backends.Native.Population_Count (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), "F64x2 native mask reductions" & Pattern'Image);
         Check (Backends.Native.First_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, 2) and then Backends.Native.Last_True (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, 2), "F64x2 native mask positions" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern), "F64x2 native mask not" & Pattern'Image);
         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** 2 - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "F64x2 native mask algebra" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test (Mask_64x2'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), "F64x2 native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "F64x2 exhaustive select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F64x2 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F64x2 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "F64x2 independent select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Bits_F64x2 (Reduce_Add (A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (A)) and then Bits_F64x2 (Backends.Native.Reduce_Add (A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (A)), "F64x2 independent reduce");
      Check (Bits_F64x2 (Reduce_Min_Number (B)) = Bits_F64x2 (Reference_Reduce_Min_F64x2 (B)) and then Bits_F64x2 (Backends.Native.Reduce_Min_Number (B)) = Bits_F64x2 (Reference_Reduce_Min_F64x2 (B)) and then Bits_F64x2 (Reduce_Max_Number (B)) = Bits_F64x2 (Reference_Reduce_Max_F64x2 (B)) and then Bits_F64x2 (Backends.Native.Reduce_Max_Number (B)) = Bits_F64x2 (Reference_Reduce_Max_F64x2 (B)), "F64x2 independent min/max reductions");
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
            R_Lanes : constant Lane_Values_F64x2 := Random_F64x2_Lanes;
            R_A : constant F64x2 := From_Lanes (R_Lanes);
            R_B : constant F64x2 := From_Lanes (Random_F64x2_Lanes);
            Tail : constant Lane_Count_64x2 := Lane_Count_64x2 (Next_U64 mod 3);
            Slide : constant Natural := Natural (Next_U64 mod 5);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 2);
            R_Selectors : constant Lane_Selectors_64x2 := Random_F64x2_Selectors;
            R_Map : constant Lane_Map_64x2 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)))]);
         begin
            Check (Same (Backends.Native.From_Lanes (R_Lanes), R_A) and then Backends.Native.To_Lanes (R_A) = R_Lanes and then Same (Backends.Native.Splat (R_Lanes (0)), Splat (R_Lanes (0))), "F64x2 randomized native construction");
            Check (Same (Backends.Native.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Native.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F64x2 randomized native arithmetic");
            Check (Same (Backends.Native.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Native.Max_Number (R_A, R_B), Max_Number (R_A, R_B)), "F64x2 randomized native min/max");
            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Unordered (R_A, R_B)), "F64x2 randomized native comparisons");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "F64x2 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "F64x2 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "F64x2 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "F64x2 randomized native lane slides");
            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "F64x2 randomized native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_F64x2 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_F64x2 (R_A, Mask_From_Bit_Mask (Pattern))), "F64x2 randomized native compression");
            Check (Bits_F64x2 (Backends.Native.Reduce_Add (R_A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (R_A)) and then Bits_F64x2 (Backends.Native.Reduce_Min_Number (R_A)) = Bits_F64x2 (Reference_Reduce_Min_F64x2 (R_A)) and then Bits_F64x2 (Backends.Native.Reduce_Max_Number (R_A)) = Bits_F64x2 (Reference_Reduce_Max_F64x2 (R_A)), "F64x2 randomized native reductions");
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "F64x2 randomized native full memory");
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, Tail), Load_Partial (Reference, 2, Tail)), "F64x2 randomized native partial memory");
            for Lane in Lane_Index_64x2 loop
               Check (Bits_F64x2 (Extract (Permute_Lanes (R_A, R_Map), Lane)) = Bits_F64x2 (R_Lanes (R_Selectors (Lane))), "F64x2 randomized independent lane permutation" & Lane'Image);
               Check (Bits_F64x2 (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_F64x2 (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2))), "F64x2 varied independent two-source lane permutation" & Lane'Image);
               Check (Bits_F64x2 (Backends.Native.Extract (R_A, Lane)) = Bits_F64x2 (R_Lanes (Lane)) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "F64x2 randomized native lane access" & Lane'Image);
               Check (Bits_F64x2 (Extract (Add (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Subtract (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Multiply (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) * Extract (R_B, Lane)), "F64x2 randomized independent arithmetic" & Lane'Image);
               if Extract (R_B, Lane) /= 0.0 then Check (Bits_F64x2 (Extract (Divide (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) / Extract (R_B, Lane)), "F64x2 randomized independent division" & Lane'Image); end if;
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "F64x2 randomized independent comparison" & Lane'Image);
               Check (Extract (Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "F64x2 randomized independent min/max" & Lane'Image);
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
   function Is_Quiet_NaN (Value : F32) return Boolean is
     (Is_NaN (Value) and then (F32_Bits (Value) and 16#0040_0000#) /= 0);
   function Is_Quiet_NaN (Value : F64) return Boolean is
     (Is_NaN (Value) and then (F64_Bits (Value) and 16#0008_0000_0000_0000#) /= 0);
   procedure Test_Floating_Specials is
      pragma Suppress (Validity_Check);
      NaN32 : constant F32 := To_F32 (16#7FC0_0001#);
      SNaN32 : constant F32 := To_F32 (16#7F80_0001#);
      Inf32 : constant F32 := To_F32 (16#7F80_0000#);
      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);
      A32 : constant F32x4 := From_Lanes ([NaN32, Inf32, Neg_Zero32, 0.0]);
      B32 : constant F32x4 := From_Lanes ([1.0, Inf32, 0.0, Neg_Zero32]);
      Slide32 : constant F32x4 := From_Lanes ([NaN32, SNaN32, Inf32, Neg_Zero32]);
      Two32_Right : constant F32x4 := From_Lanes ([Neg_Zero32, Inf32, SNaN32, NaN32]);
      Permute32_Selectors : constant Lane_Selectors_32x4 := [3, 0, 1, 1];
      Permute32_Map : constant Lane_Map_32x4 := Make_Lane_Map (Permute32_Selectors);
      Two32_Map_A : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([Select_Left_Lane (0), Select_Right_Lane (1), Select_Left_Lane (2), Select_Right_Lane (3)]);
      Two32_Map_B : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([Select_Right_Lane (0), Select_Left_Lane (1), Select_Right_Lane (2), Select_Left_Lane (3)]);
      NaN64 : constant F64 := To_F64 (16#7FF8_0000_0000_0001#);
      SNaN64 : constant F64 := To_F64 (16#7FF0_0000_0000_0001#);
      Inf64 : constant F64 := To_F64 (16#7FF0_0000_0000_0000#);
      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);
      A64 : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);
      B64 : constant F64x2 := From_Lanes ([1.0, 0.0]);
      Slide64_A : constant F64x2 := From_Lanes ([NaN64, SNaN64]);
      Slide64_B : constant F64x2 := From_Lanes ([Inf64, Neg_Zero64]);
      Permute64_Selectors : constant Lane_Selectors_64x2 := [1, 0];
      Permute64_Map : constant Lane_Map_64x2 := Make_Lane_Map (Permute64_Selectors);
      Two64_Map_A : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([Select_Left_Lane (0), Select_Right_Lane (1)]);
      Two64_Map_B : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([Select_Right_Lane (0), Select_Left_Lane (1)]);
      Zero32 : constant F32x4 := From_Lanes ([0.0, 0.0, 0.0, 0.0]);
      Numerator32 : constant F32x4 := From_Lanes ([1.0, 0.0, -1.0, 0.0]);
      Quiet32 : constant F32x4 := From_Lanes ([NaN32, NaN32, NaN32, NaN32]);
      Signal32 : constant F32x4 := From_Lanes ([SNaN32, SNaN32, SNaN32, SNaN32]);
      Number32 : constant F32x4 := From_Lanes ([1.0, 1.0, 1.0, 1.0]);
      Fold_Order32 : constant F32x4 := From_Lanes ([2.0, 1.0, SNaN32, 3.0]);
      Positive_Zero_First32 : constant F32x4 := From_Lanes ([0.0, Neg_Zero32, 0.0, Neg_Zero32]);
      Negative_Zero_First32 : constant F32x4 := From_Lanes ([Neg_Zero32, 0.0, Neg_Zero32, 0.0]);
      Quiet_Left32 : constant F32x4 := From_Lanes ([NaN32, 5.0, NaN32, NaN32]);
      Quiet_Right32 : constant F32x4 := From_Lanes ([5.0, NaN32, NaN32, NaN32]);
      Signal_Left32 : constant F32x4 := From_Lanes ([SNaN32, 5.0, NaN32, NaN32]);
      Signal_Right32 : constant F32x4 := From_Lanes ([5.0, SNaN32, NaN32, NaN32]);
      Zero64 : constant F64x2 := From_Lanes ([0.0, 0.0]);
      Numerator64 : constant F64x2 := From_Lanes ([1.0, 0.0]);
      Infinity64 : constant F64x2 := From_Lanes ([Inf64, 0.0]);
      Twice64 : constant F64x2 := From_Lanes ([2.0, 0.0]);
      Quiet64 : constant F64x2 := From_Lanes ([NaN64, NaN64]);
      Signal64 : constant F64x2 := From_Lanes ([SNaN64, SNaN64]);
      Number64 : constant F64x2 := From_Lanes ([1.0, 1.0]);
      Positive_Zero_First64 : constant F64x2 := From_Lanes ([0.0, Neg_Zero64]);
      Negative_Zero_First64 : constant F64x2 := From_Lanes ([Neg_Zero64, 0.0]);
      Quiet_Left64 : constant F64x2 := From_Lanes ([NaN64, 5.0]);
      Quiet_Right64 : constant F64x2 := From_Lanes ([5.0, NaN64]);
      Signal_Left64 : constant F64x2 := From_Lanes ([SNaN64, 5.0]);
      Signal_Right64 : constant F64x2 := From_Lanes ([5.0, SNaN64]);
   begin
      for Lane in Lane_Index_32x4 loop
         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Permute32_Map), Lane)) = F32_Bits (Extract (Slide32, Permute32_Selectors (Lane))) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Permute32_Map), Lane)) = F32_Bits (Extract (Slide32, Permute32_Selectors (Lane))), "F32 special lane permutation" & Lane'Image);
         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Two32_Right, Two32_Map_A), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Slide32 else Two32_Right), Lane)) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Two32_Right, Two32_Map_A), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Slide32 else Two32_Right), Lane)), "F32 special two-source permutation A" & Lane'Image);
         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Two32_Right, Two32_Map_B), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Two32_Right else Slide32), Lane)) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Two32_Right, Two32_Map_B), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Two32_Right else Slide32), Lane)), "F32 special two-source permutation B" & Lane'Image);
      end loop;
      for Pattern in Natural range 0 .. 15 loop
         declare
            Mask : constant Mask_32x4 := Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern));
            Packed : constant F32x4 := Reference_Compress_F32x4 (Slide32, Mask);
            Spread : constant F32x4 := Reference_Expand_F32x4 (Slide32, Mask);
         begin
            Check (Same (Compress (Slide32, Mask), Packed) and then Same (Backends.Native.Compress (Slide32, Mask), Packed), "F32 special compress" & Pattern'Image);
            Check (Same (Expand (Slide32, Mask), Spread) and then Same (Backends.Native.Expand (Slide32, Mask), Spread), "F32 special expand" & Pattern'Image);
         end;
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (F64_Bits (Extract (Permute_Lanes (Slide64_A, Permute64_Map), Lane)) = F64_Bits (Extract (Slide64_A, Permute64_Selectors (Lane))) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_A, Permute64_Map), Lane)) = F64_Bits (Extract (Slide64_A, Permute64_Selectors (Lane))) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_B, Permute64_Map), Lane)) = F64_Bits (Extract (Slide64_B, Permute64_Selectors (Lane))), "F64 special lane permutation" & Lane'Image);
         Check (F64_Bits (Extract (Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_A), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_A else Slide64_B), Lane)) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_A), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_A else Slide64_B), Lane)), "F64 special two-source permutation A" & Lane'Image);
         Check (F64_Bits (Extract (Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_B), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_B else Slide64_A), Lane)) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_B), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_B else Slide64_A), Lane)), "F64 special two-source permutation B" & Lane'Image);
      end loop;
      for Pattern in Natural range 0 .. 3 loop
         declare
            Mask : constant Mask_64x2 := Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern));
            Packed_A : constant F64x2 := Reference_Compress_F64x2 (Slide64_A, Mask);
            Spread_A : constant F64x2 := Reference_Expand_F64x2 (Slide64_A, Mask);
            Packed_B : constant F64x2 := Reference_Compress_F64x2 (Slide64_B, Mask);
            Spread_B : constant F64x2 := Reference_Expand_F64x2 (Slide64_B, Mask);
         begin
            Check (Same (Compress (Slide64_A, Mask), Packed_A) and then Same (Backends.Native.Compress (Slide64_A, Mask), Packed_A) and then Same (Compress (Slide64_B, Mask), Packed_B) and then Same (Backends.Native.Compress (Slide64_B, Mask), Packed_B), "F64 special compress" & Pattern'Image);
            Check (Same (Expand (Slide64_A, Mask), Spread_A) and then Same (Backends.Native.Expand (Slide64_A, Mask), Spread_A) and then Same (Expand (Slide64_B, Mask), Spread_B) and then Same (Backends.Native.Expand (Slide64_B, Mask), Spread_B), "F64 special expand" & Pattern'Image);
         end;
      end loop;
      for Slide in Natural range 0 .. 6 loop
         for Lane in Lane_Index_32x4 loop
            declare
               Expected_Low : constant Interfaces.Unsigned_32 := (if Slide < 4 and then Lane < 4 - Slide then F32_Bits (Extract (Slide32, Lane_Index_32x4 (Lane + Slide))) else 0);
               Expected_High : constant Interfaces.Unsigned_32 := (if Slide < 4 and then Lane >= Slide then F32_Bits (Extract (Slide32, Lane_Index_32x4 (Lane - Slide))) else 0);
            begin
               Check (F32_Bits (Extract (Slide_Lanes_Toward_Low (Slide32, Slide), Lane)) = Expected_Low and then F32_Bits (Extract (Backends.Native.Slide_Lanes_Toward_Low (Slide32, Slide), Lane)) = Expected_Low, "F32 special slide toward low" & Slide'Image & Lane'Image);
               Check (F32_Bits (Extract (Slide_Lanes_Toward_High (Slide32, Slide), Lane)) = Expected_High and then F32_Bits (Extract (Backends.Native.Slide_Lanes_Toward_High (Slide32, Slide), Lane)) = Expected_High, "F32 special slide toward high" & Slide'Image & Lane'Image);
            end;
         end loop;
      end loop;
      for Slide in Natural range 0 .. 4 loop
         for Lane in Lane_Index_64x2 loop
            for Source_Choice in Boolean loop
               declare
                  Source : constant F64x2 := (if Source_Choice then Slide64_A else Slide64_B);
                  Expected_Low : constant Interfaces.Unsigned_64 := (if Slide < 2 and then Lane < 2 - Slide then F64_Bits (Extract (Source, Lane_Index_64x2 (Lane + Slide))) else 0);
                  Expected_High : constant Interfaces.Unsigned_64 := (if Slide < 2 and then Lane >= Slide then F64_Bits (Extract (Source, Lane_Index_64x2 (Lane - Slide))) else 0);
               begin
                  Check (F64_Bits (Extract (Slide_Lanes_Toward_Low (Source, Slide), Lane)) = Expected_Low and then F64_Bits (Extract (Backends.Native.Slide_Lanes_Toward_Low (Source, Slide), Lane)) = Expected_Low, "F64 special slide toward low" & Slide'Image & Lane'Image);
                  Check (F64_Bits (Extract (Slide_Lanes_Toward_High (Source, Slide), Lane)) = Expected_High and then F64_Bits (Extract (Backends.Native.Slide_Lanes_Toward_High (Source, Slide), Lane)) = Expected_High, "F64 special slide toward high" & Slide'Image & Lane'Image);
               end;
            end loop;
         end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A32, B32)) = Flyology_SIMD.To_Bit_Mask (Unordered (A32, B32)), "F32 NaN unordered");
      Check (Extract (Backends.Native.Min_Number (A32, B32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A32, B32), 0) = 1.0, "F32 quiet NaN returns number");
      Check ((F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), B32), 0)) and 16#7FC0_0000#) = 16#7FC0_0000#, "F32 signaling NaN is quieted");
      Check (F32_Bits (Extract (Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Max_Number (A32, B32), 2)) = 0 and then F32_Bits (Extract (Min_Number (B32, A32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Max_Number (B32, A32), 2)) = 0 and then F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0 and then F32_Bits (Extract (Backends.Native.Min_Number (B32, A32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (B32, A32), 2)) = 0, "F32 signed zero operand orders");
      Check (Extract (Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Max_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number32, Quiet32), 0) = 1.0, "F32 quiet NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number32, Signal32), 0)), "F32 signaling NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Quiet32), 0)), "F32 two quiet NaNs");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Quiet32), 0)), "F32 signaling then quiet NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Signal32), 0)), "F32 quiet then signaling NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Signal32), 0)), "F32 two signaling NaNs");
      Check (Is_NaN (Extract (Add (A32, B32), 0)) and then Is_NaN (Extract (Backends.Native.Add (A32, B32), 0)), "F32 NaN addition");
      Check (Is_NaN (Extract (Subtract (A32, B32), 1)) and then Is_NaN (Extract (Backends.Native.Subtract (A32, B32), 1)), "F32 infinity subtraction");
      Check (F32_Bits (Extract (Multiply (A32, B32), 1)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Multiply (A32, B32), 1)) = 16#7F80_0000#, "F32 infinity multiplication");
      Check (F32_Bits (Extract (Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then Is_NaN (Extract (Divide (Numerator32, Zero32), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator32, Zero32), 1)), "F32 division edge cases");
      Check (Is_NaN (Reduce_Add (A32)) and then Is_NaN (Backends.Native.Reduce_Add (A32)), "F32 NaN reduction");
      Check (F32_Bits (Reduce_Min_Number (A32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Min_Number (A32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (A32)) = 16#7F80_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (A32)) = 16#7F80_0000#, "F32 min/max reduction NaN and signed zero");
      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal32)), "F32 signaling NaN reductions");
      Check (Reduce_Min_Number (Fold_Order32) = 3.0 and then Reduce_Max_Number (Fold_Order32) = 3.0 and then Backends.Native.Reduce_Min_Number (Fold_Order32) = 3.0 and then Backends.Native.Reduce_Max_Number (Fold_Order32) = 3.0, "F32 ascending fold order");
      Check (F32_Bits (Reduce_Min_Number (Positive_Zero_First32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (Positive_Zero_First32)) = 0 and then F32_Bits (Reduce_Min_Number (Negative_Zero_First32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (Negative_Zero_First32)) = 0 and then F32_Bits (Backends.Native.Reduce_Min_Number (Positive_Zero_First32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (Positive_Zero_First32)) = 0 and then F32_Bits (Backends.Native.Reduce_Min_Number (Negative_Zero_First32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (Negative_Zero_First32)) = 0, "F32 reduction signed-zero orders");
      Check (Reduce_Min_Number (Quiet_Left32) = 5.0 and then Reduce_Max_Number (Quiet_Left32) = 5.0 and then Reduce_Min_Number (Quiet_Right32) = 5.0 and then Reduce_Max_Number (Quiet_Right32) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Left32) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Left32) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Right32) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Right32) = 5.0, "F32 reduction quiet-NaN orders");
      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal_Left32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Left32)) and then Is_Quiet_NaN (Reduce_Min_Number (Signal_Right32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Right32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Left32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Left32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Right32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Right32)), "F32 reduction signaling-NaN orders");
      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A64, B64)) = Flyology_SIMD.To_Bit_Mask (Unordered (A64, B64)), "F64 NaN unordered");
      Check (Extract (Backends.Native.Min_Number (A64, B64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A64, B64), 0) = 1.0, "F64 quiet NaN returns number");
      Check ((F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64, 0.0]), B64), 0)) and 16#7FF8_0000_0000_0000#) = 16#7FF8_0000_0000_0000#, "F64 signaling NaN is quieted");
      Check (F64_Bits (Extract (Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Max_Number (A64, B64), 1)) = 0 and then F64_Bits (Extract (Min_Number (B64, A64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Max_Number (B64, A64), 1)) = 0 and then F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0 and then F64_Bits (Extract (Backends.Native.Min_Number (B64, A64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (B64, A64), 1)) = 0, "F64 signed zero operand orders");
      Check (Extract (Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Max_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number64, Quiet64), 0) = 1.0, "F64 quiet NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number64, Signal64), 0)), "F64 signaling NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Quiet64), 0)), "F64 two quiet NaNs");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Quiet64), 0)), "F64 signaling then quiet NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Signal64), 0)), "F64 quiet then signaling NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Signal64), 0)), "F64 two signaling NaNs");
      Check (Is_NaN (Extract (Add (A64, B64), 0)) and then Is_NaN (Extract (Backends.Native.Add (A64, B64), 0)), "F64 NaN addition");
      Check (Is_NaN (Extract (Subtract (Infinity64, Infinity64), 0)) and then Is_NaN (Extract (Backends.Native.Subtract (Infinity64, Infinity64), 0)), "F64 infinity subtraction");
      Check (F64_Bits (Extract (Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000#, "F64 infinity multiplication");
      Check (F64_Bits (Extract (Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then Is_NaN (Extract (Divide (Numerator64, Zero64), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator64, Zero64), 1)), "F64 division edge cases");
      Check (Is_NaN (Reduce_Add (A64)) and then Is_NaN (Backends.Native.Reduce_Add (A64)), "F64 NaN reduction");
      Check (F64_Bits (Reduce_Min_Number (A64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Min_Number (A64)) = 16#8000_0000_0000_0000# and then F64_Bits (Reduce_Max_Number (A64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Max_Number (A64)) = 16#8000_0000_0000_0000#, "F64 min/max reduction NaN and signed zero");
      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal64)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal64)), "F64 signaling NaN reductions");
      Check (F64_Bits (Reduce_Min_Number (Positive_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Reduce_Max_Number (Positive_Zero_First64)) = 0 and then F64_Bits (Reduce_Min_Number (Negative_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Reduce_Max_Number (Negative_Zero_First64)) = 0 and then F64_Bits (Backends.Native.Reduce_Min_Number (Positive_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Max_Number (Positive_Zero_First64)) = 0 and then F64_Bits (Backends.Native.Reduce_Min_Number (Negative_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Max_Number (Negative_Zero_First64)) = 0, "F64 reduction signed-zero orders");
      Check (Reduce_Min_Number (Quiet_Left64) = 5.0 and then Reduce_Max_Number (Quiet_Left64) = 5.0 and then Reduce_Min_Number (Quiet_Right64) = 5.0 and then Reduce_Max_Number (Quiet_Right64) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Left64) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Left64) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Right64) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Right64) = 5.0, "F64 reduction quiet-NaN orders");
      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal_Left64)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Left64)) and then Is_Quiet_NaN (Reduce_Min_Number (Signal_Right64)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Right64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Left64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Left64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Right64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Right64)), "F64 reduction signaling-NaN orders");
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
