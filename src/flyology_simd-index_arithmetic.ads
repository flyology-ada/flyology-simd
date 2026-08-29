private generic
   type Index_Type is range <>;
   type Byte_Type is mod <>;
   type Byte_Array_Type is array (Index_Type range <>) of aliased Byte_Type;
package Flyology_SIMD.Index_Arithmetic with Preelaborate, SPARK_Mode => On is
   --  Convert zero-based offsets to array index values without overflowing the
   --  index type.
   --  @formal Index_Type The array's integer index type.
   --  @formal Byte_Type The array's modular component type.
   --  @formal Byte_Array_Type The unconstrained, aliased-component array type.
   pragma Assertion_Policy (Pre => Ignore, Post => Ignore);

   function Index_At (Data : Byte_Array_Type; Offset : Natural) return Index_Type
   with
     Pre  =>
       (if Index_Type'Base'Size < Long_Long_Long_Integer'Size
        then
          Long_Long_Long_Integer (Offset)
          <= Long_Long_Long_Integer (Data'Last) - Long_Long_Long_Integer (Data'First)
        else
          Data'First <= Index_Type'Base'Last - Index_Type'Base (Offset)
          and then Data'First + Index_Type'Base (Offset) <= Data'Last),
     Post =>
       Index_At'Result in Data'Range
       and then (if Index_Type'Base'Size < Long_Long_Long_Integer'Size
                 then
                   Long_Long_Long_Integer (Index_At'Result)
                   = Long_Long_Long_Integer (Data'First) + Long_Long_Long_Integer (Offset)
                 else Index_At'Result = Data'First + Index_Type'Base (Offset));
   --  Return the array index at Offset positions from Data'First.
   --  @param Data The array whose bounds constrain the result.
   --  @param Offset The zero-based position in Data.
   --  @return The corresponding value in Data'Range.
end Flyology_SIMD.Index_Arithmetic;
