with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Table_Lookup is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Native renames Flyology_SIMD.Backends.Native;

   Hex_Digits : constant U8x16 := From_Lanes
     ([Character'Pos ('0'), Character'Pos ('1'), Character'Pos ('2'),
       Character'Pos ('3'), Character'Pos ('4'), Character'Pos ('5'),
       Character'Pos ('6'), Character'Pos ('7'), Character'Pos ('8'),
       Character'Pos ('9'), Character'Pos ('A'), Character'Pos ('B'),
       Character'Pos ('C'), Character'Pos ('D'), Character'Pos ('E'),
       Character'Pos ('F')]);
   All_Indices : constant U8x16 := From_Lanes
     ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
   Encoded : constant U8x16 := Native.Table_Lookup (Hex_Digits, All_Indices);
   Invalid : constant U8x16 :=
     Native.Table_Lookup (Hex_Digits, Replace (All_Indices, 15, 255));
begin
   Put ("hex: ");
   for Lane in Lane_Index_8x16 loop
      Put (Character'Val (Extract (Encoded, Lane)));
   end loop;
   New_Line;
   Put_Line ("out-of-range lane:" & U8'Image (Extract (Invalid, 15)));
end Table_Lookup;
