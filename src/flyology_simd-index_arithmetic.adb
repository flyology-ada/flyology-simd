package body Flyology_SIMD.Index_Arithmetic
  with SPARK_Mode => On
is
   function Index_At (Data : Byte_Array_Type; Offset : Natural) return Index_Type is
   begin
      --  An instance selects this branch statically. GNATprove otherwise emits
      --  a compiler warning for the intentionally constant selection.
      pragma Warnings (Off, "statement has no effect");
      if Index_Type'Base'Size < Long_Long_Long_Integer'Size then
         return Index_Type (Long_Long_Long_Integer (Data'First) + Long_Long_Long_Integer (Offset));
      else
         declare
            Result : Index_Type := Data'First;
         begin
            for Step in 1 .. Offset loop
               Result := Index_Type'Succ (Result);
            end loop;
            return Result;
         end;
      end if;
      pragma Warnings (On, "statement has no effect");
   end Index_At;
end Flyology_SIMD.Index_Arithmetic;
