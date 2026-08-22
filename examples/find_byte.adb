with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Runtime;

procedure Find_Byte is
   use Ada.Text_IO;
   Data   : Flyology_SIMD.Byte_Array (1 .. 23) :=
     [70, 108, 121, 111, 108, 111, 103, 121, 32, 83, 73, 77, 68, 32, 105, 115, 32, 65, 100, 97, 33, 10, 0];
   Result : constant Flyology_SIMD.Algorithms.Search_Result :=
     Flyology_SIMD.Algorithms.Runtime.Find_First (Data, Flyology_SIMD.U8 (Character'Pos ('!')));
begin
   if Result.Found then
      Put_Line ("Found '!' at Ada array index" & Result.Index'Image);
   else
      Put_Line ("Not found");
   end if;
end Find_Byte;
