with Flyology_SIMD.Algorithms.Generic_Indexed_Bytes;
with Flyology_SIMD.Backends.Scalar;

package body Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar is
   package Implementation is new
     Flyology_SIMD.Algorithms.Generic_Indexed_Bytes
       (Index_Type          => Ada.Streams.Stream_Element_Offset,
        Byte_Type           => Ada.Streams.Stream_Element,
        Byte_Array_Type     => Ada.Streams.Stream_Element_Array,
        Backend_Splat       => Flyology_SIMD.Backends.Scalar.Splat,
        Backend_Equal       => Flyology_SIMD.Backends.Scalar.Equal,
        Backend_To_Bit_Mask => Flyology_SIMD.Backends.Scalar.To_Bit_Mask);

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
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;
