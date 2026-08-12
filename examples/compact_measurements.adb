with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Compact_Measurements is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   use type Flyology_SIMD.Wide.Lane_Values_F32x8;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;

   --  The mask selects positive measurements.  Compress preserves their order
   --  and packs them into a prefix that starts at lane zero.  Expand restores
   --  those values to the true mask positions and fills all other lanes with
   --  positive zero.
   Sample_Lanes : constant Wide.Lane_Values_F32x8 :=
     [-2.5, 3.0, -1.0, 4.5, 6.25, -7.0, 8.5, 9.75];
   Samples : constant Wide.F32x8 := Native.From_Lanes (Sample_Lanes);
   Keep : constant Wide.Mask_32x8 :=
     Native.Greater_Than (Samples, Native.Zero);
   Packed : constant Wide.F32x8 := Native.Compress (Samples, Keep);
   Expanded : constant Wide.F32x8 := Native.Expand (Packed, Keep);
   Kept_Count : constant Wide.Lane_Count_32x8 :=
     Native.Population_Count (Keep);
   Packed_Lanes : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Packed);
   Expanded_Lanes : constant Wide.Lane_Values_F32x8 :=
     Native.To_Lanes (Expanded);
begin
   pragma Assert
     (Packed_Lanes = [3.0, 4.5, 6.25, 8.5, 9.75, 0.0, 0.0, 0.0]);
   pragma Assert
     (Expanded_Lanes = [0.0, 3.0, 0.0, 4.5, 6.25, 0.0, 8.5, 9.75]);
   pragma Assert (Kept_Count = 5);

   Put ("input   :");
   for Lane in Wide.Lane_Index_32x8 loop
      Put (F32'Image (Sample_Lanes (Lane)));
      if Lane < Wide.Lane_Index_32x8'Last then
         Put (", ");
      end if;
   end loop;
   New_Line;

   Put ("mask    :");
   for Lane in Wide.Lane_Index_32x8 loop
      Put (Boolean'Image (Native.Test (Keep, Lane)));
      if Lane < Wide.Lane_Index_32x8'Last then
         Put (" ");
      end if;
   end loop;
   New_Line;

   Put_Line ("count   :" & Kept_Count'Image);

   Put ("packed  :");
   for Lane in Wide.Lane_Index_32x8 loop
      declare
         Value : constant F32 := Packed_Lanes (Lane);
      begin
         Put (F32'Image (Value));
         if Lane < Wide.Lane_Index_32x8'Last then
            Put (", ");
         end if;
      end;
   end loop;
   New_Line;

   Put ("expanded:");
   for Lane in Wide.Lane_Index_32x8 loop
      Put (F32'Image (Expanded_Lanes (Lane)));
      if Lane < Wide.Lane_Index_32x8'Last then
         Put (", ");
      end if;
   end loop;
   New_Line;
end Compact_Measurements;
