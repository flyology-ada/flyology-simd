with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Wide_Table_Lookup is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;

   Base32_Alphabet : constant Wide.U8x32 :=
     Wide.From_Lanes
       ([Character'Pos ('A'),
         Character'Pos ('B'),
         Character'Pos ('C'),
         Character'Pos ('D'),
         Character'Pos ('E'),
         Character'Pos ('F'),
         Character'Pos ('G'),
         Character'Pos ('H'),
         Character'Pos ('I'),
         Character'Pos ('J'),
         Character'Pos ('K'),
         Character'Pos ('L'),
         Character'Pos ('M'),
         Character'Pos ('N'),
         Character'Pos ('O'),
         Character'Pos ('P'),
         Character'Pos ('Q'),
         Character'Pos ('R'),
         Character'Pos ('S'),
         Character'Pos ('T'),
         Character'Pos ('U'),
         Character'Pos ('V'),
         Character'Pos ('W'),
         Character'Pos ('X'),
         Character'Pos ('Y'),
         Character'Pos ('Z'),
         Character'Pos ('2'),
         Character'Pos ('3'),
         Character'Pos ('4'),
         Character'Pos ('5'),
         Character'Pos ('6'),
         Character'Pos ('7')]);
   Digit_Values    : constant Wide.U8x32 :=
     Wide.From_Lanes
       ([5,
         11,
         24,
         14,
         11,
         14,
         6,
         24,
         18,
         8,
         12,
         3,
         0,
         1,
         2,
         3,
         4,
         5,
         6,
         7,
         8,
         9,
         10,
         11,
         12,
         13,
         14,
         15,
         16,
         17,
         18,
         19]);
   Encoded         : constant Wide.U8x32 := Native.Table_Lookup (Base32_Alphabet, Digit_Values);
   Invalid         : constant Wide.U8x32 :=
     Native.Table_Lookup (Base32_Alphabet, Wide.Replace (Digit_Values, 31, 32));
begin
   Put ("Base32 digits: ");
   for Lane in Wide.Lane_Index_8x32 loop
      Put (Character'Val (Wide.Extract (Encoded, Lane)));
   end loop;
   New_Line;
   Put_Line ("out-of-range lane:" & U8'Image (Wide.Extract (Invalid, 31)));
end Wide_Table_Lookup;
