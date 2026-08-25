package body Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar
  with SPARK_Mode => On
is
   use type Ada.Streams.Stream_Element;

   function Find_First_Of
     (Data : Ada.Streams.Stream_Element_Array; Needles : Ada.Streams.Stream_Element_Array)
      return Search_Result is
   begin
      for Index in Data'Range loop
         for Needle of Needles loop
            if Data (Index) = Needle then
               return (Found => True, Index => Index);
            end if;
         end loop;
      end loop;
      return (Found => False, Index => Ada.Streams.Stream_Element_Offset'First);
   end Find_First_Of;
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;
