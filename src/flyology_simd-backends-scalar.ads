with Interfaces;

--  Authoritative scalar implementation of the primitive operation contract.
package Flyology_SIMD.Backends.Scalar
  with Preelaborate
is
   function Zero return U8x16 renames Flyology_SIMD.Zero;
   function Splat (Value : U8) return U8x16 renames Flyology_SIMD.Splat;
   function From_Lanes (Values : Lane_Values_8x16) return U8x16
     renames Flyology_SIMD.From_Lanes;
   function To_Lanes (Value : U8x16) return Lane_Values_8x16
     renames Flyology_SIMD.To_Lanes;
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8
     renames Flyology_SIMD.Extract;
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16
     renames Flyology_SIMD.Replace;
   function Add_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Wrap;
   function Subtract_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Subtract_Wrap;
   function Multiply_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Multiply_Wrap;
   function Add_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Saturate;
   function Subtract_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Subtract_Saturate;
   function Bitwise_And (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_And;
   function Bitwise_Or (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Or;
   function Bitwise_Xor (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Xor;
   function Bitwise_Not (Value : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Not;
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Shift_Left_Logical;
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Shift_Right_Logical;
   function Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Equal;
   function Less_Than (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Than;
   function Less_Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Equal;
   function Greater_Than (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Than;
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Equal;
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16
     renames Flyology_SIMD.Select_Value;
   function Min (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Min;
   function Max (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Max;
   function Horizontal_Sum (Value : U8x16) return Natural
     renames Flyology_SIMD.Horizontal_Sum;
   function Reverse_Bytes (Value : U8x16) return U8x16
     renames Flyology_SIMD.Reverse_Bytes;
   function Interleave_Low (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Interleave_Low;
   function Interleave_High (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Interleave_High;
   function Deinterleave_Even (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Deinterleave_Odd;
   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16
     renames Flyology_SIMD.Mask_From_Bit_Mask;
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16
     renames Flyology_SIMD.To_Bit_Mask;
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean
     renames Flyology_SIMD.Test;
   function Any_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.Any_True;
   function All_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.All_True;
   function None_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.None_True;
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.Population_Count;
   function Load (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load;
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store;
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Unaligned;
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Unaligned;
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Aligned;
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Aligned;
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     renames Flyology_SIMD.Load_Partial;
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16)
     renames Flyology_SIMD.Store_Partial;
end Flyology_SIMD.Backends.Scalar;
