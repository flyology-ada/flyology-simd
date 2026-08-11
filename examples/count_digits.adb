with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Count_Digits is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Native renames Flyology_SIMD.Backends.Native;

   Input_Text : constant String := "port=8080; workers=16";
   Data : Byte_Array (Input_Text'Range);
   Start : Natural := Data'First;
   Total : Natural := 0;
begin
   for Index in Input_Text'Range loop
      Data (Index) := U8 (Character'Pos (Input_Text (Index)));
   end loop;

   while Start <= Data'Last loop
      declare
         Remaining : constant Natural := Data'Last - Start + 1;
         Count : constant Lane_Count_8x16 :=
           Lane_Count_8x16'Min (16, Remaining);
         Value : constant U8x16 :=
           Native.Load_Partial (Data, Start, Count);
         At_Least_Zero : constant Mask_8x16 :=
           Native.Greater_Equal
             (Value, Native.Splat (U8 (Character'Pos ('0'))));
         At_Most_Nine : constant Mask_8x16 :=
           Native.Less_Equal
             (Value, Native.Splat (U8 (Character'Pos ('9'))));
         Digit_Mask : constant Mask_8x16 :=
           Native.Mask_And (At_Least_Zero, At_Most_Nine);
      begin
         Total := Total + Native.Population_Count (Digit_Mask);
         Start := Start + Count;
      end;
   end loop;

   Put_Line ("digits:" & Total'Image);
end Count_Digits;
