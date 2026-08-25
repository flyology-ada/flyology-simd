with Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search;
with Flyology_SIMD.Index_Arithmetic;

package body Flyology_SIMD.Algorithms.Generic_Indexed_Bytes is
   pragma
     Compile_Time_Error
       (Byte_Type'Modulus /= 2**U8'Size,
        "Generic_Indexed_Bytes requires an eight-bit modular component type");
   pragma
     Compile_Time_Error
       (Byte_Array_Type'Component_Size /= U8'Size,
        "Generic_Indexed_Bytes requires contiguous eight-bit array components");

   package Index_Arithmetic is new Flyology_SIMD.Index_Arithmetic (Index_Type, Byte_Type, Byte_Array_Type);

   function Load_Unaligned (Data : Byte_Array_Type; Offset : Natural) return U8x16
   with
     Pre =>
       Data'Length in Natural'Range
       and then Natural (Data'Length) >= 16
       and then Offset <= Natural (Data'Length) - 16;

   function Load_Unaligned (Data : Byte_Array_Type; Offset : Natural) return U8x16 is
      Start  : constant Index_Type := Index_Arithmetic.Index_At (Data, Offset);
      Source : constant Lane_Values_8x16
      with Import, Address => Data (Start)'Address;
   begin
      return (Lanes => Source);
   end Load_Unaligned;
   pragma Inline_Always (Load_Unaligned);

   package Implementation is new
     Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search
       (Index_Type             => Index_Type,
        Byte_Type              => Byte_Type,
        Byte_Array_Type        => Byte_Array_Type,
        Backend_Splat          => Backend_Splat,
        Backend_Equal          => Backend_Equal,
        Backend_To_Bit_Mask    => Backend_To_Bit_Mask,
        Backend_Load_Unaligned => Load_Unaligned);

   function Find_First_Of (Data : Byte_Array_Type; Needles : Byte_Array_Type) return Search_Result is
      Result : constant Implementation.Search_Result := Implementation.Find_First_Of (Data, Needles);
   begin
      return (Found => Result.Found, Index => Result.Index);
   end Find_First_Of;
end Flyology_SIMD.Algorithms.Generic_Indexed_Bytes;
