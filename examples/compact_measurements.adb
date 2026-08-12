with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Compact_Measurements is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   package Native renames Flyology_SIMD.Backends.Native;

   --  Keep positive measurements in their original order.  Compress packs
   --  the selected values into a low-lane prefix.  Expand places that prefix
   --  back into the mask's true positions and fills other positions with zero.
   Samples : constant F32x4 :=
     Native.From_Lanes ([-2.5, 3.0, -1.0, 4.5]);
   Keep : constant Mask_32x4 :=
     Native.Greater_Than (Samples, Native.Zero);
   Packed : constant F32x4 := Native.Compress (Samples, Keep);
   Expanded : constant F32x4 := Native.Expand (Packed, Keep);
   Kept_Count : constant Lane_Count_32x4 := Native.Population_Count (Keep);
   Packed_Lanes : constant Lane_Values_F32x4 := Native.To_Lanes (Packed);
   Expanded_Lanes : constant Lane_Values_F32x4 := Native.To_Lanes (Expanded);
begin
   pragma Assert (Packed_Lanes = [3.0, 4.5, 0.0, 0.0]);
   pragma Assert (Expanded_Lanes = [0.0, 3.0, 0.0, 4.5]);
   pragma Assert (Kept_Count = 2);

   Put ("packed  :");
   for Value of Packed_Lanes loop
      Put (F32'Image (Value));
   end loop;
   New_Line;

   Put ("expanded:");
   for Value of Expanded_Lanes loop
      Put (F32'Image (Value));
   end loop;
   New_Line;
end Compact_Measurements;
