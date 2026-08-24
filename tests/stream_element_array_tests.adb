with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Text_IO;
with Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native;
with Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;

procedure Stream_Element_Array_Tests is
   use Ada.Streams;
   use Ada.Text_IO;

   package Native renames Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native;
   package Scalar renames Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;

   Failures : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Failures := Failures + 1;
         Put_Line ("FAIL: " & Message);
      end if;
   end Check;

   procedure Check_Case
     (Data           : Stream_Element_Array;
      Needles        : Stream_Element_Array;
      Expected_Found : Boolean;
      Expected_Index : Stream_Element_Offset;
      Message        : String)
   is
      Native_Result : constant Native.Search_Result := Native.Find_First_Of (Data, Needles);
      Scalar_Result : constant Scalar.Search_Result := Scalar.Find_First_Of (Data, Needles);
   begin
      Check (Native_Result.Found = Expected_Found, Message & " native found");
      Check (Scalar_Result.Found = Expected_Found, Message & " scalar found");
      if Expected_Found then
         Check (Native_Result.Index = Expected_Index, Message & " native index");
         Check (Scalar_Result.Index = Expected_Index, Message & " scalar index");
      end if;
   end Check_Case;

   Needles       : constant Stream_Element_Array (-3 .. 0) := [9, 10, 13, 32];
   Empty         : constant Stream_Element_Array (1 .. 0) := [others => 0];
   Storage       : Stream_Element_Array (-80 .. 80) := [others => 65];
   Large_Needles : constant Stream_Element_Array (7 .. 11) := [1, 2, 3, 4, 32];
   Duplicates    : constant Stream_Element_Array (4 .. 7) := [9, 9, 9, 9];
   Short_Data    : constant Stream_Element_Array (2 .. 4) := [32, 9, 65];
begin
   Check_Case (Empty, Needles, False, 0, "empty data");
   Check_Case (Short_Data, Empty, False, 0, "empty needles");

   for Length in Stream_Element_Offset range 1 .. 65 loop
      for Padding in Stream_Element_Offset range 0 .. 15 loop
         declare
            First : constant Stream_Element_Offset := Storage'First + Padding;
            Last  : constant Stream_Element_Offset := First + Length - 1;
         begin
            Storage (First .. Last) := [others => 65];
            Check_Case
              (Storage (First .. Last), Needles, False, 0, "no match" & Length'Image & Padding'Image);
            Storage (First) := 9;
            Check_Case
              (Storage (First .. Last), Needles, True, First, "first match" & Length'Image & Padding'Image);
            Storage (First) := 65;
            Storage (Last) := 32;
            Check_Case
              (Storage (First .. Last), Needles, True, Last, "last match" & Length'Image & Padding'Image);
         end;
      end loop;
   end loop;

   Storage (-20 .. -18) := [65, 32, 9];
   Check_Case (Storage (-20 .. -18), Large_Needles, True, -19, "large set scalar fallback");
   Check_Case (Short_Data, Duplicates, True, 3, "duplicate needles");

   if Failures = 0 then
      Put_Line ("stream element array tests passed");
   else
      Put_Line ("stream element array failures:" & Failures'Image);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
exception
   when Error : others =>
      Put_Line ("UNHANDLED: " & Ada.Exceptions.Exception_Information (Error));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Stream_Element_Array_Tests;
