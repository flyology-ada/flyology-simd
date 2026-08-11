with Ada.Text_IO;
with Interfaces;
with Flyology_SIMD;

procedure Floating_Vectors is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;

   Samples : constant F32x4 := From_Lanes ([-1.5, 0.0, 2.25, 10.0]);
   Scaled : constant F32x4 := Multiply (Samples, Splat (2.0));
   Negative : constant Mask_32x4 := Less_Than (Scaled, Zero);
begin
   for Lane in Lane_Index_32x4 loop
      Put_Line
        ("lane" & Lane'Image & " = " & F32'Image (Extract (Scaled, Lane)));
   end loop;
   Put_Line
     ("negative-lane bits: " &
      Interfaces.Unsigned_8'Image (To_Bit_Mask (Negative)));
end Floating_Vectors;
