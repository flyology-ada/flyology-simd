with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Permute_Points is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   package Native renames Flyology_SIMD.Backends.Native;

   --  Two planar points are stored as [x0, y0, x1, y1].  One reusable map
   --  exchanges x and y inside both points.  Multiplication by alternating
   --  signs then rotates both points counterclockwise by 90 degrees.
   Swap_XY : constant Lane_Map_32x4 := Make_Lane_Map ([1, 0, 3, 2]);
   Points : constant F32x4 := Native.From_Lanes ([2.0, 5.0, -3.0, 4.0]);
   Signs : constant F32x4 := Native.From_Lanes ([-1.0, 1.0, -1.0, 1.0]);
   Rotated : constant F32x4 :=
     Native.Multiply (Native.Permute_Lanes (Points, Swap_XY), Signs);
   Result : constant Lane_Values_F32x4 := Native.To_Lanes (Rotated);
begin
   pragma Assert (Result = [-5.0, 2.0, -4.0, -3.0]);
   Put_Line
     ("rotated points: [" & F32'Image (Result (0)) & "," &
      F32'Image (Result (1)) & "] [" & F32'Image (Result (2)) & "," &
      F32'Image (Result (3)) & "]");
end Permute_Points;
