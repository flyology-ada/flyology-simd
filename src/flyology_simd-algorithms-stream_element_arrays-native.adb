with Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search;
with Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load;
with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native
  with SPARK_Mode => On
is
   package Implementation is new
     Flyology_SIMD.Algorithms.Generic_Indexed_Byte_Search
       (Index_Type             => Ada.Streams.Stream_Element_Offset,
        Byte_Type              => Ada.Streams.Stream_Element,
        Byte_Array_Type        => Ada.Streams.Stream_Element_Array,
        Backend_Splat          => Flyology_SIMD.Backends.Native.Splat,
        Backend_Equal          => Flyology_SIMD.Backends.Native.Equal,
        Backend_To_Bit_Mask    => Flyology_SIMD.Backends.Native.To_Bit_Mask,
        Backend_Load_Unaligned => Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native_Load.Load_Unaligned);

   function Find_First_Of
     (Data : Ada.Streams.Stream_Element_Array; Needles : Ada.Streams.Stream_Element_Array)
      return Search_Result
   is
      Result : constant Implementation.Search_Result := Implementation.Find_First_Of (Data, Needles);
   begin
      if Result.Found then
         return (Found => True, Index => Result.Index);
      else
         return (Found => False, Index => Ada.Streams.Stream_Element_Offset'First);
      end if;
   end Find_First_Of;
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native;
