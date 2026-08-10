with Interfaces;

generic
   with function Backend_Splat (Value : U8) return U8x16;
   with function Backend_Bitwise_And (Left, Right : U8x16) return U8x16;
   with function Backend_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_To_Bit_Mask
     (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   with function Backend_Load_Unaligned
     (Data : Byte_Array; Start : Natural) return U8x16;
--  Complete-buffer byte algorithms composed from a statically known backend.
package Flyology_SIMD.Algorithms.Generic_Bytes
  with Preelaborate
is
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   function Count (Data : Byte_Array; Needle : U8) return Natural;
   function Is_ASCII (Data : Byte_Array) return Boolean;
end Flyology_SIMD.Algorithms.Generic_Bytes;
