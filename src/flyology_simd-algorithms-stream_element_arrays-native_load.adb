with Flyology_SIMD.Index_Arithmetic;

package body Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load is
   package Index_Arithmetic is new
     Flyology_SIMD.Index_Arithmetic
       (Ada.Streams.Stream_Element_Offset,
        Ada.Streams.Stream_Element,
        Ada.Streams.Stream_Element_Array);

   function Load_Unaligned (Data : Ada.Streams.Stream_Element_Array; Offset : Natural) return U8x16 is
      Start  : constant Ada.Streams.Stream_Element_Offset := Index_Arithmetic.Index_At (Data, Offset);
      Source : constant Lane_Values_8x16
      with Import, Address => Data (Start)'Address;
   begin
      return (Lanes => Source);
   end Load_Unaligned;
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load;
