with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Wide.Byte_Mechanism;
with Flyology_SIMD.Wide.Compact_Mechanism;
with Flyology_SIMD.Wide.Lookup_Mechanism;
with Flyology_SIMD.Wide.Permute_Mechanism;
with System.Storage_Elements;

package body Flyology_SIMD.Wide.Native is
   package Byte_Mechanism renames Flyology_SIMD.Wide.Byte_Mechanism;
   package Compact_Mechanism renames Flyology_SIMD.Wide.Compact_Mechanism;
   package Lookup_Mechanism renames Flyology_SIMD.Wide.Lookup_Mechanism;
   package Permute_Mechanism renames Flyology_SIMD.Wide.Permute_Mechanism;
   use type System.Storage_Elements.Integer_Address;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type F32;
   use type F64;
   function Make_Lane_Map (Selectors : Lane_Selectors_8x32) return Lane_Map_8x32 is
     ((Selectors => Selectors));

   function Select_Left_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32 is
     ((From_Right => False, Lane => Lane));

   function Select_Right_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32 is
     ((From_Right => True, Lane => Lane));

   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_8x32) return Two_Source_Lane_Map_8x32 is
     ((Selectors => Selectors));

   function Zero return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : U8) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_U8x32) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 15 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 15 => Values (Lane + 16)])));

   function To_Lanes (Value : U8x32) return Lane_Values_U8x32 is
      Low : constant Lane_Values_U8x32 := [for Lane in Lane_Index_8x32 => (if Lane < 16 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 16))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : U8x32; Lane : Lane_Index_8x32) return U8 is
     (if Lane < 16 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 16));

   function Replace (Value : U8x32; Lane : Lane_Index_8x32; With_Value : U8) return U8x32 is
     (if Lane < 16
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 16, With_Value)));

   function Table_Lookup (Table, Indices : U8x32) return U8x32 is
     (Lookup_Mechanism.Table_Lookup_32 (Table, Indices));

   function Horizontal_Sum (Value : U8x32) return Natural is
      --  Each exact half sum is at most 16 * 255, so their sum
      --  is at most 8_160 and cannot overflow Natural.
      pragma Suppress (Overflow_Check);
   begin
      return Flyology_SIMD.Backends.Native.Horizontal_Sum (Value.Low) + Flyology_SIMD.Backends.Native.Horizontal_Sum (Value.High);
   end Horizontal_Sum;

   function Bit_Cast (Value : U8x32) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Add_Wrap (Left, Right));

   function Subtract_Wrap (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Subtract_Wrap (Left, Right));

   function Multiply_Wrap (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Multiply_Wrap (Left, Right));

   function Add_Saturate (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Add_Saturate (Left, Right));

   function Subtract_Saturate (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Subtract_Saturate (Left, Right));

   function Bitwise_And (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Bitwise_And (Left, Right));

   function Bitwise_Or (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Bitwise_Or (Left, Right));

   function Bitwise_Xor (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Bitwise_Xor (Left, Right));

   function Min (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Min (Left, Right));

   function Max (Left, Right : U8x32) return U8x32 is
     (Byte_Mechanism.Max (Left, Right));

   function Bitwise_Not (Value : U8x32) return U8x32 is
     (Byte_Mechanism.Bitwise_Not (Value));

   function Shift_Left_Logical (Value : U8x32; Count : Natural) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : U8x32; Count : Natural) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Equal (Left, Right : U8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Equal (Left, Right)));

   function Less_Than (Left, Right : U8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Less_Than (Left, Right)));

   function Less_Equal (Left, Right : U8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Less_Equal (Left, Right)));

   function Greater_Than (Left, Right : U8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Greater_Than (Left, Right)));

   function Greater_Equal (Left, Right : U8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Greater_Equal (Left, Right)));

   function Select_Value (Mask : Mask_8x32; If_True, If_False : U8x32) return U8x32 is
     (Byte_Mechanism.Select_Value
        (To_Bit_Mask (Mask), If_True, If_False));

   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : U8x32) return U8 is
      Pair : constant U8x16 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : U8x32) return U8 is
      Pair : constant U8x16 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : U8x32) return U8 is
      Pair : constant U8x16 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : U8x32) return U8x32 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : U8x32) return U8x32 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : U8x32) return U8x32 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : U8x32) return U8x32 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : U8x32) return U8x32 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Mask_From_Bit_Mask (Bits : Mask_Bits_8x32) return Mask_8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Bits and Mask_Bits_8x32 (65535))),
       High => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Bits, 16)))));

   function To_Bit_Mask (Mask : Mask_8x32) return Mask_Bits_8x32 is
     (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low)) or Interfaces.Shift_Left (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)), 16));

   function Mask_And (Left, Right : Mask_8x32) return Mask_8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_And (Left.High, Right.High)));

   function Mask_Or (Left, Right : Mask_8x32) return Mask_8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Or (Left.High, Right.High)));

   function Mask_Xor (Left, Right : Mask_8x32) return Mask_8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Xor (Left.High, Right.High)));

   function Mask_Not (Value : Mask_8x32) return Mask_8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Not (Value.High)));

   function Test (Mask : Mask_8x32; Lane : Lane_Index_8x32) return Boolean is
     (if Lane < 16 then Flyology_SIMD.Backends.Native.Test (Mask.Low, Lane) else Flyology_SIMD.Backends.Native.Test (Mask.High, Lane - 16));

   function Any_True (Mask : Mask_8x32) return Boolean is (Flyology_SIMD.Backends.Native.Any_True (Mask.Low) or else Flyology_SIMD.Backends.Native.Any_True (Mask.High));

   function All_True (Mask : Mask_8x32) return Boolean is (Flyology_SIMD.Backends.Native.All_True (Mask.Low) and then Flyology_SIMD.Backends.Native.All_True (Mask.High));

   function None_True (Mask : Mask_8x32) return Boolean is (not Any_True (Mask));

   function Population_Count (Mask : Mask_8x32) return Lane_Count_8x32 is (Lane_Count_8x32 (Flyology_SIMD.Backends.Native.Population_Count (Mask.Low) + Flyology_SIMD.Backends.Native.Population_Count (Mask.High)));

   function First_True (Mask : Mask_8x32) return Lane_Count_8x32 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.High);
   begin
      return (if Low < 16 then Low elsif High < 16 then 16 + High else 32);
   end First_True;

   function Last_True (Mask : Mask_8x32) return Lane_Count_8x32 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.High);
   begin
      return (if High < 16 then 16 + High elsif Low < 16 then Low else 32);
   end Last_True;

   function Is_Aligned_32 (Data : Byte_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : Byte_Array; Start : Natural) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 16)));

   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x32) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 16, Value.High);
   end Store;

   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 16)));

   procedure Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 16, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 16)));

   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 16, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x32) return U8x32 is
     (if Count <= 16
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 16, Count - 16)));

   procedure Store_Partial (Data : in out Byte_Array; Start : Natural; Count : Lane_Count_8x32; Value : U8x32) is
   begin
      if Count <= 16 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 16, Count - 16, Value.High); end if;
   end Store_Partial;
   function Zero return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : I8) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_I8x32) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 15 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 15 => Values (Lane + 16)])));

   function To_Lanes (Value : I8x32) return Lane_Values_I8x32 is
      Low : constant Lane_Values_I8x32 := [for Lane in Lane_Index_8x32 => (if Lane < 16 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 16))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : I8x32; Lane : Lane_Index_8x32) return I8 is
     (if Lane < 16 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 16));

   function Replace (Value : I8x32; Lane : Lane_Index_8x32; With_Value : I8) return I8x32 is
     (if Lane < 16
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 16, With_Value)));

   function Bit_Cast (Value : I8x32) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Add_Wrap (Left, Right));

   function Subtract_Wrap (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Subtract_Wrap (Left, Right));

   function Multiply_Wrap (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Multiply_Wrap (Left, Right));

   function Add_Saturate (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Add_Saturate (Left, Right));

   function Subtract_Saturate (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Subtract_Saturate (Left, Right));

   function Bitwise_And (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Bitwise_And (Left, Right));

   function Bitwise_Or (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Bitwise_Or (Left, Right));

   function Bitwise_Xor (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Bitwise_Xor (Left, Right));

   function Min (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Min (Left, Right));

   function Max (Left, Right : I8x32) return I8x32 is
     (Byte_Mechanism.Max (Left, Right));

   function Bitwise_Not (Value : I8x32) return I8x32 is
     (Byte_Mechanism.Bitwise_Not (Value));

   function Shift_Left_Logical (Value : I8x32; Count : Natural) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : I8x32; Count : Natural) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Shift_Right_Arithmetic (Value : I8x32; Count : Natural) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.High, Count)));

   function Equal (Left, Right : I8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Equal (Left, Right)));

   function Less_Than (Left, Right : I8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Less_Than (Left, Right)));

   function Less_Equal (Left, Right : I8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Less_Equal (Left, Right)));

   function Greater_Than (Left, Right : I8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Greater_Than (Left, Right)));

   function Greater_Equal (Left, Right : I8x32) return Mask_8x32 is
     (Mask_From_Bit_Mask (Byte_Mechanism.Greater_Equal (Left, Right)));

   function Select_Value (Mask : Mask_8x32; If_True, If_False : I8x32) return I8x32 is
     (Byte_Mechanism.Select_Value
        (To_Bit_Mask (Mask), If_True, If_False));

   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : I8x32) return I8 is
      Pair : constant I8x16 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : I8x32) return I8 is
      Pair : constant I8x16 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : I8x32) return I8 is
      Pair : constant I8x16 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : I8x32) return I8x32 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : I8x32) return I8x32 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : I8x32) return I8x32 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : I8x32) return I8x32 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : I8x32) return I8x32 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Is_Aligned_32 (Data : I8_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : I8_Array; Start : Natural) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 16)));

   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x32) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 16, Value.High);
   end Store;

   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 16)));

   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x32) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 16, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 16)));

   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x32) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 16, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x32) return I8x32 is
     (if Count <= 16
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 16, Count - 16)));

   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x32; Value : I8x32) is
   begin
      if Count <= 16 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 16, Count - 16, Value.High); end if;
   end Store_Partial;
   function Make_Lane_Map (Selectors : Lane_Selectors_16x16) return Lane_Map_16x16 is
     ((Selectors => Selectors));

   function Select_Left_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16 is
     ((From_Right => False, Lane => Lane));

   function Select_Right_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16 is
     ((From_Right => True, Lane => Lane));

   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_16x16) return Two_Source_Lane_Map_16x16 is
     ((Selectors => Selectors));

   function Zero return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : U16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 7 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 7 => Values (Lane + 8)])));

   function To_Lanes (Value : U16x16) return Lane_Values_U16x16 is
      Low : constant Lane_Values_U16x16 := [for Lane in Lane_Index_16x16 => (if Lane < 8 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 8))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : U16x16; Lane : Lane_Index_16x16) return U16 is
     (if Lane < 8 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 8));

   function Replace (Value : U16x16; Lane : Lane_Index_16x16; With_Value : U16) return U16x16 is
     (if Lane < 8
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 8, With_Value)));

   function Bit_Cast (Value : U16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Wrap (Left.High, Right.High)));

   function Subtract_Wrap (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.High, Right.High)));

   function Multiply_Wrap (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.High, Right.High)));

   function Add_Saturate (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Saturate (Left.High, Right.High)));

   function Subtract_Saturate (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.High, Right.High)));

   function Bitwise_And (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_And (Left.High, Right.High)));

   function Bitwise_Or (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.High, Right.High)));

   function Bitwise_Xor (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.High, Right.High)));

   function Min (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Min (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min (Left.High, Right.High)));

   function Max (Left, Right : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Max (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max (Left.High, Right.High)));

   function Bitwise_Not (Value : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.High)));

   function Shift_Left_Logical (Value : U16x16; Count : Natural) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : U16x16; Count : Natural) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Equal (Left, Right : U16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : U16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : U16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : U16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : U16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Select_Value (Mask : Mask_16x16; If_True, If_False : U16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : U16x16) return U16 is
      Pair : constant U16x8 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : U16x16) return U16 is
      Pair : constant U16x8 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : U16x16) return U16 is
      Pair : constant U16x8 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : U16x16) return U16x16 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : U16x16) return U16x16 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : U16x16) return U16x16 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : U16x16) return U16x16 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : U16x16) return U16x16 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Mask_From_Bit_Mask (Bits : Mask_Bits_16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Bits and Mask_Bits_16x16 (255))),
       High => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Interfaces.Shift_Right (Bits, 8)))));

   function To_Bit_Mask (Mask : Mask_16x16) return Mask_Bits_16x16 is
     (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low)) or Interfaces.Shift_Left (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)), 8));

   function Mask_And (Left, Right : Mask_16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_And (Left.High, Right.High)));

   function Mask_Or (Left, Right : Mask_16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Or (Left.High, Right.High)));

   function Mask_Xor (Left, Right : Mask_16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Xor (Left.High, Right.High)));

   function Mask_Not (Value : Mask_16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Not (Value.High)));

   function Test (Mask : Mask_16x16; Lane : Lane_Index_16x16) return Boolean is
     (if Lane < 8 then Flyology_SIMD.Backends.Native.Test (Mask.Low, Lane) else Flyology_SIMD.Backends.Native.Test (Mask.High, Lane - 8));

   function Any_True (Mask : Mask_16x16) return Boolean is (Flyology_SIMD.Backends.Native.Any_True (Mask.Low) or else Flyology_SIMD.Backends.Native.Any_True (Mask.High));

   function All_True (Mask : Mask_16x16) return Boolean is (Flyology_SIMD.Backends.Native.All_True (Mask.Low) and then Flyology_SIMD.Backends.Native.All_True (Mask.High));

   function None_True (Mask : Mask_16x16) return Boolean is (not Any_True (Mask));

   function Population_Count (Mask : Mask_16x16) return Lane_Count_16x16 is (Lane_Count_16x16 (Flyology_SIMD.Backends.Native.Population_Count (Mask.Low) + Flyology_SIMD.Backends.Native.Population_Count (Mask.High)));

   function First_True (Mask : Mask_16x16) return Lane_Count_16x16 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.High);
   begin
      return (if Low < 8 then Low elsif High < 8 then 8 + High else 16);
   end First_True;

   function Last_True (Mask : Mask_16x16) return Lane_Count_16x16 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.High);
   begin
      return (if High < 8 then 8 + High elsif Low < 8 then Low else 16);
   end Last_True;

   function Is_Aligned_32 (Data : U16_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : U16_Array; Start : Natural) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 8)));

   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x16) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 8, Value.High);
   end Store;

   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 8)));

   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 8, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 8)));

   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 8, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x16) return U16x16 is
     (if Count <= 8
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 8, Count - 8)));

   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x16; Value : U16x16) is
   begin
      if Count <= 8 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 8, Count - 8, Value.High); end if;
   end Store_Partial;
   function Zero return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : I16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 7 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 7 => Values (Lane + 8)])));

   function To_Lanes (Value : I16x16) return Lane_Values_I16x16 is
      Low : constant Lane_Values_I16x16 := [for Lane in Lane_Index_16x16 => (if Lane < 8 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 8))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : I16x16; Lane : Lane_Index_16x16) return I16 is
     (if Lane < 8 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 8));

   function Replace (Value : I16x16; Lane : Lane_Index_16x16; With_Value : I16) return I16x16 is
     (if Lane < 8
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 8, With_Value)));

   function Bit_Cast (Value : I16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Wrap (Left.High, Right.High)));

   function Subtract_Wrap (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.High, Right.High)));

   function Multiply_Wrap (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.High, Right.High)));

   function Add_Saturate (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Saturate (Left.High, Right.High)));

   function Subtract_Saturate (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.High, Right.High)));

   function Bitwise_And (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_And (Left.High, Right.High)));

   function Bitwise_Or (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.High, Right.High)));

   function Bitwise_Xor (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.High, Right.High)));

   function Min (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Min (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min (Left.High, Right.High)));

   function Max (Left, Right : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Max (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max (Left.High, Right.High)));

   function Bitwise_Not (Value : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.High)));

   function Shift_Left_Logical (Value : I16x16; Count : Natural) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : I16x16; Count : Natural) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Shift_Right_Arithmetic (Value : I16x16; Count : Natural) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.High, Count)));

   function Equal (Left, Right : I16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : I16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : I16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : I16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : I16x16) return Mask_16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Select_Value (Mask : Mask_16x16; If_True, If_False : I16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : I16x16) return I16 is
      Pair : constant I16x8 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : I16x16) return I16 is
      Pair : constant I16x8 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : I16x16) return I16 is
      Pair : constant I16x8 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : I16x16) return I16x16 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : I16x16) return I16x16 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : I16x16) return I16x16 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : I16x16) return I16x16 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : I16x16) return I16x16 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Is_Aligned_32 (Data : I16_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : I16_Array; Start : Natural) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 8)));

   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x16) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 8, Value.High);
   end Store;

   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 8)));

   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 8, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 8)));

   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 8, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x16) return I16x16 is
     (if Count <= 8
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 8, Count - 8)));

   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x16; Value : I16x16) is
   begin
      if Count <= 8 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 8, Count - 8, Value.High); end if;
   end Store_Partial;
   function Make_Lane_Map (Selectors : Lane_Selectors_32x8) return Lane_Map_32x8 is
     ((Selectors => Selectors));

   function Select_Left_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8 is
     ((From_Right => False, Lane => Lane));

   function Select_Right_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8 is
     ((From_Right => True, Lane => Lane));

   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_32x8) return Two_Source_Lane_Map_32x8 is
     ((Selectors => Selectors));

   function Zero return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : U32) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 3 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 3 => Values (Lane + 4)])));

   function To_Lanes (Value : U32x8) return Lane_Values_U32x8 is
      Low : constant Lane_Values_U32x8 := [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 4))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : U32x8; Lane : Lane_Index_32x8) return U32 is
     (if Lane < 4 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 4));

   function Replace (Value : U32x8; Lane : Lane_Index_32x8; With_Value : U32) return U32x8 is
     (if Lane < 4
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 4, With_Value)));

   function Bit_Cast (Value : U32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Bit_Cast (Value : U32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Wrap (Left.High, Right.High)));

   function Subtract_Wrap (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.High, Right.High)));

   function Multiply_Wrap (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.High, Right.High)));

   function Add_Saturate (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Saturate (Left.High, Right.High)));

   function Subtract_Saturate (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.High, Right.High)));

   function Bitwise_And (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_And (Left.High, Right.High)));

   function Bitwise_Or (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.High, Right.High)));

   function Bitwise_Xor (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.High, Right.High)));

   function Min (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Min (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min (Left.High, Right.High)));

   function Max (Left, Right : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Max (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max (Left.High, Right.High)));

   function Bitwise_Not (Value : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.High)));

   function Shift_Left_Logical (Value : U32x8; Count : Natural) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : U32x8; Count : Natural) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Equal (Left, Right : U32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : U32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : U32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : U32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : U32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Select_Value (Mask : Mask_32x8; If_True, If_False : U32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : U32x8) return U32 is
      Pair : constant U32x4 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : U32x8) return U32 is
      Pair : constant U32x4 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : U32x8) return U32 is
      Pair : constant U32x4 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : U32x8) return U32x8 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : U32x8) return U32x8 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : U32x8) return U32x8 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : U32x8) return U32x8 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : U32x8) return U32x8 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Mask_From_Bit_Mask (Bits : Mask_Bits_32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits and Mask_Bits_32x8 (15)),
       High => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Bits, 4))));

   function To_Bit_Mask (Mask : Mask_32x8) return Mask_Bits_32x8 is
     (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low)) or Interfaces.Shift_Left (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)), 4));

   function Mask_And (Left, Right : Mask_32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_And (Left.High, Right.High)));

   function Mask_Or (Left, Right : Mask_32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Or (Left.High, Right.High)));

   function Mask_Xor (Left, Right : Mask_32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Xor (Left.High, Right.High)));

   function Mask_Not (Value : Mask_32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Not (Value.High)));

   function Test (Mask : Mask_32x8; Lane : Lane_Index_32x8) return Boolean is
     (if Lane < 4 then Flyology_SIMD.Backends.Native.Test (Mask.Low, Lane) else Flyology_SIMD.Backends.Native.Test (Mask.High, Lane - 4));

   function Any_True (Mask : Mask_32x8) return Boolean is (Flyology_SIMD.Backends.Native.Any_True (Mask.Low) or else Flyology_SIMD.Backends.Native.Any_True (Mask.High));

   function All_True (Mask : Mask_32x8) return Boolean is (Flyology_SIMD.Backends.Native.All_True (Mask.Low) and then Flyology_SIMD.Backends.Native.All_True (Mask.High));

   function None_True (Mask : Mask_32x8) return Boolean is (not Any_True (Mask));

   function Population_Count (Mask : Mask_32x8) return Lane_Count_32x8 is (Lane_Count_32x8 (Flyology_SIMD.Backends.Native.Population_Count (Mask.Low) + Flyology_SIMD.Backends.Native.Population_Count (Mask.High)));

   function First_True (Mask : Mask_32x8) return Lane_Count_32x8 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.High);
   begin
      return (if Low < 4 then Low elsif High < 4 then 4 + High else 8);
   end First_True;

   function Last_True (Mask : Mask_32x8) return Lane_Count_32x8 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.High);
   begin
      return (if High < 4 then 4 + High elsif Low < 4 then Low else 8);
   end Last_True;

   function Is_Aligned_32 (Data : U32_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : U32_Array; Start : Natural) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 4)));

   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 4, Value.High);
   end Store;

   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 4)));

   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 4, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 4)));

   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 4, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x8) return U32x8 is
     (if Count <= 4
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 4, Count - 4)));

   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x8; Value : U32x8) is
   begin
      if Count <= 4 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 4, Count - 4, Value.High); end if;
   end Store_Partial;
   function Zero return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : I32) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 3 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 3 => Values (Lane + 4)])));

   function To_Lanes (Value : I32x8) return Lane_Values_I32x8 is
      Low : constant Lane_Values_I32x8 := [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 4))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : I32x8; Lane : Lane_Index_32x8) return I32 is
     (if Lane < 4 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 4));

   function Replace (Value : I32x8; Lane : Lane_Index_32x8; With_Value : I32) return I32x8 is
     (if Lane < 4
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 4, With_Value)));

   function Bit_Cast (Value : I32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Bit_Cast (Value : I32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Wrap (Left.High, Right.High)));

   function Subtract_Wrap (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.High, Right.High)));

   function Multiply_Wrap (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.High, Right.High)));

   function Add_Saturate (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Saturate (Left.High, Right.High)));

   function Subtract_Saturate (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.High, Right.High)));

   function Bitwise_And (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_And (Left.High, Right.High)));

   function Bitwise_Or (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.High, Right.High)));

   function Bitwise_Xor (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.High, Right.High)));

   function Min (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Min (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min (Left.High, Right.High)));

   function Max (Left, Right : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Max (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max (Left.High, Right.High)));

   function Bitwise_Not (Value : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.High)));

   function Shift_Left_Logical (Value : I32x8; Count : Natural) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : I32x8; Count : Natural) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Shift_Right_Arithmetic (Value : I32x8; Count : Natural) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.High, Count)));

   function Equal (Left, Right : I32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : I32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : I32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : I32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : I32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Select_Value (Mask : Mask_32x8; If_True, If_False : I32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : I32x8) return I32 is
      Pair : constant I32x4 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : I32x8) return I32 is
      Pair : constant I32x4 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : I32x8) return I32 is
      Pair : constant I32x4 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : I32x8) return I32x8 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : I32x8) return I32x8 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : I32x8) return I32x8 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : I32x8) return I32x8 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : I32x8) return I32x8 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Is_Aligned_32 (Data : I32_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : I32_Array; Start : Natural) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 4)));

   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 4, Value.High);
   end Store;

   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 4)));

   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 4, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 4)));

   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 4, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x8) return I32x8 is
     (if Count <= 4
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 4, Count - 4)));

   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x8; Value : I32x8) is
   begin
      if Count <= 4 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 4, Count - 4, Value.High); end if;
   end Store_Partial;
   function Make_Lane_Map (Selectors : Lane_Selectors_64x4) return Lane_Map_64x4 is
     ((Selectors => Selectors));

   function Select_Left_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4 is
     ((From_Right => False, Lane => Lane));

   function Select_Right_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4 is
     ((From_Right => True, Lane => Lane));

   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_64x4) return Two_Source_Lane_Map_64x4 is
     ((Selectors => Selectors));

   function Zero return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : U64) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 1 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 1 => Values (Lane + 2)])));

   function To_Lanes (Value : U64x4) return Lane_Values_U64x4 is
      Low : constant Lane_Values_U64x4 := [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 2))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : U64x4; Lane : Lane_Index_64x4) return U64 is
     (if Lane < 2 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 2));

   function Replace (Value : U64x4; Lane : Lane_Index_64x4; With_Value : U64) return U64x4 is
     (if Lane < 2
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 2, With_Value)));

   function Bit_Cast (Value : U64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Bit_Cast (Value : U64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Wrap (Left.High, Right.High)));

   function Subtract_Wrap (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.High, Right.High)));

   function Multiply_Wrap (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.High, Right.High)));

   function Add_Saturate (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Saturate (Left.High, Right.High)));

   function Subtract_Saturate (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.High, Right.High)));

   function Bitwise_And (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_And (Left.High, Right.High)));

   function Bitwise_Or (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.High, Right.High)));

   function Bitwise_Xor (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.High, Right.High)));

   function Min (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Min (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min (Left.High, Right.High)));

   function Max (Left, Right : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Max (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max (Left.High, Right.High)));

   function Bitwise_Not (Value : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.High)));

   function Shift_Left_Logical (Value : U64x4; Count : Natural) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : U64x4; Count : Natural) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Equal (Left, Right : U64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : U64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : U64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : U64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : U64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Select_Value (Mask : Mask_64x4; If_True, If_False : U64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : U64x4) return U64 is
      Pair : constant U64x2 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : U64x4) return U64 is
      Pair : constant U64x2 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : U64x4) return U64 is
      Pair : constant U64x2 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : U64x4) return U64x4 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : U64x4) return U64x4 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : U64x4) return U64x4 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : U64x4) return U64x4 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : U64x4) return U64x4 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Mask_From_Bit_Mask (Bits : Mask_Bits_64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits and Mask_Bits_64x4 (3)),
       High => Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Bits, 2))));

   function To_Bit_Mask (Mask : Mask_64x4) return Mask_Bits_64x4 is
     (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low)) or Interfaces.Shift_Left (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)), 2));

   function Mask_And (Left, Right : Mask_64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_And (Left.High, Right.High)));

   function Mask_Or (Left, Right : Mask_64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Or (Left.High, Right.High)));

   function Mask_Xor (Left, Right : Mask_64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Xor (Left.High, Right.High)));

   function Mask_Not (Value : Mask_64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Mask_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Mask_Not (Value.High)));

   function Test (Mask : Mask_64x4; Lane : Lane_Index_64x4) return Boolean is
     (if Lane < 2 then Flyology_SIMD.Backends.Native.Test (Mask.Low, Lane) else Flyology_SIMD.Backends.Native.Test (Mask.High, Lane - 2));

   function Any_True (Mask : Mask_64x4) return Boolean is (Flyology_SIMD.Backends.Native.Any_True (Mask.Low) or else Flyology_SIMD.Backends.Native.Any_True (Mask.High));

   function All_True (Mask : Mask_64x4) return Boolean is (Flyology_SIMD.Backends.Native.All_True (Mask.Low) and then Flyology_SIMD.Backends.Native.All_True (Mask.High));

   function None_True (Mask : Mask_64x4) return Boolean is (not Any_True (Mask));

   function Population_Count (Mask : Mask_64x4) return Lane_Count_64x4 is (Lane_Count_64x4 (Flyology_SIMD.Backends.Native.Population_Count (Mask.Low) + Flyology_SIMD.Backends.Native.Population_Count (Mask.High)));

   function First_True (Mask : Mask_64x4) return Lane_Count_64x4 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.First_True (Mask.High);
   begin
      return (if Low < 2 then Low elsif High < 2 then 2 + High else 4);
   end First_True;

   function Last_True (Mask : Mask_64x4) return Lane_Count_64x4 is
      Low : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.Low);
      High : constant Natural := Flyology_SIMD.Backends.Native.Last_True (Mask.High);
   begin
      return (if High < 2 then 2 + High elsif Low < 2 then Low else 4);
   end Last_True;

   function Is_Aligned_32 (Data : U64_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : U64_Array; Start : Natural) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 2)));

   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 2, Value.High);
   end Store;

   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 2)));

   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 2, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 2)));

   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 2, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x4) return U64x4 is
     (if Count <= 2
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 2, Count - 2)));

   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x4; Value : U64x4) is
   begin
      if Count <= 2 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 2, Count - 2, Value.High); end if;
   end Store_Partial;
   function Zero return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : I64) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 1 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 1 => Values (Lane + 2)])));

   function To_Lanes (Value : I64x4) return Lane_Values_I64x4 is
      Low : constant Lane_Values_I64x4 := [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 2))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : I64x4; Lane : Lane_Index_64x4) return I64 is
     (if Lane < 2 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 2));

   function Replace (Value : I64x4; Lane : Lane_Index_64x4; With_Value : I64) return I64x4 is
     (if Lane < 2
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 2, With_Value)));

   function Bit_Cast (Value : I64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Bit_Cast (Value : I64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add_Wrap (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Wrap (Left.High, Right.High)));

   function Subtract_Wrap (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Wrap (Left.High, Right.High)));

   function Multiply_Wrap (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply_Wrap (Left.High, Right.High)));

   function Add_Saturate (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Add_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add_Saturate (Left.High, Right.High)));

   function Subtract_Saturate (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract_Saturate (Left.High, Right.High)));

   function Bitwise_And (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_And (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_And (Left.High, Right.High)));

   function Bitwise_Or (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Or (Left.High, Right.High)));

   function Bitwise_Xor (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Xor (Left.High, Right.High)));

   function Min (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Min (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min (Left.High, Right.High)));

   function Max (Left, Right : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Max (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max (Left.High, Right.High)));

   function Bitwise_Not (Value : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.Low),
       High => Flyology_SIMD.Backends.Native.Bitwise_Not (Value.High)));

   function Shift_Left_Logical (Value : I64x4; Count : Natural) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value.High, Count)));

   function Shift_Right_Logical (Value : I64x4; Count : Natural) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value.High, Count)));

   function Shift_Right_Arithmetic (Value : I64x4; Count : Natural) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.Low, Count),
       High => Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value.High, Count)));

   function Equal (Left, Right : I64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : I64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : I64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : I64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : I64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Select_Value (Mask : Mask_64x4; If_True, If_False : I64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add_Wrap (Value : I64x4) return I64 is
      Pair : constant I64x2 := Flyology_SIMD.Backends.Native.Add_Wrap (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Add_Wrap;

   function Reduce_Min (Value : I64x4) return I64 is
      Pair : constant I64x2 := Flyology_SIMD.Backends.Native.Min (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Min (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Min;

   function Reduce_Max (Value : I64x4) return I64 is
      Pair : constant I64x2 := Flyology_SIMD.Backends.Native.Max (Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.Low)), Flyology_SIMD.Backends.Native.Splat (Flyology_SIMD.Backends.Native.Reduce_Max (Value.High)));
   begin return Flyology_SIMD.Backends.Native.Extract (Pair, 0); end Reduce_Max;

   function Reverse_Lanes (Value : I64x4) return I64x4 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : I64x4) return I64x4 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : I64x4) return I64x4 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : I64x4) return I64x4 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : I64x4) return I64x4 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Is_Aligned_32 (Data : I64_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : I64_Array; Start : Natural) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 2)));

   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 2, Value.High);
   end Store;

   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 2)));

   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 2, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 2)));

   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 2, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x4) return I64x4 is
     (if Count <= 2
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 2, Count - 2)));

   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x4; Value : I64x4) is
   begin
      if Count <= 2 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 2, Count - 2, Value.High); end if;
   end Store_Partial;
   function Zero return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : F32) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 3 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 3 => Values (Lane + 4)])));

   function To_Lanes (Value : F32x8) return Lane_Values_F32x8 is
      Low : constant Lane_Values_F32x8 := [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 4))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : F32x8; Lane : Lane_Index_32x8) return F32 is
     (if Lane < 4 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 4));

   function Replace (Value : F32x8; Lane : Lane_Index_32x8; With_Value : F32) return F32x8 is
     (if Lane < 4
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 4, With_Value)));

   function Bit_Cast (Value : F32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Bit_Cast (Value : F32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Add (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add (Left.High, Right.High)));

   function Subtract (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract (Left.High, Right.High)));

   function Multiply (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply (Left.High, Right.High)));

   function Divide (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Divide (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Divide (Left.High, Right.High)));

   function Min_Number (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Min_Number (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min_Number (Left.High, Right.High)));

   function Max_Number (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Max_Number (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max_Number (Left.High, Right.High)));

   function Equal (Left, Right : F32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : F32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : F32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : F32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : F32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Unordered (Left, Right : F32x8) return Mask_32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Unordered (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Unordered (Left.High, Right.High)));

   function Select_Value (Mask : Mask_32x8; If_True, If_False : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add (Value : F32x8) return F32 is
      Lanes : constant Lane_Values_F32x8 := To_Lanes (Value);
      Result : F32 := 0.0;
   begin
      for Lane in Lane_Index_32x8 loop Result := Result + Lanes (Lane); end loop;
      return Result;
   end Reduce_Add;

   function Reduce_Min_Number (Value : F32x8) return F32 is
      Result : F32 := Extract (Value, 0);
   begin
      for Lane in 1 .. 7 loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Min_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;
      return Result;
   end Reduce_Min_Number;

   function Reduce_Max_Number (Value : F32x8) return F32 is
      Result : F32 := Extract (Value, 0);
   begin
      for Lane in 1 .. 7 loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Max_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;
      return Result;
   end Reduce_Max_Number;

   function Reverse_Lanes (Value : F32x8) return F32x8 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : F32x8) return F32x8 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : F32x8) return F32x8 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : F32x8) return F32x8 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : F32x8) return F32x8 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Is_Aligned_32 (Data : F32_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : F32_Array; Start : Natural) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 4)));

   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 4, Value.High);
   end Store;

   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 4)));

   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 4, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 4)));

   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 4, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x8) return F32x8 is
     (if Count <= 4
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 4, Count - 4)));

   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x8; Value : F32x8) is
   begin
      if Count <= 4 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 4, Count - 4, Value.High); end if;
   end Store_Partial;
   function Zero return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Zero, High => Flyology_SIMD.Backends.Native.Zero));

   function Splat (Value : F64) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Splat (Value),
       High => Flyology_SIMD.Backends.Native.Splat (Value)));

   function From_Lanes (Values : Lane_Values_F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 1 => Values (Lane)]),
       High => Flyology_SIMD.Backends.Native.From_Lanes ([for Lane in 0 .. 1 => Values (Lane + 2)])));

   function To_Lanes (Value : F64x4) return Lane_Values_F64x4 is
      Low : constant Lane_Values_F64x4 := [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 2))];
   begin
      return Low;
   end To_Lanes;

   function Extract (Value : F64x4; Lane : Lane_Index_64x4) return F64 is
     (if Lane < 2 then Flyology_SIMD.Backends.Native.Extract (Value.Low, Lane) else Flyology_SIMD.Backends.Native.Extract (Value.High, Lane - 2));

   function Replace (Value : F64x4; Lane : Lane_Index_64x4; With_Value : F64) return F64x4 is
     (if Lane < 2
      then (Low => Flyology_SIMD.Backends.Native.Replace (Value.Low, Lane, With_Value), High => Value.High)
      else (Low => Value.Low, High => Flyology_SIMD.Backends.Native.Replace (Value.High, Lane - 2, With_Value)));

   function Bit_Cast (Value : F64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Bit_Cast (Value : F64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Bit_Cast (Value.Low), High => Flyology_SIMD.Backends.Native.Bit_Cast (Value.High)));

   function Add (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Add (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add (Left.High, Right.High)));

   function Subtract (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract (Left.High, Right.High)));

   function Multiply (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply (Left.High, Right.High)));

   function Divide (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Divide (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Divide (Left.High, Right.High)));

   function Min_Number (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Min_Number (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min_Number (Left.High, Right.High)));

   function Max_Number (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Max_Number (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max_Number (Left.High, Right.High)));

   function Equal (Left, Right : F64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Equal (Left.High, Right.High)));

   function Less_Than (Left, Right : F64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Than (Left.High, Right.High)));

   function Less_Equal (Left, Right : F64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Less_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Less_Equal (Left.High, Right.High)));

   function Greater_Than (Left, Right : F64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Than (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Than (Left.High, Right.High)));

   function Greater_Equal (Left, Right : F64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Greater_Equal (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Greater_Equal (Left.High, Right.High)));

   function Unordered (Left, Right : F64x4) return Mask_64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Unordered (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Unordered (Left.High, Right.High)));

   function Select_Value (Mask : Mask_64x4; If_True, If_False : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Select_Value (Mask.Low, If_True.Low, If_False.Low),
       High => Flyology_SIMD.Backends.Native.Select_Value (Mask.High, If_True.High, If_False.High)));

   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4 is
     (Compact_Mechanism.Compress (Value, Mask));

   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4 is
     (Compact_Mechanism.Expand (Value, Mask));

   function Reduce_Add (Value : F64x4) return F64 is
      Lanes : constant Lane_Values_F64x4 := To_Lanes (Value);
      Result : F64 := 0.0;
   begin
      for Lane in Lane_Index_64x4 loop Result := Result + Lanes (Lane); end loop;
      return Result;
   end Reduce_Add;

   function Reduce_Min_Number (Value : F64x4) return F64 is
      Result : F64 := Extract (Value, 0);
   begin
      for Lane in 1 .. 3 loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Min_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;
      return Result;
   end Reduce_Min_Number;

   function Reduce_Max_Number (Value : F64x4) return F64 is
      Result : F64 := Extract (Value, 0);
   begin
      for Lane in 1 .. 3 loop Result := Flyology_SIMD.Extract (Flyology_SIMD.Max_Number (Flyology_SIMD.Splat (Result), Flyology_SIMD.Splat (Extract (Value, Lane))), 0); end loop;
      return Result;
   end Reduce_Max_Number;

   function Reverse_Lanes (Value : F64x4) return F64x4 is
     (Permute_Mechanism.Reverse_Lanes (Value));

   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4 is
     (Permute_Mechanism.Permute_Lanes (Value, Map));

   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4 is
     (Permute_Mechanism.Permute_Lanes (Left, Right, Map));

   function Interleave_Low (Left, Right : F64x4) return F64x4 is
     (Permute_Mechanism.Interleave_Low (Left, Right));

   function Interleave_High (Left, Right : F64x4) return F64x4 is
     (Permute_Mechanism.Interleave_High (Left, Right));

   function Deinterleave_Even (Left, Right : F64x4) return F64x4 is
     (Permute_Mechanism.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd (Left, Right : F64x4) return F64x4 is
     (Permute_Mechanism.Deinterleave_Odd (Left, Right));

   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4 is
     (Permute_Mechanism.Slide_Lanes_Toward_Low (Value, Count));

   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4 is
     (Permute_Mechanism.Slide_Lanes_Toward_High (Value, Count));

   function Is_Aligned_32 (Data : F64_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 32 = 0);

   function Load (Data : F64_Array; Start : Natural) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load (Data, Start + 2)));

   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store (Data, Start + 2, Value.High);
   end Store;

   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start + 2)));

   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start + 2, Value.High);
   end Store_Unaligned;

   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start + 2)));

   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start + 2, Value.High);
   end Store_Aligned;

   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x4) return F64x4 is
     (if Count <= 2
      then (Low => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start, Count), High => Flyology_SIMD.Backends.Native.Zero)
      else (Low => Flyology_SIMD.Backends.Native.Load (Data, Start), High => Flyology_SIMD.Backends.Native.Load_Partial (Data, Start + 2, Count - 2)));

   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x4; Value : F64x4) is
   begin
      if Count <= 2 then Flyology_SIMD.Backends.Native.Store_Partial (Data, Start, Count, Value.Low);
      else Flyology_SIMD.Backends.Native.Store (Data, Start, Value.Low); Flyology_SIMD.Backends.Native.Store_Partial (Data, Start + 2, Count - 2, Value.High); end if;
   end Store_Partial;

   function Widen_Low (Value : U8x32) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : U8x32) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Widen_Low (Value : I8x32) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : I8x32) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Widen_Low (Value : U16x16) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : U16x16) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Widen_Low (Value : I16x16) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : I16x16) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Widen_Low (Value : U32x8) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : U32x8) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Widen_Low (Value : I32x8) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : I32x8) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Widen_Low (Value : F32x8) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.Low),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.Low)));

   function Widen_High (Value : F32x8) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Widen_Low (Value.High),
       High => Flyology_SIMD.Backends.Native.Widen_High (Value.High)));

   function Narrow_Truncate (Low, High : U16x16) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Truncate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Truncate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : U16x16) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Truncate (Low, High : I16x16) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Truncate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Truncate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : I16x16) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Truncate (Low, High : U32x8) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Truncate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Truncate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : U32x8) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Truncate (Low, High : I32x8) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Truncate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Truncate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : I32x8) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Truncate (Low, High : U64x4) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Truncate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Truncate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : U64x4) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Truncate (Low, High : I64x4) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Truncate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Truncate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : I64x4) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : I16x16) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : I32x8) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Saturate (Low, High : I64x4) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Saturate (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Saturate (High.Low, High.High)));

   function Narrow_Round (Low, High : F64x4) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Narrow_Round (Low.Low, Low.High),
       High => Flyology_SIMD.Backends.Native.Narrow_Round (High.Low, High.High)));

   function Convert_Round (Value : I32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Round (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Round (Value.High)));

   function Convert_Round (Value : U32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Round (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Round (Value.High)));

   function Convert_Round (Value : I64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Round (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Round (Value.High)));

   function Convert_Round (Value : U64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Round (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Round (Value.High)));

   function Convert_Truncate_Saturate (Value : F32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.High)));

   function Convert_Truncate_Saturate (Value : F32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.High)));

   function Convert_Truncate_Saturate (Value : F64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.High)));

   function Convert_Truncate_Saturate (Value : F64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value.High)));

   function Convert_Saturate (Value : I8x32) return U8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : U8x32) return I8x32 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : I16x16) return U16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : U16x16) return I16x16 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : I32x8) return U32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : U32x8) return I32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : I64x4) return U64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));

   function Convert_Saturate (Value : U64x4) return I64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.Low),
       High => Flyology_SIMD.Backends.Native.Convert_Saturate (Value.High)));
end Flyology_SIMD.Wide.Native;
