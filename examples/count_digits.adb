with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Runtime;

procedure Count_Digits is
   use Ada.Text_IO;
   use Flyology_SIMD;

   Input_Text : constant String := "port=8080; workers=16";
   Data : Byte_Array (Input_Text'Range);
begin
   for Index in Input_Text'Range loop
      Data (Index) := U8 (Character'Pos (Input_Text (Index)));
   end loop;

   Put_Line
     ("digits:" &
      Natural'Image
        (Algorithms.Runtime.Count_In_Range
           (Data,
            U8 (Character'Pos ('0')),
            U8 (Character'Pos ('9')))));
end Count_Digits;
