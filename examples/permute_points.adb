with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Permute_Points is
   use Ada.Text_IO;
   use type Flyology_SIMD.F32;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;
   use type Wide.Lane_Values_F32x8;

   --  Four planar points are stored as [x0, y0, ..., x3, y3].  One reusable
   --  map exchanges x and y inside each point.  Multiplication by alternating
   --  signs then rotates all four points counterclockwise by 90 degrees.
   Swap_XY       : constant Wide.Lane_Map_32x8 := Wide.Make_Lane_Map ([1, 0, 3, 2, 5, 4, 7, 6]);
   Points        : constant Wide.F32x8 := Native.From_Lanes ([2.0, 5.0, -3.0, 4.0, 0.0, -2.0, 7.0, 1.0]);
   Signs         : constant Wide.F32x8 := Native.From_Lanes ([-1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0]);
   Swapped       : constant Wide.F32x8 := Native.Permute_Lanes (Points, Swap_XY);
   Rotated       : constant Wide.F32x8 := Native.Multiply (Swapped, Signs);
   Swapped_Lanes : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Swapped);
   Result        : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Rotated);
begin
   pragma Assert (Swapped_Lanes = [5.0, 2.0, 4.0, -3.0, -2.0, 0.0, 1.0, 7.0]);
   pragma Assert (Result = [-5.0, 2.0, -4.0, -3.0, 2.0, 0.0, -1.0, 7.0]);
   Put_Line ("rotated points:");
   for Point in Natural range 0 .. 3 loop
      Put_Line
        ("  point"
         & Natural'Image (Point)
         & ": x="
         & Flyology_SIMD.F32'Image (Result (2 * Point))
         & ", y="
         & Flyology_SIMD.F32'Image (Result (2 * Point + 1)));
   end loop;
end Permute_Points;
