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
   Previous_Lanes : constant Lane_Values_F32x4 := Native.To_Lanes (Previous);
   Following_Lanes : constant Lane_Values_F32x4 := Native.To_Lanes (Following);
   Result : constant Lane_Values_F32x4 := Native.To_Lanes (Three_Point_Sums);

   procedure Put_Vector (Label : String; Values : Lane_Values_F32x4) is
   begin
      Put (Label & ":");
      for Value of Values loop
         Put (F32'Image (Value));
      end loop;
      New_Line;
   end Put_Vector;
begin
   pragma Assert (Previous_Lanes = [0.0, 1.0, 2.0, 3.0]);
   pragma Assert (Following_Lanes = [2.0, 3.0, 4.0, 0.0]);
   pragma Assert (Result = [3.0, 6.0, 9.0, 7.0]);
   Put_Vector ("toward high", Previous_Lanes);
   Put_Vector ("toward low ", Following_Lanes);
   Put_Vector ("sums       ", Result);
end Lane_Slides;
