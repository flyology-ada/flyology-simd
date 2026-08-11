with Ada.Text_IO;
with Interfaces;
with Flyology_SIMD;

procedure Integer_Vectors is
   use Ada.Text_IO;
   use Flyology_SIMD;

   Input : constant U16x8 :=
     From_Lanes ([65_530, 1, 2, 3, 100, 200, 300, 400]);
   Increment : constant U16x8 := Splat (10);
   Wrapped : constant U16x8 := Add_Wrap (Input, Increment);
   Saturated : constant U16x8 := Add_Saturate (Input, Increment);
   Large : constant Mask_16x8 := Greater_Than (Input, Splat (150));
begin
   Put_Line ("wrapped lane 0:   " & U16'Image (Extract (Wrapped, 0)));
   Put_Line ("saturated lane 0: " & U16'Image (Extract (Saturated, 0)));
   Put_Line
     ("compact mask:      " &
      Interfaces.Unsigned_8'Image (To_Bit_Mask (Large)));
end Integer_Vectors;
