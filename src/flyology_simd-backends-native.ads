with Interfaces;

package Flyology_SIMD.Backends.Native
  with Preelaborate
is
   function Zero return U8x16;
   function Splat (Value : U8) return U8x16;
   function Add_Wrap (Left, Right : U8x16) return U8x16;
   function Add_Saturate (Left, Right : U8x16) return U8x16;
   function Bitwise_And (Left, Right : U8x16) return U8x16;
   function Equal (Left, Right : U8x16) return Mask_8x16;
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16;
   function Min (Left, Right : U8x16) return U8x16;
   function Max (Left, Right : U8x16) return U8x16;
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
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
end Flyology_SIMD.Backends.Native;
