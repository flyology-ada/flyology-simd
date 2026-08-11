with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Partial_Tail is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Native renames Flyology_SIMD.Backends.Native;

   Data : Byte_Array (1 .. 19) := [others => 250];
   Start : Natural := Data'First;
begin
   while Start <= Data'Last loop
      declare
         Remaining : constant Natural := Data'Last - Start + 1;
         Count : constant Lane_Count_8x16 :=
           Lane_Count_8x16'Min (16, Remaining);
         Value : constant U8x16 :=
           Native.Load_Partial (Data, Start, Count);
         Result : constant U8x16 :=
           Native.Add_Saturate (Value, Native.Splat (10));
      begin
         Native.Store_Partial (Data, Start, Count, Result);
         Start := Start + Count;
      end;
   end loop;

   Put_Line
     ("first=" & U8'Image (Data (Data'First)) &
      ", last=" & U8'Image (Data (Data'Last)));
end Partial_Tail;
