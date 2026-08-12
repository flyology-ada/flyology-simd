with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Cross_Block_Differences is
   use Ada.Text_IO;
   use type Flyology_SIMD.F32;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;
   use type Wide.Lane_Values_F32x8;

   --  Two adjacent blocks hold sixteen consecutive samples.  The reusable
   --  map forms the eight successors of the left block, including the first
   --  lane of the right block.  One subtraction then produces eight first
   --  differences across the block boundary.
   Successor_Map : constant Wide.Two_Source_Lane_Map_32x8 :=
     Wide.Make_Two_Source_Lane_Map
       ([Wide.Select_Left_Lane (1), Wide.Select_Left_Lane (2),
         Wide.Select_Left_Lane (3), Wide.Select_Left_Lane (4),
         Wide.Select_Left_Lane (5), Wide.Select_Left_Lane (6),
         Wide.Select_Left_Lane (7), Wide.Select_Right_Lane (0)]);
   Left : constant Wide.F32x8 :=
     Native.From_Lanes ([1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0]);
   Right : constant Wide.F32x8 :=
     Native.From_Lanes
       ([81.0, 100.0, 121.0, 144.0, 169.0, 196.0, 225.0, 256.0]);
   Successors : constant Wide.F32x8 :=
     Native.Permute_Lanes (Left, Right, Successor_Map);
   Differences : constant Wide.F32x8 := Native.Subtract (Successors, Left);
   Successor_Lanes : constant Wide.Lane_Values_F32x8 :=
     Native.To_Lanes (Successors);
   Result : constant Wide.Lane_Values_F32x8 := Native.To_Lanes (Differences);

   procedure Put_Vector
     (Label_Text : String; Values : Wide.Lane_Values_F32x8)
   is
   begin
      Put_Line (Label_Text);
      for Lane in Wide.Lane_Index_32x8 loop
         if Lane = 0 then
            Put ("  lanes 0..3:");
         elsif Lane = 4 then
            Put ("  lanes 4..7:");
         end if;
         Put (Flyology_SIMD.F32'Image (Values (Lane)));
         if Lane = 3 or else Lane = 7 then
            New_Line;
         else
            Put (",");
         end if;
      end loop;
   end Put_Vector;
begin
   pragma Assert
     (Successor_Lanes = [4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0]);
   pragma Assert (Result = [3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0, 17.0]);
   Put_Vector ("successors:", Successor_Lanes);
   Put_Vector ("differences:", Result);
end Cross_Block_Differences;
