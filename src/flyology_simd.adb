with Ada.Unchecked_Conversion;
with System.Storage_Elements;

package body Flyology_SIMD is
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
   use type System.Storage_Elements.Integer_Address;

   function Zero return U8x16 is (Lanes => [others => 0]);

   function Splat (Value : U8) return U8x16 is
     (Lanes => [others => Value]);

   function From_Lanes (Values : Lane_Values_8x16) return U8x16 is
     (Lanes => Values);

   function To_Lanes (Value : U8x16) return Lane_Values_8x16 is
     (Value.Lanes);

   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8 is
     (Value.Lanes (Lane));

   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16
   is
      Result : U8x16 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) * Right.Lanes (Lane);
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
      Sum    : Natural;
   begin
      for Lane in Lane_Index_8x16 loop
         Sum := Natural (Left.Lanes (Lane)) + Natural (Right.Lanes (Lane));
         Result.Lanes (Lane) := U8 (Natural'Min (Sum, 255));
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         if Left.Lanes (Lane) < Right.Lanes (Lane) then
            Result.Lanes (Lane) := 0;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) and Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) or Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) xor Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := not Value.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16 is
      Result : U8x16;
   begin
      if Count >= 8 then
         return Zero;
      end if;
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Interfaces.Shift_Left (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16 is
      Result : U8x16;
   begin
      if Count >= 8 then
         return Zero;
      end if;
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Interfaces.Shift_Right (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Comparison
     (Left, Right : U8x16; Kind : Character) return Mask_8x16
   is
      Bits : Interfaces.Unsigned_16 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_8x16 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then
            Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane);
         end if;
      end loop;
      return (Bits => Bits);
   end Comparison;

   function Equal (Left, Right : U8x16) return Mask_8x16 is
     (Comparison (Left, Right, '='));
   function Less_Than (Left, Right : U8x16) return Mask_8x16 is
     (Comparison (Left, Right, '<'));
   function Less_Equal (Left, Right : U8x16) return Mask_8x16 is
     (Comparison (Left, Right, 'L'));
   function Greater_Than (Left, Right : U8x16) return Mask_8x16 is
     (Comparison (Left, Right, '>'));
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16 is
     (Comparison (Left, Right, 'G'));

   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16
   is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) :=
           (if Test (Mask, Lane) then If_True.Lanes (Lane)
            else If_False.Lanes (Lane));
      end loop;
      return Result;
   end Select_Value;

   function Min (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := U8'Min (Left.Lanes (Lane), Right.Lanes (Lane));
      end loop;
      return Result;
   end Min;

   function Max (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := U8'Max (Left.Lanes (Lane), Right.Lanes (Lane));
      end loop;
      return Result;
   end Max;

   function Horizontal_Sum (Value : U8x16) return Natural is
      Result : Natural := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         Result := Result + Natural (Value.Lanes (Lane));
      end loop;
      return Result;
   end Horizontal_Sum;

   function Reduce_Add_Wrap (Value : U8x16) return U8 is
      Result : U8 := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         Result := Result + Value.Lanes (Lane);
      end loop;
      return Result;
   end Reduce_Add_Wrap;

   function Reduce_Min (Value : U8x16) return U8 is
      Result : U8 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_8x16 range 1 .. 15 loop
         Result := U8'Min (Result, Value.Lanes (Lane));
      end loop;
      return Result;
   end Reduce_Min;

   function Reduce_Max (Value : U8x16) return U8 is
      Result : U8 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_8x16 range 1 .. 15 loop
         Result := U8'Max (Result, Value.Lanes (Lane));
      end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Bytes (Value : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Value.Lanes (15 - Lane);
      end loop;
      return Result;
   end Reverse_Bytes;

   function Reverse_Lanes (Value : U8x16) return U8x16 is
     (Reverse_Bytes (Value));

   function Interleave_Low (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane);
      end loop;
      return Result;
   end Interleave_Low;

   function Interleave_High (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 8);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 8);
      end loop;
      return Result;
   end Interleave_High;

   function Deinterleave_Even (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane);
         Result.Lanes (Lane + 8) := Right.Lanes (2 * Lane);
      end loop;
      return Result;
   end Deinterleave_Even;

   function Deinterleave_Odd (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 8) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16) return Mask_8x16 is
     (Bits => Bits);
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Mask.Bits);
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => Left.Bits and Right.Bits);
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => Left.Bits or Right.Bits);
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => Left.Bits xor Right.Bits);
   function Mask_Not (Value : Mask_8x16) return Mask_8x16 is
     (Bits => not Value.Bits);

   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean is
     ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_8x16) return Boolean is (Mask.Bits /= 0);
   function All_True (Mask : Mask_8x16) return Boolean is
     (Mask.Bits = Interfaces.Unsigned_16'Last);
   function None_True (Mask : Mask_8x16) return Boolean is (Mask.Bits = 0);

   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16 is
      Bits   : Interfaces.Unsigned_16 := Mask.Bits;
      Result : Lane_Count_8x16 := 0;
   begin
      while Bits /= 0 loop
         Result := Result + 1;
         Bits := Bits and (Bits - 1);
      end loop;
      return Result;
   end Population_Count;

   function Has_Extent
     (Data : Byte_Array; Start : Natural; Count : Natural) return Boolean
   is
   begin
      return Count = 0
        or else (Start in Data'Range
                 and then Count - 1 <= Natural (Data'Last - Start));
   end Has_Extent;

   function Is_Aligned_16 (Data : Byte_Array; Start : Natural) return Boolean is
      use System.Storage_Elements;
   begin
      return Start in Data'Range
        and then To_Integer (Data (Start)'Address) mod 16 = 0;
   end Is_Aligned_16;

   function Load (Data : Byte_Array; Start : Natural) return U8x16 is
     (Load_Unaligned (Data, Start));

   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Store_Unaligned (Data, Start, Value);
   end Store;

   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Data (Start + Lane);
      end loop;
      return Result;
   end Load_Unaligned;

   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      for Lane in Lane_Index_8x16 loop
         Data (Start + Lane) := Value.Lanes (Lane);
      end loop;
   end Store_Unaligned;

   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16 is
     (Load_Unaligned (Data, Start));

   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Store_Unaligned (Data, Start, Value);
   end Store_Aligned;

   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
   is
      Result : U8x16 := Zero;
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;

   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane);
         end loop;
      end if;
   end Store_Partial;

   --  BEGIN GENERATED 128-BIT SCALAR BODIES
   function Cast_U8_To_I8_For_U8x16 is new Ada.Unchecked_Conversion (U8, I8);
   function Bit_Cast (Value : U8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Cast_U8_To_I8_For_U8x16 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_I8_To_U8_For_I8x16 is new Ada.Unchecked_Conversion (I8, U8);
   function Bit_Cast (Value : I8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Cast_I8_To_U8_For_I8x16 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_U16_To_I16_For_U16x8 is new Ada.Unchecked_Conversion (U16, I16);
   function Bit_Cast (Value : U16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Cast_U16_To_I16_For_U16x8 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_I16_To_U16_For_I16x8 is new Ada.Unchecked_Conversion (I16, U16);
   function Bit_Cast (Value : I16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Cast_I16_To_U16_For_I16x8 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_U32_To_I32_For_U32x4 is new Ada.Unchecked_Conversion (U32, I32);
   function Bit_Cast (Value : U32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Cast_U32_To_I32_For_U32x4 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_U32_To_F32_For_U32x4 is new Ada.Unchecked_Conversion (U32, F32);
   function Bit_Cast (Value : U32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Cast_U32_To_F32_For_U32x4 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_I32_To_U32_For_I32x4 is new Ada.Unchecked_Conversion (I32, U32);
   function Bit_Cast (Value : I32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Cast_I32_To_U32_For_I32x4 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_I32_To_F32_For_I32x4 is new Ada.Unchecked_Conversion (I32, F32);
   function Bit_Cast (Value : I32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Cast_I32_To_F32_For_I32x4 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_F32_To_U32_For_F32x4 is new Ada.Unchecked_Conversion (F32, U32);
   function Bit_Cast (Value : F32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Cast_F32_To_U32_For_F32x4 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_F32_To_I32_For_F32x4 is new Ada.Unchecked_Conversion (F32, I32);
   function Bit_Cast (Value : F32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Cast_F32_To_I32_For_F32x4 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_U64_To_I64_For_U64x2 is new Ada.Unchecked_Conversion (U64, I64);
   function Bit_Cast (Value : U64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Cast_U64_To_I64_For_U64x2 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_U64_To_F64_For_U64x2 is new Ada.Unchecked_Conversion (U64, F64);
   function Bit_Cast (Value : U64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Cast_U64_To_F64_For_U64x2 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_I64_To_U64_For_I64x2 is new Ada.Unchecked_Conversion (I64, U64);
   function Bit_Cast (Value : I64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Cast_I64_To_U64_For_I64x2 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_I64_To_F64_For_I64x2 is new Ada.Unchecked_Conversion (I64, F64);
   function Bit_Cast (Value : I64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Cast_I64_To_F64_For_I64x2 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_F64_To_U64_For_F64x2 is new Ada.Unchecked_Conversion (F64, U64);
   function Bit_Cast (Value : F64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Cast_F64_To_U64_For_F64x2 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Cast_F64_To_I64_For_F64x2 is new Ada.Unchecked_Conversion (F64, I64);
   function Bit_Cast (Value : F64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Cast_F64_To_I64_For_F64x2 (Value.Lanes (Lane));
      end loop;
      return Result;
   end Bit_Cast;

   function Widen_Low (Value : U8x16) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := U16 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : U8x16) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := U16 (Value.Lanes (Lane + 8));
      end loop;
      return Result;
   end Widen_High;

   function Widen_Low (Value : I8x16) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := I16 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : I8x16) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := I16 (Value.Lanes (Lane + 8));
      end loop;
      return Result;
   end Widen_High;

   function Widen_Low (Value : U16x8) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := U32 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : U16x8) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := U32 (Value.Lanes (Lane + 4));
      end loop;
      return Result;
   end Widen_High;

   function Widen_Low (Value : I16x8) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := I32 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : I16x8) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := I32 (Value.Lanes (Lane + 4));
      end loop;
      return Result;
   end Widen_High;

   function Widen_Low (Value : U32x4) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := U64 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : U32x4) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := U64 (Value.Lanes (Lane + 2));
      end loop;
      return Result;
   end Widen_High;

   function Widen_Low (Value : I32x4) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := I64 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : I32x4) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := I64 (Value.Lanes (Lane + 2));
      end loop;
      return Result;
   end Widen_High;

   function Widen_Low (Value : F32x4) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := F64 (Value.Lanes (Lane + 0));
      end loop;
      return Result;
   end Widen_Low;

   function Widen_High (Value : F32x4) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := F64 (Value.Lanes (Lane + 2));
      end loop;
      return Result;
   end Widen_High;

   function Narrow_Truncate_U16x8_Lane (Item : U16) return U8 is
     (U8 (Item and U16 (U8'Last)));
   function Narrow_Truncate (Low, High : U16x8) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Narrow_Truncate_U16x8_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 8) := Narrow_Truncate_U16x8_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Truncate;

   function Narrow_Saturate_U16x8_Lane (Item : U16) return U8 is
     ((if Item > U16 (U8'Last) then U8'Last else U8 (Item)));
   function Narrow_Saturate (Low, High : U16x8) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Narrow_Saturate_U16x8_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 8) := Narrow_Saturate_U16x8_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Bits_Of_I16 is new Ada.Unchecked_Conversion (I16, U16);
   function Narrow_I8_Of_Bits is new Ada.Unchecked_Conversion (U8, I8);
   function Narrow_Truncate_I16x8_Lane (Item : I16) return I8 is
     (Narrow_I8_Of_Bits (U8 (Narrow_Bits_Of_I16 (Item) and U16 (U8'Last))));
   function Narrow_Truncate (Low, High : I16x8) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Narrow_Truncate_I16x8_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 8) := Narrow_Truncate_I16x8_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Truncate;

   function Narrow_Saturate_I16x8_Lane (Item : I16) return I8 is
     ((if Item < I16 (I8'First) then I8'First elsif Item > I16 (I8'Last) then I8'Last else I8 (Item)));
   function Narrow_Saturate (Low, High : I16x8) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Narrow_Saturate_I16x8_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 8) := Narrow_Saturate_I16x8_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Truncate_U32x4_Lane (Item : U32) return U16 is
     (U16 (Item and U32 (U16'Last)));
   function Narrow_Truncate (Low, High : U32x4) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Narrow_Truncate_U32x4_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 4) := Narrow_Truncate_U32x4_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Truncate;

   function Narrow_Saturate_U32x4_Lane (Item : U32) return U16 is
     ((if Item > U32 (U16'Last) then U16'Last else U16 (Item)));
   function Narrow_Saturate (Low, High : U32x4) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Narrow_Saturate_U32x4_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 4) := Narrow_Saturate_U32x4_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Bits_Of_I32 is new Ada.Unchecked_Conversion (I32, U32);
   function Narrow_I16_Of_Bits is new Ada.Unchecked_Conversion (U16, I16);
   function Narrow_Truncate_I32x4_Lane (Item : I32) return I16 is
     (Narrow_I16_Of_Bits (U16 (Narrow_Bits_Of_I32 (Item) and U32 (U16'Last))));
   function Narrow_Truncate (Low, High : I32x4) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Narrow_Truncate_I32x4_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 4) := Narrow_Truncate_I32x4_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Truncate;

   function Narrow_Saturate_I32x4_Lane (Item : I32) return I16 is
     ((if Item < I32 (I16'First) then I16'First elsif Item > I32 (I16'Last) then I16'Last else I16 (Item)));
   function Narrow_Saturate (Low, High : I32x4) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Narrow_Saturate_I32x4_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 4) := Narrow_Saturate_I32x4_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Truncate_U64x2_Lane (Item : U64) return U32 is
     (U32 (Item and U64 (U32'Last)));
   function Narrow_Truncate (Low, High : U64x2) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Narrow_Truncate_U64x2_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 2) := Narrow_Truncate_U64x2_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Truncate;

   function Narrow_Saturate_U64x2_Lane (Item : U64) return U32 is
     ((if Item > U64 (U32'Last) then U32'Last else U32 (Item)));
   function Narrow_Saturate (Low, High : U64x2) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Narrow_Saturate_U64x2_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 2) := Narrow_Saturate_U64x2_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Bits_Of_I64 is new Ada.Unchecked_Conversion (I64, U64);
   function Narrow_I32_Of_Bits is new Ada.Unchecked_Conversion (U32, I32);
   function Narrow_Truncate_I64x2_Lane (Item : I64) return I32 is
     (Narrow_I32_Of_Bits (U32 (Narrow_Bits_Of_I64 (Item) and U64 (U32'Last))));
   function Narrow_Truncate (Low, High : I64x2) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Narrow_Truncate_I64x2_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 2) := Narrow_Truncate_I64x2_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Truncate;

   function Narrow_Saturate_I64x2_Lane (Item : I64) return I32 is
     ((if Item < I64 (I32'First) then I32'First elsif Item > I64 (I32'Last) then I32'Last else I32 (Item)));
   function Narrow_Saturate (Low, High : I64x2) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Narrow_Saturate_I64x2_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 2) := Narrow_Saturate_I64x2_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Saturate_I16x8_To_U8x16_Lane (Item : I16) return U8 is
     (if Item < 0 then 0 elsif Item > I16 (U8'Last) then U8'Last else U8 (Item));
   function Narrow_Saturate (Low, High : I16x8) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Narrow_Saturate_I16x8_To_U8x16_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 8) := Narrow_Saturate_I16x8_To_U8x16_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Saturate_I32x4_To_U16x8_Lane (Item : I32) return U16 is
     (if Item < 0 then 0 elsif Item > I32 (U16'Last) then U16'Last else U16 (Item));
   function Narrow_Saturate (Low, High : I32x4) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Narrow_Saturate_I32x4_To_U16x8_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 4) := Narrow_Saturate_I32x4_To_U16x8_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function Narrow_Saturate_I64x2_To_U32x4_Lane (Item : I64) return U32 is
     (if Item < 0 then 0 elsif Item > I64 (U32'Last) then U32'Last else U32 (Item));
   function Narrow_Saturate (Low, High : I64x2) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Narrow_Saturate_I64x2_To_U32x4_Lane (Low.Lanes (Lane));
         Result.Lanes (Lane + 2) := Narrow_Saturate_I64x2_To_U32x4_Lane (High.Lanes (Lane));
      end loop;
      return Result;
   end Narrow_Saturate;

   function To_U8 is new Ada.Unchecked_Conversion (I8, U8);
   function To_I8 is new Ada.Unchecked_Conversion (U8, I8);

   function Zero return I8x16 is (Lanes => [others => 0]);
   function Splat (Value : I8) return I8x16 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16 is (Lanes => Values);
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16 is (Value.Lanes);
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8 is (Value.Lanes (Lane));
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16 is
      Result : I8x16 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (To_U8 (Left.Lanes (Lane)) + To_U8 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (To_U8 (Left.Lanes (Lane)) - To_U8 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (To_U8 (Left.Lanes (Lane)) * To_U8 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         if Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) > I8'Last - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I8'Last;
         elsif Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) < I8'First - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I8'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         if Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) > I8'Last + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I8'Last;
         elsif Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) < I8'First + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I8'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (To_U8 (Left.Lanes (Lane)) and To_U8 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (To_U8 (Left.Lanes (Lane)) or To_U8 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (To_U8 (Left.Lanes (Lane)) xor To_U8 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (not To_U8 (Value.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16 is
      Result : I8x16;
   begin
      if Count >= 8 then return Zero; end if;
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (Interfaces.Shift_Left (To_U8 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16 is
      Result : I8x16;
   begin
      if Count >= 8 then return Zero; end if;
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (Interfaces.Shift_Right (To_U8 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16 is
      Result : I8x16;
   begin
      if Count >= 8 then
         for Lane in Lane_Index_8x16 loop Result.Lanes (Lane) := (if Value.Lanes (Lane) < 0 then -1 else 0); end loop;
         return Result;
      end if;
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := To_I8 (Interfaces.Shift_Right_Arithmetic (To_U8 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Arithmetic;

   function Compare_I8x16 (Left, Right : I8x16; Kind : Character) return Mask_8x16 is
      Bits : Interfaces.Unsigned_16 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_8x16 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_I8x16;
   function Equal (Left, Right : I8x16) return Mask_8x16 is (Compare_I8x16 (Left, Right, '='));
   function Less_Than (Left, Right : I8x16) return Mask_8x16 is (Compare_I8x16 (Left, Right, '<'));
   function Less_Equal (Left, Right : I8x16) return Mask_8x16 is (Compare_I8x16 (Left, Right, 'L'));
   function Greater_Than (Left, Right : I8x16) return Mask_8x16 is (Compare_I8x16 (Left, Right, '>'));
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16 is (Compare_I8x16 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result.Lanes (Lane) := I8'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result.Lanes (Lane) := I8'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : I8x16) return I8 is
      Result : I8 := 0;
   begin
      for Lane in Lane_Index_8x16 loop Result := To_I8 (To_U8 (Result) + To_U8 (Value.Lanes (Lane))); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : I8x16) return I8 is
      Result : I8 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_8x16 range 1 .. 15 loop Result := I8'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : I8x16) return I8 is
      Result : I8 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_8x16 range 1 .. 15 loop Result := I8'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result.Lanes (Lane) := Value.Lanes (15 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 8);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 8);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 8) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Natural range 0 .. 7 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 8) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 is
      Result : I8x16;
   begin
      for Lane in Lane_Index_8x16 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin
      for Lane in Lane_Index_8x16 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 is
      Result : I8x16 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function Zero return U16x8 is (Lanes => [others => 0]);
   function Splat (Value : U16) return U16x8 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8 is (Lanes => Values);
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8 is (Value.Lanes);
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16 is (Value.Lanes (Lane));
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8 is
      Result : U16x8 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) * Right.Lanes (Lane);
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := (if Left.Lanes (Lane) > U16'Last - Right.Lanes (Lane) then U16'Last else Left.Lanes (Lane) + Right.Lanes (Lane));
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := (if Left.Lanes (Lane) < Right.Lanes (Lane) then 0 else Left.Lanes (Lane) - Right.Lanes (Lane));
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) and Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) or Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) xor Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := not Value.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8 is
      Result : U16x8;
   begin
      if Count >= 16 then return Zero; end if;
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Interfaces.Shift_Left (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8 is
      Result : U16x8;
   begin
      if Count >= 16 then return Zero; end if;
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := Interfaces.Shift_Right (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Compare_U16x8 (Left, Right : U16x8; Kind : Character) return Mask_16x8 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_16x8 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_U16x8;
   function Equal (Left, Right : U16x8) return Mask_16x8 is (Compare_U16x8 (Left, Right, '='));
   function Less_Than (Left, Right : U16x8) return Mask_16x8 is (Compare_U16x8 (Left, Right, '<'));
   function Less_Equal (Left, Right : U16x8) return Mask_16x8 is (Compare_U16x8 (Left, Right, 'L'));
   function Greater_Than (Left, Right : U16x8) return Mask_16x8 is (Compare_U16x8 (Left, Right, '>'));
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8 is (Compare_U16x8 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := U16'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := U16'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : U16x8) return U16 is
      Result : U16 := 0;
   begin
      for Lane in Lane_Index_16x8 loop Result := Result + Value.Lanes (Lane); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : U16x8) return U16 is
      Result : U16 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_16x8 range 1 .. 7 loop Result := U16'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : U16x8) return U16 is
      Result : U16 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_16x8 range 1 .. 7 loop Result := U16'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := Value.Lanes (7 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 4);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 4);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 4) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 4) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 is
      Result : U16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin
      for Lane in Lane_Index_16x8 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 is
      Result : U16x8 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function To_U16 is new Ada.Unchecked_Conversion (I16, U16);
   function To_I16 is new Ada.Unchecked_Conversion (U16, I16);

   function Zero return I16x8 is (Lanes => [others => 0]);
   function Splat (Value : I16) return I16x8 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8 is (Lanes => Values);
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8 is (Value.Lanes);
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16 is (Value.Lanes (Lane));
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8 is
      Result : I16x8 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (To_U16 (Left.Lanes (Lane)) + To_U16 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (To_U16 (Left.Lanes (Lane)) - To_U16 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (To_U16 (Left.Lanes (Lane)) * To_U16 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         if Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) > I16'Last - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I16'Last;
         elsif Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) < I16'First - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I16'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         if Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) > I16'Last + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I16'Last;
         elsif Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) < I16'First + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I16'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (To_U16 (Left.Lanes (Lane)) and To_U16 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (To_U16 (Left.Lanes (Lane)) or To_U16 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (To_U16 (Left.Lanes (Lane)) xor To_U16 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (not To_U16 (Value.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8 is
      Result : I16x8;
   begin
      if Count >= 16 then return Zero; end if;
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (Interfaces.Shift_Left (To_U16 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8 is
      Result : I16x8;
   begin
      if Count >= 16 then return Zero; end if;
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (Interfaces.Shift_Right (To_U16 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8 is
      Result : I16x8;
   begin
      if Count >= 16 then
         for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := (if Value.Lanes (Lane) < 0 then -1 else 0); end loop;
         return Result;
      end if;
      for Lane in Lane_Index_16x8 loop
         Result.Lanes (Lane) := To_I16 (Interfaces.Shift_Right_Arithmetic (To_U16 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Arithmetic;

   function Compare_I16x8 (Left, Right : I16x8; Kind : Character) return Mask_16x8 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_16x8 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_I16x8;
   function Equal (Left, Right : I16x8) return Mask_16x8 is (Compare_I16x8 (Left, Right, '='));
   function Less_Than (Left, Right : I16x8) return Mask_16x8 is (Compare_I16x8 (Left, Right, '<'));
   function Less_Equal (Left, Right : I16x8) return Mask_16x8 is (Compare_I16x8 (Left, Right, 'L'));
   function Greater_Than (Left, Right : I16x8) return Mask_16x8 is (Compare_I16x8 (Left, Right, '>'));
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8 is (Compare_I16x8 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := I16'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := I16'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : I16x8) return I16 is
      Result : I16 := 0;
   begin
      for Lane in Lane_Index_16x8 loop Result := To_I16 (To_U16 (Result) + To_U16 (Value.Lanes (Lane))); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : I16x8) return I16 is
      Result : I16 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_16x8 range 1 .. 7 loop Result := I16'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : I16x8) return I16 is
      Result : I16 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_16x8 range 1 .. 7 loop Result := I16'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := Value.Lanes (7 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 4);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 4);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 4) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Natural range 0 .. 3 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 4) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 is
      Result : I16x8;
   begin
      for Lane in Lane_Index_16x8 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin
      for Lane in Lane_Index_16x8 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 is
      Result : I16x8 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function Zero return U32x4 is (Lanes => [others => 0]);
   function Splat (Value : U32) return U32x4 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4 is (Lanes => Values);
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4 is (Value.Lanes);
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32 is (Value.Lanes (Lane));
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4 is
      Result : U32x4 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) * Right.Lanes (Lane);
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := (if Left.Lanes (Lane) > U32'Last - Right.Lanes (Lane) then U32'Last else Left.Lanes (Lane) + Right.Lanes (Lane));
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := (if Left.Lanes (Lane) < Right.Lanes (Lane) then 0 else Left.Lanes (Lane) - Right.Lanes (Lane));
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) and Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) or Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) xor Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := not Value.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4 is
      Result : U32x4;
   begin
      if Count >= 32 then return Zero; end if;
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Interfaces.Shift_Left (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4 is
      Result : U32x4;
   begin
      if Count >= 32 then return Zero; end if;
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := Interfaces.Shift_Right (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Compare_U32x4 (Left, Right : U32x4; Kind : Character) return Mask_32x4 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_32x4 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_U32x4;
   function Equal (Left, Right : U32x4) return Mask_32x4 is (Compare_U32x4 (Left, Right, '='));
   function Less_Than (Left, Right : U32x4) return Mask_32x4 is (Compare_U32x4 (Left, Right, '<'));
   function Less_Equal (Left, Right : U32x4) return Mask_32x4 is (Compare_U32x4 (Left, Right, 'L'));
   function Greater_Than (Left, Right : U32x4) return Mask_32x4 is (Compare_U32x4 (Left, Right, '>'));
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4 is (Compare_U32x4 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := U32'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := U32'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : U32x4) return U32 is
      Result : U32 := 0;
   begin
      for Lane in Lane_Index_32x4 loop Result := Result + Value.Lanes (Lane); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : U32x4) return U32 is
      Result : U32 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_32x4 range 1 .. 3 loop Result := U32'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : U32x4) return U32 is
      Result : U32 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_32x4 range 1 .. 3 loop Result := U32'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Value.Lanes (3 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 2);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 2);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 2) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 2) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 is
      Result : U32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin
      for Lane in Lane_Index_32x4 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 is
      Result : U32x4 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function To_U32 is new Ada.Unchecked_Conversion (I32, U32);
   function To_I32 is new Ada.Unchecked_Conversion (U32, I32);

   function Zero return I32x4 is (Lanes => [others => 0]);
   function Splat (Value : I32) return I32x4 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4 is (Lanes => Values);
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4 is (Value.Lanes);
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32 is (Value.Lanes (Lane));
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4 is
      Result : I32x4 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (To_U32 (Left.Lanes (Lane)) + To_U32 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (To_U32 (Left.Lanes (Lane)) - To_U32 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (To_U32 (Left.Lanes (Lane)) * To_U32 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         if Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) > I32'Last - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I32'Last;
         elsif Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) < I32'First - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I32'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         if Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) > I32'Last + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I32'Last;
         elsif Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) < I32'First + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I32'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (To_U32 (Left.Lanes (Lane)) and To_U32 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (To_U32 (Left.Lanes (Lane)) or To_U32 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (To_U32 (Left.Lanes (Lane)) xor To_U32 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (not To_U32 (Value.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4 is
      Result : I32x4;
   begin
      if Count >= 32 then return Zero; end if;
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (Interfaces.Shift_Left (To_U32 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4 is
      Result : I32x4;
   begin
      if Count >= 32 then return Zero; end if;
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (Interfaces.Shift_Right (To_U32 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4 is
      Result : I32x4;
   begin
      if Count >= 32 then
         for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := (if Value.Lanes (Lane) < 0 then -1 else 0); end loop;
         return Result;
      end if;
      for Lane in Lane_Index_32x4 loop
         Result.Lanes (Lane) := To_I32 (Interfaces.Shift_Right_Arithmetic (To_U32 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Arithmetic;

   function Compare_I32x4 (Left, Right : I32x4; Kind : Character) return Mask_32x4 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_32x4 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_I32x4;
   function Equal (Left, Right : I32x4) return Mask_32x4 is (Compare_I32x4 (Left, Right, '='));
   function Less_Than (Left, Right : I32x4) return Mask_32x4 is (Compare_I32x4 (Left, Right, '<'));
   function Less_Equal (Left, Right : I32x4) return Mask_32x4 is (Compare_I32x4 (Left, Right, 'L'));
   function Greater_Than (Left, Right : I32x4) return Mask_32x4 is (Compare_I32x4 (Left, Right, '>'));
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4 is (Compare_I32x4 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := I32'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := I32'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : I32x4) return I32 is
      Result : I32 := 0;
   begin
      for Lane in Lane_Index_32x4 loop Result := To_I32 (To_U32 (Result) + To_U32 (Value.Lanes (Lane))); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : I32x4) return I32 is
      Result : I32 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_32x4 range 1 .. 3 loop Result := I32'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : I32x4) return I32 is
      Result : I32 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_32x4 range 1 .. 3 loop Result := I32'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Value.Lanes (3 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 2);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 2);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 2) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Natural range 0 .. 1 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 2) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 is
      Result : I32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin
      for Lane in Lane_Index_32x4 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 is
      Result : I32x4 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function Zero return U64x2 is (Lanes => [others => 0]);
   function Splat (Value : U64) return U64x2 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2 is (Lanes => Values);
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2 is (Value.Lanes);
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64 is (Value.Lanes (Lane));
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2 is
      Result : U64x2 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) * Right.Lanes (Lane);
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := (if Left.Lanes (Lane) > U64'Last - Right.Lanes (Lane) then U64'Last else Left.Lanes (Lane) + Right.Lanes (Lane));
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := (if Left.Lanes (Lane) < Right.Lanes (Lane) then 0 else Left.Lanes (Lane) - Right.Lanes (Lane));
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) and Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) or Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Left.Lanes (Lane) xor Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := not Value.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2 is
      Result : U64x2;
   begin
      if Count >= 64 then return Zero; end if;
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Interfaces.Shift_Left (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2 is
      Result : U64x2;
   begin
      if Count >= 64 then return Zero; end if;
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := Interfaces.Shift_Right (Value.Lanes (Lane), Count);
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Compare_U64x2 (Left, Right : U64x2; Kind : Character) return Mask_64x2 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_64x2 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_U64x2;
   function Equal (Left, Right : U64x2) return Mask_64x2 is (Compare_U64x2 (Left, Right, '='));
   function Less_Than (Left, Right : U64x2) return Mask_64x2 is (Compare_U64x2 (Left, Right, '<'));
   function Less_Equal (Left, Right : U64x2) return Mask_64x2 is (Compare_U64x2 (Left, Right, 'L'));
   function Greater_Than (Left, Right : U64x2) return Mask_64x2 is (Compare_U64x2 (Left, Right, '>'));
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2 is (Compare_U64x2 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := U64'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := U64'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : U64x2) return U64 is
      Result : U64 := 0;
   begin
      for Lane in Lane_Index_64x2 loop Result := Result + Value.Lanes (Lane); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : U64x2) return U64 is
      Result : U64 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_64x2 range 1 .. 1 loop Result := U64'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : U64x2) return U64 is
      Result : U64 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_64x2 range 1 .. 1 loop Result := U64'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Value.Lanes (1 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 1);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 1);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 1) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 1) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 is
      Result : U64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin
      for Lane in Lane_Index_64x2 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 is
      Result : U64x2 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function To_U64 is new Ada.Unchecked_Conversion (I64, U64);
   function To_I64 is new Ada.Unchecked_Conversion (U64, I64);

   function Zero return I64x2 is (Lanes => [others => 0]);
   function Splat (Value : I64) return I64x2 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2 is (Lanes => Values);
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2 is (Value.Lanes);
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64 is (Value.Lanes (Lane));
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2 is
      Result : I64x2 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (To_U64 (Left.Lanes (Lane)) + To_U64 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Add_Wrap;

   function Subtract_Wrap (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (To_U64 (Left.Lanes (Lane)) - To_U64 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Subtract_Wrap;

   function Multiply_Wrap (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (To_U64 (Left.Lanes (Lane)) * To_U64 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Multiply_Wrap;

   function Add_Saturate (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         if Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) > I64'Last - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I64'Last;
         elsif Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) < I64'First - Right.Lanes (Lane) then
            Result.Lanes (Lane) := I64'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Add_Saturate;

   function Subtract_Saturate (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         if Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) > I64'Last + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I64'Last;
         elsif Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) < I64'First + Right.Lanes (Lane) then
            Result.Lanes (Lane) := I64'First;
         else
            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);
         end if;
      end loop;
      return Result;
   end Subtract_Saturate;

   function Bitwise_And (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (To_U64 (Left.Lanes (Lane)) and To_U64 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (To_U64 (Left.Lanes (Lane)) or To_U64 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (To_U64 (Left.Lanes (Lane)) xor To_U64 (Right.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Value : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (not To_U64 (Value.Lanes (Lane)));
      end loop;
      return Result;
   end Bitwise_Not;

   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2 is
      Result : I64x2;
   begin
      if Count >= 64 then return Zero; end if;
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (Interfaces.Shift_Left (To_U64 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2 is
      Result : I64x2;
   begin
      if Count >= 64 then return Zero; end if;
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (Interfaces.Shift_Right (To_U64 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Logical;

   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2 is
      Result : I64x2;
   begin
      if Count >= 64 then
         for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := (if Value.Lanes (Lane) < 0 then -1 else 0); end loop;
         return Result;
      end if;
      for Lane in Lane_Index_64x2 loop
         Result.Lanes (Lane) := To_I64 (Interfaces.Shift_Right_Arithmetic (To_U64 (Value.Lanes (Lane)), Count));
      end loop;
      return Result;
   end Shift_Right_Arithmetic;

   function Compare_I64x2 (Left, Right : I64x2; Kind : Character) return Mask_64x2 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_64x2 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_I64x2;
   function Equal (Left, Right : I64x2) return Mask_64x2 is (Compare_I64x2 (Left, Right, '='));
   function Less_Than (Left, Right : I64x2) return Mask_64x2 is (Compare_I64x2 (Left, Right, '<'));
   function Less_Equal (Left, Right : I64x2) return Mask_64x2 is (Compare_I64x2 (Left, Right, 'L'));
   function Greater_Than (Left, Right : I64x2) return Mask_64x2 is (Compare_I64x2 (Left, Right, '>'));
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2 is (Compare_I64x2 (Left, Right, 'G'));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := I64'Min (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Min;
   function Max (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := I64'Max (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;
      return Result;
   end Max;
   function Reduce_Add_Wrap (Value : I64x2) return I64 is
      Result : I64 := 0;
   begin
      for Lane in Lane_Index_64x2 loop Result := To_I64 (To_U64 (Result) + To_U64 (Value.Lanes (Lane))); end loop;
      return Result;
   end Reduce_Add_Wrap;
   function Reduce_Min (Value : I64x2) return I64 is
      Result : I64 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_64x2 range 1 .. 1 loop Result := I64'Min (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : I64x2) return I64 is
      Result : I64 := Value.Lanes (0);
   begin
      for Lane in Lane_Index_64x2 range 1 .. 1 loop Result := I64'Max (Result, Value.Lanes (Lane)); end loop;
      return Result;
   end Reduce_Max;

   function Reverse_Lanes (Value : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Value.Lanes (1 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0);
      end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (2 * Lane) := Left.Lanes (Lane + 1);
         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 1);
      end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0);
         Result.Lanes (Lane + 1) := Right.Lanes (2 * Lane + 0);
      end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Natural range 0 .. 0 loop
         Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1);
         Result.Lanes (Lane + 1) := Right.Lanes (2 * Lane + 1);
      end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 is
      Result : I64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin
      for Lane in Lane_Index_64x2 loop Data (Start + Lane) := Value.Lanes (Lane); end loop;
   end Store_Unaligned;
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 is
      Result : I64x2 := Zero;
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) is
   begin
      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;
   end Store_Partial;

   function Bits_Of_F32 is new Ada.Unchecked_Conversion (F32, U32);
   function F32_Of_Bits is new Ada.Unchecked_Conversion (U32, F32);
   function Is_Signaling_NaN (Value : F32) return Boolean is
      Bits : constant U32 := Bits_Of_F32 (Value);
   begin
      return (Bits and 16#7F80_0000#) = 16#7F80_0000#
        and then (Bits and 16#007F_FFFF#) /= 0
        and then (Bits and 16#0040_0000#) = 0;
   end Is_Signaling_NaN;
   function Quiet_NaN (Value : F32) return F32 is
     (F32_Of_Bits (Bits_Of_F32 (Value) or 16#0040_0000#));
   function Zero return F32x4 is (Lanes => [others => 0.0]);
   function Splat (Value : F32) return F32x4 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4 is (Lanes => Values);
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4 is (Value.Lanes);
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32 is (Value.Lanes (Lane));
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4 is
      Result : F32x4 := Value;
   begin Result.Lanes (Lane) := With_Value; return Result; end Replace;
   function Add (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane); end loop;
      return Result;
   end Add;
   function Subtract (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane); end loop;
      return Result;
   end Subtract;
   function Multiply (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Left.Lanes (Lane) * Right.Lanes (Lane); end loop;
      return Result;
   end Multiply;
   function Divide (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Left.Lanes (Lane) / Right.Lanes (Lane); end loop;
      return Result;
   end Divide;
   function Compare_F32x4 (Left, Right : F32x4; Kind : Character) return Mask_32x4 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_32x4 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when 'G' => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) /= Left.Lanes (Lane) or else Right.Lanes (Lane) /= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_F32x4;
   function Equal (Left, Right : F32x4) return Mask_32x4 is (Compare_F32x4 (Left, Right, '='));
   function Less_Than (Left, Right : F32x4) return Mask_32x4 is (Compare_F32x4 (Left, Right, '<'));
   function Less_Equal (Left, Right : F32x4) return Mask_32x4 is (Compare_F32x4 (Left, Right, 'L'));
   function Greater_Than (Left, Right : F32x4) return Mask_32x4 is (Compare_F32x4 (Left, Right, '>'));
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4 is (Compare_F32x4 (Left, Right, 'G'));
   function Unordered (Left, Right : F32x4) return Mask_32x4 is (Compare_F32x4 (Left, Right, 'U'));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min_Number (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         if Is_Signaling_NaN (Left.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Left.Lanes (Lane));
         elsif Is_Signaling_NaN (Right.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Right.Lanes (Lane));
         elsif Left.Lanes (Lane) /= Left.Lanes (Lane) then Result.Lanes (Lane) := Right.Lanes (Lane);
         elsif Right.Lanes (Lane) /= Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         elsif Left.Lanes (Lane) = 0.0 and then Right.Lanes (Lane) = 0.0 then Result.Lanes (Lane) := (if (Bits_Of_F32 (Left.Lanes (Lane)) and 2 ** 31) /= 0 then Left.Lanes (Lane) else Right.Lanes (Lane));
         elsif Left.Lanes (Lane) < Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         else Result.Lanes (Lane) := Right.Lanes (Lane); end if;
      end loop;
      return Result;
   end Min_Number;
   function Max_Number (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         if Is_Signaling_NaN (Left.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Left.Lanes (Lane));
         elsif Is_Signaling_NaN (Right.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Right.Lanes (Lane));
         elsif Left.Lanes (Lane) /= Left.Lanes (Lane) then Result.Lanes (Lane) := Right.Lanes (Lane);
         elsif Right.Lanes (Lane) /= Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         elsif Left.Lanes (Lane) = 0.0 and then Right.Lanes (Lane) = 0.0 then Result.Lanes (Lane) := (if (Bits_Of_F32 (Left.Lanes (Lane)) and 2 ** 31) = 0 then Left.Lanes (Lane) else Right.Lanes (Lane));
         elsif Left.Lanes (Lane) > Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         else Result.Lanes (Lane) := Right.Lanes (Lane); end if;
      end loop;
      return Result;
   end Max_Number;
   function Reduce_Add (Value : F32x4) return F32 is
      Result : F32 := 0.0;
   begin
      for Lane in Lane_Index_32x4 loop Result := Result + Value.Lanes (Lane); end loop;
      return Result;
   end Reduce_Add;
   function Reverse_Lanes (Value : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Value.Lanes (3 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Natural range 0 .. 1 loop Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0); Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0); end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Natural range 0 .. 1 loop Result.Lanes (2 * Lane) := Left.Lanes (Lane + 2); Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 2); end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Natural range 0 .. 1 loop Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0); Result.Lanes (Lane + 2) := Right.Lanes (2 * Lane + 0); end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Natural range 0 .. 1 loop Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1); Result.Lanes (Lane + 2) := Right.Lanes (2 * Lane + 1); end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 is
      Result : F32x4;
   begin
      for Lane in Lane_Index_32x4 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin for Lane in Lane_Index_32x4 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end Store_Unaligned;
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 is
      Result : F32x4 := Zero;
   begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if; return Result; end Load_Partial;
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) is begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if; end Store_Partial;

   function Bits_Of_F64 is new Ada.Unchecked_Conversion (F64, U64);
   function F64_Of_Bits is new Ada.Unchecked_Conversion (U64, F64);
   function Is_Signaling_NaN (Value : F64) return Boolean is
      Bits : constant U64 := Bits_Of_F64 (Value);
   begin
      return (Bits and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#
        and then (Bits and 16#000F_FFFF_FFFF_FFFF#) /= 0
        and then (Bits and 16#0008_0000_0000_0000#) = 0;
   end Is_Signaling_NaN;
   function Quiet_NaN (Value : F64) return F64 is
     (F64_Of_Bits (Bits_Of_F64 (Value) or 16#0008_0000_0000_0000#));
   function Zero return F64x2 is (Lanes => [others => 0.0]);
   function Splat (Value : F64) return F64x2 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2 is (Lanes => Values);
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2 is (Value.Lanes);
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64 is (Value.Lanes (Lane));
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2 is
      Result : F64x2 := Value;
   begin Result.Lanes (Lane) := With_Value; return Result; end Replace;
   function Add (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane); end loop;
      return Result;
   end Add;
   function Subtract (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane); end loop;
      return Result;
   end Subtract;
   function Multiply (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Left.Lanes (Lane) * Right.Lanes (Lane); end loop;
      return Result;
   end Multiply;
   function Divide (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Left.Lanes (Lane) / Right.Lanes (Lane); end loop;
      return Result;
   end Divide;
   function Compare_F64x2 (Left, Right : F64x2; Kind : Character) return Mask_64x2 is
      Bits : Interfaces.Unsigned_8 := 0;
      Truth : Boolean;
   begin
      for Lane in Lane_Index_64x2 loop
         case Kind is
            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);
            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);
            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);
            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);
            when 'G' => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);
            when others => Truth := Left.Lanes (Lane) /= Left.Lanes (Lane) or else Right.Lanes (Lane) /= Right.Lanes (Lane);
         end case;
         if Truth then Bits := Bits or Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane); end if;
      end loop;
      return (Bits => Bits);
   end Compare_F64x2;
   function Equal (Left, Right : F64x2) return Mask_64x2 is (Compare_F64x2 (Left, Right, '='));
   function Less_Than (Left, Right : F64x2) return Mask_64x2 is (Compare_F64x2 (Left, Right, '<'));
   function Less_Equal (Left, Right : F64x2) return Mask_64x2 is (Compare_F64x2 (Left, Right, 'L'));
   function Greater_Than (Left, Right : F64x2) return Mask_64x2 is (Compare_F64x2 (Left, Right, '>'));
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2 is (Compare_F64x2 (Left, Right, 'G'));
   function Unordered (Left, Right : F64x2) return Mask_64x2 is (Compare_F64x2 (Left, Right, 'U'));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;
      return Result;
   end Select_Value;
   function Min_Number (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         if Is_Signaling_NaN (Left.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Left.Lanes (Lane));
         elsif Is_Signaling_NaN (Right.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Right.Lanes (Lane));
         elsif Left.Lanes (Lane) /= Left.Lanes (Lane) then Result.Lanes (Lane) := Right.Lanes (Lane);
         elsif Right.Lanes (Lane) /= Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         elsif Left.Lanes (Lane) = 0.0 and then Right.Lanes (Lane) = 0.0 then Result.Lanes (Lane) := (if (Bits_Of_F64 (Left.Lanes (Lane)) and 2 ** 63) /= 0 then Left.Lanes (Lane) else Right.Lanes (Lane));
         elsif Left.Lanes (Lane) < Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         else Result.Lanes (Lane) := Right.Lanes (Lane); end if;
      end loop;
      return Result;
   end Min_Number;
   function Max_Number (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         if Is_Signaling_NaN (Left.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Left.Lanes (Lane));
         elsif Is_Signaling_NaN (Right.Lanes (Lane)) then Result.Lanes (Lane) := Quiet_NaN (Right.Lanes (Lane));
         elsif Left.Lanes (Lane) /= Left.Lanes (Lane) then Result.Lanes (Lane) := Right.Lanes (Lane);
         elsif Right.Lanes (Lane) /= Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         elsif Left.Lanes (Lane) = 0.0 and then Right.Lanes (Lane) = 0.0 then Result.Lanes (Lane) := (if (Bits_Of_F64 (Left.Lanes (Lane)) and 2 ** 63) = 0 then Left.Lanes (Lane) else Right.Lanes (Lane));
         elsif Left.Lanes (Lane) > Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);
         else Result.Lanes (Lane) := Right.Lanes (Lane); end if;
      end loop;
      return Result;
   end Max_Number;
   function Reduce_Add (Value : F64x2) return F64 is
      Result : F64 := 0.0;
   begin
      for Lane in Lane_Index_64x2 loop Result := Result + Value.Lanes (Lane); end loop;
      return Result;
   end Reduce_Add;
   function Reverse_Lanes (Value : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Value.Lanes (1 - Lane); end loop;
      return Result;
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Natural range 0 .. 0 loop Result.Lanes (2 * Lane) := Left.Lanes (Lane + 0); Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 0); end loop;
      return Result;
   end Interleave_Low;
   function Interleave_High (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Natural range 0 .. 0 loop Result.Lanes (2 * Lane) := Left.Lanes (Lane + 1); Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + 1); end loop;
      return Result;
   end Interleave_High;
   function Deinterleave_Even (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Natural range 0 .. 0 loop Result.Lanes (Lane) := Left.Lanes (2 * Lane + 0); Result.Lanes (Lane + 1) := Right.Lanes (2 * Lane + 0); end loop;
      return Result;
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Natural range 0 .. 0 loop Result.Lanes (Lane) := Left.Lanes (2 * Lane + 1); Result.Lanes (Lane + 1) := Right.Lanes (2 * Lane + 1); end loop;
      return Result;
   end Deinterleave_Odd;
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);
   function Load (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 is
      Result : F64x2;
   begin
      for Lane in Lane_Index_64x2 loop Result.Lanes (Lane) := Data (Start + Lane); end loop;
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin for Lane in Lane_Index_64x2 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end Store_Unaligned;
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 is
      Result : F64x2 := Zero;
   begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if; return Result; end Load_Partial;
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) is begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if; end Store_Partial;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8 is (Bits => Bits and 255);
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8 is (Mask.Bits);
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8 is (Bits => Left.Bits and Right.Bits);
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8 is (Bits => Left.Bits or Right.Bits);
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8 is (Bits => Left.Bits xor Right.Bits);
   function Mask_Not (Value : Mask_16x8) return Mask_16x8 is (Bits => (not Value.Bits) and 255);
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean is ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_16x8) return Boolean is (Mask.Bits /= 0);
   function All_True (Mask : Mask_16x8) return Boolean is (Mask.Bits = 255);
   function None_True (Mask : Mask_16x8) return Boolean is (Mask.Bits = 0);
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8 is
      Bits : Interfaces.Unsigned_8 := Mask.Bits;
      Result : Lane_Count_16x8 := 0;
   begin while Bits /= 0 loop Result := Result + 1; Bits := Bits and (Bits - 1); end loop; return Result; end Population_Count;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4 is (Bits => Bits and 15);
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8 is (Mask.Bits);
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4 is (Bits => Left.Bits and Right.Bits);
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4 is (Bits => Left.Bits or Right.Bits);
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4 is (Bits => Left.Bits xor Right.Bits);
   function Mask_Not (Value : Mask_32x4) return Mask_32x4 is (Bits => (not Value.Bits) and 15);
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean is ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_32x4) return Boolean is (Mask.Bits /= 0);
   function All_True (Mask : Mask_32x4) return Boolean is (Mask.Bits = 15);
   function None_True (Mask : Mask_32x4) return Boolean is (Mask.Bits = 0);
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4 is
      Bits : Interfaces.Unsigned_8 := Mask.Bits;
      Result : Lane_Count_32x4 := 0;
   begin while Bits /= 0 loop Result := Result + 1; Bits := Bits and (Bits - 1); end loop; return Result; end Population_Count;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2 is (Bits => Bits and 3);
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8 is (Mask.Bits);
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2 is (Bits => Left.Bits and Right.Bits);
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2 is (Bits => Left.Bits or Right.Bits);
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2 is (Bits => Left.Bits xor Right.Bits);
   function Mask_Not (Value : Mask_64x2) return Mask_64x2 is (Bits => (not Value.Bits) and 3);
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean is ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_64x2) return Boolean is (Mask.Bits /= 0);
   function All_True (Mask : Mask_64x2) return Boolean is (Mask.Bits = 3);
   function None_True (Mask : Mask_64x2) return Boolean is (Mask.Bits = 0);
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2 is
      Bits : Interfaces.Unsigned_8 := Mask.Bits;
      Result : Lane_Count_64x2 := 0;
   begin while Bits /= 0 loop Result := Result + 1; Bits := Bits and (Bits - 1); end loop; return Result; end Population_Count;
   --  END GENERATED 128-BIT SCALAR BODIES
end Flyology_SIMD;
