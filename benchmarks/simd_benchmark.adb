with Ada.Environment_Variables;
with Ada.Text_IO;
with Flyology_Bench;
with Flyology_Bench.Host_Control;
with Flyology_Bench.Reporters;
with GNAT.Compiler_Version;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Features;

procedure SIMD_Benchmark is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_64;

   package Compiler is new GNAT.Compiler_Version;

   type Candidate is (Ada_Loop, Scalar, Native, Runtime);
   type Size_List is array (Positive range <>) of Positive;
   Sizes : constant Size_List := [7, 15, 16, 17, 4_096, 1_048_576];

   Data         : Byte_Array (1 .. Sizes (Sizes'Last));
   Current_Size : Positive := Sizes (Sizes'First);
   Checksum     : Interfaces.Unsigned_64 := 0;
   pragma Volatile (Checksum);

   function Ordinary_Count (Buffer : Byte_Array; Needle : U8) return Natural is
      Result : Natural := 0;
   begin
      for Index in Buffer'Range loop
         if Buffer (Index) = Needle then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Ordinary_Count;

   function Count_Once (Which : Candidate) return Natural is
   begin
      case Which is
         when Ada_Loop =>
            return Ordinary_Count (Data (1 .. Current_Size), 42);

         when Scalar   =>
            return Algorithms.Scalar.Count (Data (1 .. Current_Size), 42);

         when Native   =>
            return Algorithms.Native.Count (Data (1 .. Current_Size), 42);

         when Runtime  =>
            return Algorithms.Runtime.Count (Data (1 .. Current_Size), 42);
      end case;
   end Count_Once;

   procedure Batch (Which : Candidate; Iterations : Flyology_Bench.Iteration_Count) is
      Local : Interfaces.Unsigned_64 := 0;
   begin
      for Iteration in Flyology_Bench.Iteration_Count range 1 .. Iterations loop
         Local := Local + Interfaces.Unsigned_64 (Count_Once (Which));
      end loop;
      --  One observable write per calibrated batch keeps every complete buffer
      --  operation live without charging an out-of-line barrier per operation.
      Checksum :=
        Checksum
        + Local
        + Interfaces.Unsigned_64 (Candidate'Pos (Which) + 1)
        + Interfaces.Unsigned_64 (Current_Size);
   end Batch;

   procedure Compare_All is new Flyology_Bench.Compare_Many (Case_Id => Candidate, Batch => Batch);
   procedure Put_Console is new Flyology_Bench.Reporters.Put_Multi_Comparison_Console (Candidate);
   procedure Put_JSON is new Flyology_Bench.Reporters.Put_Multi_Comparison_JSON (Candidate);
   procedure Put_CSV is new Flyology_Bench.Reporters.Put_Multi_Comparison_CSV (Candidate);

   Output_Mode : constant String :=
     Ada.Environment_Variables.Value ("FLYOLOGY_BENCH_OUTPUT", Default => "terminal");
   Quiet_CPU   : constant Boolean :=
     Ada.Environment_Variables.Value ("FLYOLOGY_BENCH_QUIESCENCE", Default => "0") = "1";
   Base_Config : constant Flyology_Bench.Configuration :=
     (Warmup_Time                 => 0.250,
      Measurement_Time            => 3.000,
      Maximum_Sampling_Time       => 4.000,
      Samples                     => 75,
      Minimum_Sample_Time         => 0.001,
      Maximum_Iterations          => Flyology_Bench.Iteration_Count'Last,
      Comparison_Batching         => Flyology_Bench.Equal_Time,
      Shootout_Scheduling         => Flyology_Bench.Balanced_Rounds,
      Subtract_Timer_Cost         => False,
      Practical_Threshold_Percent => 1.0,
      Random_Seed                 => 16#5EED_0123#,
      Metrics                     => Flyology_Bench.Time_Metrics,
      Scheduler_Probe             => null,
      CPU_Quiescence              =>
        (Enabled                     => Quiet_CPU,
         Maximum_Average_CPU_Percent => 20.0,
         Maximum_Core_CPU_Percent    => 50.0,
         Stable_Time                 => 1.0,
         Poll_Interval               => 0.100,
         Timeout                     => 15.0),
      Collect_Process_Telemetry   => False,
      Progress                    => null,
      Progress_Name               => <>);

   procedure Maybe_Pin is
   begin
      if Ada.Environment_Variables.Exists ("FLYOLOGY_SIMD_BENCH_CPU") then
         declare
            CPU      : constant Natural :=
              Natural'Value (Ada.Environment_Variables.Value ("FLYOLOGY_SIMD_BENCH_CPU"));
            Strength : constant Flyology_Bench.Host_Control.Placement_Strength :=
              Flyology_Bench.Host_Control.Pin_Current_Thread (CPU);
         begin
            Put_Line
              ("placement_cpu="
               & CPU'Image
               & " strength="
               & Flyology_Bench.Host_Control.Placement_Strength'Image (Strength));
         end;
      else
         Put_Line ("placement=uncontrolled (set FLYOLOGY_SIMD_BENCH_CPU)");
      end if;
   end Maybe_Pin;

   procedure Validate is
      Expected : constant Natural := Ordinary_Count (Data (1 .. Current_Size), 42);
   begin
      for Which in Candidate loop
         if Count_Once (Which) /= Expected then
            raise Program_Error with "benchmark validation failed for " & Candidate'Image (Which);
         end if;
      end loop;
   end Validate;
begin
   for Index in Data'Range loop
      Data (Index) := U8 ((Index * 37 + 11) mod 251);
   end loop;

   Put_Line ("flyology_simd statistical benchmark");
   Put_Line
     ("architecture="
      & Features.Architecture_Name
      & " best_backend="
      & Features.Name (Features.Best_Available));
   Put_Line ("compiler=" & Compiler.Version);
   Put_Line
     ("project_switches=library:-gnat2022,-gnata,-gnatwa,-fstack-check,"
      & "-fno-strict-aliasing,-O2,-ftree-vectorize,-gnatn2;"
      & "benchmark:-gnat2022,-gnata,-O3,-ftree-vectorize");
   Put_Line
     ("method=flyology_bench balanced_rounds equal_time warmup=0.25s "
      & "measurement=3s samples=75 seed=0x5EED0123");
   Put_Line ("timer_cost_subtraction=false fast_math=false " & "quiescence=" & Boolean'Image (Quiet_CPU));
   Maybe_Pin;

   for Size of Sizes loop
      declare
         Result : Flyology_Bench.Multi_Comparison;
         Config : constant Flyology_Bench.Configuration :=
           (if Output_Mode = "terminal"
            then Flyology_Bench.Reporters.Terminal_Mode (Base_Config, "count bytes=" & Size'Image)
            else Base_Config);
      begin
         Current_Size := Size;
         Validate;
         Compare_All (Config => Config, Result => Result);

         Put_Line ("input_bytes=" & Size'Image);
         if Output_Mode = "terminal" then
            Put_Console (Result, Show_Individual_Details => True);
            for Which in Candidate loop
               declare
                  Index     : constant Flyology_Bench.Comparison_Case_Index :=
                    Flyology_Bench.Comparison_Case_Index (Candidate'Pos (Which) + 1);
                  Median_NS : constant Long_Float :=
                    Flyology_Bench.Median_Nanoseconds (Flyology_Bench.Case_Measurement (Result, Index));
               begin
                  Put_Line
                    ("throughput backend="
                     & Candidate'Image (Which)
                     & " bytes="
                     & Size'Image
                     & " median_GB_s="
                     & Long_Float'Image (Long_Float (Size) / Median_NS));
               end;
            end loop;
         elsif Output_Mode = "json" then
            Put_JSON (Result);
         elsif Output_Mode = "csv" then
            Flyology_Bench.Reporters.Put_Multi_Comparison_CSV_Header;
            Put_CSV (Result);
         else
            raise Constraint_Error with "FLYOLOGY_BENCH_OUTPUT must be terminal, json, or csv";
         end if;
      end;
   end loop;
   Put_Line ("validation_checksum=" & Checksum'Image);
end SIMD_Benchmark;
