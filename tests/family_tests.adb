with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Backends.Scalar;

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
   function Reference_Comparison_I8x16 (Left, Right : I8x16; Relation : Natural) return Interfaces.Unsigned_16 is
      Result : Interfaces.Unsigned_16 := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_16 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_I8x16;
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
   function Reference_Shift_Left_Logical_I8x16 (Value : I8x16; Count : Natural) return I8x16 is
      Result : I8x16 := Zero;
      Raw : Interfaces.Unsigned_8;
   begin
      for Lane in Lane_Index_8x16 loop
         Raw := I8x16_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I8x16 ((if Count >= 8 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_I8x16;
   function Reference_Shift_Right_Logical_I8x16 (Value : I8x16; Count : Natural) return I8x16 is
      Result : I8x16 := Zero;
      Raw : Interfaces.Unsigned_8;
   begin
      for Lane in Lane_Index_8x16 loop
         Raw := I8x16_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I8x16 ((if Count >= 8 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_I8x16;
   function Reference_Shift_Right_Arithmetic_I8x16 (Value : I8x16; Count : Natural) return I8x16 is
      Result : I8x16 := Zero;
      Raw, Shifted : Interfaces.Unsigned_8;
   begin
      for Lane in Lane_Index_8x16 loop
         Raw := I8x16_To_Bits (Extract (Value, Lane));
         if Count = 0 then Shifted := Raw;
         elsif Count >= 8 then Shifted := (if Extract (Value, Lane) < 0 then Interfaces.Unsigned_8'Last else 0);
         elsif Extract (Value, Lane) < 0 then Shifted := Interfaces.Shift_Right (Raw, Count) or Interfaces.Shift_Left (Interfaces.Unsigned_8'Last, 8 - Count);
         else Shifted := Interfaces.Shift_Right (Raw, Count); end if;
         Result := Replace (Result, Lane, Bits_To_I8x16 (Shifted));
      end loop;
      return Result;
   end Reference_Shift_Right_Arithmetic_I8x16;
   procedure Check_Complete_Memory_I8x16 (Values : Lane_Values_I8x16; Label_Text : String) is
      Value : constant I8x16 := From_Lanes (Values);
      Source : I8_Array (0 .. 17) := [others => I8 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : I8_Array (0 .. 17) := [others => I8 (17)];
      Aligned_Source : I8_Array (0 .. 15) := I8_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : I8_Array (0 .. 16) := [others => I8 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_8x16 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "I8x16 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "I8x16 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "I8x16 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => I8 (17)]; Scalar_Data := [others => I8 (17)]; Native_Data := [others => I8 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I8 := (if Index in 1 .. 16 then Values (Lane_Index_8x16 (Index - 1)) else I8 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I8x16 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => I8 (17)]; Scalar_Data := [others => I8 (17)]; Native_Data := [others => I8 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I8 := (if Index in 1 .. 16 then Values (Lane_Index_8x16 (Index - 1)) else I8 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I8x16 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => I8 (17)]; Scalar_Aligned := [others => I8 (17)]; Native_Aligned := [others => I8 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 16 then Values (Lane_Index_8x16 (Index)) else I8 (17)) and then Scalar_Aligned (Index) = (if Index < 16 then Values (Lane_Index_8x16 (Index)) else I8 (17)) and then Native_Aligned (Index) = (if Index < 16 then Values (Lane_Index_8x16 (Index)) else I8 (17)), "I8x16 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_I8x16;

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
      Maximum_Index_Data : I8_Array (Natural'Last .. Natural'Last) := [others => I8 (1)];
   begin
      Check_Complete_Memory_I8x16 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First, -1, 0, 1, I8'Last, I8'First], "I8x16 scalar lane construction");
      for Lane in Lane_Index_8x16 loop Check (Extract (I8x16'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "I8x16 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Splat (I8'Last), Lane) = I8'Last, "I8x16 maximum-value native splat" & Lane'Image); end loop;
      for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Splat (I8'First), Lane) = I8'First, "I8x16 minimum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I8x16 independent native lane construction");
      for Lane in Lane_Index_8x16 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I8x16 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I8x16 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "I8x16 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "I8x16 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) + I8x16_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) + I8x16_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) + I8x16_To_Bits (Extract (B, Lane))), "I8x16 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) - I8x16_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) - I8x16_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) - I8x16_To_Bits (Extract (B, Lane))), "I8x16 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) * I8x16_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) * I8x16_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (A, Lane)) * I8x16_To_Bits (Extract (B, Lane))), "I8x16 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I8x16 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I8x16 (A, Shift)), "I8x16 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I8x16 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I8x16 (A, Shift)), "I8x16 independent logical right shift" & Shift'Image);
         Check (Same (Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I8x16 (A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I8x16 (A, Shift)), "I8x16 independent arithmetic shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 8), Zero) and then Same (Shift_Right_Logical (A, 8), Zero), "I8x16 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I8x16 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I8x16 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I8x16 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I8x16 (A, Natural'Last)), "I8x16 maximum-count independent logical shifts");
      Check (Same (Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I8x16 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I8x16 (A, Natural'Last)), "I8x16 maximum-count independent arithmetic shift");
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I8x16 (Interfaces.Shift_Left (I8x16_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I8x16 (Interfaces.Shift_Right (I8x16_To_Bits (Extract (A, Lane)), 1)), "I8x16 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I8x16 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 8), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I8x16 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 18 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I8x16 native lane slides" & Slide'Image);
         for Lane in Lane_Index_8x16 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 16 and then Lane < 16 - Slide then Extract (A, Lane_Index_8x16 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 16 and then Lane < 16 - Slide then Extract (A, Lane_Index_8x16 (Lane + Slide)) else 0), "I8x16 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 16 and then Lane >= Slide then Extract (A, Lane_Index_8x16 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 16 and then Lane >= Slide then Extract (A, Lane_Index_8x16 (Lane - Slide)) else 0), "I8x16 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "I8x16 maximum-count lane slides");
      for Lane in Lane_Index_8x16 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_8x16 (15 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_8x16 (15 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_8x16 (15 - Lane)), "I8x16 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (Lane / 2)) else Extract (B, Lane_Index_8x16 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (Lane / 2)) else Extract (B, Lane_Index_8x16 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (Lane / 2)) else Extract (B, Lane_Index_8x16 (Lane / 2))), "I8x16 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (B, Lane_Index_8x16 (8 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (B, Lane_Index_8x16 (8 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (B, Lane_Index_8x16 (8 + Lane / 2))), "I8x16 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8)))), "I8x16 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 8 then Extract (A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (B, Lane_Index_8x16 (2 * (Lane - 8) + 1))), "I8x16 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 0), "I8x16 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_I8x16 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_I8x16 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_I8x16 (A, B, 1), "I8x16 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 2), "I8x16 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_I8x16 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_I8x16 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_I8x16 (A, B, 3), "I8x16 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_I8x16 (A, B, 4), "I8x16 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I8x16 scalar and native select");
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
         for Lane in Lane_Index_8x16 loop Check (Backends.Native.Test (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "I8x16 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B)), "I8x16 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Compress_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Compress_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))), "I8x16 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Expand_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern))), Reference_Expand_I8x16 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)))), "I8x16 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_8x16 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I8x16 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_8x16'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16'Last))) = Interfaces.Unsigned_16 (2 ** 16 - 1), "I8x16 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I8x16 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I8x16 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I8x16 (A), "I8x16 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I8x16 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_I8x16 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I8x16 (A), "I8x16 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I8x16 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_I8x16 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I8x16 (A), "I8x16 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I8x16 full memory");
      for Lane in Lane_Index_8x16 loop Check (Data (1 + Lane) = Extract (A, Lane), "I8x16 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I8x16 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I8x16 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "I8x16 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "I8x16 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I8x16 aligned memory");
      for N in Lane_Count_8x16 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_8x16 (Index - 2)) else 0), "I8x16 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "I8x16 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : I8_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "I8x16 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "I8x16 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = I8 (1), "I8x16 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "I8x16 randomized independent native lane construction");
            for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "I8x16 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I8x16 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I8x16 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I8x16 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I8x16 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_I8x16 (R_A, R_B, 4), "I8x16 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I8x16 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I8x16 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I8x16 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I8x16 (R_A, Shift)), "I8x16 randomized independent logical shifts");
            Check (Same (Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I8x16 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I8x16 (R_A, Shift)), "I8x16 randomized independent arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I8x16 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I8x16 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I8x16 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I8x16 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I8x16 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I8x16 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I8x16 (R_A, Mask_From_Bit_Mask (Pattern))), "I8x16 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I8x16 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_I8x16 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_I8x16 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I8x16 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_I8x16 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_I8x16 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I8x16 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I8x16 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I8x16 (R_A), "I8x16 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I8x16 randomized native full memory");
            Check_Complete_Memory_I8x16 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "I8x16 randomized native partial store");
            for Lane in Lane_Index_8x16 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "I8x16 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_8x16 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_8x16 (15 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_8x16 (15 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_8x16 (15 - Lane)), "I8x16 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_8x16 (Lane / 2)) else Extract (R_B, Lane_Index_8x16 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_8x16 (Lane / 2)) else Extract (R_B, Lane_Index_8x16 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_8x16 (Lane / 2)) else Extract (R_B, Lane_Index_8x16 (Lane / 2))), "I8x16 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (R_B, Lane_Index_8x16 (8 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (R_B, Lane_Index_8x16 (8 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_8x16 (8 + Lane / 2)) else Extract (R_B, Lane_Index_8x16 (8 + Lane / 2))), "I8x16 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 8 then Extract (R_A, Lane_Index_8x16 (2 * Lane)) else Extract (R_B, Lane_Index_8x16 (2 * (Lane - 8)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 8 then Extract (R_A, Lane_Index_8x16 (2 * Lane)) else Extract (R_B, Lane_Index_8x16 (2 * (Lane - 8)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 8 then Extract (R_A, Lane_Index_8x16 (2 * Lane)) else Extract (R_B, Lane_Index_8x16 (2 * (Lane - 8)))), "I8x16 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 8 then Extract (R_A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (R_B, Lane_Index_8x16 (2 * (Lane - 8) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 8 then Extract (R_A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (R_B, Lane_Index_8x16 (2 * (Lane - 8) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 8 then Extract (R_A, Lane_Index_8x16 (2 * Lane + 1)) else Extract (R_B, Lane_Index_8x16 (2 * (Lane - 8) + 1))), "I8x16 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I8x16 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_8x16 ((Iteration * 3 + Lane * 5) mod 16)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_8x16 ((Iteration * 3 + Lane * 5) mod 16)), "I8x16 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I8x16 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 16 and then Lane < 16 - Slide then R_Lanes (Lane_Index_8x16 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 16 and then Lane >= Slide then R_Lanes (Lane_Index_8x16 (Lane - Slide)) else 0), "I8x16 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) + I8x16_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) + I8x16_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) + I8x16_To_Bits (Extract (R_B, Lane))), "I8x16 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) - I8x16_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) - I8x16_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) - I8x16_To_Bits (Extract (R_B, Lane))), "I8x16 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) * I8x16_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) * I8x16_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I8x16 (I8x16_To_Bits (Extract (R_A, Lane)) * I8x16_To_Bits (Extract (R_B, Lane))), "I8x16 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I8x16 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I8x16 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I8x16 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I8x16 (Extract (R_A, Lane), Extract (R_B, Lane)), "I8x16 independent scalar and native saturation oracle" & Lane'Image);
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
   function Reference_Comparison_U16x8 (Left, Right : U16x8; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_16x8 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_U16x8;
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
   function Reference_Shift_Left_Logical_U16x8 (Value : U16x8; Count : Natural) return U16x8 is
      Result : U16x8 := Zero;
      Raw : Interfaces.Unsigned_16;
   begin
      for Lane in Lane_Index_16x8 loop
         Raw := Interfaces.Unsigned_16 (Extract (Value, Lane));
         Result := Replace (Result, Lane, U16 ((if Count >= 16 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_U16x8;
   function Reference_Shift_Right_Logical_U16x8 (Value : U16x8; Count : Natural) return U16x8 is
      Result : U16x8 := Zero;
      Raw : Interfaces.Unsigned_16;
   begin
      for Lane in Lane_Index_16x8 loop
         Raw := Interfaces.Unsigned_16 (Extract (Value, Lane));
         Result := Replace (Result, Lane, U16 ((if Count >= 16 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_U16x8;
   procedure Check_Complete_Memory_U16x8 (Values : Lane_Values_U16x8; Label_Text : String) is
      Value : constant U16x8 := From_Lanes (Values);
      Source : U16_Array (0 .. 9) := [others => U16 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : U16_Array (0 .. 9) := [others => U16 (17)];
      Aligned_Source : U16_Array (0 .. 7) := U16_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : U16_Array (0 .. 8) := [others => U16 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_16x8 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "U16x8 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "U16x8 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "U16x8 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => U16 (17)]; Scalar_Data := [others => U16 (17)]; Native_Data := [others => U16 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant U16 := (if Index in 1 .. 8 then Values (Lane_Index_16x8 (Index - 1)) else U16 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "U16x8 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => U16 (17)]; Scalar_Data := [others => U16 (17)]; Native_Data := [others => U16 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant U16 := (if Index in 1 .. 8 then Values (Lane_Index_16x8 (Index - 1)) else U16 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "U16x8 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => U16 (17)]; Scalar_Aligned := [others => U16 (17)]; Native_Aligned := [others => U16 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 8 then Values (Lane_Index_16x8 (Index)) else U16 (17)) and then Scalar_Aligned (Index) = (if Index < 8 then Values (Lane_Index_16x8 (Index)) else U16 (17)) and then Native_Aligned (Index) = (if Index < 8 then Values (Lane_Index_16x8 (Index)) else U16 (17)), "U16x8 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_U16x8;

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
      Maximum_Index_Data : U16_Array (Natural'Last .. Natural'Last) := [others => U16 (1)];
   begin
      Check_Complete_Memory_U16x8 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [0, 1, U16'Last, 2 ** (15), 17, 0, 1, U16'Last], "U16x8 scalar lane construction");
      for Lane in Lane_Index_16x8 loop Check (Extract (U16x8'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "U16x8 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Splat (U16'Last), Lane) = U16'Last, "U16x8 maximum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "U16x8 independent native lane construction");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "U16x8 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "U16x8 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "U16x8 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "U16x8 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane), "U16x8 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane), "U16x8 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane), "U16x8 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_U16x8 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_U16x8 (A, Shift)), "U16x8 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_U16x8 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_U16x8 (A, Shift)), "U16x8 independent logical right shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 16), Zero) and then Same (Shift_Right_Logical (A, 16), Zero), "U16x8 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_U16x8 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_U16x8 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_U16x8 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_U16x8 (A, Natural'Last)), "U16x8 maximum-count independent logical shifts");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U16 (Interfaces.Shift_Left (Interfaces.Unsigned_16 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U16 (Interfaces.Shift_Right (Interfaces.Unsigned_16 (Extract (A, Lane)), 1)), "U16x8 independent logical shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 10 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "U16x8 native lane slides" & Slide'Image);
         for Lane in Lane_Index_16x8 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then Extract (A, Lane_Index_16x8 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then Extract (A, Lane_Index_16x8 (Lane + Slide)) else 0), "U16x8 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then Extract (A, Lane_Index_16x8 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then Extract (A, Lane_Index_16x8 (Lane - Slide)) else 0), "U16x8 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "U16x8 maximum-count lane slides");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)), "U16x8 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))), "U16x8 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))), "U16x8 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))), "U16x8 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))), "U16x8 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 0), "U16x8 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_U16x8 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_U16x8 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_U16x8 (A, B, 1), "U16x8 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 2), "U16x8 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_U16x8 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_U16x8 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_U16x8 (A, B, 3), "U16x8 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_U16x8 (A, B, 4), "U16x8 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U16x8 scalar and native select");
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
         for Lane in Lane_Index_16x8 loop Check (Backends.Native.Test (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "U16x8 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U16x8 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U16x8 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U16x8 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "U16x8 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "U16x8 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_U16x8 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U16x8 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U16x8 (A), "U16x8 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_U16x8 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_U16x8 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_U16x8 (A), "U16x8 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_U16x8 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_U16x8 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_U16x8 (A), "U16x8 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U16x8 full memory");
      for Lane in Lane_Index_16x8 loop Check (Data (1 + Lane) = Extract (A, Lane), "U16x8 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "U16x8 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "U16x8 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "U16x8 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "U16x8 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "U16x8 aligned memory");
      for N in Lane_Count_16x8 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_16x8 (Index - 2)) else 0), "U16x8 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "U16x8 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : U16_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "U16x8 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "U16x8 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = U16 (1), "U16x8 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "U16x8 randomized independent native lane construction");
            for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "U16x8 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U16x8 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "U16x8 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "U16x8 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "U16x8 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_U16x8 (R_A, R_B, 4), "U16x8 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_U16x8 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_U16x8 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_U16x8 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_U16x8 (R_A, Shift)), "U16x8 randomized independent logical shifts");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "U16x8 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "U16x8 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "U16x8 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "U16x8 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "U16x8 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_U16x8 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_U16x8 (R_A, Mask_From_Bit_Mask (Pattern))), "U16x8 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U16x8 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_U16x8 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_U16x8 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U16x8 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_U16x8 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_U16x8 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U16x8 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_U16x8 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_U16x8 (R_A), "U16x8 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "U16x8 randomized native full memory");
            Check_Complete_Memory_U16x8 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "U16x8 randomized native partial store");
            for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "U16x8 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_16x8 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_16x8 (7 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_16x8 (7 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_16x8 (7 - Lane)), "U16x8 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (Lane / 2)) else Extract (R_B, Lane_Index_16x8 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (Lane / 2)) else Extract (R_B, Lane_Index_16x8 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (Lane / 2)) else Extract (R_B, Lane_Index_16x8 (Lane / 2))), "U16x8 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (R_B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (R_B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (R_B, Lane_Index_16x8 (4 + Lane / 2))), "U16x8 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4)))), "U16x8 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4) + 1))), "U16x8 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "U16x8 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)), "U16x8 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "U16x8 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then R_Lanes (Lane_Index_16x8 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then R_Lanes (Lane_Index_16x8 (Lane - Slide)) else 0), "U16x8 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane), "U16x8 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane), "U16x8 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane), "U16x8 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U16x8 (Extract (R_A, Lane), Extract (R_B, Lane)), "U16x8 independent scalar and native saturation oracle" & Lane'Image);
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
   function Reference_Comparison_I16x8 (Left, Right : I16x8; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_16x8 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_I16x8;
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
   function Reference_Shift_Left_Logical_I16x8 (Value : I16x8; Count : Natural) return I16x8 is
      Result : I16x8 := Zero;
      Raw : Interfaces.Unsigned_16;
   begin
      for Lane in Lane_Index_16x8 loop
         Raw := I16x8_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I16x8 ((if Count >= 16 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_I16x8;
   function Reference_Shift_Right_Logical_I16x8 (Value : I16x8; Count : Natural) return I16x8 is
      Result : I16x8 := Zero;
      Raw : Interfaces.Unsigned_16;
   begin
      for Lane in Lane_Index_16x8 loop
         Raw := I16x8_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I16x8 ((if Count >= 16 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_I16x8;
   function Reference_Shift_Right_Arithmetic_I16x8 (Value : I16x8; Count : Natural) return I16x8 is
      Result : I16x8 := Zero;
      Raw, Shifted : Interfaces.Unsigned_16;
   begin
      for Lane in Lane_Index_16x8 loop
         Raw := I16x8_To_Bits (Extract (Value, Lane));
         if Count = 0 then Shifted := Raw;
         elsif Count >= 16 then Shifted := (if Extract (Value, Lane) < 0 then Interfaces.Unsigned_16'Last else 0);
         elsif Extract (Value, Lane) < 0 then Shifted := Interfaces.Shift_Right (Raw, Count) or Interfaces.Shift_Left (Interfaces.Unsigned_16'Last, 16 - Count);
         else Shifted := Interfaces.Shift_Right (Raw, Count); end if;
         Result := Replace (Result, Lane, Bits_To_I16x8 (Shifted));
      end loop;
      return Result;
   end Reference_Shift_Right_Arithmetic_I16x8;
   procedure Check_Complete_Memory_I16x8 (Values : Lane_Values_I16x8; Label_Text : String) is
      Value : constant I16x8 := From_Lanes (Values);
      Source : I16_Array (0 .. 9) := [others => I16 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : I16_Array (0 .. 9) := [others => I16 (17)];
      Aligned_Source : I16_Array (0 .. 7) := I16_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : I16_Array (0 .. 8) := [others => I16 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_16x8 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "I16x8 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "I16x8 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "I16x8 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => I16 (17)]; Scalar_Data := [others => I16 (17)]; Native_Data := [others => I16 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I16 := (if Index in 1 .. 8 then Values (Lane_Index_16x8 (Index - 1)) else I16 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I16x8 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => I16 (17)]; Scalar_Data := [others => I16 (17)]; Native_Data := [others => I16 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I16 := (if Index in 1 .. 8 then Values (Lane_Index_16x8 (Index - 1)) else I16 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I16x8 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => I16 (17)]; Scalar_Aligned := [others => I16 (17)]; Native_Aligned := [others => I16 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 8 then Values (Lane_Index_16x8 (Index)) else I16 (17)) and then Scalar_Aligned (Index) = (if Index < 8 then Values (Lane_Index_16x8 (Index)) else I16 (17)) and then Native_Aligned (Index) = (if Index < 8 then Values (Lane_Index_16x8 (Index)) else I16 (17)), "I16x8 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_I16x8;

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
      Maximum_Index_Data : I16_Array (Natural'Last .. Natural'Last) := [others => I16 (1)];
   begin
      Check_Complete_Memory_I16x8 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [I16'First, -1, 0, 1, I16'Last, I16'First, -1, 0], "I16x8 scalar lane construction");
      for Lane in Lane_Index_16x8 loop Check (Extract (I16x8'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "I16x8 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Splat (I16'Last), Lane) = I16'Last, "I16x8 maximum-value native splat" & Lane'Image); end loop;
      for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Splat (I16'First), Lane) = I16'First, "I16x8 minimum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I16x8 independent native lane construction");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I16x8 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I16x8 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "I16x8 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "I16x8 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) + I16x8_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) + I16x8_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) + I16x8_To_Bits (Extract (B, Lane))), "I16x8 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) - I16x8_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) - I16x8_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) - I16x8_To_Bits (Extract (B, Lane))), "I16x8 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) * I16x8_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) * I16x8_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (A, Lane)) * I16x8_To_Bits (Extract (B, Lane))), "I16x8 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I16x8 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I16x8 (A, Shift)), "I16x8 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I16x8 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I16x8 (A, Shift)), "I16x8 independent logical right shift" & Shift'Image);
         Check (Same (Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I16x8 (A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I16x8 (A, Shift)), "I16x8 independent arithmetic shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 16), Zero) and then Same (Shift_Right_Logical (A, 16), Zero), "I16x8 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I16x8 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I16x8 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I16x8 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I16x8 (A, Natural'Last)), "I16x8 maximum-count independent logical shifts");
      Check (Same (Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I16x8 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I16x8 (A, Natural'Last)), "I16x8 maximum-count independent arithmetic shift");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I16x8 (Interfaces.Shift_Left (I16x8_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I16x8 (Interfaces.Shift_Right (I16x8_To_Bits (Extract (A, Lane)), 1)), "I16x8 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I16x8 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 16), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I16x8 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 10 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I16x8 native lane slides" & Slide'Image);
         for Lane in Lane_Index_16x8 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then Extract (A, Lane_Index_16x8 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then Extract (A, Lane_Index_16x8 (Lane + Slide)) else 0), "I16x8 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then Extract (A, Lane_Index_16x8 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then Extract (A, Lane_Index_16x8 (Lane - Slide)) else 0), "I16x8 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "I16x8 maximum-count lane slides");
      for Lane in Lane_Index_16x8 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_16x8 (7 - Lane)), "I16x8 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (Lane / 2)) else Extract (B, Lane_Index_16x8 (Lane / 2))), "I16x8 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (B, Lane_Index_16x8 (4 + Lane / 2))), "I16x8 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4)))), "I16x8 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 4 then Extract (A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (B, Lane_Index_16x8 (2 * (Lane - 4) + 1))), "I16x8 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 0), "I16x8 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_I16x8 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_I16x8 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_I16x8 (A, B, 1), "I16x8 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 2), "I16x8 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_I16x8 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_I16x8 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_I16x8 (A, B, 3), "I16x8 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_I16x8 (A, B, 4), "I16x8 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I16x8 scalar and native select");
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
         for Lane in Lane_Index_16x8 loop Check (Backends.Native.Test (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "I16x8 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I16x8 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I16x8 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I16x8 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I16x8 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_16x8 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I16x8 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_16x8'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 8 - 1), "I16x8 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I16x8 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I16x8 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I16x8 (A), "I16x8 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I16x8 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_I16x8 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I16x8 (A), "I16x8 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I16x8 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_I16x8 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I16x8 (A), "I16x8 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I16x8 full memory");
      for Lane in Lane_Index_16x8 loop Check (Data (1 + Lane) = Extract (A, Lane), "I16x8 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I16x8 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I16x8 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "I16x8 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "I16x8 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I16x8 aligned memory");
      for N in Lane_Count_16x8 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_16x8 (Index - 2)) else 0), "I16x8 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "I16x8 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : I16_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "I16x8 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "I16x8 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = I16 (1), "I16x8 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "I16x8 randomized independent native lane construction");
            for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "I16x8 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I16x8 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I16x8 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I16x8 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I16x8 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_I16x8 (R_A, R_B, 4), "I16x8 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I16x8 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I16x8 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I16x8 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I16x8 (R_A, Shift)), "I16x8 randomized independent logical shifts");
            Check (Same (Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I16x8 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I16x8 (R_A, Shift)), "I16x8 randomized independent arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I16x8 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I16x8 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I16x8 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I16x8 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I16x8 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I16x8 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I16x8 (R_A, Mask_From_Bit_Mask (Pattern))), "I16x8 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I16x8 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_I16x8 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_I16x8 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I16x8 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_I16x8 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_I16x8 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I16x8 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I16x8 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I16x8 (R_A), "I16x8 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I16x8 randomized native full memory");
            Check_Complete_Memory_I16x8 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "I16x8 randomized native partial store");
            for Lane in Lane_Index_16x8 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "I16x8 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_16x8 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_16x8 (7 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_16x8 (7 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_16x8 (7 - Lane)), "I16x8 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (Lane / 2)) else Extract (R_B, Lane_Index_16x8 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (Lane / 2)) else Extract (R_B, Lane_Index_16x8 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (Lane / 2)) else Extract (R_B, Lane_Index_16x8 (Lane / 2))), "I16x8 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (R_B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (R_B, Lane_Index_16x8 (4 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_16x8 (4 + Lane / 2)) else Extract (R_B, Lane_Index_16x8 (4 + Lane / 2))), "I16x8 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4)))), "I16x8 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 4 then Extract (R_A, Lane_Index_16x8 (2 * Lane + 1)) else Extract (R_B, Lane_Index_16x8 (2 * (Lane - 4) + 1))), "I16x8 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I16x8 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_16x8 ((Iteration * 3 + Lane * 5) mod 8)), "I16x8 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I16x8 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 8 and then Lane < 8 - Slide then R_Lanes (Lane_Index_16x8 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 8 and then Lane >= Slide then R_Lanes (Lane_Index_16x8 (Lane - Slide)) else 0), "I16x8 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) + I16x8_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) + I16x8_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) + I16x8_To_Bits (Extract (R_B, Lane))), "I16x8 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) - I16x8_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) - I16x8_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) - I16x8_To_Bits (Extract (R_B, Lane))), "I16x8 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) * I16x8_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) * I16x8_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I16x8 (I16x8_To_Bits (Extract (R_A, Lane)) * I16x8_To_Bits (Extract (R_B, Lane))), "I16x8 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I16x8 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I16x8 (Extract (R_A, Lane), Extract (R_B, Lane)), "I16x8 independent scalar and native saturation oracle" & Lane'Image);
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
   function Reference_Comparison_U32x4 (Left, Right : U32x4; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_32x4 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_U32x4;
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
   function Reference_Shift_Left_Logical_U32x4 (Value : U32x4; Count : Natural) return U32x4 is
      Result : U32x4 := Zero;
      Raw : Interfaces.Unsigned_32;
   begin
      for Lane in Lane_Index_32x4 loop
         Raw := Interfaces.Unsigned_32 (Extract (Value, Lane));
         Result := Replace (Result, Lane, U32 ((if Count >= 32 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_U32x4;
   function Reference_Shift_Right_Logical_U32x4 (Value : U32x4; Count : Natural) return U32x4 is
      Result : U32x4 := Zero;
      Raw : Interfaces.Unsigned_32;
   begin
      for Lane in Lane_Index_32x4 loop
         Raw := Interfaces.Unsigned_32 (Extract (Value, Lane));
         Result := Replace (Result, Lane, U32 ((if Count >= 32 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_U32x4;
   procedure Check_Complete_Memory_U32x4 (Values : Lane_Values_U32x4; Label_Text : String) is
      Value : constant U32x4 := From_Lanes (Values);
      Source : U32_Array (0 .. 5) := [others => U32 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : U32_Array (0 .. 5) := [others => U32 (17)];
      Aligned_Source : U32_Array (0 .. 3) := U32_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : U32_Array (0 .. 4) := [others => U32 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_32x4 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "U32x4 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "U32x4 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "U32x4 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => U32 (17)]; Scalar_Data := [others => U32 (17)]; Native_Data := [others => U32 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant U32 := (if Index in 1 .. 4 then Values (Lane_Index_32x4 (Index - 1)) else U32 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "U32x4 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => U32 (17)]; Scalar_Data := [others => U32 (17)]; Native_Data := [others => U32 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant U32 := (if Index in 1 .. 4 then Values (Lane_Index_32x4 (Index - 1)) else U32 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "U32x4 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => U32 (17)]; Scalar_Aligned := [others => U32 (17)]; Native_Aligned := [others => U32 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 4 then Values (Lane_Index_32x4 (Index)) else U32 (17)) and then Scalar_Aligned (Index) = (if Index < 4 then Values (Lane_Index_32x4 (Index)) else U32 (17)) and then Native_Aligned (Index) = (if Index < 4 then Values (Lane_Index_32x4 (Index)) else U32 (17)), "U32x4 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_U32x4;

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
      Maximum_Index_Data : U32_Array (Natural'Last .. Natural'Last) := [others => U32 (1)];
      Saturation_Left : constant U32x4 := From_Lanes ([U32'Last, 0, U32'Last, 0]);
      Saturation_Right : constant U32x4 := From_Lanes ([1, 1, U32'Last, U32'Last]);
      Saturating_Add_Expected : constant Lane_Values_U32x4 := [U32'Last, 1, U32'Last, U32'Last];
      Saturating_Subtract_Expected : constant Lane_Values_U32x4 := [U32'Last - 1, 0, 0, 0];
   begin
      Check_Complete_Memory_U32x4 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [0, 1, U32'Last, 2 ** (31)], "U32x4 scalar lane construction");
      for Lane in Lane_Index_32x4 loop Check (Extract (U32x4'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "U32x4 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Splat (U32'Last), Lane) = U32'Last, "U32x4 maximum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "U32x4 independent native lane construction");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "U32x4 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "U32x4 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "U32x4 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "U32x4 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane), "U32x4 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane), "U32x4 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane), "U32x4 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Add_Expected and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Subtract_Expected, "U32x4 independent fixed saturation boundaries");
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_U32x4 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_U32x4 (A, Shift)), "U32x4 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_U32x4 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_U32x4 (A, Shift)), "U32x4 independent logical right shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 32), Zero) and then Same (Shift_Right_Logical (A, 32), Zero), "U32x4 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_U32x4 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_U32x4 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_U32x4 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_U32x4 (A, Natural'Last)), "U32x4 maximum-count independent logical shifts");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U32 (Interfaces.Shift_Left (Interfaces.Unsigned_32 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U32 (Interfaces.Shift_Right (Interfaces.Unsigned_32 (Extract (A, Lane)), 1)), "U32x4 independent logical shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 6 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "U32x4 native lane slides" & Slide'Image);
         for Lane in Lane_Index_32x4 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then Extract (A, Lane_Index_32x4 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then Extract (A, Lane_Index_32x4 (Lane + Slide)) else 0), "U32x4 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then Extract (A, Lane_Index_32x4 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then Extract (A, Lane_Index_32x4 (Lane - Slide)) else 0), "U32x4 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "U32x4 maximum-count lane slides");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)), "U32x4 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))), "U32x4 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))), "U32x4 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))), "U32x4 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "U32x4 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 0), "U32x4 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_U32x4 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_U32x4 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_U32x4 (A, B, 1), "U32x4 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 2), "U32x4 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_U32x4 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_U32x4 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_U32x4 (A, B, 3), "U32x4 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_U32x4 (A, B, 4), "U32x4 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U32x4 scalar and native select");
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
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "U32x4 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U32x4 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U32x4 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U32x4 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "U32x4 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "U32x4 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_U32x4 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U32x4 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U32x4 (A), "U32x4 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_U32x4 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_U32x4 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_U32x4 (A), "U32x4 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_U32x4 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_U32x4 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_U32x4 (A), "U32x4 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U32x4 full memory");
      for Lane in Lane_Index_32x4 loop Check (Data (1 + Lane) = Extract (A, Lane), "U32x4 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "U32x4 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "U32x4 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "U32x4 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "U32x4 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "U32x4 aligned memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_32x4 (Index - 2)) else 0), "U32x4 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "U32x4 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : U32_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "U32x4 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "U32x4 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = U32 (1), "U32x4 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "U32x4 randomized independent native lane construction");
            for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "U32x4 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U32x4 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "U32x4 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "U32x4 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "U32x4 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_U32x4 (R_A, R_B, 4), "U32x4 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_U32x4 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_U32x4 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_U32x4 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_U32x4 (R_A, Shift)), "U32x4 randomized independent logical shifts");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "U32x4 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "U32x4 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "U32x4 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "U32x4 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "U32x4 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_U32x4 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_U32x4 (R_A, Mask_From_Bit_Mask (Pattern))), "U32x4 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U32x4 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_U32x4 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_U32x4 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U32x4 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_U32x4 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_U32x4 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U32x4 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_U32x4 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_U32x4 (R_A), "U32x4 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "U32x4 randomized native full memory");
            Check_Complete_Memory_U32x4 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "U32x4 randomized native partial store");
            for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "U32x4 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_32x4 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_32x4 (3 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_32x4 (3 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_32x4 (3 - Lane)), "U32x4 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (Lane / 2)) else Extract (R_B, Lane_Index_32x4 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (Lane / 2)) else Extract (R_B, Lane_Index_32x4 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (Lane / 2)) else Extract (R_B, Lane_Index_32x4 (Lane / 2))), "U32x4 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (R_B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (R_B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (R_B, Lane_Index_32x4 (2 + Lane / 2))), "U32x4 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2)))), "U32x4 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "U32x4 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "U32x4 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)), "U32x4 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "U32x4 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then R_Lanes (Lane_Index_32x4 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then R_Lanes (Lane_Index_32x4 (Lane - Slide)) else 0), "U32x4 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane), "U32x4 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane), "U32x4 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane), "U32x4 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U32x4 (Extract (R_A, Lane), Extract (R_B, Lane)), "U32x4 independent scalar and native saturation oracle" & Lane'Image);
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
   function Reference_Comparison_I32x4 (Left, Right : I32x4; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_32x4 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_I32x4;
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
   function Reference_Shift_Left_Logical_I32x4 (Value : I32x4; Count : Natural) return I32x4 is
      Result : I32x4 := Zero;
      Raw : Interfaces.Unsigned_32;
   begin
      for Lane in Lane_Index_32x4 loop
         Raw := I32x4_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I32x4 ((if Count >= 32 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_I32x4;
   function Reference_Shift_Right_Logical_I32x4 (Value : I32x4; Count : Natural) return I32x4 is
      Result : I32x4 := Zero;
      Raw : Interfaces.Unsigned_32;
   begin
      for Lane in Lane_Index_32x4 loop
         Raw := I32x4_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I32x4 ((if Count >= 32 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_I32x4;
   function Reference_Shift_Right_Arithmetic_I32x4 (Value : I32x4; Count : Natural) return I32x4 is
      Result : I32x4 := Zero;
      Raw, Shifted : Interfaces.Unsigned_32;
   begin
      for Lane in Lane_Index_32x4 loop
         Raw := I32x4_To_Bits (Extract (Value, Lane));
         if Count = 0 then Shifted := Raw;
         elsif Count >= 32 then Shifted := (if Extract (Value, Lane) < 0 then Interfaces.Unsigned_32'Last else 0);
         elsif Extract (Value, Lane) < 0 then Shifted := Interfaces.Shift_Right (Raw, Count) or Interfaces.Shift_Left (Interfaces.Unsigned_32'Last, 32 - Count);
         else Shifted := Interfaces.Shift_Right (Raw, Count); end if;
         Result := Replace (Result, Lane, Bits_To_I32x4 (Shifted));
      end loop;
      return Result;
   end Reference_Shift_Right_Arithmetic_I32x4;
   procedure Check_Complete_Memory_I32x4 (Values : Lane_Values_I32x4; Label_Text : String) is
      Value : constant I32x4 := From_Lanes (Values);
      Source : I32_Array (0 .. 5) := [others => I32 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : I32_Array (0 .. 5) := [others => I32 (17)];
      Aligned_Source : I32_Array (0 .. 3) := I32_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : I32_Array (0 .. 4) := [others => I32 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_32x4 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "I32x4 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "I32x4 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "I32x4 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => I32 (17)]; Scalar_Data := [others => I32 (17)]; Native_Data := [others => I32 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I32 := (if Index in 1 .. 4 then Values (Lane_Index_32x4 (Index - 1)) else I32 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I32x4 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => I32 (17)]; Scalar_Data := [others => I32 (17)]; Native_Data := [others => I32 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I32 := (if Index in 1 .. 4 then Values (Lane_Index_32x4 (Index - 1)) else I32 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I32x4 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => I32 (17)]; Scalar_Aligned := [others => I32 (17)]; Native_Aligned := [others => I32 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 4 then Values (Lane_Index_32x4 (Index)) else I32 (17)) and then Scalar_Aligned (Index) = (if Index < 4 then Values (Lane_Index_32x4 (Index)) else I32 (17)) and then Native_Aligned (Index) = (if Index < 4 then Values (Lane_Index_32x4 (Index)) else I32 (17)), "I32x4 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_I32x4;

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
      Maximum_Index_Data : I32_Array (Natural'Last .. Natural'Last) := [others => I32 (1)];
      Saturation_Left : constant I32x4 := From_Lanes ([I32'Last, I32'First, I32'Last, I32'First]);
      Saturation_Right : constant I32x4 := From_Lanes ([1, -1, -1, 1]);
      Saturating_Add_Expected : constant Lane_Values_I32x4 := [I32'Last, I32'First, I32'Last - 1, I32'First + 1];
      Saturating_Subtract_Expected : constant Lane_Values_I32x4 := [I32'Last - 1, I32'First + 1, I32'Last, I32'First];
   begin
      Check_Complete_Memory_I32x4 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [I32'First, -1, 0, 1], "I32x4 scalar lane construction");
      for Lane in Lane_Index_32x4 loop Check (Extract (I32x4'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "I32x4 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Splat (I32'Last), Lane) = I32'Last, "I32x4 maximum-value native splat" & Lane'Image); end loop;
      for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Splat (I32'First), Lane) = I32'First, "I32x4 minimum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I32x4 independent native lane construction");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I32x4 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I32x4 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "I32x4 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "I32x4 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) + I32x4_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) + I32x4_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) + I32x4_To_Bits (Extract (B, Lane))), "I32x4 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) - I32x4_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) - I32x4_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) - I32x4_To_Bits (Extract (B, Lane))), "I32x4 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) * I32x4_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) * I32x4_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (A, Lane)) * I32x4_To_Bits (Extract (B, Lane))), "I32x4 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Add_Expected and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Subtract_Expected, "I32x4 independent fixed saturation boundaries");
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I32x4 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I32x4 (A, Shift)), "I32x4 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I32x4 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I32x4 (A, Shift)), "I32x4 independent logical right shift" & Shift'Image);
         Check (Same (Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I32x4 (A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I32x4 (A, Shift)), "I32x4 independent arithmetic shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 32), Zero) and then Same (Shift_Right_Logical (A, 32), Zero), "I32x4 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I32x4 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I32x4 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I32x4 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I32x4 (A, Natural'Last)), "I32x4 maximum-count independent logical shifts");
      Check (Same (Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I32x4 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I32x4 (A, Natural'Last)), "I32x4 maximum-count independent arithmetic shift");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I32x4 (Interfaces.Shift_Left (I32x4_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I32x4 (Interfaces.Shift_Right (I32x4_To_Bits (Extract (A, Lane)), 1)), "I32x4 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I32x4 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 32), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I32x4 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 6 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I32x4 native lane slides" & Slide'Image);
         for Lane in Lane_Index_32x4 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then Extract (A, Lane_Index_32x4 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then Extract (A, Lane_Index_32x4 (Lane + Slide)) else 0), "I32x4 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then Extract (A, Lane_Index_32x4 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then Extract (A, Lane_Index_32x4 (Lane - Slide)) else 0), "I32x4 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "I32x4 maximum-count lane slides");
      for Lane in Lane_Index_32x4 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)), "I32x4 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))), "I32x4 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))), "I32x4 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))), "I32x4 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "I32x4 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 0), "I32x4 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_I32x4 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_I32x4 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_I32x4 (A, B, 1), "I32x4 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 2), "I32x4 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_I32x4 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_I32x4 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_I32x4 (A, B, 3), "I32x4 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_I32x4 (A, B, 4), "I32x4 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I32x4 scalar and native select");
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
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "I32x4 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I32x4 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I32x4 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I32x4 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I32x4 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "I32x4 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I32x4 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I32x4 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I32x4 (A), "I32x4 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I32x4 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_I32x4 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I32x4 (A), "I32x4 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I32x4 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_I32x4 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I32x4 (A), "I32x4 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I32x4 full memory");
      for Lane in Lane_Index_32x4 loop Check (Data (1 + Lane) = Extract (A, Lane), "I32x4 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I32x4 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I32x4 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "I32x4 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "I32x4 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I32x4 aligned memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_32x4 (Index - 2)) else 0), "I32x4 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "I32x4 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : I32_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "I32x4 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "I32x4 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = I32 (1), "I32x4 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "I32x4 randomized independent native lane construction");
            for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "I32x4 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I32x4 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I32x4 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I32x4 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I32x4 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_I32x4 (R_A, R_B, 4), "I32x4 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I32x4 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I32x4 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I32x4 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I32x4 (R_A, Shift)), "I32x4 randomized independent logical shifts");
            Check (Same (Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I32x4 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I32x4 (R_A, Shift)), "I32x4 randomized independent arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I32x4 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I32x4 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I32x4 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I32x4 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I32x4 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I32x4 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I32x4 (R_A, Mask_From_Bit_Mask (Pattern))), "I32x4 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I32x4 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_I32x4 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_I32x4 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I32x4 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_I32x4 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_I32x4 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I32x4 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I32x4 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I32x4 (R_A), "I32x4 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I32x4 randomized native full memory");
            Check_Complete_Memory_I32x4 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "I32x4 randomized native partial store");
            for Lane in Lane_Index_32x4 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "I32x4 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_32x4 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_32x4 (3 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_32x4 (3 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_32x4 (3 - Lane)), "I32x4 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (Lane / 2)) else Extract (R_B, Lane_Index_32x4 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (Lane / 2)) else Extract (R_B, Lane_Index_32x4 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (Lane / 2)) else Extract (R_B, Lane_Index_32x4 (Lane / 2))), "I32x4 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (R_B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (R_B, Lane_Index_32x4 (2 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (R_B, Lane_Index_32x4 (2 + Lane / 2))), "I32x4 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2)))), "I32x4 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 2 then Extract (R_A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (R_B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "I32x4 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I32x4 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)), "I32x4 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I32x4 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 4 and then Lane < 4 - Slide then R_Lanes (Lane_Index_32x4 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 4 and then Lane >= Slide then R_Lanes (Lane_Index_32x4 (Lane - Slide)) else 0), "I32x4 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) + I32x4_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) + I32x4_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) + I32x4_To_Bits (Extract (R_B, Lane))), "I32x4 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) - I32x4_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) - I32x4_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) - I32x4_To_Bits (Extract (R_B, Lane))), "I32x4 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) * I32x4_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) * I32x4_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I32x4 (I32x4_To_Bits (Extract (R_A, Lane)) * I32x4_To_Bits (Extract (R_B, Lane))), "I32x4 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I32x4 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I32x4 (Extract (R_A, Lane), Extract (R_B, Lane)), "I32x4 independent scalar and native saturation oracle" & Lane'Image);
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
   function Reference_Comparison_U64x2 (Left, Right : U64x2; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_64x2 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_U64x2;
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
   function Reference_Shift_Left_Logical_U64x2 (Value : U64x2; Count : Natural) return U64x2 is
      Result : U64x2 := Zero;
      Raw : Interfaces.Unsigned_64;
   begin
      for Lane in Lane_Index_64x2 loop
         Raw := Interfaces.Unsigned_64 (Extract (Value, Lane));
         Result := Replace (Result, Lane, U64 ((if Count >= 64 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_U64x2;
   function Reference_Shift_Right_Logical_U64x2 (Value : U64x2; Count : Natural) return U64x2 is
      Result : U64x2 := Zero;
      Raw : Interfaces.Unsigned_64;
   begin
      for Lane in Lane_Index_64x2 loop
         Raw := Interfaces.Unsigned_64 (Extract (Value, Lane));
         Result := Replace (Result, Lane, U64 ((if Count >= 64 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_U64x2;
   procedure Check_Complete_Memory_U64x2 (Values : Lane_Values_U64x2; Label_Text : String) is
      Value : constant U64x2 := From_Lanes (Values);
      Source : U64_Array (0 .. 3) := [others => U64 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : U64_Array (0 .. 3) := [others => U64 (17)];
      Aligned_Source : U64_Array (0 .. 1) := U64_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : U64_Array (0 .. 2) := [others => U64 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_64x2 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "U64x2 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "U64x2 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "U64x2 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => U64 (17)]; Scalar_Data := [others => U64 (17)]; Native_Data := [others => U64 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant U64 := (if Index in 1 .. 2 then Values (Lane_Index_64x2 (Index - 1)) else U64 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "U64x2 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => U64 (17)]; Scalar_Data := [others => U64 (17)]; Native_Data := [others => U64 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant U64 := (if Index in 1 .. 2 then Values (Lane_Index_64x2 (Index - 1)) else U64 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "U64x2 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => U64 (17)]; Scalar_Aligned := [others => U64 (17)]; Native_Aligned := [others => U64 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 2 then Values (Lane_Index_64x2 (Index)) else U64 (17)) and then Scalar_Aligned (Index) = (if Index < 2 then Values (Lane_Index_64x2 (Index)) else U64 (17)) and then Native_Aligned (Index) = (if Index < 2 then Values (Lane_Index_64x2 (Index)) else U64 (17)), "U64x2 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_U64x2;

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
      Maximum_Index_Data : U64_Array (Natural'Last .. Natural'Last) := [others => U64 (1)];
      Saturation_Left : constant U64x2 := From_Lanes ([U64'Last, 0]);
      Saturation_Right : constant U64x2 := From_Lanes ([1, 1]);
      Saturating_Add_Expected : constant Lane_Values_U64x2 := [U64'Last, 1];
      Saturating_Subtract_Expected : constant Lane_Values_U64x2 := [U64'Last - 1, 0];
      Reduction_Wrap : constant U64x2 := From_Lanes ([U64'Last, 2]);
      Reduction_Order : constant U64x2 := From_Lanes ([16#7FFF_FFFF_FFFF_FFFF#, 16#8000_0000_0000_0000#]);
      Multiply_Edge_Left : constant U64x2 := From_Lanes ([16#FFFF_FFFF_0000_0001#, 16#8000_0001_0000_0001#]);
      Multiply_Edge_Right : constant U64x2 := From_Lanes ([16#0000_0002_FFFF_FFFF#, 16#FFFF_FFFF_0000_0003#]);
      Multiply_Edge_Expected : constant Lane_Values_U64x2 := [16#0000_0003_FFFF_FFFF#, 16#8000_0002_0000_0003#];
   begin
      Check_Complete_Memory_U64x2 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [0, 1], "U64x2 scalar lane construction");
      for Lane in Lane_Index_64x2 loop Check (Extract (U64x2'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "U64x2 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Splat (U64'Last), Lane) = U64'Last, "U64x2 maximum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "U64x2 independent native lane construction");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "U64x2 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "U64x2 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "U64x2 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "U64x2 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Extract (A, Lane) + Extract (B, Lane), "U64x2 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Extract (A, Lane) - Extract (B, Lane), "U64x2 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Extract (A, Lane) * Extract (B, Lane), "U64x2 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
      Check (To_Lanes (Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected and then Backends.Scalar.To_Lanes (Backends.Scalar.Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected and then Backends.Native.To_Lanes (Backends.Native.Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected, "U64x2 independent root, Scalar, and Native 32-bit partial-product boundaries");
      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Add_Expected and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Subtract_Expected, "U64x2 independent fixed saturation boundaries");
      Check (Reduce_Add_Wrap (Reduction_Wrap) = 1 and then Backends.Scalar.Reduce_Add_Wrap (Reduction_Wrap) = 1 and then Backends.Native.Reduce_Add_Wrap (Reduction_Wrap) = 1, "U64x2 independent wrapping reduction boundary");
      Check (Reduce_Min (Reduction_Order) = 16#7FFF_FFFF_FFFF_FFFF# and then Backends.Scalar.Reduce_Min (Reduction_Order) = 16#7FFF_FFFF_FFFF_FFFF# and then Backends.Native.Reduce_Min (Reduction_Order) = 16#7FFF_FFFF_FFFF_FFFF# and then Reduce_Max (Reduction_Order) = 16#8000_0000_0000_0000# and then Backends.Scalar.Reduce_Max (Reduction_Order) = 16#8000_0000_0000_0000# and then Backends.Native.Reduce_Max (Reduction_Order) = 16#8000_0000_0000_0000#, "U64x2 independent top-bit reduction boundary");
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_U64x2 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_U64x2 (A, Shift)), "U64x2 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_U64x2 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_U64x2 (A, Shift)), "U64x2 independent logical right shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 64), Zero) and then Same (Shift_Right_Logical (A, 64), Zero), "U64x2 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_U64x2 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_U64x2 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_U64x2 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_U64x2 (A, Natural'Last)), "U64x2 maximum-count independent logical shifts");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = U64 (Interfaces.Shift_Left (Interfaces.Unsigned_64 (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = U64 (Interfaces.Shift_Right (Interfaces.Unsigned_64 (Extract (A, Lane)), 1)), "U64x2 independent logical shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 4 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "U64x2 native lane slides" & Slide'Image);
         for Lane in Lane_Index_64x2 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then Extract (A, Lane_Index_64x2 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then Extract (A, Lane_Index_64x2 (Lane + Slide)) else 0), "U64x2 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then Extract (A, Lane_Index_64x2 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then Extract (A, Lane_Index_64x2 (Lane - Slide)) else 0), "U64x2 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "U64x2 maximum-count lane slides");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)), "U64x2 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))), "U64x2 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))), "U64x2 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))), "U64x2 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "U64x2 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 0), "U64x2 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_U64x2 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_U64x2 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_U64x2 (A, B, 1), "U64x2 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 2), "U64x2 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_U64x2 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_U64x2 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_U64x2 (A, B, 3), "U64x2 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_U64x2 (A, B, 4), "U64x2 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "U64x2 scalar and native select");
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
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "U64x2 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "U64x2 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U64x2 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_U64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "U64x2 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "U64x2 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "U64x2 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_U64x2 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U64x2 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_U64x2 (A), "U64x2 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_U64x2 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_U64x2 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_U64x2 (A), "U64x2 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_U64x2 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_U64x2 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_U64x2 (A), "U64x2 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "U64x2 full memory");
      for Lane in Lane_Index_64x2 loop Check (Data (1 + Lane) = Extract (A, Lane), "U64x2 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "U64x2 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "U64x2 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "U64x2 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "U64x2 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "U64x2 aligned memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_64x2 (Index - 2)) else 0), "U64x2 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "U64x2 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : U64_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "U64x2 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "U64x2 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = U64 (1), "U64x2 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "U64x2 randomized independent native lane construction");
            for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "U64x2 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "U64x2 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "U64x2 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "U64x2 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "U64x2 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_U64x2 (R_A, R_B, 4), "U64x2 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_U64x2 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_U64x2 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_U64x2 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_U64x2 (R_A, Shift)), "U64x2 randomized independent logical shifts");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "U64x2 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "U64x2 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "U64x2 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "U64x2 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "U64x2 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_U64x2 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_U64x2 (R_A, Mask_From_Bit_Mask (Pattern))), "U64x2 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U64x2 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_U64x2 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_U64x2 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U64x2 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_U64x2 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_U64x2 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_U64x2 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_U64x2 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_U64x2 (R_A), "U64x2 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "U64x2 randomized native full memory");
            Check_Complete_Memory_U64x2 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "U64x2 randomized native partial store");
            for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "U64x2 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_64x2 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_64x2 (1 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_64x2 (1 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_64x2 (1 - Lane)), "U64x2 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (Lane / 2)) else Extract (R_B, Lane_Index_64x2 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (Lane / 2)) else Extract (R_B, Lane_Index_64x2 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (Lane / 2)) else Extract (R_B, Lane_Index_64x2 (Lane / 2))), "U64x2 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (R_B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (R_B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (R_B, Lane_Index_64x2 (1 + Lane / 2))), "U64x2 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1)))), "U64x2 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "U64x2 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "U64x2 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)), "U64x2 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "U64x2 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then R_Lanes (Lane_Index_64x2 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then R_Lanes (Lane_Index_64x2 (Lane - Slide)) else 0), "U64x2 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) + Extract (R_B, Lane), "U64x2 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) - Extract (R_B, Lane), "U64x2 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Extract (R_A, Lane) * Extract (R_B, Lane), "U64x2 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_U64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_U64x2 (Extract (R_A, Lane), Extract (R_B, Lane)), "U64x2 independent scalar and native saturation oracle" & Lane'Image);
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
   function Reference_Comparison_I64x2 (Left, Right : I64x2; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_64x2 loop
         if (case Relation is
                when 0 => Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => Extract (Left, Lane) > Extract (Right, Lane),
                when others => Extract (Left, Lane) >= Extract (Right, Lane)) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
      end loop;
      return Result;
   end Reference_Comparison_I64x2;
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
   function Reference_Shift_Left_Logical_I64x2 (Value : I64x2; Count : Natural) return I64x2 is
      Result : I64x2 := Zero;
      Raw : Interfaces.Unsigned_64;
   begin
      for Lane in Lane_Index_64x2 loop
         Raw := I64x2_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I64x2 ((if Count >= 64 then 0 else Interfaces.Shift_Left (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Left_Logical_I64x2;
   function Reference_Shift_Right_Logical_I64x2 (Value : I64x2; Count : Natural) return I64x2 is
      Result : I64x2 := Zero;
      Raw : Interfaces.Unsigned_64;
   begin
      for Lane in Lane_Index_64x2 loop
         Raw := I64x2_To_Bits (Extract (Value, Lane));
         Result := Replace (Result, Lane, Bits_To_I64x2 ((if Count >= 64 then 0 else Interfaces.Shift_Right (Raw, Count))));
      end loop;
      return Result;
   end Reference_Shift_Right_Logical_I64x2;
   function Reference_Shift_Right_Arithmetic_I64x2 (Value : I64x2; Count : Natural) return I64x2 is
      Result : I64x2 := Zero;
      Raw, Shifted : Interfaces.Unsigned_64;
   begin
      for Lane in Lane_Index_64x2 loop
         Raw := I64x2_To_Bits (Extract (Value, Lane));
         if Count = 0 then Shifted := Raw;
         elsif Count >= 64 then Shifted := (if Extract (Value, Lane) < 0 then Interfaces.Unsigned_64'Last else 0);
         elsif Extract (Value, Lane) < 0 then Shifted := Interfaces.Shift_Right (Raw, Count) or Interfaces.Shift_Left (Interfaces.Unsigned_64'Last, 64 - Count);
         else Shifted := Interfaces.Shift_Right (Raw, Count); end if;
         Result := Replace (Result, Lane, Bits_To_I64x2 (Shifted));
      end loop;
      return Result;
   end Reference_Shift_Right_Arithmetic_I64x2;
   procedure Check_Complete_Memory_I64x2 (Values : Lane_Values_I64x2; Label_Text : String) is
      Value : constant I64x2 := From_Lanes (Values);
      Source : I64_Array (0 .. 3) := [others => I64 (17)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : I64_Array (0 .. 3) := [others => I64 (17)];
      Aligned_Source : I64_Array (0 .. 1) := I64_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : I64_Array (0 .. 2) := [others => I64 (17)] with Alignment => 16;
   begin
      for Lane in Lane_Index_64x2 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load (Source, 1), Lane) = Values (Lane), "I64x2 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Unaligned (Source, 1), Lane) = Values (Lane), "I64x2 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane) and then Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane) = Values (Lane), "I64x2 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => I64 (17)]; Scalar_Data := [others => I64 (17)]; Native_Data := [others => I64 (17)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I64 := (if Index in 1 .. 2 then Values (Lane_Index_64x2 (Index - 1)) else I64 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I64x2 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => I64 (17)]; Scalar_Data := [others => I64 (17)]; Native_Data := [others => I64 (17)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant I64 := (if Index in 1 .. 2 then Values (Lane_Index_64x2 (Index - 1)) else I64 (17)); begin
            Check (Root_Data (Index) = Expected and then Scalar_Data (Index) = Expected and then Native_Data (Index) = Expected, "I64x2 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => I64 (17)]; Scalar_Aligned := [others => I64 (17)]; Native_Aligned := [others => I64 (17)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Root_Aligned (Index) = (if Index < 2 then Values (Lane_Index_64x2 (Index)) else I64 (17)) and then Scalar_Aligned (Index) = (if Index < 2 then Values (Lane_Index_64x2 (Index)) else I64 (17)) and then Native_Aligned (Index) = (if Index < 2 then Values (Lane_Index_64x2 (Index)) else I64 (17)), "I64x2 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_I64x2;

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
      Maximum_Index_Data : I64_Array (Natural'Last .. Natural'Last) := [others => I64 (1)];
      Saturation_Left : constant I64x2 := From_Lanes ([I64'Last, I64'First]);
      Saturation_Right : constant I64x2 := From_Lanes ([1, -1]);
      Saturating_Add_Expected : constant Lane_Values_I64x2 := [I64'Last, I64'First];
      Saturating_Subtract_Expected : constant Lane_Values_I64x2 := [I64'Last - 1, I64'First + 1];
      Saturation_Left_2 : constant I64x2 := Saturation_Left;
      Saturation_Right_2 : constant I64x2 := From_Lanes ([-1, 1]);
      Saturating_Add_Expected_2 : constant Lane_Values_I64x2 := [I64'Last - 1, I64'First + 1];
      Saturating_Subtract_Expected_2 : constant Lane_Values_I64x2 := [I64'Last, I64'First];
      Reduction_Order : constant I64x2 := From_Lanes ([Bits_To_I64x2 (16#0000_0001_FFFF_FFFF#), Bits_To_I64x2 (16#0000_0001_0000_0000#)]);
      Multiply_Edge_Left : constant I64x2 := From_Lanes ([Bits_To_I64x2 (16#8000_0000_0000_0000#), Bits_To_I64x2 (16#7FFF_FFFF_0000_0001#)]);
      Multiply_Edge_Right : constant I64x2 := From_Lanes ([Bits_To_I64x2 (16#FFFF_FFFF_FFFF_FFFF#), Bits_To_I64x2 (16#FFFF_FFFE_0000_0003#)]);
      Multiply_Edge_Expected : constant Lane_Values_I64x2 := [Bits_To_I64x2 (16#8000_0000_0000_0000#), Bits_To_I64x2 (16#7FFF_FFFB_0000_0003#)];
   begin
      Check_Complete_Memory_I64x2 (To_Lanes (A), " fixed");
      Check (To_Lanes (A) = [I64'First, -1], "I64x2 scalar lane construction");
      for Lane in Lane_Index_64x2 loop Check (Extract (I64x2'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), "I64x2 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Splat (I64'Last), Lane) = I64'Last, "I64x2 maximum-value native splat" & Lane'Image); end loop;
      for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Splat (I64'First), Lane) = I64'First, "I64x2 minimum-value native splat" & Lane'Image); end loop;
      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), "I64x2 independent native lane construction");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (A, Lane) = To_Lanes (A) (Lane), "I64x2 scalar extract" & Lane'Image);
         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), "I64x2 scalar replace" & Lane'Image);
         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), "I64x2 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), "I64x2 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Add_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) + I64x2_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) + I64x2_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) + I64x2_To_Bits (Extract (B, Lane))), "I64x2 independent fixed root, Scalar, and Native add oracle" & Lane'Image);
         Check (Extract (Subtract_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) - I64x2_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) - I64x2_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) - I64x2_To_Bits (Extract (B, Lane))), "I64x2 independent fixed root, Scalar, and Native subtract oracle" & Lane'Image);
         Check (Extract (Multiply_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) * I64x2_To_Bits (Extract (B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) * I64x2_To_Bits (Extract (B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (A, B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (A, Lane)) * I64x2_To_Bits (Extract (B, Lane))), "I64x2 independent fixed root, Scalar, and Native multiply oracle" & Lane'Image);
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
      Check (To_Lanes (Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected and then Backends.Scalar.To_Lanes (Backends.Scalar.Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected and then Backends.Native.To_Lanes (Backends.Native.Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected, "I64x2 independent root, Scalar, and Native 32-bit partial-product boundaries");
      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Add_Expected and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Subtract_Expected, "I64x2 independent fixed saturation boundaries");
      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left_2, Saturation_Right_2)) = Saturating_Add_Expected_2 and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left_2, Saturation_Right_2)) = Saturating_Subtract_Expected_2, "I64x2 opposite fixed saturation boundaries");
      Check (Reduce_Min (Reduction_Order) = Bits_To_I64x2 (16#0000_0001_0000_0000#) and then Backends.Scalar.Reduce_Min (Reduction_Order) = Bits_To_I64x2 (16#0000_0001_0000_0000#) and then Backends.Native.Reduce_Min (Reduction_Order) = Bits_To_I64x2 (16#0000_0001_0000_0000#) and then Reduce_Max (Reduction_Order) = Bits_To_I64x2 (16#0000_0001_FFFF_FFFF#) and then Backends.Scalar.Reduce_Max (Reduction_Order) = Bits_To_I64x2 (16#0000_0001_FFFF_FFFF#) and then Backends.Native.Reduce_Max (Reduction_Order) = Bits_To_I64x2 (16#0000_0001_FFFF_FFFF#), "I64x2 independent equal-high-word reduction boundary");
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
         Check (Same (Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I64x2 (A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (A, Shift), Reference_Shift_Left_Logical_I64x2 (A, Shift)), "I64x2 independent logical left shift" & Shift'Image);
         Check (Same (Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I64x2 (A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (A, Shift), Reference_Shift_Right_Logical_I64x2 (A, Shift)), "I64x2 independent logical right shift" & Shift'Image);
         Check (Same (Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (A, Shift)), "I64x2 independent arithmetic shift" & Shift'Image);
      end loop;
      Check (Same (Shift_Left_Logical (A, 64), Zero) and then Same (Shift_Right_Logical (A, 64), Zero), "I64x2 independent oversized logical shifts");
      Check (Same (Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I64x2 (A, Natural'Last)) and then Same (Backends.Native.Shift_Left_Logical (A, Natural'Last), Reference_Shift_Left_Logical_I64x2 (A, Natural'Last)) and then Same (Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I64x2 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Logical (A, Natural'Last), Reference_Shift_Right_Logical_I64x2 (A, Natural'Last)), "I64x2 maximum-count independent logical shifts");
      Check (Same (Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I64x2 (A, Natural'Last)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Natural'Last), Reference_Shift_Right_Arithmetic_I64x2 (A, Natural'Last)), "I64x2 maximum-count independent arithmetic shift");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Shift_Left_Logical (A, 1), Lane) = Bits_To_I64x2 (Interfaces.Shift_Left (I64x2_To_Bits (Extract (A, Lane)), 1)) and then Extract (Shift_Right_Logical (A, 1), Lane) = Bits_To_I64x2 (Interfaces.Shift_Right (I64x2_To_Bits (Extract (A, Lane)), 1)), "I64x2 independent logical shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = (if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2)), "I64x2 independent arithmetic shift" & Lane'Image);
         Check (Extract (Shift_Right_Arithmetic (A, 64), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), "I64x2 independent oversized arithmetic shift" & Lane'Image);
      end loop;
      for Slide in Natural range 0 .. 4 loop
         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), "I64x2 native lane slides" & Slide'Image);
         for Lane in Lane_Index_64x2 loop
            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then Extract (A, Lane_Index_64x2 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then Extract (A, Lane_Index_64x2 (Lane + Slide)) else 0), "I64x2 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then Extract (A, Lane_Index_64x2 (Lane - Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then Extract (A, Lane_Index_64x2 (Lane - Slide)) else 0), "I64x2 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "I64x2 maximum-count lane slides");
      for Lane in Lane_Index_64x2 loop
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)), "I64x2 independent root, Scalar, and Native reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))), "I64x2 independent root, Scalar, and Native interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))), "I64x2 independent root, Scalar, and Native interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))), "I64x2 independent root, Scalar, and Native deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "I64x2 independent root, Scalar, and Native deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 0), "I64x2 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_I64x2 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_I64x2 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_I64x2 (A, B, 1), "I64x2 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 2), "I64x2 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_I64x2 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_I64x2 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_I64x2 (A, B, 3), "I64x2 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_I64x2 (A, B, 4), "I64x2 independent root, Scalar, and Native Greater_Equal");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "I64x2 scalar and native select");
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
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "I64x2 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "I64x2 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I64x2 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_I64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "I64x2 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), "I64x2 independent root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "I64x2 native masks unused storage bits");
      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_I64x2 (A) and then Backends.Scalar.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I64x2 (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_I64x2 (A), "I64x2 independent reduce add");
      Check (Reduce_Min (A) = Reference_Reduce_Min_I64x2 (A) and then Backends.Scalar.Reduce_Min (A) = Reference_Reduce_Min_I64x2 (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_I64x2 (A), "I64x2 independent reduce min");
      Check (Reduce_Max (A) = Reference_Reduce_Max_I64x2 (A) and then Backends.Scalar.Reduce_Max (A) = Reference_Reduce_Max_I64x2 (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_I64x2 (A), "I64x2 independent reduce max");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "I64x2 full memory");
      for Lane in Lane_Index_64x2 loop Check (Data (1 + Lane) = Extract (A, Lane), "I64x2 independent full store" & Lane'Image); end loop;
      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "I64x2 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "I64x2 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "I64x2 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "I64x2 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "I64x2 aligned memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0]; Reference := [others => 0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_64x2 (Index - 2)) else 0), "I64x2 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), "I64x2 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : I64_Array (1 .. N) := [others => 0];
         begin
            for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, "I64x2 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, "I64x2 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Maximum_Index_Data (Natural'Last) = I64 (1), "I64x2 maximum-index zero-count partial store");
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
            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, "I64x2 randomized independent native lane construction");
            for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), "I64x2 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), "I64x2 randomized arithmetic");
            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), "I64x2 randomized native saturation");
            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), "I64x2 randomized native bitwise");
            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), "I64x2 randomized native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_I64x2 (R_A, R_B, 4), "I64x2 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I64x2 (R_A, Shift)) and then Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Reference_Shift_Left_Logical_I64x2 (R_A, Shift)) and then Same (Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I64x2 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Reference_Shift_Right_Logical_I64x2 (R_A, Shift)), "I64x2 randomized independent logical shifts");
            Check (Same (Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (R_A, Shift)), "I64x2 randomized independent arithmetic shift");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "I64x2 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "I64x2 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "I64x2 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "I64x2 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "I64x2 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_I64x2 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_I64x2 (R_A, Mask_From_Bit_Mask (Pattern))), "I64x2 randomized native compression");
            Check (Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I64x2 (R_A) and then Reduce_Min (R_A) = Reference_Reduce_Min_I64x2 (R_A) and then Reduce_Max (R_A) = Reference_Reduce_Max_I64x2 (R_A) and then Backends.Scalar.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I64x2 (R_A) and then Backends.Scalar.Reduce_Min (R_A) = Reference_Reduce_Min_I64x2 (R_A) and then Backends.Scalar.Reduce_Max (R_A) = Reference_Reduce_Max_I64x2 (R_A) and then Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_I64x2 (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_I64x2 (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_I64x2 (R_A), "I64x2 randomized root, scalar, and native reductions");
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "I64x2 randomized native full memory");
            Check_Complete_Memory_I64x2 (R_Lanes, " random" & Iteration'Image);
            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "I64x2 randomized native partial store");
            for Lane in Lane_Index_64x2 loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), "I64x2 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_64x2 loop
               Check (Extract (Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_64x2 (1 - Lane)) and then Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_64x2 (1 - Lane)) and then Backends.Native.Extract (Backends.Native.Reverse_Lanes (R_A), Lane) = R_Lanes (Lane_Index_64x2 (1 - Lane)), "I64x2 randomized independent root, Scalar, and Native reverse" & Lane'Image);
               Check (Extract (Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (Lane / 2)) else Extract (R_B, Lane_Index_64x2 (Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (Lane / 2)) else Extract (R_B, Lane_Index_64x2 (Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_Low (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (Lane / 2)) else Extract (R_B, Lane_Index_64x2 (Lane / 2))), "I64x2 randomized independent root, Scalar, and Native interleave low" & Lane'Image);
               Check (Extract (Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (R_B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Scalar.Extract (Backends.Scalar.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (R_B, Lane_Index_64x2 (1 + Lane / 2))) and then Backends.Native.Extract (Backends.Native.Interleave_High (R_A, R_B), Lane) = (if Lane mod 2 = 0 then Extract (R_A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (R_B, Lane_Index_64x2 (1 + Lane / 2))), "I64x2 randomized independent root, Scalar, and Native interleave high" & Lane'Image);
               Check (Extract (Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1)))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Even (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1)))), "I64x2 randomized independent root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Extract (Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1) + 1))) and then Backends.Native.Extract (Backends.Native.Deinterleave_Odd (R_A, R_B), Lane) = (if Lane < 1 then Extract (R_A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (R_B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "I64x2 randomized independent root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), "I64x2 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)) and then Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)), "I64x2 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "I64x2 randomized native lane access" & Lane'Image);
               Check (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane) = (if Slide < 2 and then Lane < 2 - Slide then R_Lanes (Lane_Index_64x2 (Lane + Slide)) else 0) and then Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane) = (if Slide < 2 and then Lane >= Slide then R_Lanes (Lane_Index_64x2 (Lane - Slide)) else 0), "I64x2 randomized independent native lane slides" & Lane'Image);
               Check (Extract (Add_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) + I64x2_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Add_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) + I64x2_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Add_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) + I64x2_To_Bits (Extract (R_B, Lane))), "I64x2 independent root, Scalar, and Native add oracle" & Lane'Image);
               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) - I64x2_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) - I64x2_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Subtract_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) - I64x2_To_Bits (Extract (R_B, Lane))), "I64x2 independent root, Scalar, and Native subtract oracle" & Lane'Image);
               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) * I64x2_To_Bits (Extract (R_B, Lane))) and then Backends.Scalar.Extract (Backends.Scalar.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) * I64x2_To_Bits (Extract (R_B, Lane))) and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = Bits_To_I64x2 (I64x2_To_Bits (Extract (R_A, Lane)) * I64x2_To_Bits (Extract (R_B, Lane))), "I64x2 independent root, Scalar, and Native multiply oracle" & Lane'Image);
               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_I64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I64x2 (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_I64x2 (Extract (R_A, Lane), Extract (R_B, Lane)), "I64x2 independent scalar and native saturation oracle" & Lane'Image);
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
   function Value_From_Bits_F32x4 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, F32);
   function Same (Left, Right : F32x4) return Boolean is
      L : constant Lane_Values_F32x4 := To_Lanes (Left);
      R : constant Lane_Values_F32x4 := To_Lanes (Right);
   begin
      for Lane in Lane_Index_32x4 loop
         if Bits_F32x4 (L (Lane)) /= Bits_F32x4 (R (Lane)) then return False; end if;
      end loop;
      return True;
   end Same;
   procedure Check_Complete_Memory_F32x4 (Values : Lane_Values_F32x4; Label_Text : String) is
      Value : constant F32x4 := From_Lanes (Values);
      Source : F32_Array (0 .. 5) := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : F32_Array (0 .. 5) := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
      Aligned_Source : F32_Array (0 .. 3) := F32_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : F32_Array (0 .. 4) := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)] with Alignment => 16;
   begin
      for Lane in Lane_Index_32x4 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (Load (Source, 1), Lane)) = Bits_F32x4 (Values (Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Load (Source, 1), Lane)) = Bits_F32x4 (Values (Lane)) and then Bits_F32x4 (Extract (Backends.Native.Load (Source, 1), Lane)) = Bits_F32x4 (Values (Lane)), "F32x4 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (Load_Unaligned (Source, 1), Lane)) = Bits_F32x4 (Values (Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane)) = Bits_F32x4 (Values (Lane)) and then Bits_F32x4 (Extract (Backends.Native.Load_Unaligned (Source, 1), Lane)) = Bits_F32x4 (Values (Lane)), "F32x4 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (Load_Aligned (Aligned_Source, 0), Lane)) = Bits_F32x4 (Values (Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane)) = Bits_F32x4 (Values (Lane)) and then Bits_F32x4 (Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane)) = Bits_F32x4 (Values (Lane)), "F32x4 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)]; Scalar_Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)]; Native_Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant F32 := (if Index in 1 .. 4 then Values (Lane_Index_32x4 (Index - 1)) else Value_From_Bits_F32x4 (16#7FC0_0055#)); begin
            Check (Bits_F32x4 (Root_Data (Index)) = Bits_F32x4 (Expected) and then Bits_F32x4 (Scalar_Data (Index)) = Bits_F32x4 (Expected) and then Bits_F32x4 (Native_Data (Index)) = Bits_F32x4 (Expected), "F32x4 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)]; Scalar_Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)]; Native_Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant F32 := (if Index in 1 .. 4 then Values (Lane_Index_32x4 (Index - 1)) else Value_From_Bits_F32x4 (16#7FC0_0055#)); begin
            Check (Bits_F32x4 (Root_Data (Index)) = Bits_F32x4 (Expected) and then Bits_F32x4 (Scalar_Data (Index)) = Bits_F32x4 (Expected) and then Bits_F32x4 (Native_Data (Index)) = Bits_F32x4 (Expected), "F32x4 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)]; Scalar_Aligned := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)]; Native_Aligned := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Bits_F32x4 (Root_Aligned (Index)) = Bits_F32x4 ((if Index < 4 then Values (Lane_Index_32x4 (Index)) else Value_From_Bits_F32x4 (16#7FC0_0055#))) and then Bits_F32x4 (Scalar_Aligned (Index)) = Bits_F32x4 ((if Index < 4 then Values (Lane_Index_32x4 (Index)) else Value_From_Bits_F32x4 (16#7FC0_0055#))) and then Bits_F32x4 (Native_Aligned (Index)) = Bits_F32x4 ((if Index < 4 then Values (Lane_Index_32x4 (Index)) else Value_From_Bits_F32x4 (16#7FC0_0055#))), "F32x4 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_F32x4;

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
   function Reference_Comparison_F32x4 (Left, Right : F32x4; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Left_Bits : constant Interfaces.Unsigned_32 := Bits_F32x4 (Extract (Left, Lane));
            Right_Bits : constant Interfaces.Unsigned_32 := Bits_F32x4 (Extract (Right, Lane));
            Left_NaN : constant Boolean := (Left_Bits and 16#7F80_0000#) = 16#7F80_0000# and then (Left_Bits and 16#007F_FFFF#) /= 0;
            Right_NaN : constant Boolean := (Right_Bits and 16#7F80_0000#) = 16#7F80_0000# and then (Right_Bits and 16#007F_FFFF#) /= 0;
         begin
         if (case Relation is
                when 0 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) > Extract (Right, Lane),
                when 4 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) >= Extract (Right, Lane),
                when others => Left_NaN or else Right_NaN) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
         end;
      end loop;
      return Result;
   end Reference_Comparison_F32x4;
   procedure Check_Arrangements_F32x4 (Left_Lanes, Right_Lanes : Lane_Values_F32x4; Label_Text : String) is
      Left : constant F32x4 := From_Lanes (Left_Lanes);
      Right : constant F32x4 := From_Lanes (Right_Lanes);
      Reverse_Expected : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => Left_Lanes (Lane_Index_32x4 (3 - Lane))]);
      Interleave_Low_Expected : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => (if Lane mod 2 = 0 then Left_Lanes (Lane_Index_32x4 (Lane / 2)) else Right_Lanes (Lane_Index_32x4 (Lane / 2)))]);
      Interleave_High_Expected : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => (if Lane mod 2 = 0 then Left_Lanes (Lane_Index_32x4 (2 + Lane / 2)) else Right_Lanes (Lane_Index_32x4 (2 + Lane / 2)))]);
      Deinterleave_Even_Expected : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => (if Lane < 2 then Left_Lanes (Lane_Index_32x4 (2 * Lane)) else Right_Lanes (Lane_Index_32x4 (2 * (Lane - 2))))]);
      Deinterleave_Odd_Expected : constant F32x4 := From_Lanes ([for Lane in Lane_Index_32x4 => (if Lane < 2 then Left_Lanes (Lane_Index_32x4 (2 * Lane + 1)) else Right_Lanes (Lane_Index_32x4 (2 * (Lane - 2) + 1)))]);
   begin
      Check (Same (Reverse_Lanes (Left), Reverse_Expected) and then Same (Backends.Scalar.Reverse_Lanes (Left), Reverse_Expected) and then Same (Backends.Native.Reverse_Lanes (Left), Reverse_Expected), "F32x4 independent root Scalar Native reverse" & Label_Text);
      Check (Same (Interleave_Low (Left, Right), Interleave_Low_Expected) and then Same (Backends.Scalar.Interleave_Low (Left, Right), Interleave_Low_Expected) and then Same (Backends.Native.Interleave_Low (Left, Right), Interleave_Low_Expected), "F32x4 independent root Scalar Native interleave low" & Label_Text);
      Check (Same (Interleave_High (Left, Right), Interleave_High_Expected) and then Same (Backends.Scalar.Interleave_High (Left, Right), Interleave_High_Expected) and then Same (Backends.Native.Interleave_High (Left, Right), Interleave_High_Expected), "F32x4 independent root Scalar Native interleave high" & Label_Text);
      Check (Same (Deinterleave_Even (Left, Right), Deinterleave_Even_Expected) and then Same (Backends.Scalar.Deinterleave_Even (Left, Right), Deinterleave_Even_Expected) and then Same (Backends.Native.Deinterleave_Even (Left, Right), Deinterleave_Even_Expected), "F32x4 independent root Scalar Native deinterleave even" & Label_Text);
      Check (Same (Deinterleave_Odd (Left, Right), Deinterleave_Odd_Expected) and then Same (Backends.Scalar.Deinterleave_Odd (Left, Right), Deinterleave_Odd_Expected) and then Same (Backends.Native.Deinterleave_Odd (Left, Right), Deinterleave_Odd_Expected), "F32x4 independent root Scalar Native deinterleave odd" & Label_Text);
   end Check_Arrangements_F32x4;
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
      Maximum_Index_Data : F32_Array (Natural'Last .. Natural'Last) := [others => 1.0];
      Special_Lanes_1 : constant Lane_Values_F32x4 := [Value_From_Bits_F32x4 (16#8000_0000#), Value_From_Bits_F32x4 (16#0000_0001#), Value_From_Bits_F32x4 (16#7F80_0000#), Value_From_Bits_F32x4 (16#7FC0_0001#)];
      Special_Lanes_2 : constant Lane_Values_F32x4 := [Value_From_Bits_F32x4 (16#7F80_0001#), Value_From_Bits_F32x4 (16#FF80_0000#), Value_From_Bits_F32x4 (16#FFC0_0021#), Value_From_Bits_F32x4 (16#8000_0001#)];
   begin
      Check_Complete_Memory_F32x4 (To_Lanes (A), " fixed");
      Check_Arrangements_F32x4 (Special_Lanes_1, Special_Lanes_2, " special bits");
      Check_Complete_Memory_F32x4 (Special_Lanes_1, " special 1");
      Check_Complete_Memory_F32x4 (Special_Lanes_2, " special 2");
      Check (Same (A, From_Lanes (To_Lanes (A))), "F32x4 scalar lane roundtrip");
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (F32x4'(Backends.Native.Zero), Lane)) = 0 and then Bits_F32x4 (Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane)) = Bits_F32x4 (To_Lanes (A) (0)), "F32x4 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.From_Lanes (To_Lanes (A)), Lane)) = Bits_F32x4 (To_Lanes (A) (Lane)) and then Bits_F32x4 (Backends.Native.To_Lanes (A) (Lane)) = Bits_F32x4 (To_Lanes (A) (Lane)), "F32x4 independent native lane construction" & Lane'Image); end loop;
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (A, Lane)) = Bits_F32x4 (To_Lanes (A) (Lane)), "F32x4 scalar extract" & Lane'Image);
         Check (Bits_F32x4 (Backends.Native.Extract (A, Lane)) = Bits_F32x4 (To_Lanes (A) (Lane)), "F32x4 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane)) = Bits_F32x4 ((if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane))), "F32x4 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      Check (Same (Backends.Scalar.Add (A, B), Add (A, B)) and then Same (Backends.Native.Add (A, B), Add (A, B)), "F32x4 scalar and native Add");
      Check (Same (Backends.Scalar.Subtract (A, B), Subtract (A, B)) and then Same (Backends.Native.Subtract (A, B), Subtract (A, B)), "F32x4 scalar and native Subtract");
      Check (Same (Backends.Scalar.Multiply (A, B), Multiply (A, B)) and then Same (Backends.Native.Multiply (A, B), Multiply (A, B)), "F32x4 scalar and native Multiply");
      Check (Same (Backends.Scalar.Divide (A, B), Divide (A, B)) and then Same (Backends.Native.Divide (A, B), Divide (A, B)), "F32x4 scalar and native Divide");
      Check (Same (Backends.Scalar.Min_Number (A, B), Min_Number (A, B)) and then Same (Backends.Native.Min_Number (A, B), Min_Number (A, B)), "F32x4 scalar and native Min_Number");
      Check (Same (Backends.Scalar.Max_Number (A, B), Max_Number (A, B)) and then Same (Backends.Native.Max_Number (A, B), Max_Number (A, B)), "F32x4 scalar and native Max_Number");
      Check (Same (Backends.Scalar.Interleave_Low (A, B), Interleave_Low (A, B)) and then Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "F32x4 scalar and native Interleave_Low");
      Check (Same (Backends.Scalar.Interleave_High (A, B), Interleave_High (A, B)) and then Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "F32x4 scalar and native Interleave_High");
      Check (Same (Backends.Scalar.Deinterleave_Even (A, B), Deinterleave_Even (A, B)) and then Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "F32x4 scalar and native Deinterleave_Even");
      Check (Same (Backends.Scalar.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)) and then Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "F32x4 scalar and native Deinterleave_Odd");
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
            Check (Bits_F32x4 (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < 4 and then Lane < 4 - Slide then Bits_F32x4 (Extract (A, Lane_Index_32x4 (Lane + Slide))) else 0) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < 4 and then Lane < 4 - Slide then Bits_F32x4 (Extract (A, Lane_Index_32x4 (Lane + Slide))) else 0), "F32x4 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Bits_F32x4 (Extract (Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < 4 and then Lane >= Slide then Bits_F32x4 (Extract (A, Lane_Index_32x4 (Lane - Slide))) else 0) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < 4 and then Lane >= Slide then Bits_F32x4 (Extract (A, Lane_Index_32x4 (Lane - Slide))) else 0), "F32x4 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "F32x4 maximum-count lane slides");
      for Lane in Lane_Index_32x4 loop
         Check (Bits_F32x4 (Extract (Add (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) + Extract (B, Lane)) and then Bits_F32x4 (Extract (Subtract (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) - Extract (B, Lane)) and then Bits_F32x4 (Extract (Multiply (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) * Extract (B, Lane)), "F32x4 independent arithmetic" & Lane'Image);
         Check (Bits_F32x4 (Extract (Divide (A, B), Lane)) = Bits_F32x4 (Extract (A, Lane) / Extract (B, Lane)), "F32x4 independent division" & Lane'Image);
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_32x4 (3 - Lane)), "F32x4 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (Lane / 2)) else Extract (B, Lane_Index_32x4 (Lane / 2))), "F32x4 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_32x4 (2 + Lane / 2)) else Extract (B, Lane_Index_32x4 (2 + Lane / 2))), "F32x4 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2)))), "F32x4 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 2 then Extract (A, Lane_Index_32x4 (2 * Lane + 1)) else Extract (B, Lane_Index_32x4 (2 * (Lane - 2) + 1))), "F32x4 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 0), "F32x4 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_F32x4 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_F32x4 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_F32x4 (A, B, 1), "F32x4 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 2), "F32x4 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_F32x4 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_F32x4 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_F32x4 (A, B, 3), "F32x4 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_F32x4 (A, B, 4), "F32x4 independent root, Scalar, and Native Greater_Equal");
      Check (To_Bit_Mask (Unordered (A, B)) = Reference_Comparison_F32x4 (A, B, 5) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (A, B)) = Reference_Comparison_F32x4 (A, B, 5) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A, B)) = Reference_Comparison_F32x4 (A, B, 5), "F32x4 independent root, Scalar, and Native Unordered");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "F32x4 scalar and native select");
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
         for Lane in Lane_Index_32x4 loop Check (Backends.Native.Test (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "F32x4 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "F32x4 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F32x4 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F32x4 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F32x4 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_F32x4 ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))) and then Bits_F32x4 (Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_F32x4 ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_F32x4 ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))), "F32x4 independent bitwise root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_32x4'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 4 - 1), "F32x4 native masks unused storage bits");
      Check (Bits_F32x4 (Reduce_Add (A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (A)) and then Bits_F32x4 (Backends.Native.Reduce_Add (A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (A)), "F32x4 independent reduce");
      Check (Bits_F32x4 (Reduce_Min_Number (B)) = Bits_F32x4 (Reference_Reduce_Min_F32x4 (B)) and then Bits_F32x4 (Backends.Native.Reduce_Min_Number (B)) = Bits_F32x4 (Reference_Reduce_Min_F32x4 (B)) and then Bits_F32x4 (Reduce_Max_Number (B)) = Bits_F32x4 (Reference_Reduce_Max_F32x4 (B)) and then Bits_F32x4 (Backends.Native.Reduce_Max_Number (B)) = Bits_F32x4 (Reference_Reduce_Max_F32x4 (B)), "F32x4 independent min/max reductions");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "F32x4 full memory");
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Data (1 + Lane)) = Bits_F32x4 (Extract (A, Lane)), "F32x4 independent full store" & Lane'Image); end loop;
      Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "F32x4 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "F32x4 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "F32x4 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "F32x4 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "F32x4 aligned memory");
      for N in Lane_Count_32x4 loop
         Data := [others => 0.0]; Reference := [others => 0.0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Bits_F32x4 (Data (Index)) = Bits_F32x4 ((if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_32x4 (Index - 2)) else 0.0)), "F32x4 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = Bits_F32x4 ((if Lane < N then Extract (B, Lane) else 0.0)), "F32x4 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : F32_Array (1 .. N) := [others => 0.0];
         begin
            for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane)) = 0, "F32x4 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for N in Lane_Count_32x4 loop
         Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
         for Lane in Lane_Index_32x4 loop Data (2 + Lane) := Special_Lanes_1 (Lane); end loop;
         for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = (if Lane < N then Bits_F32x4 (Special_Lanes_1 (Lane)) else 0), "F32x4 special-bit partial load group 1" & N'Image & Lane'Image); end loop;
         Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
         Backends.Native.Store_Partial (Data, 2, N, From_Lanes (Special_Lanes_1));
         for Index in Data'Range loop Check (Bits_F32x4 (Data (Index)) = (if Index in 2 .. 2 + N - 1 then Bits_F32x4 (Special_Lanes_1 (Lane_Index_32x4 (Index - 2))) else 16#7FC0_0055#), "F32x4 special-bit partial store group 1" & N'Image & Index'Image); end loop;
      end loop;
      for N in Lane_Count_32x4 loop
         Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
         for Lane in Lane_Index_32x4 loop Data (2 + Lane) := Special_Lanes_2 (Lane); end loop;
         for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = (if Lane < N then Bits_F32x4 (Special_Lanes_2 (Lane)) else 0), "F32x4 special-bit partial load group 2" & N'Image & Lane'Image); end loop;
         Data := [others => Value_From_Bits_F32x4 (16#7FC0_0055#)];
         Backends.Native.Store_Partial (Data, 2, N, From_Lanes (Special_Lanes_2));
         for Index in Data'Range loop Check (Bits_F32x4 (Data (Index)) = (if Index in 2 .. 2 + N - 1 then Bits_F32x4 (Special_Lanes_2 (Lane_Index_32x4 (Index - 2))) else 16#7FC0_0055#), "F32x4 special-bit partial store group 2" & N'Image & Index'Image); end loop;
      end loop;
      for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane)) = 0, "F32x4 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Bits_F32x4 (Maximum_Index_Data (Natural'Last)) = Bits_F32x4 (1.0), "F32x4 maximum-index zero-count partial store");
      for Iteration in 1 .. 250 loop
         declare
            R_Lanes : constant Lane_Values_F32x4 := Random_F32x4_Lanes;
            Memory_Lanes : constant Lane_Values_F32x4 := [for Lane in Lane_Index_32x4 => Value_From_Bits_F32x4 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFF_FFFF#))];
            Arrangement_Other_Lanes : constant Lane_Values_F32x4 := [for Lane in Lane_Index_32x4 => Value_From_Bits_F32x4 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFF_FFFF#))];
            R_A : constant F32x4 := From_Lanes (R_Lanes);
            R_B : constant F32x4 := From_Lanes (Random_F32x4_Lanes);
            Arrangement_A : constant F32x4 := From_Lanes (Memory_Lanes);
            Arrangement_B : constant F32x4 := From_Lanes (Arrangement_Other_Lanes);
            Tail : constant Lane_Count_32x4 := Lane_Count_32x4 (Next_U64 mod 5);
            Slide : constant Natural := Natural (Next_U64 mod 7);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 4);
            R_Selectors : constant Lane_Selectors_32x4 := Random_F32x4_Selectors;
            R_Map : constant Lane_Map_32x4 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_32x4 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)) else Select_Right_Lane (Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4)))]);
         begin
            Check_Arrangements_F32x4 (Memory_Lanes, Arrangement_Other_Lanes, " raw random" & Iteration'Image);
            for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.From_Lanes (R_Lanes), Lane)) = Bits_F32x4 (R_Lanes (Lane)) and then Bits_F32x4 (Backends.Native.To_Lanes (R_A) (Lane)) = Bits_F32x4 (R_Lanes (Lane)), "F32x4 randomized independent native lane construction" & Lane'Image); end loop;
            for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Splat (R_Lanes (0)), Lane)) = Bits_F32x4 (R_Lanes (0)), "F32x4 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Scalar.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Native.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Scalar.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Native.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Scalar.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Scalar.Divide (R_A, R_B), Divide (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F32x4 randomized scalar and native arithmetic");
            Check (Same (Backends.Scalar.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Native.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Scalar.Max_Number (R_A, R_B), Max_Number (R_A, R_B)) and then Same (Backends.Native.Max_Number (R_A, R_B), Max_Number (R_A, R_B)), "F32x4 randomized scalar and native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 4) and then To_Bit_Mask (Unordered (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 5) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 5) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (R_A, R_B)) = Reference_Comparison_F32x4 (R_A, R_B, 5), "F32x4 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "F32x4 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "F32x4 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "F32x4 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "F32x4 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "F32x4 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_F32x4 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_F32x4 (R_A, Mask_From_Bit_Mask (Pattern))), "F32x4 randomized native compression");
            Check (Bits_F32x4 (Backends.Native.Reduce_Add (R_A)) = Bits_F32x4 (Reference_Reduce_Add_F32x4 (R_A)) and then Bits_F32x4 (Backends.Native.Reduce_Min_Number (R_A)) = Bits_F32x4 (Reference_Reduce_Min_F32x4 (R_A)) and then Bits_F32x4 (Backends.Native.Reduce_Max_Number (R_A)) = Bits_F32x4 (Reference_Reduce_Max_F32x4 (R_A)), "F32x4 randomized native reductions");
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "F32x4 randomized native full memory");
            Check_Complete_Memory_F32x4 (Memory_Lanes, " raw random" & Iteration'Image);
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "F32x4 randomized native partial store");
            for Lane in Lane_Index_32x4 loop Check (Bits_F32x4 (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane)) = Bits_F32x4 ((if Lane < Tail then Extract (R_B, Lane) else 0.0)), "F32x4 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_32x4 loop
               Check (Bits_F32x4 (Extract (Reverse_Lanes (Arrangement_A), Lane)) = Bits_F32x4 (Memory_Lanes (Lane_Index_32x4 (3 - Lane))) and then Bits_F32x4 (Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (Arrangement_A), Lane)) = Bits_F32x4 (Memory_Lanes (Lane_Index_32x4 (3 - Lane))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Reverse_Lanes (Arrangement_A), Lane)) = Bits_F32x4 (Memory_Lanes (Lane_Index_32x4 (3 - Lane))), "F32x4 raw-bit root, Scalar, and Native reverse" & Lane'Image);
               Check (Bits_F32x4 (Extract (Interleave_Low (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_32x4 (Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_32x4 (Lane / 2)))) and then Bits_F32x4 (Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_32x4 (Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_32x4 (Lane / 2)))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Interleave_Low (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_32x4 (Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_32x4 (Lane / 2)))), "F32x4 raw-bit root, Scalar, and Native interleave low" & Lane'Image);
               Check (Bits_F32x4 (Extract (Interleave_High (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_32x4 (2 + Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 + Lane / 2)))) and then Bits_F32x4 (Backends.Scalar.Extract (Backends.Scalar.Interleave_High (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_32x4 (2 + Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 + Lane / 2)))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Interleave_High (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_32x4 (2 + Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 + Lane / 2)))), "F32x4 raw-bit root, Scalar, and Native interleave high" & Lane'Image);
               Check (Bits_F32x4 (Extract (Deinterleave_Even (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane < 2 then Memory_Lanes (Lane_Index_32x4 (2 * Lane)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 * (Lane - 2))))) and then Bits_F32x4 (Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane < 2 then Memory_Lanes (Lane_Index_32x4 (2 * Lane)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 * (Lane - 2))))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Deinterleave_Even (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane < 2 then Memory_Lanes (Lane_Index_32x4 (2 * Lane)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 * (Lane - 2))))), "F32x4 raw-bit root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Bits_F32x4 (Extract (Deinterleave_Odd (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane < 2 then Memory_Lanes (Lane_Index_32x4 (2 * Lane + 1)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 * (Lane - 2) + 1)))) and then Bits_F32x4 (Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane < 2 then Memory_Lanes (Lane_Index_32x4 (2 * Lane + 1)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 * (Lane - 2) + 1)))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Deinterleave_Odd (Arrangement_A, Arrangement_B), Lane)) = Bits_F32x4 ((if Lane < 2 then Memory_Lanes (Lane_Index_32x4 (2 * Lane + 1)) else Arrangement_Other_Lanes (Lane_Index_32x4 (2 * (Lane - 2) + 1)))), "F32x4 raw-bit root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Bits_F32x4 (Extract (Permute_Lanes (R_A, R_Map), Lane)) = Bits_F32x4 (R_Lanes (R_Selectors (Lane))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane)) = Bits_F32x4 (R_Lanes (R_Selectors (Lane))), "F32x4 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Bits_F32x4 (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_F32x4 (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4))) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_F32x4 (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_32x4 ((Iteration * 3 + Lane * 5) mod 4))), "F32x4 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Bits_F32x4 (Backends.Native.Extract (R_A, Lane)) = Bits_F32x4 (R_Lanes (Lane)) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "F32x4 randomized native lane access" & Lane'Image);
               Check (Bits_F32x4 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane)) = (if Slide < 4 and then Lane < 4 - Slide then Bits_F32x4 (R_Lanes (Lane_Index_32x4 (Lane + Slide))) else 0) and then Bits_F32x4 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane)) = (if Slide < 4 and then Lane >= Slide then Bits_F32x4 (R_Lanes (Lane_Index_32x4 (Lane - Slide))) else 0), "F32x4 randomized independent native lane slides" & Lane'Image);
               Check (Bits_F32x4 (Extract (Add (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Add (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Native.Add (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Subtract (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Subtract (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Native.Subtract (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Multiply (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) * Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Multiply (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) * Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Native.Multiply (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) * Extract (R_B, Lane)), "F32x4 randomized independent root, scalar, and native arithmetic" & Lane'Image);
               if Extract (R_B, Lane) /= 0.0 then Check (Bits_F32x4 (Extract (Divide (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) / Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Scalar.Divide (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) / Extract (R_B, Lane)) and then Bits_F32x4 (Extract (Backends.Native.Divide (R_A, R_B), Lane)) = Bits_F32x4 (Extract (R_A, Lane) / Extract (R_B, Lane)), "F32x4 randomized independent root, scalar, and native division" & Lane'Image); end if;
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "F32x4 randomized independent comparison" & Lane'Image);
               Check (Extract (Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Scalar.Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Native.Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Scalar.Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Native.Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "F32x4 randomized independent root, scalar, and native min/max" & Lane'Image);
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
   function Value_From_Bits_F64x2 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, F64);
   function Same (Left, Right : F64x2) return Boolean is
      L : constant Lane_Values_F64x2 := To_Lanes (Left);
      R : constant Lane_Values_F64x2 := To_Lanes (Right);
   begin
      for Lane in Lane_Index_64x2 loop
         if Bits_F64x2 (L (Lane)) /= Bits_F64x2 (R (Lane)) then return False; end if;
      end loop;
      return True;
   end Same;
   procedure Check_Complete_Memory_F64x2 (Values : Lane_Values_F64x2; Label_Text : String) is
      Value : constant F64x2 := From_Lanes (Values);
      Source : F64_Array (0 .. 3) := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)] with Alignment => 16;
      Root_Data, Scalar_Data, Native_Data : F64_Array (0 .. 3) := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
      Aligned_Source : F64_Array (0 .. 1) := F64_Array (Values) with Alignment => 16;
      Root_Aligned, Scalar_Aligned, Native_Aligned : F64_Array (0 .. 2) := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)] with Alignment => 16;
   begin
      for Lane in Lane_Index_64x2 loop Source (1 + Lane) := Values (Lane); end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (Load (Source, 1), Lane)) = Bits_F64x2 (Values (Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Load (Source, 1), Lane)) = Bits_F64x2 (Values (Lane)) and then Bits_F64x2 (Extract (Backends.Native.Load (Source, 1), Lane)) = Bits_F64x2 (Values (Lane)), "F64x2 independent root scalar native Load" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (Load_Unaligned (Source, 1), Lane)) = Bits_F64x2 (Values (Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Load_Unaligned (Source, 1), Lane)) = Bits_F64x2 (Values (Lane)) and then Bits_F64x2 (Extract (Backends.Native.Load_Unaligned (Source, 1), Lane)) = Bits_F64x2 (Values (Lane)), "F64x2 independent root scalar native Load_Unaligned" & Label_Text & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (Load_Aligned (Aligned_Source, 0), Lane)) = Bits_F64x2 (Values (Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Load_Aligned (Aligned_Source, 0), Lane)) = Bits_F64x2 (Values (Lane)) and then Bits_F64x2 (Extract (Backends.Native.Load_Aligned (Aligned_Source, 0), Lane)) = Bits_F64x2 (Values (Lane)), "F64x2 independent root scalar native Load_Aligned" & Label_Text & Lane'Image);
      end loop;
      Root_Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)]; Scalar_Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)]; Native_Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
      Store (Root_Data, 1, Value); Backends.Scalar.Store (Scalar_Data, 1, Value); Backends.Native.Store (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant F64 := (if Index in 1 .. 2 then Values (Lane_Index_64x2 (Index - 1)) else Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)); begin
            Check (Bits_F64x2 (Root_Data (Index)) = Bits_F64x2 (Expected) and then Bits_F64x2 (Scalar_Data (Index)) = Bits_F64x2 (Expected) and then Bits_F64x2 (Native_Data (Index)) = Bits_F64x2 (Expected), "F64x2 independent root scalar native Store" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)]; Scalar_Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)]; Native_Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
      Store_Unaligned (Root_Data, 1, Value); Backends.Scalar.Store_Unaligned (Scalar_Data, 1, Value); Backends.Native.Store_Unaligned (Native_Data, 1, Value);
      for Index in Root_Data'Range loop
         declare Expected : constant F64 := (if Index in 1 .. 2 then Values (Lane_Index_64x2 (Index - 1)) else Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)); begin
            Check (Bits_F64x2 (Root_Data (Index)) = Bits_F64x2 (Expected) and then Bits_F64x2 (Scalar_Data (Index)) = Bits_F64x2 (Expected) and then Bits_F64x2 (Native_Data (Index)) = Bits_F64x2 (Expected), "F64x2 independent root scalar native Store_Unaligned" & Label_Text & Index'Image);
         end;
      end loop;
      Root_Aligned := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)]; Scalar_Aligned := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)]; Native_Aligned := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
      Store_Aligned (Root_Aligned, 0, Value); Backends.Scalar.Store_Aligned (Scalar_Aligned, 0, Value); Backends.Native.Store_Aligned (Native_Aligned, 0, Value);
      for Index in Root_Aligned'Range loop
         Check (Bits_F64x2 (Root_Aligned (Index)) = Bits_F64x2 ((if Index < 2 then Values (Lane_Index_64x2 (Index)) else Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#))) and then Bits_F64x2 (Scalar_Aligned (Index)) = Bits_F64x2 ((if Index < 2 then Values (Lane_Index_64x2 (Index)) else Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#))) and then Bits_F64x2 (Native_Aligned (Index)) = Bits_F64x2 ((if Index < 2 then Values (Lane_Index_64x2 (Index)) else Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#))), "F64x2 independent root scalar native Store_Aligned" & Label_Text & Index'Image);
      end loop;
   end Check_Complete_Memory_F64x2;

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
   function Reference_Comparison_F64x2 (Left, Right : F64x2; Relation : Natural) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Left_Bits : constant Interfaces.Unsigned_64 := Bits_F64x2 (Extract (Left, Lane));
            Right_Bits : constant Interfaces.Unsigned_64 := Bits_F64x2 (Extract (Right, Lane));
            Left_NaN : constant Boolean := (Left_Bits and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000# and then (Left_Bits and 16#000F_FFFF_FFFF_FFFF#) /= 0;
            Right_NaN : constant Boolean := (Right_Bits and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000# and then (Right_Bits and 16#000F_FFFF_FFFF_FFFF#) /= 0;
         begin
         if (case Relation is
                when 0 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) = Extract (Right, Lane),
                when 1 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) < Extract (Right, Lane),
                when 2 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) <= Extract (Right, Lane),
                when 3 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) > Extract (Right, Lane),
                when 4 => not Left_NaN and then not Right_NaN and then Extract (Left, Lane) >= Extract (Right, Lane),
                when others => Left_NaN or else Right_NaN) then
            Result := Result or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane);
         end if;
         end;
      end loop;
      return Result;
   end Reference_Comparison_F64x2;
   procedure Check_Arrangements_F64x2 (Left_Lanes, Right_Lanes : Lane_Values_F64x2; Label_Text : String) is
      Left : constant F64x2 := From_Lanes (Left_Lanes);
      Right : constant F64x2 := From_Lanes (Right_Lanes);
      Reverse_Expected : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => Left_Lanes (Lane_Index_64x2 (1 - Lane))]);
      Interleave_Low_Expected : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => (if Lane mod 2 = 0 then Left_Lanes (Lane_Index_64x2 (Lane / 2)) else Right_Lanes (Lane_Index_64x2 (Lane / 2)))]);
      Interleave_High_Expected : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => (if Lane mod 2 = 0 then Left_Lanes (Lane_Index_64x2 (1 + Lane / 2)) else Right_Lanes (Lane_Index_64x2 (1 + Lane / 2)))]);
      Deinterleave_Even_Expected : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => (if Lane < 1 then Left_Lanes (Lane_Index_64x2 (2 * Lane)) else Right_Lanes (Lane_Index_64x2 (2 * (Lane - 1))))]);
      Deinterleave_Odd_Expected : constant F64x2 := From_Lanes ([for Lane in Lane_Index_64x2 => (if Lane < 1 then Left_Lanes (Lane_Index_64x2 (2 * Lane + 1)) else Right_Lanes (Lane_Index_64x2 (2 * (Lane - 1) + 1)))]);
   begin
      Check (Same (Reverse_Lanes (Left), Reverse_Expected) and then Same (Backends.Scalar.Reverse_Lanes (Left), Reverse_Expected) and then Same (Backends.Native.Reverse_Lanes (Left), Reverse_Expected), "F64x2 independent root Scalar Native reverse" & Label_Text);
      Check (Same (Interleave_Low (Left, Right), Interleave_Low_Expected) and then Same (Backends.Scalar.Interleave_Low (Left, Right), Interleave_Low_Expected) and then Same (Backends.Native.Interleave_Low (Left, Right), Interleave_Low_Expected), "F64x2 independent root Scalar Native interleave low" & Label_Text);
      Check (Same (Interleave_High (Left, Right), Interleave_High_Expected) and then Same (Backends.Scalar.Interleave_High (Left, Right), Interleave_High_Expected) and then Same (Backends.Native.Interleave_High (Left, Right), Interleave_High_Expected), "F64x2 independent root Scalar Native interleave high" & Label_Text);
      Check (Same (Deinterleave_Even (Left, Right), Deinterleave_Even_Expected) and then Same (Backends.Scalar.Deinterleave_Even (Left, Right), Deinterleave_Even_Expected) and then Same (Backends.Native.Deinterleave_Even (Left, Right), Deinterleave_Even_Expected), "F64x2 independent root Scalar Native deinterleave even" & Label_Text);
      Check (Same (Deinterleave_Odd (Left, Right), Deinterleave_Odd_Expected) and then Same (Backends.Scalar.Deinterleave_Odd (Left, Right), Deinterleave_Odd_Expected) and then Same (Backends.Native.Deinterleave_Odd (Left, Right), Deinterleave_Odd_Expected), "F64x2 independent root Scalar Native deinterleave odd" & Label_Text);
   end Check_Arrangements_F64x2;
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
      Maximum_Index_Data : F64_Array (Natural'Last .. Natural'Last) := [others => 1.0];
      Special_Lanes_1 : constant Lane_Values_F64x2 := [Value_From_Bits_F64x2 (16#8000_0000_0000_0000#), Value_From_Bits_F64x2 (16#0000_0000_0000_0001#)];
      Special_Lanes_2 : constant Lane_Values_F64x2 := [Value_From_Bits_F64x2 (16#7FF0_0000_0000_0000#), Value_From_Bits_F64x2 (16#7FF8_0000_0000_0001#)];
      Special_Lanes_3 : constant Lane_Values_F64x2 := [Value_From_Bits_F64x2 (16#7FF0_0000_0000_0001#), Value_From_Bits_F64x2 (16#FFF0_0000_0000_0000#)];
   begin
      Check_Complete_Memory_F64x2 (To_Lanes (A), " fixed");
      Check_Arrangements_F64x2 (Special_Lanes_1, Special_Lanes_2, " special bits");
      Check_Arrangements_F64x2 (Special_Lanes_3, Special_Lanes_1, " special bits 3");
      Check_Complete_Memory_F64x2 (Special_Lanes_1, " special 1");
      Check_Complete_Memory_F64x2 (Special_Lanes_2, " special 2");
      Check_Complete_Memory_F64x2 (Special_Lanes_3, " special 3");
      Check (Same (A, From_Lanes (To_Lanes (A))), "F64x2 scalar lane roundtrip");
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (F64x2'(Backends.Native.Zero), Lane)) = 0 and then Bits_F64x2 (Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane)) = Bits_F64x2 (To_Lanes (A) (0)), "F64x2 independent native construction" & Lane'Image); end loop;
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.From_Lanes (To_Lanes (A)), Lane)) = Bits_F64x2 (To_Lanes (A) (Lane)) and then Bits_F64x2 (Backends.Native.To_Lanes (A) (Lane)) = Bits_F64x2 (To_Lanes (A) (Lane)), "F64x2 independent native lane construction" & Lane'Image); end loop;
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (A, Lane)) = Bits_F64x2 (To_Lanes (A) (Lane)), "F64x2 scalar extract" & Lane'Image);
         Check (Bits_F64x2 (Backends.Native.Extract (A, Lane)) = Bits_F64x2 (To_Lanes (A) (Lane)), "F64x2 independent native extract" & Lane'Image);
         for Result_Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane)) = Bits_F64x2 ((if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane))), "F64x2 independent native replace" & Lane'Image & Result_Lane'Image); end loop;
      end loop;
      Check (Same (Backends.Scalar.Add (A, B), Add (A, B)) and then Same (Backends.Native.Add (A, B), Add (A, B)), "F64x2 scalar and native Add");
      Check (Same (Backends.Scalar.Subtract (A, B), Subtract (A, B)) and then Same (Backends.Native.Subtract (A, B), Subtract (A, B)), "F64x2 scalar and native Subtract");
      Check (Same (Backends.Scalar.Multiply (A, B), Multiply (A, B)) and then Same (Backends.Native.Multiply (A, B), Multiply (A, B)), "F64x2 scalar and native Multiply");
      Check (Same (Backends.Scalar.Divide (A, B), Divide (A, B)) and then Same (Backends.Native.Divide (A, B), Divide (A, B)), "F64x2 scalar and native Divide");
      Check (Same (Backends.Scalar.Min_Number (A, B), Min_Number (A, B)) and then Same (Backends.Native.Min_Number (A, B), Min_Number (A, B)), "F64x2 scalar and native Min_Number");
      Check (Same (Backends.Scalar.Max_Number (A, B), Max_Number (A, B)) and then Same (Backends.Native.Max_Number (A, B), Max_Number (A, B)), "F64x2 scalar and native Max_Number");
      Check (Same (Backends.Scalar.Interleave_Low (A, B), Interleave_Low (A, B)) and then Same (Backends.Native.Interleave_Low (A, B), Interleave_Low (A, B)), "F64x2 scalar and native Interleave_Low");
      Check (Same (Backends.Scalar.Interleave_High (A, B), Interleave_High (A, B)) and then Same (Backends.Native.Interleave_High (A, B), Interleave_High (A, B)), "F64x2 scalar and native Interleave_High");
      Check (Same (Backends.Scalar.Deinterleave_Even (A, B), Deinterleave_Even (A, B)) and then Same (Backends.Native.Deinterleave_Even (A, B), Deinterleave_Even (A, B)), "F64x2 scalar and native Deinterleave_Even");
      Check (Same (Backends.Scalar.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)) and then Same (Backends.Native.Deinterleave_Odd (A, B), Deinterleave_Odd (A, B)), "F64x2 scalar and native Deinterleave_Odd");
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
            Check (Bits_F64x2 (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < 2 and then Lane < 2 - Slide then Bits_F64x2 (Extract (A, Lane_Index_64x2 (Lane + Slide))) else 0) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < 2 and then Lane < 2 - Slide then Bits_F64x2 (Extract (A, Lane_Index_64x2 (Lane + Slide))) else 0), "F64x2 independent scalar and native slide toward low" & Slide'Image & Lane'Image);
            Check (Bits_F64x2 (Extract (Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < 2 and then Lane >= Slide then Bits_F64x2 (Extract (A, Lane_Index_64x2 (Lane - Slide))) else 0) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < 2 and then Lane >= Slide then Bits_F64x2 (Extract (A, Lane_Index_64x2 (Lane - Slide))) else 0), "F64x2 independent scalar and native slide toward high" & Slide'Image & Lane'Image);
         end loop;
      end loop;
      Check (Same (Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_Low (A, Natural'Last), Zero) and then Same (Slide_Lanes_Toward_High (A, Natural'Last), Zero) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Natural'Last), Zero), "F64x2 maximum-count lane slides");
      for Lane in Lane_Index_64x2 loop
         Check (Bits_F64x2 (Extract (Add (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) + Extract (B, Lane)) and then Bits_F64x2 (Extract (Subtract (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) - Extract (B, Lane)) and then Bits_F64x2 (Extract (Multiply (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) * Extract (B, Lane)), "F64x2 independent arithmetic" & Lane'Image);
         Check (Bits_F64x2 (Extract (Divide (A, B), Lane)) = Bits_F64x2 (Extract (A, Lane) / Extract (B, Lane)), "F64x2 independent division" & Lane'Image);
         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, Lane_Index_64x2 (1 - Lane)), "F64x2 independent reverse" & Lane'Image);
         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (Lane / 2)) else Extract (B, Lane_Index_64x2 (Lane / 2))), "F64x2 independent interleave low" & Lane'Image);
         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, Lane_Index_64x2 (1 + Lane / 2)) else Extract (B, Lane_Index_64x2 (1 + Lane / 2))), "F64x2 independent interleave high" & Lane'Image);
         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1)))), "F64x2 independent deinterleave even" & Lane'Image);
         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < 1 then Extract (A, Lane_Index_64x2 (2 * Lane + 1)) else Extract (B, Lane_Index_64x2 (2 * (Lane - 1) + 1))), "F64x2 independent deinterleave odd" & Lane'Image);
      end loop;
      Check (To_Bit_Mask (Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 0), "F64x2 independent root, Scalar, and Native Equal");
      Check (To_Bit_Mask (Less_Than (A, B)) = Reference_Comparison_F64x2 (A, B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (A, B)) = Reference_Comparison_F64x2 (A, B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (A, B)) = Reference_Comparison_F64x2 (A, B, 1), "F64x2 independent root, Scalar, and Native Less_Than");
      Check (To_Bit_Mask (Less_Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 2), "F64x2 independent root, Scalar, and Native Less_Equal");
      Check (To_Bit_Mask (Greater_Than (A, B)) = Reference_Comparison_F64x2 (A, B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (A, B)) = Reference_Comparison_F64x2 (A, B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (A, B)) = Reference_Comparison_F64x2 (A, B, 3), "F64x2 independent root, Scalar, and Native Greater_Than");
      Check (To_Bit_Mask (Greater_Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (A, B)) = Reference_Comparison_F64x2 (A, B, 4), "F64x2 independent root, Scalar, and Native Greater_Equal");
      Check (To_Bit_Mask (Unordered (A, B)) = Reference_Comparison_F64x2 (A, B, 5) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (A, B)) = Reference_Comparison_F64x2 (A, B, 5) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A, B)) = Reference_Comparison_F64x2 (A, B, 5), "F64x2 independent root, Scalar, and Native Unordered");
      Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)) and then Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), "F64x2 scalar and native select");
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
         for Lane in Lane_Index_64x2 loop Check (Backends.Native.Test (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), "F64x2 independent native mask lane" & Pattern'Image & Lane'Image); end loop;
         Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), "F64x2 exhaustive scalar and native select" & Pattern'Image);
         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F64x2 exhaustive compress" & Pattern'Image);
         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_F64x2 (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), "F64x2 exhaustive expand" & Pattern'Image);
         for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_F64x2 ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))) and then Bits_F64x2 (Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_F64x2 ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_F64x2 ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))), "F64x2 independent bitwise root, Scalar, and Native select" & Pattern'Image & Lane'Image); end loop;
      end loop;
      Check (Backends.Native.To_Bit_Mask (Mask_64x2'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** 2 - 1), "F64x2 native masks unused storage bits");
      Check (Bits_F64x2 (Reduce_Add (A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (A)) and then Bits_F64x2 (Backends.Native.Reduce_Add (A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (A)), "F64x2 independent reduce");
      Check (Bits_F64x2 (Reduce_Min_Number (B)) = Bits_F64x2 (Reference_Reduce_Min_F64x2 (B)) and then Bits_F64x2 (Backends.Native.Reduce_Min_Number (B)) = Bits_F64x2 (Reference_Reduce_Min_F64x2 (B)) and then Bits_F64x2 (Reduce_Max_Number (B)) = Bits_F64x2 (Reference_Reduce_Max_F64x2 (B)) and then Bits_F64x2 (Backends.Native.Reduce_Max_Number (B)) = Bits_F64x2 (Reference_Reduce_Max_F64x2 (B)), "F64x2 independent min/max reductions");
      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);
      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), "F64x2 full memory");
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Data (1 + Lane)) = Bits_F64x2 (Extract (A, Lane)), "F64x2 independent full store" & Lane'Image); end loop;
      Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);
      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), "F64x2 ordinary memory");
      Check (Is_Aligned_16 (Aligned_Data, 0) and then Backends.Native.Is_Aligned_16 (Aligned_Data, 0), "F64x2 aligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, 1) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, 1), "F64x2 misaligned address predicate");
      Check (not Is_Aligned_16 (Aligned_Data, Natural'Last) and then not Backends.Native.Is_Aligned_16 (Aligned_Data, Natural'Last), "F64x2 out-of-range maximum-index alignment predicate");
      Backends.Native.Store_Aligned (Aligned_Data, 0, A);
      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), "F64x2 aligned memory");
      for N in Lane_Count_64x2 loop
         Data := [others => 0.0]; Reference := [others => 0.0];
         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);
         for Index in Data'Range loop Check (Bits_F64x2 (Data (Index)) = Bits_F64x2 ((if Index in 2 .. 2 + N - 1 then Extract (B, Lane_Index_64x2 (Index - 2)) else 0.0)), "F64x2 independent partial store" & N'Image & Index'Image); end loop;
         for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = Bits_F64x2 ((if Lane < N then Extract (B, Lane) else 0.0)), "F64x2 independent partial load" & N'Image & Lane'Image); end loop;
         declare
            Exact : F64_Array (1 .. N) := [others => 0.0];
         begin
            for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane)) = 0, "F64x2 exact-extent partial load" & N'Image & Lane'Image); end loop;
            Backends.Native.Store_Partial (Exact, 1, N, B);
         end;
      end loop;
      for N in Lane_Count_64x2 loop
         Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
         for Lane in Lane_Index_64x2 loop Data (2 + Lane) := Special_Lanes_1 (Lane); end loop;
         for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = (if Lane < N then Bits_F64x2 (Special_Lanes_1 (Lane)) else 0), "F64x2 special-bit partial load group 1" & N'Image & Lane'Image); end loop;
         Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
         Backends.Native.Store_Partial (Data, 2, N, From_Lanes (Special_Lanes_1));
         for Index in Data'Range loop Check (Bits_F64x2 (Data (Index)) = (if Index in 2 .. 2 + N - 1 then Bits_F64x2 (Special_Lanes_1 (Lane_Index_64x2 (Index - 2))) else 16#7FF8_0000_0000_0055#), "F64x2 special-bit partial store group 1" & N'Image & Index'Image); end loop;
      end loop;
      for N in Lane_Count_64x2 loop
         Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
         for Lane in Lane_Index_64x2 loop Data (2 + Lane) := Special_Lanes_2 (Lane); end loop;
         for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = (if Lane < N then Bits_F64x2 (Special_Lanes_2 (Lane)) else 0), "F64x2 special-bit partial load group 2" & N'Image & Lane'Image); end loop;
         Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
         Backends.Native.Store_Partial (Data, 2, N, From_Lanes (Special_Lanes_2));
         for Index in Data'Range loop Check (Bits_F64x2 (Data (Index)) = (if Index in 2 .. 2 + N - 1 then Bits_F64x2 (Special_Lanes_2 (Lane_Index_64x2 (Index - 2))) else 16#7FF8_0000_0000_0055#), "F64x2 special-bit partial store group 2" & N'Image & Index'Image); end loop;
      end loop;
      for N in Lane_Count_64x2 loop
         Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
         for Lane in Lane_Index_64x2 loop Data (2 + Lane) := Special_Lanes_3 (Lane); end loop;
         for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = (if Lane < N then Bits_F64x2 (Special_Lanes_3 (Lane)) else 0), "F64x2 special-bit partial load group 3" & N'Image & Lane'Image); end loop;
         Data := [others => Value_From_Bits_F64x2 (16#7FF8_0000_0000_0055#)];
         Backends.Native.Store_Partial (Data, 2, N, From_Lanes (Special_Lanes_3));
         for Index in Data'Range loop Check (Bits_F64x2 (Data (Index)) = (if Index in 2 .. 2 + N - 1 then Bits_F64x2 (Special_Lanes_3 (Lane_Index_64x2 (Index - 2))) else 16#7FF8_0000_0000_0055#), "F64x2 special-bit partial store group 3" & N'Image & Index'Image); end loop;
      end loop;
      for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane)) = 0, "F64x2 maximum-index zero-count partial load" & Lane'Image); end loop;
      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);
      Check (Bits_F64x2 (Maximum_Index_Data (Natural'Last)) = Bits_F64x2 (1.0), "F64x2 maximum-index zero-count partial store");
      for Iteration in 1 .. 250 loop
         declare
            R_Lanes : constant Lane_Values_F64x2 := Random_F64x2_Lanes;
            Memory_Lanes : constant Lane_Values_F64x2 := [for Lane in Lane_Index_64x2 => Value_From_Bits_F64x2 (Next_U64)];
            Arrangement_Other_Lanes : constant Lane_Values_F64x2 := [for Lane in Lane_Index_64x2 => Value_From_Bits_F64x2 (Next_U64)];
            R_A : constant F64x2 := From_Lanes (R_Lanes);
            R_B : constant F64x2 := From_Lanes (Random_F64x2_Lanes);
            Arrangement_A : constant F64x2 := From_Lanes (Memory_Lanes);
            Arrangement_B : constant F64x2 := From_Lanes (Arrangement_Other_Lanes);
            Tail : constant Lane_Count_64x2 := Lane_Count_64x2 (Next_U64 mod 3);
            Slide : constant Natural := Natural (Next_U64 mod 5);
            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** 2);
            R_Selectors : constant Lane_Selectors_64x2 := Random_F64x2_Selectors;
            R_Map : constant Lane_Map_64x2 := Make_Lane_Map (R_Selectors);
            R_Two_Source_Map : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([for Lane in Lane_Index_64x2 => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)) else Select_Right_Lane (Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2)))]);
         begin
            Check_Arrangements_F64x2 (Memory_Lanes, Arrangement_Other_Lanes, " raw random" & Iteration'Image);
            for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.From_Lanes (R_Lanes), Lane)) = Bits_F64x2 (R_Lanes (Lane)) and then Bits_F64x2 (Backends.Native.To_Lanes (R_A) (Lane)) = Bits_F64x2 (R_Lanes (Lane)), "F64x2 randomized independent native lane construction" & Lane'Image); end loop;
            for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Splat (R_Lanes (0)), Lane)) = Bits_F64x2 (R_Lanes (0)), "F64x2 randomized independent native splat" & Lane'Image); end loop;
            Check (Same (Backends.Scalar.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Native.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Scalar.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Native.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Scalar.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Scalar.Divide (R_A, R_B), Divide (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), "F64x2 randomized scalar and native arithmetic");
            Check (Same (Backends.Scalar.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Native.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Scalar.Max_Number (R_A, R_B), Max_Number (R_A, R_B)) and then Same (Backends.Native.Max_Number (R_A, R_B), Max_Number (R_A, R_B)), "F64x2 randomized scalar and native min/max");
            Check (To_Bit_Mask (Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 0) and then To_Bit_Mask (Less_Than (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 1) and then To_Bit_Mask (Less_Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 2) and then To_Bit_Mask (Greater_Than (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 3) and then To_Bit_Mask (Greater_Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 4) and then To_Bit_Mask (Unordered (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 5) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 5) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (R_A, R_B)) = Reference_Comparison_F64x2 (R_A, R_B, 5), "F64x2 randomized independent root, Scalar, and Native comparisons");
            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), "F64x2 randomized native permutations");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), "F64x2 randomized native lane permutation");
            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), "F64x2 randomized native two-source lane permutation");
            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), "F64x2 randomized native lane slides");
            Check (Same (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)) and then Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), "F64x2 randomized scalar and native select");
            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_F64x2 (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_F64x2 (R_A, Mask_From_Bit_Mask (Pattern))), "F64x2 randomized native compression");
            Check (Bits_F64x2 (Backends.Native.Reduce_Add (R_A)) = Bits_F64x2 (Reference_Reduce_Add_F64x2 (R_A)) and then Bits_F64x2 (Backends.Native.Reduce_Min_Number (R_A)) = Bits_F64x2 (Reference_Reduce_Min_F64x2 (R_A)) and then Bits_F64x2 (Backends.Native.Reduce_Max_Number (R_A)) = Bits_F64x2 (Reference_Reduce_Max_F64x2 (R_A)), "F64x2 randomized native reductions");
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);
            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), "F64x2 randomized native full memory");
            Check_Complete_Memory_F64x2 (Memory_Lanes, " raw random" & Iteration'Image);
            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);
            Check (Data = Reference, "F64x2 randomized native partial store");
            for Lane in Lane_Index_64x2 loop Check (Bits_F64x2 (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane)) = Bits_F64x2 ((if Lane < Tail then Extract (R_B, Lane) else 0.0)), "F64x2 randomized independent partial load" & Lane'Image); end loop;
            for Lane in Lane_Index_64x2 loop
               Check (Bits_F64x2 (Extract (Reverse_Lanes (Arrangement_A), Lane)) = Bits_F64x2 (Memory_Lanes (Lane_Index_64x2 (1 - Lane))) and then Bits_F64x2 (Backends.Scalar.Extract (Backends.Scalar.Reverse_Lanes (Arrangement_A), Lane)) = Bits_F64x2 (Memory_Lanes (Lane_Index_64x2 (1 - Lane))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Reverse_Lanes (Arrangement_A), Lane)) = Bits_F64x2 (Memory_Lanes (Lane_Index_64x2 (1 - Lane))), "F64x2 raw-bit root, Scalar, and Native reverse" & Lane'Image);
               Check (Bits_F64x2 (Extract (Interleave_Low (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_64x2 (Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_64x2 (Lane / 2)))) and then Bits_F64x2 (Backends.Scalar.Extract (Backends.Scalar.Interleave_Low (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_64x2 (Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_64x2 (Lane / 2)))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Interleave_Low (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_64x2 (Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_64x2 (Lane / 2)))), "F64x2 raw-bit root, Scalar, and Native interleave low" & Lane'Image);
               Check (Bits_F64x2 (Extract (Interleave_High (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_64x2 (1 + Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_64x2 (1 + Lane / 2)))) and then Bits_F64x2 (Backends.Scalar.Extract (Backends.Scalar.Interleave_High (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_64x2 (1 + Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_64x2 (1 + Lane / 2)))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Interleave_High (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane mod 2 = 0 then Memory_Lanes (Lane_Index_64x2 (1 + Lane / 2)) else Arrangement_Other_Lanes (Lane_Index_64x2 (1 + Lane / 2)))), "F64x2 raw-bit root, Scalar, and Native interleave high" & Lane'Image);
               Check (Bits_F64x2 (Extract (Deinterleave_Even (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane < 1 then Memory_Lanes (Lane_Index_64x2 (2 * Lane)) else Arrangement_Other_Lanes (Lane_Index_64x2 (2 * (Lane - 1))))) and then Bits_F64x2 (Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Even (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane < 1 then Memory_Lanes (Lane_Index_64x2 (2 * Lane)) else Arrangement_Other_Lanes (Lane_Index_64x2 (2 * (Lane - 1))))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Deinterleave_Even (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane < 1 then Memory_Lanes (Lane_Index_64x2 (2 * Lane)) else Arrangement_Other_Lanes (Lane_Index_64x2 (2 * (Lane - 1))))), "F64x2 raw-bit root, Scalar, and Native deinterleave even" & Lane'Image);
               Check (Bits_F64x2 (Extract (Deinterleave_Odd (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane < 1 then Memory_Lanes (Lane_Index_64x2 (2 * Lane + 1)) else Arrangement_Other_Lanes (Lane_Index_64x2 (2 * (Lane - 1) + 1)))) and then Bits_F64x2 (Backends.Scalar.Extract (Backends.Scalar.Deinterleave_Odd (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane < 1 then Memory_Lanes (Lane_Index_64x2 (2 * Lane + 1)) else Arrangement_Other_Lanes (Lane_Index_64x2 (2 * (Lane - 1) + 1)))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Deinterleave_Odd (Arrangement_A, Arrangement_B), Lane)) = Bits_F64x2 ((if Lane < 1 then Memory_Lanes (Lane_Index_64x2 (2 * Lane + 1)) else Arrangement_Other_Lanes (Lane_Index_64x2 (2 * (Lane - 1) + 1)))), "F64x2 raw-bit root, Scalar, and Native deinterleave odd" & Lane'Image);
               Check (Bits_F64x2 (Extract (Permute_Lanes (R_A, R_Map), Lane)) = Bits_F64x2 (R_Lanes (R_Selectors (Lane))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_Map), Lane)) = Bits_F64x2 (R_Lanes (R_Selectors (Lane))), "F64x2 randomized independent scalar and native lane permutation" & Lane'Image);
               Check (Bits_F64x2 (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_F64x2 (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2))) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_F64x2 (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), Lane_Index_64x2 ((Iteration * 3 + Lane * 5) mod 2))), "F64x2 varied independent scalar and native two-source lane permutation" & Lane'Image);
               Check (Bits_F64x2 (Backends.Native.Extract (R_A, Lane)) = Bits_F64x2 (R_Lanes (Lane)) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), "F64x2 randomized native lane access" & Lane'Image);
               Check (Bits_F64x2 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Lane)) = (if Slide < 2 and then Lane < 2 - Slide then Bits_F64x2 (R_Lanes (Lane_Index_64x2 (Lane + Slide))) else 0) and then Bits_F64x2 (Backends.Native.Extract (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Lane)) = (if Slide < 2 and then Lane >= Slide then Bits_F64x2 (R_Lanes (Lane_Index_64x2 (Lane - Slide))) else 0), "F64x2 randomized independent native lane slides" & Lane'Image);
               Check (Bits_F64x2 (Extract (Add (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Add (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Native.Add (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Subtract (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Subtract (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Native.Subtract (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Multiply (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) * Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Multiply (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) * Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Native.Multiply (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) * Extract (R_B, Lane)), "F64x2 randomized independent root, scalar, and native arithmetic" & Lane'Image);
               if Extract (R_B, Lane) /= 0.0 then Check (Bits_F64x2 (Extract (Divide (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) / Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Scalar.Divide (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) / Extract (R_B, Lane)) and then Bits_F64x2 (Extract (Backends.Native.Divide (R_A, R_B), Lane)) = Bits_F64x2 (Extract (R_A, Lane) / Extract (R_B, Lane)), "F64x2 randomized independent root, scalar, and native division" & Lane'Image); end if;
               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), "F64x2 randomized independent comparison" & Lane'Image);
               Check (Extract (Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Scalar.Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Native.Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Scalar.Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Native.Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), "F64x2 randomized independent root, scalar, and native min/max" & Lane'Image);
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
      SNaN32_B : constant F32 := To_F32 (16#FF80_0021#);
      Inf32 : constant F32 := To_F32 (16#7F80_0000#);
      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);
      Subnormal32 : constant F32 := To_F32 (16#0000_0001#);
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
      SNaN64_B : constant F64 := To_F64 (16#FFF0_0000_0000_0021#);
      Inf64 : constant F64 := To_F64 (16#7FF0_0000_0000_0000#);
      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);
      Subnormal64 : constant F64 := To_F64 (16#0000_0000_0000_0001#);
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
      Add_Order32 : constant F32x4 := From_Lanes ([1.0E20, 1.0, -1.0E20, 1.0]);
      Add_Negative_Zero32 : constant F32x4 := From_Lanes ([Neg_Zero32, Neg_Zero32, Neg_Zero32, Neg_Zero32]);
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
      Add_Negative_Zero64 : constant F64x2 := From_Lanes ([Neg_Zero64, Neg_Zero64]);
      Unordered32_Left : constant F32x4 := From_Lanes ([NaN32, 1.0, SNaN32_B, Inf32]);
      Unordered32_Right : constant F32x4 := From_Lanes ([2.0, SNaN32, NaN32, Neg_Zero32]);
      Unordered64_Left : constant F64x2 := From_Lanes ([NaN64, 1.0]);
      Unordered64_Right : constant F64x2 := From_Lanes ([1.0, SNaN64_B]);
      Unordered64_Both : constant F64x2 := From_Lanes ([SNaN64, Inf64]);
      Unordered64_Both_Right : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);
   begin
      for Lane in Lane_Index_32x4 loop
         Check (F32_Bits (Extract (F32x4'(Backends.Native.Zero), Lane)) = 0, "F32 native positive-zero construction" & Lane'Image);
         Check (F32_Bits (Extract (Backends.Native.Splat (Neg_Zero32), Lane)) = F32_Bits (Neg_Zero32) and then F32_Bits (Extract (Backends.Native.Splat (NaN32), Lane)) = F32_Bits (NaN32) and then F32_Bits (Extract (Backends.Native.Splat (SNaN32_B), Lane)) = F32_Bits (SNaN32_B) and then F32_Bits (Extract (Backends.Native.Splat (Inf32), Lane)) = F32_Bits (Inf32) and then F32_Bits (Extract (Backends.Native.Splat (Subnormal32), Lane)) = F32_Bits (Subnormal32), "F32 native special-bit splat" & Lane'Image);
      end loop;
      for Lane in Lane_Index_64x2 loop
         Check (F64_Bits (Extract (F64x2'(Backends.Native.Zero), Lane)) = 0, "F64 native positive-zero construction" & Lane'Image);
         Check (F64_Bits (Extract (Backends.Native.Splat (Neg_Zero64), Lane)) = F64_Bits (Neg_Zero64) and then F64_Bits (Extract (Backends.Native.Splat (NaN64), Lane)) = F64_Bits (NaN64) and then F64_Bits (Extract (Backends.Native.Splat (SNaN64_B), Lane)) = F64_Bits (SNaN64_B) and then F64_Bits (Extract (Backends.Native.Splat (Inf64), Lane)) = F64_Bits (Inf64) and then F64_Bits (Extract (Backends.Native.Splat (Subnormal64), Lane)) = F64_Bits (Subnormal64), "F64 native special-bit splat" & Lane'Image);
      end loop;
      for Lane in Lane_Index_32x4 loop
         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Permute32_Map), Lane)) = F32_Bits (Extract (Slide32, Permute32_Selectors (Lane))) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Permute32_Map), Lane)) = F32_Bits (Extract (Slide32, Permute32_Selectors (Lane))), "F32 special lane permutation" & Lane'Image);
         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Two32_Right, Two32_Map_A), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Slide32 else Two32_Right), Lane)) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Two32_Right, Two32_Map_A), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Slide32 else Two32_Right), Lane)), "F32 special two-source permutation A" & Lane'Image);
         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Two32_Right, Two32_Map_B), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Two32_Right else Slide32), Lane)) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Two32_Right, Two32_Map_B), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Two32_Right else Slide32), Lane)), "F32 special two-source permutation B" & Lane'Image);
      end loop;
      for Pattern in Natural range 0 .. 15 loop
         for Lane in Lane_Index_32x4 loop
            Check (F32_Bits (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide32, Two32_Right), Lane)) = F32_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide32, Lane) else Extract (Two32_Right, Lane))) and then F32_Bits (Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide32, Two32_Right), Lane)) = F32_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide32, Lane) else Extract (Two32_Right, Lane))) and then F32_Bits (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide32, Two32_Right), Lane)) = F32_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide32, Lane) else Extract (Two32_Right, Lane))), "F32 special bitwise root, Scalar, and Native select" & Pattern'Image & Lane'Image);
         end loop;
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
         for Lane in Lane_Index_64x2 loop
            Check (F64_Bits (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide64_A, Slide64_B), Lane)) = F64_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide64_A, Lane) else Extract (Slide64_B, Lane))) and then F64_Bits (Backends.Scalar.Extract (Backends.Scalar.Select_Value (Backends.Scalar.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide64_A, Slide64_B), Lane)) = F64_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide64_A, Lane) else Extract (Slide64_B, Lane))) and then F64_Bits (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide64_A, Slide64_B), Lane)) = F64_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide64_A, Lane) else Extract (Slide64_B, Lane))), "F64 special bitwise root, Scalar, and Native select" & Pattern'Image & Lane'Image);
         end loop;
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
      Check (Flyology_SIMD.To_Bit_Mask (Unordered (Unordered32_Left, Unordered32_Right)) = 7 and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (Unordered32_Left, Unordered32_Right)) = 7 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Unordered32_Left, Unordered32_Right)) = 7, "F32 independent fixed root, Scalar, and Native unordered oracle");
      for Relation in Natural range 0 .. 4 loop
         Check (Flyology_SIMD.To_Bit_Mask ((case Relation is when 0 => Equal (Unordered32_Left, Unordered32_Right), when 1 => Less_Than (Unordered32_Left, Unordered32_Right), when 2 => Less_Equal (Unordered32_Left, Unordered32_Right), when 3 => Greater_Than (Unordered32_Left, Unordered32_Right), when others => Greater_Equal (Unordered32_Left, Unordered32_Right))) = Reference_Comparison_F32x4 (Unordered32_Left, Unordered32_Right, Relation), "F32 directed root ordered NaN oracle" & Relation'Image);
         Check (Backends.Scalar.To_Bit_Mask ((case Relation is when 0 => Backends.Scalar.Equal (Unordered32_Left, Unordered32_Right), when 1 => Backends.Scalar.Less_Than (Unordered32_Left, Unordered32_Right), when 2 => Backends.Scalar.Less_Equal (Unordered32_Left, Unordered32_Right), when 3 => Backends.Scalar.Greater_Than (Unordered32_Left, Unordered32_Right), when others => Backends.Scalar.Greater_Equal (Unordered32_Left, Unordered32_Right))) = Reference_Comparison_F32x4 (Unordered32_Left, Unordered32_Right, Relation), "F32 directed Scalar ordered NaN oracle" & Relation'Image);
         Check (Backends.Native.To_Bit_Mask ((case Relation is when 0 => Backends.Native.Equal (Unordered32_Left, Unordered32_Right), when 1 => Backends.Native.Less_Than (Unordered32_Left, Unordered32_Right), when 2 => Backends.Native.Less_Equal (Unordered32_Left, Unordered32_Right), when 3 => Backends.Native.Greater_Than (Unordered32_Left, Unordered32_Right), when others => Backends.Native.Greater_Equal (Unordered32_Left, Unordered32_Right))) = Reference_Comparison_F32x4 (Unordered32_Left, Unordered32_Right, Relation), "F32 directed Native ordered NaN oracle" & Relation'Image);
      end loop;
      Check (Extract (Backends.Native.Min_Number (A32, B32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A32, B32), 0) = 1.0, "F32 quiet NaN returns number");
      Check ((F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), B32), 0)) and 16#7FC0_0000#) = 16#7FC0_0000#, "F32 signaling NaN is quieted");
      Check (F32_Bits (Extract (Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Max_Number (A32, B32), 2)) = 0 and then F32_Bits (Extract (Min_Number (B32, A32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Max_Number (B32, A32), 2)) = 0 and then F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0 and then F32_Bits (Extract (Backends.Native.Min_Number (B32, A32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (B32, A32), 2)) = 0, "F32 signed zero operand orders");
      Check (Extract (Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Max_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number32, Quiet32), 0) = 1.0, "F32 quiet NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number32, Signal32), 0)), "F32 signaling NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Quiet32), 0)), "F32 two quiet NaNs");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Quiet32), 0)), "F32 signaling then quiet NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Signal32), 0)), "F32 quiet then signaling NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Signal32), 0)), "F32 two signaling NaNs");
      Check (F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), From_Lanes ([SNaN32_B, 0.0, 0.0, 0.0])), 0)) = (F32_Bits (SNaN32) or 16#0040_0000#) and then F32_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN32_B, 0.0, 0.0, 0.0]), From_Lanes ([SNaN32, 0.0, 0.0, 0.0])), 0)) = (F32_Bits (SNaN32_B) or 16#0040_0000#), "F32 signaling NaN left precedence");
      Check (Same (Backends.Scalar.Min_Number (A32, B32), Min_Number (A32, B32)) and then Same (Backends.Scalar.Max_Number (A32, B32), Max_Number (A32, B32)) and then Same (Backends.Scalar.Min_Number (B32, A32), Min_Number (B32, A32)) and then Same (Backends.Scalar.Max_Number (B32, A32), Max_Number (B32, A32)), "F32 scalar signed-zero and quiet-NaN extrema");
      Check (Same (Backends.Scalar.Min_Number (Quiet32, Number32), Min_Number (Quiet32, Number32)) and then Same (Backends.Scalar.Max_Number (Number32, Quiet32), Max_Number (Number32, Quiet32)) and then Same (Backends.Scalar.Min_Number (Signal32, Quiet32), Min_Number (Signal32, Quiet32)) and then Same (Backends.Scalar.Max_Number (Quiet32, Signal32), Max_Number (Quiet32, Signal32)) and then Same (Backends.Scalar.Min_Number (Signal32, Signal32), Min_Number (Signal32, Signal32)) and then Same (Backends.Scalar.Max_Number (Signal32, Signal32), Max_Number (Signal32, Signal32)), "F32 scalar quiet and signaling NaN extrema");
      Check (Same (Backends.Scalar.Add (A32, B32), Add (A32, B32)) and then Same (Backends.Scalar.Subtract (A32, B32), Subtract (A32, B32)) and then Same (Backends.Scalar.Multiply (A32, B32), Multiply (A32, B32)) and then Same (Backends.Scalar.Divide (Numerator32, Zero32), Divide (Numerator32, Zero32)), "F32 scalar IEEE arithmetic edges");
      Check (Is_NaN (Extract (Add (A32, B32), 0)) and then Is_NaN (Extract (Backends.Native.Add (A32, B32), 0)), "F32 NaN addition");
      Check (Is_NaN (Extract (Subtract (A32, B32), 1)) and then Is_NaN (Extract (Backends.Native.Subtract (A32, B32), 1)), "F32 infinity subtraction");
      Check (F32_Bits (Extract (Multiply (A32, B32), 1)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Multiply (A32, B32), 1)) = 16#7F80_0000#, "F32 infinity multiplication");
      Check (F32_Bits (Extract (Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then Is_NaN (Extract (Divide (Numerator32, Zero32), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator32, Zero32), 1)), "F32 division edge cases");
      Check (Is_NaN (Reduce_Add (A32)) and then Is_NaN (Backends.Native.Reduce_Add (A32)), "F32 NaN reduction");
      Check (Is_Quiet_NaN (Reduce_Add (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Add (Signal32)), "F32 signaling NaN addition reduction");
      Check (F32_Bits (Reduce_Add (Add_Negative_Zero32)) = 0 and then F32_Bits (Backends.Native.Reduce_Add (Add_Negative_Zero32)) = 0, "F32 positive-zero reduction start");
      Check (Reduce_Add (Add_Order32) = 1.0 and then Backends.Native.Reduce_Add (Add_Order32) = 1.0, "F32 ascending addition order");
      Check (F32_Bits (Reduce_Min_Number (A32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Min_Number (A32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (A32)) = 16#7F80_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (A32)) = 16#7F80_0000#, "F32 min/max reduction NaN and signed zero");
      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal32)), "F32 signaling NaN reductions");
      Check (Reduce_Min_Number (Fold_Order32) = 3.0 and then Reduce_Max_Number (Fold_Order32) = 3.0 and then Backends.Native.Reduce_Min_Number (Fold_Order32) = 3.0 and then Backends.Native.Reduce_Max_Number (Fold_Order32) = 3.0, "F32 ascending fold order");
      Check (F32_Bits (Reduce_Min_Number (Positive_Zero_First32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (Positive_Zero_First32)) = 0 and then F32_Bits (Reduce_Min_Number (Negative_Zero_First32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (Negative_Zero_First32)) = 0 and then F32_Bits (Backends.Native.Reduce_Min_Number (Positive_Zero_First32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (Positive_Zero_First32)) = 0 and then F32_Bits (Backends.Native.Reduce_Min_Number (Negative_Zero_First32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (Negative_Zero_First32)) = 0, "F32 reduction signed-zero orders");
      Check (Reduce_Min_Number (Quiet_Left32) = 5.0 and then Reduce_Max_Number (Quiet_Left32) = 5.0 and then Reduce_Min_Number (Quiet_Right32) = 5.0 and then Reduce_Max_Number (Quiet_Right32) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Left32) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Left32) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Right32) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Right32) = 5.0, "F32 reduction quiet-NaN orders");
      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal_Left32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Left32)) and then Is_Quiet_NaN (Reduce_Min_Number (Signal_Right32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Right32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Left32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Left32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Right32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Right32)), "F32 reduction signaling-NaN orders");
      Check (Flyology_SIMD.To_Bit_Mask (Unordered (Unordered64_Left, Unordered64_Right)) = 3 and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (Unordered64_Left, Unordered64_Right)) = 3 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Unordered64_Left, Unordered64_Right)) = 3 and then Flyology_SIMD.To_Bit_Mask (Unordered (Unordered64_Both, Unordered64_Both_Right)) = 1 and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (Unordered64_Both, Unordered64_Both_Right)) = 1 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Unordered64_Both, Unordered64_Both_Right)) = 1, "F64 independent fixed root, Scalar, and Native unordered oracle");
      for Relation in Natural range 0 .. 4 loop
         Check (Flyology_SIMD.To_Bit_Mask ((case Relation is when 0 => Equal (Unordered64_Left, Unordered64_Right), when 1 => Less_Than (Unordered64_Left, Unordered64_Right), when 2 => Less_Equal (Unordered64_Left, Unordered64_Right), when 3 => Greater_Than (Unordered64_Left, Unordered64_Right), when others => Greater_Equal (Unordered64_Left, Unordered64_Right))) = Reference_Comparison_F64x2 (Unordered64_Left, Unordered64_Right, Relation), "F64 directed root ordered NaN oracle" & Relation'Image);
         Check (Backends.Scalar.To_Bit_Mask ((case Relation is when 0 => Backends.Scalar.Equal (Unordered64_Left, Unordered64_Right), when 1 => Backends.Scalar.Less_Than (Unordered64_Left, Unordered64_Right), when 2 => Backends.Scalar.Less_Equal (Unordered64_Left, Unordered64_Right), when 3 => Backends.Scalar.Greater_Than (Unordered64_Left, Unordered64_Right), when others => Backends.Scalar.Greater_Equal (Unordered64_Left, Unordered64_Right))) = Reference_Comparison_F64x2 (Unordered64_Left, Unordered64_Right, Relation), "F64 directed Scalar ordered NaN oracle" & Relation'Image);
         Check (Backends.Native.To_Bit_Mask ((case Relation is when 0 => Backends.Native.Equal (Unordered64_Left, Unordered64_Right), when 1 => Backends.Native.Less_Than (Unordered64_Left, Unordered64_Right), when 2 => Backends.Native.Less_Equal (Unordered64_Left, Unordered64_Right), when 3 => Backends.Native.Greater_Than (Unordered64_Left, Unordered64_Right), when others => Backends.Native.Greater_Equal (Unordered64_Left, Unordered64_Right))) = Reference_Comparison_F64x2 (Unordered64_Left, Unordered64_Right, Relation), "F64 directed Native ordered NaN oracle" & Relation'Image);
      end loop;
      for Iteration in 1 .. 250 loop
         declare
            Left32_Lanes : Lane_Values_F32x4;
            Right32_Lanes : Lane_Values_F32x4;
            Left64_Lanes : Lane_Values_F64x2;
            Right64_Lanes : Lane_Values_F64x2;
            Expected32 : Interfaces.Unsigned_8 := 0;
            Expected64 : Interfaces.Unsigned_8 := 0;
         begin
            for Lane in Lane_Index_32x4 loop
               Left32_Lanes (Lane) := To_F32 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFF_FFFF#));
               Right32_Lanes (Lane) := To_F32 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFF_FFFF#));
               if Is_NaN (Left32_Lanes (Lane)) or else Is_NaN (Right32_Lanes (Lane)) then Expected32 := Expected32 or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane); end if;
            end loop;
            for Lane in Lane_Index_64x2 loop
               Left64_Lanes (Lane) := To_F64 (Next_U64);
               Right64_Lanes (Lane) := To_F64 (Next_U64);
               if Is_NaN (Left64_Lanes (Lane)) or else Is_NaN (Right64_Lanes (Lane)) then Expected64 := Expected64 or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane); end if;
            end loop;
            declare
               Left32 : constant F32x4 := From_Lanes (Left32_Lanes);
               Right32 : constant F32x4 := From_Lanes (Right32_Lanes);
               Left64 : constant F64x2 := From_Lanes (Left64_Lanes);
               Right64 : constant F64x2 := From_Lanes (Right64_Lanes);
            begin
               Check (Flyology_SIMD.To_Bit_Mask (Unordered (Left32, Right32)) = Expected32 and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (Left32, Right32)) = Expected32 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Left32, Right32)) = Expected32, "F32 randomized raw-bit root, Scalar, and Native unordered oracle" & Iteration'Image);
               Check (Flyology_SIMD.To_Bit_Mask (Unordered (Left64, Right64)) = Expected64 and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Unordered (Left64, Right64)) = Expected64 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Left64, Right64)) = Expected64, "F64 randomized raw-bit root, Scalar, and Native unordered oracle" & Iteration'Image);
               Check (Flyology_SIMD.To_Bit_Mask (Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 0) and then Flyology_SIMD.To_Bit_Mask (Less_Than (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 1) and then Flyology_SIMD.To_Bit_Mask (Less_Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 2) and then Flyology_SIMD.To_Bit_Mask (Greater_Than (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 3) and then Flyology_SIMD.To_Bit_Mask (Greater_Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (Left32, Right32)) = Reference_Comparison_F32x4 (Left32, Right32, 4), "F32 randomized raw-bit ordered comparison oracles" & Iteration'Image);
               Check (Flyology_SIMD.To_Bit_Mask (Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 0) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 0) and then Backends.Native.To_Bit_Mask (Backends.Native.Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 0) and then Flyology_SIMD.To_Bit_Mask (Less_Than (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 1) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Than (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 1) and then Flyology_SIMD.To_Bit_Mask (Less_Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 2) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Less_Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 2) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 2) and then Flyology_SIMD.To_Bit_Mask (Greater_Than (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 3) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Than (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 3) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 3) and then Flyology_SIMD.To_Bit_Mask (Greater_Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 4) and then Backends.Scalar.To_Bit_Mask (Backends.Scalar.Greater_Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 4) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (Left64, Right64)) = Reference_Comparison_F64x2 (Left64, Right64, 4), "F64 randomized raw-bit ordered comparison oracles" & Iteration'Image);
            end;
         end;
      end loop;
      Check (Extract (Backends.Native.Min_Number (A64, B64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A64, B64), 0) = 1.0, "F64 quiet NaN returns number");
      Check ((F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64, 0.0]), B64), 0)) and 16#7FF8_0000_0000_0000#) = 16#7FF8_0000_0000_0000#, "F64 signaling NaN is quieted");
      Check (F64_Bits (Extract (Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Max_Number (A64, B64), 1)) = 0 and then F64_Bits (Extract (Min_Number (B64, A64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Max_Number (B64, A64), 1)) = 0 and then F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0 and then F64_Bits (Extract (Backends.Native.Min_Number (B64, A64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (B64, A64), 1)) = 0, "F64 signed zero operand orders");
      Check (Extract (Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Max_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number64, Quiet64), 0) = 1.0, "F64 quiet NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number64, Signal64), 0)), "F64 signaling NaN operand orders");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Quiet64), 0)), "F64 two quiet NaNs");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Quiet64), 0)), "F64 signaling then quiet NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Signal64), 0)), "F64 quiet then signaling NaN");
      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Signal64), 0)), "F64 two signaling NaNs");
      Check (F64_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN64, 0.0]), From_Lanes ([SNaN64_B, 0.0])), 0)) = (F64_Bits (SNaN64) or 16#0008_0000_0000_0000#) and then F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64_B, 0.0]), From_Lanes ([SNaN64, 0.0])), 0)) = (F64_Bits (SNaN64_B) or 16#0008_0000_0000_0000#), "F64 signaling NaN left precedence");
      Check (Same (Backends.Scalar.Min_Number (A64, B64), Min_Number (A64, B64)) and then Same (Backends.Scalar.Max_Number (A64, B64), Max_Number (A64, B64)) and then Same (Backends.Scalar.Min_Number (B64, A64), Min_Number (B64, A64)) and then Same (Backends.Scalar.Max_Number (B64, A64), Max_Number (B64, A64)), "F64 scalar signed-zero and quiet-NaN extrema");
      Check (Same (Backends.Scalar.Min_Number (Quiet64, Number64), Min_Number (Quiet64, Number64)) and then Same (Backends.Scalar.Max_Number (Number64, Quiet64), Max_Number (Number64, Quiet64)) and then Same (Backends.Scalar.Min_Number (Signal64, Quiet64), Min_Number (Signal64, Quiet64)) and then Same (Backends.Scalar.Max_Number (Quiet64, Signal64), Max_Number (Quiet64, Signal64)) and then Same (Backends.Scalar.Min_Number (Signal64, Signal64), Min_Number (Signal64, Signal64)) and then Same (Backends.Scalar.Max_Number (Signal64, Signal64), Max_Number (Signal64, Signal64)), "F64 scalar quiet and signaling NaN extrema");
      Check (Same (Backends.Scalar.Add (A64, B64), Add (A64, B64)) and then Same (Backends.Scalar.Subtract (Infinity64, Infinity64), Subtract (Infinity64, Infinity64)) and then Same (Backends.Scalar.Multiply (Infinity64, Twice64), Multiply (Infinity64, Twice64)) and then Same (Backends.Scalar.Divide (Numerator64, Zero64), Divide (Numerator64, Zero64)), "F64 scalar IEEE arithmetic edges");
      Check (Is_NaN (Extract (Add (A64, B64), 0)) and then Is_NaN (Extract (Backends.Native.Add (A64, B64), 0)), "F64 NaN addition");
      Check (Is_NaN (Extract (Subtract (Infinity64, Infinity64), 0)) and then Is_NaN (Extract (Backends.Native.Subtract (Infinity64, Infinity64), 0)), "F64 infinity subtraction");
      Check (F64_Bits (Extract (Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000#, "F64 infinity multiplication");
      Check (F64_Bits (Extract (Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then Is_NaN (Extract (Divide (Numerator64, Zero64), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator64, Zero64), 1)), "F64 division edge cases");
      Check (Is_NaN (Reduce_Add (A64)) and then Is_NaN (Backends.Native.Reduce_Add (A64)), "F64 NaN reduction");
      Check (Is_Quiet_NaN (Reduce_Add (Signal64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Add (Signal64)), "F64 signaling NaN addition reduction");
      Check (F64_Bits (Reduce_Add (Add_Negative_Zero64)) = 0 and then F64_Bits (Backends.Native.Reduce_Add (Add_Negative_Zero64)) = 0, "F64 positive-zero reduction start");
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
