with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Cross_Block_Differences is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   package Native renames Flyology_SIMD.Backends.Native;

   --  Two adjacent blocks hold eight consecutive samples.  The reusable map
   --  forms the four successors of the left block, including the first lane
   --  of the right block.  One subtraction then produces four differences
   --  across the block boundary.
   Successor_Map : constant Two_Source_Lane_Map_32x4 :=
     Make_Two_Source_Lane_Map
       ([Select_Left_Lane (1), Select_Left_Lane (2),
         Select_Left_Lane (3), Select_Right_Lane (0)]);
   Left : constant F32x4 := Native.From_Lanes ([1.0, 4.0, 9.0, 16.0]);
   Right : constant F32x4 := Native.From_Lanes ([25.0, 36.0, 49.0, 64.0]);
   Successors : constant F32x4 :=
     Native.Permute_Lanes (Left, Right, Successor_Map);
   Differences : constant F32x4 := Native.Subtract (Successors, Left);
   Successor_Lanes : constant Lane_Values_F32x4 :=
     Native.To_Lanes (Successors);
   Result : constant Lane_Values_F32x4 := Native.To_Lanes (Differences);
begin
   pragma Assert (Successor_Lanes = [4.0, 9.0, 16.0, 25.0]);
   pragma Assert (Result = [3.0, 5.0, 7.0, 9.0]);
   Put ("successors :");
   for Value of Successor_Lanes loop
      Put (F32'Image (Value));
   end loop;
   New_Line;
   Put ("differences:");
   for Value of Result loop
      Put (F32'Image (Value));
   end loop;
   New_Line;
end Cross_Block_Differences;
