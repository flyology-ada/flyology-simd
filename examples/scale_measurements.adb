with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Backends.Native;

procedure Scale_Measurements is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   package Native renames Flyology_SIMD.Backends.Native;

   Samples : F32_Array (1 .. 7) := [-2.0, 0.5, 10.0, 25.0, 40.0, 60.0, 80.0];
   Start   : Natural := Samples'First;
begin
   Flyology_SIMD.Algorithms.Runtime.Scale (Samples, 1.5);
   while Start <= Samples'Last loop
      declare
         Remaining   : constant Natural := Samples'Last - Start + 1;
         Count       : constant Lane_Count_32x4 := Lane_Count_32x4'Min (4, Remaining);
         Value       : constant F32x4 := Native.Load_Partial (Samples, Start, Count);
         Nonnegative : constant F32x4 := Native.Max_Number (Value, Native.Splat (0.0));
         Clamped     : constant F32x4 := Native.Min_Number (Nonnegative, Native.Splat (100.0));
      begin
         Native.Store_Partial (Samples, Start, Count, Clamped);
         Start := Start + Count;
      end;
   end loop;

   for Index in Samples'Range loop
      Put_Line ("sample" & Index'Image & ":" & F32'Image (Samples (Index)));
   end loop;
end Scale_Measurements;
