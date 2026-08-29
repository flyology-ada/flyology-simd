with Ada.Streams;

private package Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load
  with Preelaborate, SPARK_Mode => On
is
   --  Native address-based stream-element load isolated from the proved search.

   function Load_Unaligned (Data : Ada.Streams.Stream_Element_Array; Offset : Natural) return U8x16
   with
     Pre =>
       Data'Length in Natural'Range
       and then Natural (Data'Length) >= 16
       and then Offset <= Natural (Data'Length) - 16;
   --  Load 16 stream elements beginning at a zero-based offset.
   --  @param Data The stream-element array that supplies the bytes.
   --  @param Offset The zero-based offset of the first loaded element.
   --  @return The 16 loaded bytes in increasing array-index order.
   pragma Inline_Always (Load_Unaligned);
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load;
