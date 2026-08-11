with Interfaces;

--  Complete-buffer byte algorithms composed from a statically known backend.
--  @formal Backend_Splat Construct a byte vector with one repeated value.
--  @formal Backend_Bitwise_And Apply bitwise AND to two byte vectors.
--  @formal Backend_Equal Compare corresponding byte lanes for equality.
--  @formal Backend_To_Bit_Mask Convert comparison truths to compact bits.
--  @formal Backend_Load_Unaligned Load 16 bytes without an alignment rule.
generic
   with function Backend_Splat (Value : U8) return U8x16;
   with function Backend_Bitwise_And (Left, Right : U8x16) return U8x16;
   with function Backend_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_To_Bit_Mask
     (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   with function Backend_Load_Unaligned
     (Data : Byte_Array; Start : Natural) return U8x16;
package Flyology_SIMD.Algorithms.Generic_Bytes
  with Preelaborate
is
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   --  Return the first Ada index at which Needle occurs.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @return A found flag and the first matching Ada index.
   function Count (Data : Byte_Array; Needle : U8) return Natural;
   --  Count occurrences of one byte.
   --  @param Data The complete byte array to scan.
   --  @param Needle The byte to count.
   --  @return The number of matching elements.
   function Is_ASCII (Data : Byte_Array) return Boolean;
   --  Report whether every byte is in the 7-bit ASCII range.
   --  @param Data The complete byte array to validate.
   --  @return True when every byte is less than 128.
end Flyology_SIMD.Algorithms.Generic_Bytes;
