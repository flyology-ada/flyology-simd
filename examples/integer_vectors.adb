with Ada.Text_IO;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Integer_Vectors is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_16;
   package Native renames Flyology_SIMD.Backends.Native;

   Input : constant U16x8 :=
     Native.From_Lanes ([65_530, 1, 2, 3, 100, 200, 300, 400]);
   Increment : constant U16x8 := Native.Splat (10);
   Added : constant U16x8 := Native.Add_Wrap (Input, Increment);
   Subtracted : constant U16x8 := Native.Subtract_Wrap (Input, Increment);
   Multiplied : constant U16x8 := Native.Multiply_Wrap (Input, Increment);
   Saturated : constant U16x8 := Native.Add_Saturate (Input, Increment);
   Large : constant Mask_16x8 :=
     Native.Greater_Than (Input, Native.Splat (150));
begin
   pragma Assert (Native.Extract (Added, 0) = 4);
   pragma Assert (Native.Extract (Subtracted, 1) = 65_527);
   pragma Assert (Native.Extract (Multiplied, 0) = 65_476);
   pragma Assert (Native.Extract (Saturated, 0) = U16'Last);

   Put_Line ("added lane 0:      " & U16'Image (Native.Extract (Added, 0)));
   Put_Line
     ("subtracted lane 1: " & U16'Image (Native.Extract (Subtracted, 1)));
   Put_Line
     ("multiplied lane 0: " & U16'Image (Native.Extract (Multiplied, 0)));
   Put_Line
     ("saturated lane 0: " & U16'Image (Native.Extract (Saturated, 0)));
   Put_Line
     ("compact mask:      " &
      Interfaces.Unsigned_8'Image (Native.To_Bit_Mask (Large)));
end Integer_Vectors;
