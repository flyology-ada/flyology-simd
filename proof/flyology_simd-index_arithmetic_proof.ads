with Ada.Streams;
with Flyology_SIMD.Index_Arithmetic;

private package Flyology_SIMD.Index_Arithmetic_Proof
  with SPARK_Mode => On
is
   package Stream_Indexes is new
     Flyology_SIMD.Index_Arithmetic
       (Index_Type      => Ada.Streams.Stream_Element_Offset,
        Byte_Type       => Ada.Streams.Stream_Element,
        Byte_Array_Type => Ada.Streams.Stream_Element_Array);
end Flyology_SIMD.Index_Arithmetic_Proof;
