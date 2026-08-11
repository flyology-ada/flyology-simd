with Ada.Text_IO;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Integer_Vectors is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Native renames Flyology_SIMD.Backends.Native;

   Input : constant U16x8 :=
     Native.From_Lanes ([65_530, 1, 2, 3, 100, 200, 300, 400]);
   Increment : constant U16x8 := Native.Splat (10);
   Wrapped : constant U16x8 := Native.Add_Wrap (Input, Increment);
   Saturated : constant U16x8 := Native.Add_Saturate (Input, Increment);
   Large : constant Mask_16x8 :=
     Native.Greater_Than (Input, Native.Splat (150));
begin
   Put_Line ("wrapped lane 0:   " & U16'Image (Native.Extract (Wrapped, 0)));
   Put_Line
     ("saturated lane 0: " & U16'Image (Native.Extract (Saturated, 0)));
   Put_Line
     ("compact mask:      " &
      Interfaces.Unsigned_8'Image (Native.To_Bit_Mask (Large)));
end Integer_Vectors;
