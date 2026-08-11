with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Features;

procedure Backend_Selection is
   use Ada.Text_IO;

   Data : constant Flyology_SIMD.Byte_Array :=
     [1, 44, 2, 44, 3, 4, 44, 5, 6, 7, 8, 9, 10, 11, 12, 13,
      14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
   Needle : constant Flyology_SIMD.U8 := 44;
   Best : constant Flyology_SIMD.Features.Backend_Kind :=
     Flyology_SIMD.Features.Best_Available;
   Static_Count : constant Natural :=
     Flyology_SIMD.Algorithms.Native.Count (Data, Needle);
   Runtime_Count : constant Natural :=
     Flyology_SIMD.Algorithms.Runtime.Count (Data, Needle);
   Forced_Count : constant Natural :=
     Flyology_SIMD.Algorithms.Runtime.Count (Data, Needle, Backend => Best);
begin
   Put_Line ("best available: " & Flyology_SIMD.Features.Name (Best));
   Put_Line ("static native count:" & Static_Count'Image);
   Put_Line ("runtime count:" & Runtime_Count'Image);
   Put_Line ("forced count:" & Forced_Count'Image);
end Backend_Selection;
