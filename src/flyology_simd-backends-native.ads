with Interfaces;

package Flyology_SIMD.Backends.Native
  with Preelaborate
is
   function Zero return U8x16;
   function Splat (Value : U8) return U8x16;
   function From_Lanes (Values : Lane_Values_8x16) return U8x16;
   function To_Lanes (Value : U8x16) return Lane_Values_8x16;
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8;
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16;

   function Add_Wrap (Left, Right : U8x16) return U8x16;
   function Subtract_Wrap (Left, Right : U8x16) return U8x16;
   function Add_Saturate (Left, Right : U8x16) return U8x16;
   function Subtract_Saturate (Left, Right : U8x16) return U8x16;

   function Bitwise_And (Left, Right : U8x16) return U8x16;
   function Bitwise_Or (Left, Right : U8x16) return U8x16;
   function Bitwise_Xor (Left, Right : U8x16) return U8x16;
   function Bitwise_Not (Value : U8x16) return U8x16;

   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16;
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16;

   function Equal (Left, Right : U8x16) return Mask_8x16;
   function Less_Than (Left, Right : U8x16) return Mask_8x16;
   function Less_Equal (Left, Right : U8x16) return Mask_8x16;
   function Greater_Than (Left, Right : U8x16) return Mask_8x16;
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16;

   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16;
   function Min (Left, Right : U8x16) return U8x16;
   function Max (Left, Right : U8x16) return U8x16;
   function Horizontal_Sum (Value : U8x16) return Natural
     with Post => Horizontal_Sum'Result <= 16 * 255;

   function Reverse_Bytes (Value : U8x16) return U8x16;
   function Interleave_Low (Left, Right : U8x16) return U8x16;
   function Interleave_High (Left, Right : U8x16) return U8x16;

   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16;
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean;
   function Any_True (Mask : Mask_8x16) return Boolean;
   function All_True (Mask : Mask_8x16) return Boolean;
   function None_True (Mask : Mask_8x16) return Boolean;
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16;

   function Load (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16)
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);

   --  These are the primitive operations used by the statically instantiated
   --  whole-buffer algorithms.  Inter-unit inlining removes one call boundary
   --  per vector while preserving the same backend contract for generic code.
   pragma Inline_Always (Splat);
   pragma Inline_Always (Bitwise_And);
   pragma Inline_Always (Equal);
   pragma Inline_Always (Mask_From_Bit_Mask);
   pragma Inline_Always (To_Bit_Mask);
   pragma Inline_Always (Load_Unaligned);

   --  BEGIN GENERATED FULL-FAMILY BACKEND CONTRACT
   function Zero return I8x16;
   function Splat (Value : I8) return I8x16;
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16;
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16;
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8;
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16;
   function Add_Wrap (Left, Right : I8x16) return I8x16;
   function Subtract_Wrap (Left, Right : I8x16) return I8x16;
   function Multiply_Wrap (Left, Right : I8x16) return I8x16;
   function Add_Saturate (Left, Right : I8x16) return I8x16;
   function Subtract_Saturate (Left, Right : I8x16) return I8x16;
   function Bitwise_And (Left, Right : I8x16) return I8x16;
   function Bitwise_Or (Left, Right : I8x16) return I8x16;
   function Bitwise_Xor (Left, Right : I8x16) return I8x16;
   function Bitwise_Not (Value : I8x16) return I8x16;
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16;
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16;
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16;
   function Equal (Left, Right : I8x16) return Mask_8x16;
   function Less_Than (Left, Right : I8x16) return Mask_8x16;
   function Less_Equal (Left, Right : I8x16) return Mask_8x16;
   function Greater_Than (Left, Right : I8x16) return Mask_8x16;
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16;
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16;
   function Min (Left, Right : I8x16) return I8x16;
   function Max (Left, Right : I8x16) return I8x16;
   function Reduce_Add_Wrap (Value : I8x16) return I8;
   function Reduce_Min (Value : I8x16) return I8;
   function Reduce_Max (Value : I8x16) return I8;
   function Reverse_Lanes (Value : I8x16) return I8x16;
   function Interleave_Low (Left, Right : I8x16) return I8x16;
   function Interleave_High (Left, Right : I8x16) return I8x16;
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean;
   function Load (Data : I8_Array; Start : Natural) return I8x16
     with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return U16x8;
   function Splat (Value : U16) return U16x8;
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8;
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8;
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16;
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8;
   function Add_Wrap (Left, Right : U16x8) return U16x8;
   function Subtract_Wrap (Left, Right : U16x8) return U16x8;
   function Multiply_Wrap (Left, Right : U16x8) return U16x8;
   function Add_Saturate (Left, Right : U16x8) return U16x8;
   function Subtract_Saturate (Left, Right : U16x8) return U16x8;
   function Bitwise_And (Left, Right : U16x8) return U16x8;
   function Bitwise_Or (Left, Right : U16x8) return U16x8;
   function Bitwise_Xor (Left, Right : U16x8) return U16x8;
   function Bitwise_Not (Value : U16x8) return U16x8;
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8;
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8;
   function Equal (Left, Right : U16x8) return Mask_16x8;
   function Less_Than (Left, Right : U16x8) return Mask_16x8;
   function Less_Equal (Left, Right : U16x8) return Mask_16x8;
   function Greater_Than (Left, Right : U16x8) return Mask_16x8;
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8;
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8;
   function Min (Left, Right : U16x8) return U16x8;
   function Max (Left, Right : U16x8) return U16x8;
   function Reduce_Add_Wrap (Value : U16x8) return U16;
   function Reduce_Min (Value : U16x8) return U16;
   function Reduce_Max (Value : U16x8) return U16;
   function Reverse_Lanes (Value : U16x8) return U16x8;
   function Interleave_Low (Left, Right : U16x8) return U16x8;
   function Interleave_High (Left, Right : U16x8) return U16x8;
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean;
   function Load (Data : U16_Array; Start : Natural) return U16x8
     with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return I16x8;
   function Splat (Value : I16) return I16x8;
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8;
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8;
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16;
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8;
   function Add_Wrap (Left, Right : I16x8) return I16x8;
   function Subtract_Wrap (Left, Right : I16x8) return I16x8;
   function Multiply_Wrap (Left, Right : I16x8) return I16x8;
   function Add_Saturate (Left, Right : I16x8) return I16x8;
   function Subtract_Saturate (Left, Right : I16x8) return I16x8;
   function Bitwise_And (Left, Right : I16x8) return I16x8;
   function Bitwise_Or (Left, Right : I16x8) return I16x8;
   function Bitwise_Xor (Left, Right : I16x8) return I16x8;
   function Bitwise_Not (Value : I16x8) return I16x8;
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8;
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8;
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8;
   function Equal (Left, Right : I16x8) return Mask_16x8;
   function Less_Than (Left, Right : I16x8) return Mask_16x8;
   function Less_Equal (Left, Right : I16x8) return Mask_16x8;
   function Greater_Than (Left, Right : I16x8) return Mask_16x8;
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8;
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8;
   function Min (Left, Right : I16x8) return I16x8;
   function Max (Left, Right : I16x8) return I16x8;
   function Reduce_Add_Wrap (Value : I16x8) return I16;
   function Reduce_Min (Value : I16x8) return I16;
   function Reduce_Max (Value : I16x8) return I16;
   function Reverse_Lanes (Value : I16x8) return I16x8;
   function Interleave_Low (Left, Right : I16x8) return I16x8;
   function Interleave_High (Left, Right : I16x8) return I16x8;
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean;
   function Load (Data : I16_Array; Start : Natural) return I16x8
     with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return U32x4;
   function Splat (Value : U32) return U32x4;
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4;
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4;
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32;
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4;
   function Add_Wrap (Left, Right : U32x4) return U32x4;
   function Subtract_Wrap (Left, Right : U32x4) return U32x4;
   function Multiply_Wrap (Left, Right : U32x4) return U32x4;
   function Add_Saturate (Left, Right : U32x4) return U32x4;
   function Subtract_Saturate (Left, Right : U32x4) return U32x4;
   function Bitwise_And (Left, Right : U32x4) return U32x4;
   function Bitwise_Or (Left, Right : U32x4) return U32x4;
   function Bitwise_Xor (Left, Right : U32x4) return U32x4;
   function Bitwise_Not (Value : U32x4) return U32x4;
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4;
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4;
   function Equal (Left, Right : U32x4) return Mask_32x4;
   function Less_Than (Left, Right : U32x4) return Mask_32x4;
   function Less_Equal (Left, Right : U32x4) return Mask_32x4;
   function Greater_Than (Left, Right : U32x4) return Mask_32x4;
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4;
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4;
   function Min (Left, Right : U32x4) return U32x4;
   function Max (Left, Right : U32x4) return U32x4;
   function Reduce_Add_Wrap (Value : U32x4) return U32;
   function Reduce_Min (Value : U32x4) return U32;
   function Reduce_Max (Value : U32x4) return U32;
   function Reverse_Lanes (Value : U32x4) return U32x4;
   function Interleave_Low (Left, Right : U32x4) return U32x4;
   function Interleave_High (Left, Right : U32x4) return U32x4;
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean;
   function Load (Data : U32_Array; Start : Natural) return U32x4
     with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return I32x4;
   function Splat (Value : I32) return I32x4;
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4;
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4;
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32;
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4;
   function Add_Wrap (Left, Right : I32x4) return I32x4;
   function Subtract_Wrap (Left, Right : I32x4) return I32x4;
   function Multiply_Wrap (Left, Right : I32x4) return I32x4;
   function Add_Saturate (Left, Right : I32x4) return I32x4;
   function Subtract_Saturate (Left, Right : I32x4) return I32x4;
   function Bitwise_And (Left, Right : I32x4) return I32x4;
   function Bitwise_Or (Left, Right : I32x4) return I32x4;
   function Bitwise_Xor (Left, Right : I32x4) return I32x4;
   function Bitwise_Not (Value : I32x4) return I32x4;
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4;
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4;
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4;
   function Equal (Left, Right : I32x4) return Mask_32x4;
   function Less_Than (Left, Right : I32x4) return Mask_32x4;
   function Less_Equal (Left, Right : I32x4) return Mask_32x4;
   function Greater_Than (Left, Right : I32x4) return Mask_32x4;
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4;
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4;
   function Min (Left, Right : I32x4) return I32x4;
   function Max (Left, Right : I32x4) return I32x4;
   function Reduce_Add_Wrap (Value : I32x4) return I32;
   function Reduce_Min (Value : I32x4) return I32;
   function Reduce_Max (Value : I32x4) return I32;
   function Reverse_Lanes (Value : I32x4) return I32x4;
   function Interleave_Low (Left, Right : I32x4) return I32x4;
   function Interleave_High (Left, Right : I32x4) return I32x4;
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean;
   function Load (Data : I32_Array; Start : Natural) return I32x4
     with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return U64x2;
   function Splat (Value : U64) return U64x2;
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2;
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2;
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64;
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2;
   function Add_Wrap (Left, Right : U64x2) return U64x2;
   function Subtract_Wrap (Left, Right : U64x2) return U64x2;
   function Multiply_Wrap (Left, Right : U64x2) return U64x2;
   function Add_Saturate (Left, Right : U64x2) return U64x2;
   function Subtract_Saturate (Left, Right : U64x2) return U64x2;
   function Bitwise_And (Left, Right : U64x2) return U64x2;
   function Bitwise_Or (Left, Right : U64x2) return U64x2;
   function Bitwise_Xor (Left, Right : U64x2) return U64x2;
   function Bitwise_Not (Value : U64x2) return U64x2;
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2;
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2;
   function Equal (Left, Right : U64x2) return Mask_64x2;
   function Less_Than (Left, Right : U64x2) return Mask_64x2;
   function Less_Equal (Left, Right : U64x2) return Mask_64x2;
   function Greater_Than (Left, Right : U64x2) return Mask_64x2;
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2;
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2;
   function Min (Left, Right : U64x2) return U64x2;
   function Max (Left, Right : U64x2) return U64x2;
   function Reduce_Add_Wrap (Value : U64x2) return U64;
   function Reduce_Min (Value : U64x2) return U64;
   function Reduce_Max (Value : U64x2) return U64;
   function Reverse_Lanes (Value : U64x2) return U64x2;
   function Interleave_Low (Left, Right : U64x2) return U64x2;
   function Interleave_High (Left, Right : U64x2) return U64x2;
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean;
   function Load (Data : U64_Array; Start : Natural) return U64x2
     with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return I64x2;
   function Splat (Value : I64) return I64x2;
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2;
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2;
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64;
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2;
   function Add_Wrap (Left, Right : I64x2) return I64x2;
   function Subtract_Wrap (Left, Right : I64x2) return I64x2;
   function Multiply_Wrap (Left, Right : I64x2) return I64x2;
   function Add_Saturate (Left, Right : I64x2) return I64x2;
   function Subtract_Saturate (Left, Right : I64x2) return I64x2;
   function Bitwise_And (Left, Right : I64x2) return I64x2;
   function Bitwise_Or (Left, Right : I64x2) return I64x2;
   function Bitwise_Xor (Left, Right : I64x2) return I64x2;
   function Bitwise_Not (Value : I64x2) return I64x2;
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2;
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2;
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2;
   function Equal (Left, Right : I64x2) return Mask_64x2;
   function Less_Than (Left, Right : I64x2) return Mask_64x2;
   function Less_Equal (Left, Right : I64x2) return Mask_64x2;
   function Greater_Than (Left, Right : I64x2) return Mask_64x2;
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2;
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2;
   function Min (Left, Right : I64x2) return I64x2;
   function Max (Left, Right : I64x2) return I64x2;
   function Reduce_Add_Wrap (Value : I64x2) return I64;
   function Reduce_Min (Value : I64x2) return I64;
   function Reduce_Max (Value : I64x2) return I64;
   function Reverse_Lanes (Value : I64x2) return I64x2;
   function Interleave_Low (Left, Right : I64x2) return I64x2;
   function Interleave_High (Left, Right : I64x2) return I64x2;
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean;
   function Load (Data : I64_Array; Start : Natural) return I64x2
     with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return F32x4;
   function Splat (Value : F32) return F32x4;
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4;
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4;
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32;
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4;
   function Add (Left, Right : F32x4) return F32x4;
   function Subtract (Left, Right : F32x4) return F32x4;
   function Multiply (Left, Right : F32x4) return F32x4;
   function Divide (Left, Right : F32x4) return F32x4;
   function Equal (Left, Right : F32x4) return Mask_32x4;
   function Less_Than (Left, Right : F32x4) return Mask_32x4;
   function Less_Equal (Left, Right : F32x4) return Mask_32x4;
   function Greater_Than (Left, Right : F32x4) return Mask_32x4;
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4;
   function Unordered (Left, Right : F32x4) return Mask_32x4;
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4;
   function Min_Number (Left, Right : F32x4) return F32x4;
   function Max_Number (Left, Right : F32x4) return F32x4;
   function Reduce_Add (Value : F32x4) return F32;
   function Reverse_Lanes (Value : F32x4) return F32x4;
   function Interleave_Low (Left, Right : F32x4) return F32x4;
   function Interleave_High (Left, Right : F32x4) return F32x4;
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean;
   function Load (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Zero return F64x2;
   function Splat (Value : F64) return F64x2;
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2;
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2;
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64;
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2;
   function Add (Left, Right : F64x2) return F64x2;
   function Subtract (Left, Right : F64x2) return F64x2;
   function Multiply (Left, Right : F64x2) return F64x2;
   function Divide (Left, Right : F64x2) return F64x2;
   function Equal (Left, Right : F64x2) return Mask_64x2;
   function Less_Than (Left, Right : F64x2) return Mask_64x2;
   function Less_Equal (Left, Right : F64x2) return Mask_64x2;
   function Greater_Than (Left, Right : F64x2) return Mask_64x2;
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2;
   function Unordered (Left, Right : F64x2) return Mask_64x2;
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2;
   function Min_Number (Left, Right : F64x2) return F64x2;
   function Max_Number (Left, Right : F64x2) return F64x2;
   function Reduce_Add (Value : F64x2) return F64;
   function Reverse_Lanes (Value : F64x2) return F64x2;
   function Interleave_Low (Left, Right : F64x2) return F64x2;
   function Interleave_High (Left, Right : F64x2) return F64x2;
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean;
   function Load (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8;
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8;
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean;
   function Any_True (Mask : Mask_16x8) return Boolean;
   function All_True (Mask : Mask_16x8) return Boolean;
   function None_True (Mask : Mask_16x8) return Boolean;
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4;
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8;
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean;
   function Any_True (Mask : Mask_32x4) return Boolean;
   function All_True (Mask : Mask_32x4) return Boolean;
   function None_True (Mask : Mask_32x4) return Boolean;
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2;
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8;
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean;
   function Any_True (Mask : Mask_64x2) return Boolean;
   function All_True (Mask : Mask_64x2) return Boolean;
   function None_True (Mask : Mask_64x2) return Boolean;
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2;
   --  END GENERATED FULL-FAMILY BACKEND CONTRACT
end Flyology_SIMD.Backends.Native;
