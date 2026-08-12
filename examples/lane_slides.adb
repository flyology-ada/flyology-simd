with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Lane_Slides is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Native renames Flyology_SIMD.Backends.Native;

   Samples : constant F32x4 := Native.From_Lanes ([1.0, 2.0, 3.0, 4.0]);
   Previous : constant F32x4 :=
     Native.Slide_Lanes_Toward_High (Samples, 1);
   Following : constant F32x4 :=
     Native.Slide_Lanes_Toward_Low (Samples, 1);
   Three_Point_Sums : constant F32x4 :=
     Native.Add (Native.Add (Previous, Samples), Following);
   Result : constant Lane_Values_F32x4 := Native.To_Lanes (Three_Point_Sums);
begin
   pragma Assert (Result = [3.0, 6.0, 9.0, 7.0]);
   for Lane in Result'Range loop
      Put_Line ("lane" & Lane'Image & ":" & F32'Image (Result (Lane)));
   end loop;
end Lane_Slides;
