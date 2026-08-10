with Interfaces;

package Flyology_SIMD.Backends.Scalar
  with Preelaborate
is
   function Zero return U8x16 renames Flyology_SIMD.Zero;
   function Splat (Value : U8) return U8x16 renames Flyology_SIMD.Splat;
   function Add_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Wrap;
   function Add_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Saturate;
   function Bitwise_And (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_And;
   function Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Equal;
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16
     renames Flyology_SIMD.Select_Value;
   function Min (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Min;
   function Max (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Max;
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16
     renames Flyology_SIMD.To_Bit_Mask;
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Unaligned;
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Unaligned;
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
