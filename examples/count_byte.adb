with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Features;

procedure Count_Byte is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.U8;
   package Native renames Flyology_SIMD.Backends.Native;

   Text  : constant String := "red,green,blue,amber,white";
   Data  : Byte_Array (Text'Range);
   Comma : constant U8 := U8 (Character'Pos (','));

   function Ordinary_Count (Source : Byte_Array; Needle : U8) return Natural is
      Result : Natural := 0;
   begin
      for Value of Source loop
         if Value = Needle then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Ordinary_Count;

   function Explicit_Count_Commas (Source : Byte_Array) return Natural is
      Start  : Natural := Source'First;
      Result : Natural := 0;
      Wanted : constant U8x16 := Native.Splat (Comma);
   begin
      while Start <= Source'Last loop
         declare
            Remaining : constant Natural := Source'Last - Start + 1;
            Count     : constant Lane_Count_8x16 := Lane_Count_8x16'Min (16, Remaining);
            Values    : constant U8x16 := Native.Load_Partial (Source, Start, Count);
            Matches   : constant Mask_8x16 := Native.Equal (Values, Wanted);
         begin
            Result := Result + Native.Population_Count (Matches);
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
      return Result;
   end Explicit_Count_Commas;

   Ordinary : Natural;
   Explicit : Natural;
   Scalar   : Natural;
   Static   : Natural;
   Runtime  : Natural;
begin
   for Index in Text'Range loop
      Data (Index) := U8 (Character'Pos (Text (Index)));
   end loop;

   Ordinary := Ordinary_Count (Data, Comma);
   Explicit := Explicit_Count_Commas (Data);
   Scalar := Flyology_SIMD.Algorithms.Scalar.Count (Data, Comma);
   Static := Flyology_SIMD.Algorithms.Native.Count (Data, Comma);
   Runtime := Flyology_SIMD.Algorithms.Runtime.Count (Data, Comma);

   Put_Line ("ordinary source loop:" & Ordinary'Image);
   Put_Line ("explicit U8x16 loop:" & Explicit'Image);
   Put_Line ("scalar reference backend:" & Scalar'Image);
   Put_Line ("static native algorithm:" & Static'Image);
   Put_Line ("runtime-dispatched algorithm:" & Runtime'Image);
   Put_Line
     ("best available backend: " & Flyology_SIMD.Features.Name (Flyology_SIMD.Features.Best_Available));
end Count_Byte;
