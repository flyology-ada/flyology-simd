with Interfaces;

--  Proof-oriented indexed-byte search core with an isolated load mechanism.

private generic
   type Index_Type is range <>;
   type Byte_Type is mod <>;
   type Byte_Array_Type is array (Index_Type range <>) of aliased Byte_Type;
   with function Backend_Splat (Value : U8) return U8x16;
   with function Backend_Equal (Left, Right : U8x16) return Mask_8x16;
   with function Backend_To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   with
     function Backend_Load_Unaligned (Data : Byte_Array_Type; Offset : Natural) return U8x16
     with
       Pre =>
         Data'Length in Natural'Range
         and then Natural (Data'Length) >= 16
         and then Offset <= Natural (Data'Length) - 16;
package Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search with Preelaborate, SPARK_Mode => On is
   type Search_Result is record
      Found : Boolean;
      Index : Index_Type;
   end record;

   function Find_First_Of (Data : Byte_Array_Type; Needles : Byte_Array_Type) return Search_Result;
   pragma Inline_Always (Find_First_Of);
end Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search;
