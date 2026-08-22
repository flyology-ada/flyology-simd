with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Lane_Slides is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;
   use type Wide.Lane_Values_F32x8;

   Samples          : constant Wide.F32x8 := Native.From_Lanes ([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
   Previous         : constant Wide.F32x8 := Native.Slide_Lanes_Toward_High (Samples, 1);
   Following        : constant Wide.F32x8 := Native.Slide_Lanes_Toward_Low (Samples, 1);
   Three_Point_Sums : constant Wide.F32x8 := Native.Add (Native.Add (Previous, Samples), Following);
   Previous_Lanes   : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Previous);
   Following_Lanes  : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Following);
   Result           : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Three_Point_Sums);

   procedure Put_Lanes
     (Label  : String;
      Values : Wide.Lane_Values_F32x8;
      First  : Wide.Lane_Index_32x8;
      Last   : Wide.Lane_Index_32x8) is
   begin
      Put (Label & ":");
      for Lane in First .. Last loop
         Put (F32'Image (Values (Lane)));
         if Lane < Last then
            Put (", ");
         end if;
      end loop;
      New_Line;
   end Put_Lanes;

   procedure Put_Vector (Label : String; Values : Wide.Lane_Values_F32x8) is
   begin
      Put_Lanes (Label & " lanes 0..3", Values, 0, 3);
      Put_Lanes (Label & " lanes 4..7", Values, 4, 7);
   end Put_Vector;
begin
   pragma Assert (Previous_Lanes = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
   pragma Assert (Following_Lanes = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 0.0]);
   pragma Assert (Result = [3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 15.0]);
   Put_Vector ("toward high", Previous_Lanes);
   Put_Vector ("toward low", Following_Lanes);
   Put_Vector ("sums", Result);
end Lane_Slides;
