with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Runtime;

procedure Inspect_Delimited_Bytes is
   use Ada.Text_IO;
   use Flyology_SIMD;

   Input_Text : constant String := "Ada,2026,SIMD";
   Data : Byte_Array (Input_Text'Range);
begin
   for Index in Input_Text'Range loop
      Data (Index) := U8 (Character'Pos (Input_Text (Index)));
   end loop;

   Put_Line
     ("commas:" &
      Natural'Image
        (Algorithms.Runtime.Count
           (Data, U8 (Character'Pos (',')))));
   Put_Line
     ("ASCII: " & Boolean'Image (Algorithms.Runtime.Is_ASCII (Data)));
end Inspect_Delimited_Bytes;
