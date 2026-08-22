with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Wide_Digit_Classifier is
   use Ada.Text_IO;
   use Flyology_SIMD;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;

   function To_Bytes (Value : String) return Byte_Array is
      Result : Byte_Array (0 .. Value'Length - 1);
   begin
      for Offset in 0 .. Value'Length - 1 loop
         Result (Offset) := U8 (Character'Pos (Value (Value'First + Offset)));
      end loop;
      return Result;
   end To_Bytes;

   function To_String (Value : Wide.Lane_Values_U8x32) return String is
      Result : String (1 .. 32);
   begin
      for Lane in Wide.Lane_Index_8x32 loop
         Result (Lane + 1) := Character'Val (Value (Lane));
      end loop;
      return Result;
   end To_String;

   Text          : constant String := "sensor 17: row 204, sample 0091.";
   Data          : constant Byte_Array := To_Bytes (Text);
   Values        : constant Wide.U8x32 := Native.Load_Unaligned (Data, Data'First);
   At_Least_Zero : constant Wide.Mask_8x32 :=
     Native.Greater_Equal (Values, Native.Splat (U8 (Character'Pos ('0'))));
   At_Most_Nine  : constant Wide.Mask_8x32 :=
     Native.Less_Equal (Values, Native.Splat (U8 (Character'Pos ('9'))));
   Is_Digit      : constant Wide.Mask_8x32 := Native.Mask_And (At_Least_Zero, At_Most_Nine);
   Filtered      : constant Wide.U8x32 :=
     Native.Select_Value (Is_Digit, Values, Native.Splat (U8 (Character'Pos ('.'))));
   Lanes         : constant Wide.Lane_Values_U8x32 := Native.To_Lanes (Filtered);
   Filtered_Text : constant String := To_String (Lanes);
   Digit_Count   : constant Wide.Lane_Count_8x32 := Native.Population_Count (Is_Digit);
begin
   pragma Assert (Data'Length = 32);
   pragma Assert (Filtered_Text = ".......17......204.........0091.");
   pragma Assert (Digit_Count = 9);

   Put_Line ("input : " & Text);
   Put_Line ("digits: " & Filtered_Text);
   Put_Line ("count :" & Wide.Lane_Count_8x32'Image (Digit_Count));
end Wide_Digit_Classifier;
