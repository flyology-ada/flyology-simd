package body Flyology_SIMD.Backends.Native is
   function Zero return U8x16 is (Flyology_SIMD.Zero);
   function Splat (Value : U8) return U8x16 is (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_8x16) return U8x16 is (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U8x16) return Lane_Values_8x16 is (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8 is (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16 is (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Wrap (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Subtract_Saturate (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Bitwise_Not (Value : U8x16) return U8x16 is (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16 is (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16 is (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Equal (Left, Right : U8x16) return Mask_8x16 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : U8x16) return Mask_8x16 is (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : U8x16) return Mask_8x16 is (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : U8x16) return Mask_8x16 is (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16 is (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Min (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Max (Left, Right));
   function Horizontal_Sum (Value : U8x16) return Natural is (Flyology_SIMD.Horizontal_Sum (Value));
   function Reduce_Add_Wrap (Value : U8x16) return U8 is (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U8x16) return U8 is (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U8x16) return U8 is (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Bytes (Value : U8x16) return U8x16 is (Flyology_SIMD.Reverse_Bytes (Value));
   function Reverse_Lanes (Value : U8x16) return U8x16 is (Flyology_SIMD.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16 is (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16) return Mask_8x16 is (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16 is (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16 is (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16 is (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_8x16) return Mask_8x16 is (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean is (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_8x16) return Boolean is (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_8x16) return Boolean is (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_8x16) return Boolean is (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16 is (Flyology_SIMD.Population_Count (Mask));
   function Load (Data : Byte_Array; Start : Natural) return U8x16 is (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16) is begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Flyology_SIMD.Store_Unaligned (Data, Start, Value);
   end Store_Unaligned;
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16 is (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x16) is begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16) is
   begin
      Flyology_SIMD.Store_Partial (Data, Start, Count, Value);
   end Store_Partial;

   --  BEGIN GENERATED FULL-FAMILY FALLBACK BODIES
   function Zero return I8x16 is (Flyology_SIMD.Zero);
   function Splat (Value : I8) return I8x16 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : I8x16) return I8x16 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16 is
     (Flyology_SIMD.Shift_Right_Arithmetic (Value, Count));
   function Equal (Left, Right : I8x16) return Mask_8x16 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : I8x16) return Mask_8x16 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : I8x16) return Mask_8x16 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : I8x16) return Mask_8x16 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : I8x16) return I8 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I8x16) return I8 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I8x16) return I8 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : I8x16) return I8x16 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I8_Array; Start : Natural) return I8x16 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return U16x8 is (Flyology_SIMD.Zero);
   function Splat (Value : U16) return U16x8 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : U16x8) return U16x8 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Equal (Left, Right : U16x8) return Mask_16x8 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : U16x8) return Mask_16x8 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : U16x8) return Mask_16x8 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : U16x8) return Mask_16x8 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : U16x8) return U16 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U16x8) return U16 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U16x8) return U16 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : U16x8) return U16x8 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U16_Array; Start : Natural) return U16x8 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return I16x8 is (Flyology_SIMD.Zero);
   function Splat (Value : I16) return I16x8 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : I16x8) return I16x8 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8 is
     (Flyology_SIMD.Shift_Right_Arithmetic (Value, Count));
   function Equal (Left, Right : I16x8) return Mask_16x8 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : I16x8) return Mask_16x8 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : I16x8) return Mask_16x8 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : I16x8) return Mask_16x8 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : I16x8) return I16 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I16x8) return I16 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I16x8) return I16 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : I16x8) return I16x8 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I16_Array; Start : Natural) return I16x8 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return U32x4 is (Flyology_SIMD.Zero);
   function Splat (Value : U32) return U32x4 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : U32x4) return U32x4 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Equal (Left, Right : U32x4) return Mask_32x4 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : U32x4) return Mask_32x4 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : U32x4) return Mask_32x4 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : U32x4) return Mask_32x4 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : U32x4) return U32 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U32x4) return U32 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U32x4) return U32 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : U32x4) return U32x4 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U32_Array; Start : Natural) return U32x4 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return I32x4 is (Flyology_SIMD.Zero);
   function Splat (Value : I32) return I32x4 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : I32x4) return I32x4 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4 is
     (Flyology_SIMD.Shift_Right_Arithmetic (Value, Count));
   function Equal (Left, Right : I32x4) return Mask_32x4 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : I32x4) return Mask_32x4 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : I32x4) return Mask_32x4 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : I32x4) return Mask_32x4 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : I32x4) return I32 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I32x4) return I32 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I32x4) return I32 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : I32x4) return I32x4 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I32_Array; Start : Natural) return I32x4 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return U64x2 is (Flyology_SIMD.Zero);
   function Splat (Value : U64) return U64x2 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : U64x2) return U64x2 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Equal (Left, Right : U64x2) return Mask_64x2 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : U64x2) return Mask_64x2 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : U64x2) return Mask_64x2 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : U64x2) return Mask_64x2 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : U64x2) return U64 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U64x2) return U64 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U64x2) return U64 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : U64x2) return U64x2 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U64_Array; Start : Natural) return U64x2 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return I64x2 is (Flyology_SIMD.Zero);
   function Splat (Value : I64) return I64x2 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Wrap (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Bitwise_Xor (Left, Right));
   function Min (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Max (Left, Right));
   function Interleave_Low (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Bitwise_Not (Value : I64x2) return I64x2 is
     (Flyology_SIMD.Bitwise_Not (Value));
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2 is
     (Flyology_SIMD.Shift_Left_Logical (Value, Count));
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2 is
     (Flyology_SIMD.Shift_Right_Logical (Value, Count));
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2 is
     (Flyology_SIMD.Shift_Right_Arithmetic (Value, Count));
   function Equal (Left, Right : I64x2) return Mask_64x2 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : I64x2) return Mask_64x2 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : I64x2) return Mask_64x2 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : I64x2) return Mask_64x2 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Reduce_Add_Wrap (Value : I64x2) return I64 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I64x2) return I64 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I64x2) return I64 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Lanes (Value : I64x2) return I64x2 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I64_Array; Start : Natural) return I64x2 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return F32x4 is (Flyology_SIMD.Zero);
   function Splat (Value : F32) return F32x4 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Add (Left, Right));
   function Subtract (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Subtract (Left, Right));
   function Multiply (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Multiply (Left, Right));
   function Divide (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Divide (Left, Right));
   function Equal (Left, Right : F32x4) return Mask_32x4 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : F32x4) return Mask_32x4 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : F32x4) return Mask_32x4 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : F32x4) return Mask_32x4 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Unordered (Left, Right : F32x4) return Mask_32x4 is
     (Flyology_SIMD.Unordered (Left, Right));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Min_Number (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Min_Number (Left, Right));
   function Max_Number (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Max_Number (Left, Right));
   function Reduce_Add (Value : F32x4) return F32 is
     (Flyology_SIMD.Reduce_Add (Value));
   function Reverse_Lanes (Value : F32x4) return F32x4 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : F32_Array; Start : Natural) return F32x4 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Zero return F64x2 is (Flyology_SIMD.Zero);
   function Splat (Value : F64) return F64x2 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Add (Left, Right));
   function Subtract (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Subtract (Left, Right));
   function Multiply (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Multiply (Left, Right));
   function Divide (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Divide (Left, Right));
   function Equal (Left, Right : F64x2) return Mask_64x2 is
     (Flyology_SIMD.Equal (Left, Right));
   function Less_Than (Left, Right : F64x2) return Mask_64x2 is
     (Flyology_SIMD.Less_Than (Left, Right));
   function Less_Equal (Left, Right : F64x2) return Mask_64x2 is
     (Flyology_SIMD.Less_Equal (Left, Right));
   function Greater_Than (Left, Right : F64x2) return Mask_64x2 is
     (Flyology_SIMD.Greater_Than (Left, Right));
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2 is
     (Flyology_SIMD.Greater_Equal (Left, Right));
   function Unordered (Left, Right : F64x2) return Mask_64x2 is
     (Flyology_SIMD.Unordered (Left, Right));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Min_Number (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Min_Number (Left, Right));
   function Max_Number (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Max_Number (Left, Right));
   function Reduce_Add (Value : F64x2) return F64 is
     (Flyology_SIMD.Reduce_Add (Value));
   function Reverse_Lanes (Value : F64x2) return F64x2 is
     (Flyology_SIMD.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Deinterleave_Odd (Left, Right));
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : F64_Array; Start : Natural) return F64x2 is
     (Flyology_SIMD.Load (Data, Start));
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) is
   begin Flyology_SIMD.Store (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 is
     (Flyology_SIMD.Load_Aligned (Data, Start));
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) is
   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8 is
     (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean is
     (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_16x8) return Boolean is
     (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_16x8) return Boolean is
     (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_16x8) return Boolean is
     (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8 is
     (Flyology_SIMD.Population_Count (Mask));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4 is
     (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean is
     (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_32x4) return Boolean is
     (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_32x4) return Boolean is
     (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_32x4) return Boolean is
     (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4 is
     (Flyology_SIMD.Population_Count (Mask));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2 is
     (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean is
     (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_64x2) return Boolean is
     (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_64x2) return Boolean is
     (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_64x2) return Boolean is
     (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2 is
     (Flyology_SIMD.Population_Count (Mask));
   --  END GENERATED FULL-FAMILY FALLBACK BODIES
end Flyology_SIMD.Backends.Native;
