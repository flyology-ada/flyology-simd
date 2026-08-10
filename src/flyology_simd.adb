with System.Storage_Elements;

package body Flyology_SIMD is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;

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

   function Reverse_Bytes (Value : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         Result.Lanes (Lane) := Value.Lanes (15 - Lane);
      end loop;
      return Result;
   end Reverse_Bytes;

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

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16) return Mask_8x16 is
     (Bits => Bits);
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Mask.Bits);

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
end Flyology_SIMD;
