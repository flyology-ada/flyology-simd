with Interfaces;

--  Complete-buffer byte algorithms composed from a statically known backend.
--  @formal Backend_Splat Construct a byte vector with one repeated value.
--  @formal Backend_Bitwise_And Apply bitwise AND to two byte vectors.
--  @formal Backend_Equal Compare corresponding byte lanes for equality.
--  @formal Backend_Less_Equal Compare unsigned byte lanes with less-or-equal.
--  @formal Backend_Greater_Equal Compare unsigned byte lanes with
--  greater-or-equal.
--  @formal Backend_Mask_And Apply Boolean AND to two byte masks.
--  @formal Backend_To_Bit_Mask Convert comparison truths to compact bits.
--  @formal Backend_Load_Unaligned Load 16 bytes without an alignment rule.
--  @formal Backend_Store_Unaligned Store 16 bytes without an alignment rule.
--  @formal Backend_Add_Saturate Add unsigned byte lanes with saturation.

generic
   with function Backend_Splat (Value : U8) return U8x16;
   with function Backend_Bitwise_And (Left, Right : U8x16) return U8x16;
   with function Backend_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_Less_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_Greater_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_Mask_And (Left, Right : Mask_8x16) return Mask_8x16;
   with function Backend_To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   with function Backend_Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16;
   with procedure Backend_Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x16);
   with function Backend_Add_Saturate (Left, Right : U8x16) return U8x16;
package Flyology_SIMD.Algorithms.Generic_Bytes with Preelaborate, SPARK_Mode => On is
   function Find_First_Difference (Left, Right : Byte_Array) return Search_Result
   with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the first Ada index at which the complete buffers differ.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @return A found flag and the first differing Ada index.
   function Equal (Left, Right : Byte_Array) return Boolean
   with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Report whether two complete byte arrays have identical elements.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @return True when every corresponding byte is equal.
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   --  Return the first Ada index at which Needle occurs.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @return A found flag and the first matching Ada index.
   function Find_First_Of (Data : Byte_Array; Needles : Byte_Array) return Search_Result;
   --  Return the first Ada index whose byte equals any member of Needles. An
   --  empty Data or Needles array has no match. Duplicate needles have no
   --  effect. The vector path is optimized for sets of up to four bytes;
   --  larger sets retain the same exact semantics through a scalar scan.
   --  @param Data The complete byte array to search.
   --  @param Needles The byte values that constitute the small set.
   --  @return A found flag and the first matching Ada index.
   function Count (Data : Byte_Array; Needle : U8) return Natural
   with SPARK_Mode => Off;
   --  Count occurrences of one byte.
   --  @param Data The complete byte array to scan.
   --  @param Needle The byte to count.
   --  @return The number of matching elements.
   function Count_In_Range (Data : Byte_Array; Low, High : U8) return Natural
   with SPARK_Mode => Off;
   --  Count bytes in the inclusive unsigned interval Low .. High. If Low is
   --  greater than High, the interval is empty and the result is zero.
   --  @param Data The complete byte array to scan.
   --  @param Low The inclusive lower byte bound.
   --  @param High The inclusive upper byte bound.
   --  @return The number of elements in the interval.
   procedure Add_Saturate (Data : in out Byte_Array; Value : U8);
   --  Add Value to every byte in place, clamping each result to 255. Empty
   --  buffers are unchanged.
   --  @param Data The complete byte buffer to transform in place.
   --  @param Value The unsigned byte addend broadcast to every element.
   function Is_ASCII (Data : Byte_Array) return Boolean;
   --  Report whether every byte is in the 7-bit ASCII range.
   --  @param Data The complete byte array to validate.
   --  @return True when every byte is less than 128.
end Flyology_SIMD.Algorithms.Generic_Bytes;
