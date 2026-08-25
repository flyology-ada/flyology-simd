with Interfaces;

--  Small-set byte classification for caller-selected array and index types.
--  The actual array must have contiguous eight-bit modular components.
--  @formal Index_Type The array's integer index type.
--  @formal Byte_Type The array's eight-bit modular component type.
--  @formal Byte_Array_Type The unconstrained, aliased-component byte array.
--  @formal Backend_Splat Construct a byte vector with one repeated value.
--  @formal Backend_Equal Compare corresponding byte lanes for equality.
--  @formal Backend_To_Bit_Mask Convert comparison truths to compact bits.

generic
   type Index_Type is range <>;
   type Byte_Type is mod <>;
   type Byte_Array_Type is array (Index_Type range <>) of aliased Byte_Type;
   with function Backend_Splat (Value : U8) return U8x16;
   with function Backend_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
package Flyology_SIMD.Algorithms.Generic_Indexed_Bytes with Preelaborate, SPARK_Mode => On is
   type Search_Result is record
      Found : Boolean;
      Index : Index_Type;
   end record;
   --  Result of an indexed-byte search. Index is meaningful only when Found
   --  is True.
   --  @field Found True when the algorithm found a requested byte.
   --  @field Index The actual match index when Found is True.

   function Find_First_Of (Data : Byte_Array_Type; Needles : Byte_Array_Type) return Search_Result;
   --  Return the first index whose byte equals any member of Needles. Empty
   --  inputs have no match. Duplicate needles have no effect. Sets of up to
   --  four bytes use the selected vector backend; larger sets use the scalar
   --  fallback with identical results.
   --  @param Data The complete byte array to search without copying.
   --  @param Needles The byte values that constitute the small set.
   --  @return A found flag and, when found, the first matching actual index.
end Flyology_SIMD.Algorithms.Generic_Indexed_Bytes;
