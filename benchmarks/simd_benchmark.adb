with Ada.Real_Time;
with Ada.Text_IO;
with GNAT.Compiler_Version;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Features;

procedure SIMD_Benchmark is
   use Ada.Real_Time;
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_8;

   package Compiler is new GNAT.Compiler_Version;

   type Backend is (Ada_Loop, Scalar, Native, Runtime);
   type Size_List is array (Positive range <>) of Positive;
   Sizes : constant Size_List := [7, 15, 16, 17, 4_096, 1_048_576];
   Checksum : Natural := 0;

   function Ordinary_Count (Data : Byte_Array; Needle : U8) return Natural is
      Result : Natural := 0;
   begin
      for Index in Data'Range loop
         if Data (Index) = Needle then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Ordinary_Count;

   function Run_Once
     (Which : Backend; Data : Byte_Array; Needle : U8) return Natural is
     (case Which is
         when Ada_Loop => Ordinary_Count (Data, Needle),
         when Scalar => Algorithms.Scalar.Count (Data, Needle),
         when Native => Algorithms.Native.Count (Data, Needle),
         when Runtime => Algorithms.Runtime.Count (Data, Needle));

   procedure Measure (Which : Backend; Data : Byte_Array; Iterations : Positive) is
      Warmup_Trials : constant := 2;
      Trials : constant := 5;
      Best : Duration := Duration'Last;
      Expected : constant Natural := Algorithms.Scalar.Count (Data, 42);
   begin
      for Warmup in 1 .. Warmup_Trials loop
         Checksum := Checksum + Run_Once (Which, Data, 42) + Warmup - Warmup;
      end loop;
      for Trial in 1 .. Trials loop
         declare
            Started : constant Time := Clock;
            Local : Natural := 0;
         begin
            for Iteration in 1 .. Iterations loop
               Local := Local + Run_Once (Which, Data, 42);
            end loop;
            declare
               Elapsed : constant Duration := To_Duration (Clock - Started);
            begin
               Best := Duration'Min (Best, Elapsed);
               Checksum := Checksum + Local + Trial - Trial;
               if Local /= Expected * Iterations then
                  raise Program_Error with "benchmark validation failed";
               end if;
            end;
         end;
      end loop;
      Put_Line
        ("backend=" & Which'Image &
         " size=" & Data'Length'Image &
         " iterations=" & Iterations'Image &
         " best_seconds=" & Best'Image &
         " throughput_GB_s=" &
           Long_Float'Image
             (Long_Float (Data'Length) * Long_Float (Iterations) /
              Long_Float (Best) / 1_000_000_000.0));
   end Measure;
begin
   Put_Line ("flyology_simd benchmark (generated results are not versioned)");
   Put_Line ("architecture=" & Features.Architecture_Name &
             " best_backend=" & Features.Name (Features.Best_Available));
   Put_Line ("compiler=" & Compiler.Version);
   Put_Line ("switches=-O3 -ftree-vectorize -gnat2022 -gnata; no fast-math");
   Put_Line ("trials=5 warmup=2; reported time is best repeated trial");
   for Size of Sizes loop
      declare
         Data : Byte_Array (1 .. Size);
         Iterations : constant Positive :=
           Positive'Max (1, 32_000_000 / Size);
      begin
         for Index in Data'Range loop
            Data (Index) := U8 ((Index * 37 + 11) mod 251);
         end loop;
         for Which in Backend loop
            Measure (Which, Data, Iterations);
         end loop;
      end;
   end loop;
   Put_Line ("validation_checksum=" & Checksum'Image);
end SIMD_Benchmark;
