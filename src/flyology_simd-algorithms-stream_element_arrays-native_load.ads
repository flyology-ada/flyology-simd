with Ada.Streams;

--  Native address-based stream-element load isolated from the proved search.

private package Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load
  with Preelaborate, SPARK_Mode => On
is
   function Load_Unaligned (Data : Ada.Streams.Stream_Element_Array; Offset : Natural) return U8x16
   with
     Pre =>
       Data'Length in Natural'Range
       and then Natural (Data'Length) >= 16
       and then Offset <= Natural (Data'Length) - 16;
   pragma Inline_Always (Load_Unaligned);
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load;
