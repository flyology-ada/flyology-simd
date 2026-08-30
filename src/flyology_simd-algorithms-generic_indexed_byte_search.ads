with Interfaces;

private generic
   type Index_Type is range <>;
   --  The array's integer index type.

   type Byte_Type is mod <>;
   --  The array's eight-bit modular component type.

   type Byte_Array_Type is array (Index_Type range <>) of aliased Byte_Type;
   --  The unconstrained, aliased-component byte array.

   with function Backend_Splat (Value : U8) return U8x16;
   --  Construct a byte vector with one repeated value.

   with function Backend_Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding byte lanes for equality.

   with function Backend_To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   --  Convert comparison truths to compact bits.

   with
     function Backend_Load_Unaligned (Data : Byte_Array_Type; Offset : Natural) return U8x16
     with
       Pre =>
         Data'Length in Natural'Range
         and then Natural (Data'Length) >= 16
         and then Offset <= Natural (Data'Length) - 16;
   --  Load 16 bytes beginning at a zero-based offset.

package Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search with Preelaborate, SPARK_Mode => On is
   --  Proof-oriented indexed-byte search core with an isolated load mechanism.

   type Search_Result is record
      Found : Boolean;
      --  True when the algorithm found a requested byte.
      Index : Index_Type;
      --  The actual match index when Found is True.
   end record;
   --  Result of an indexed-byte search. Index is meaningful only when Found
   --  is True.

   function Find_First_Of (Data : Byte_Array_Type; Needles : Byte_Array_Type) return Search_Result;
   --  Return the first index whose byte equals any member of Needles. Empty
   --  inputs have no match. Sets of up to four bytes use the supplied vector
   --  operations; larger sets use a scalar search with identical results.
   --  @param Data The complete byte array to search without copying.
   --  @param Needles The byte values that constitute the search set.
   --  @return A found flag and, when found, the first matching actual index.
   pragma Inline_Always (Find_First_Of);
end Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search;
