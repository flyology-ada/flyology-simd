with Ada.Environment_Variables;
with Ada.Streams;
with Ada.Text_IO;
with Flyology_Bench;
with Flyology_Bench.Host_Control;
with Flyology_Bench.Reporters;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native;
with Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;
with Flyology_SIMD.Features;
with GNAT.Compiler_Version;
with Interfaces;

procedure Class_Scan_Benchmark is
   use Ada.Text_IO;
   use type Ada.Streams.Stream_Element_Offset;
   use Flyology_SIMD;
   use type Flyology_SIMD.Algorithms.Search_Result;
   use type Interfaces.Unsigned_64;

   package Compiler is new GNAT.Compiler_Version;

   package Stream_Native renames Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native;
   package Stream_Scalar renames Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;

   type Candidate is (Ada_Class_Table, Byte_Scalar, Byte_Native, Byte_Runtime, SEA_Scalar, SEA_Native);
   type Scenario is (No_Match, Last_Match);
   type Size_List is array (Positive range <>) of Positive;
   Sizes       : constant Size_List :=
     [7, 15, 16, 17, 24, 31, 32, 33, 48, 64, 96, 127, 128, 129, 256, 4_096, 1_048_576];
   Needles     : constant Byte_Array := [9, 10, 13, 32];
   SEA_Needles : constant Ada.Streams.Stream_Element_Array (-3 .. 0) := [9, 10, 13, 32];

   type Class_Table is array (U8) of Boolean;
   function SEA_Index (Value : Natural) return Ada.Streams.Stream_Element_Offset
   is (Ada.Streams.Stream_Element_Offset (Value));
   pragma Inline_Always (SEA_Index);

   Class            : Class_Table := [others => False];
   Data             : Byte_Array (1 .. Sizes (Sizes'Last)) := [others => 65];
   SEA_Data         : Ada.Streams.Stream_Element_Array (SEA_Index (1) .. SEA_Index (Sizes (Sizes'Last))) :=
     [others => 65];
   Current_Size     : Positive := Sizes (Sizes'First);
   Current_Scenario : Scenario := No_Match;
   Checksum         : Interfaces.Unsigned_64 := 0;
   pragma Volatile (Checksum);

   function Ordinary_Find return Algorithms.Search_Result is
   begin
      for Index in Data'First .. Current_Size loop
         if Class (Data (Index)) then
            return (Found => True, Index => Index);
         end if;
      end loop;
      return (Found => False, Index => 0);
   end Ordinary_Find;

   function Scan_Once (Which : Candidate) return Algorithms.Search_Result is
   begin
      case Which is
         when Ada_Class_Table =>
            return Ordinary_Find;

         when Byte_Scalar     =>
            return Algorithms.Scalar.Find_First_Of (Data (1 .. Current_Size), Needles);

         when Byte_Native     =>
            return Algorithms.Native.Find_First_Of (Data (1 .. Current_Size), Needles);

         when Byte_Runtime    =>
            return Algorithms.Runtime.Find_First_Of (Data (1 .. Current_Size), Needles);

         when SEA_Scalar      =>
            declare
               Result : constant Stream_Scalar.Search_Result :=
                 Stream_Scalar.Find_First_Of
                   (SEA_Data (SEA_Index (1) .. SEA_Index (Current_Size)), SEA_Needles);
            begin
               return
                 (if Result.Found
                  then (Found => True, Index => Natural (Result.Index))
                  else (Found => False, Index => 0));
            end;

         when SEA_Native      =>
            declare
               Result : constant Stream_Native.Search_Result :=
                 Stream_Native.Find_First_Of
                   (SEA_Data (SEA_Index (1) .. SEA_Index (Current_Size)), SEA_Needles);
            begin
               return
                 (if Result.Found
                  then (Found => True, Index => Natural (Result.Index))
                  else (Found => False, Index => 0));
            end;
      end case;
   end Scan_Once;

   procedure Batch (Which : Candidate; Iterations : Flyology_Bench.Iteration_Count) is
      Local : Interfaces.Unsigned_64 := 0;
   begin
      for Iteration in Flyology_Bench.Iteration_Count range 1 .. Iterations loop
         declare
            Result : constant Algorithms.Search_Result := Scan_Once (Which);
         begin
            Local := Local + Interfaces.Unsigned_64 (Result.Index);
            if Result.Found then
               Local := Local + 1;
            end if;
         end;
      end loop;
      Checksum :=
        Checksum
        + Local
        + Interfaces.Unsigned_64 (Candidate'Pos (Which) + 1)
        + Interfaces.Unsigned_64 (Current_Size)
        + Interfaces.Unsigned_64 (Scenario'Pos (Current_Scenario));
   end Batch;

   procedure Compare_All is new Flyology_Bench.Compare_Many (Case_Id => Candidate, Batch => Batch);
   procedure Put_Console is new Flyology_Bench.Reporters.Put_Multi_Comparison_Console (Candidate);
   procedure Put_JSON is new Flyology_Bench.Reporters.Put_Multi_Comparison_JSON (Candidate);
   procedure Put_CSV is new Flyology_Bench.Reporters.Put_Multi_Comparison_CSV (Candidate);

   Output_Mode : constant String :=
     Ada.Environment_Variables.Value ("FLYOLOGY_BENCH_OUTPUT", Default => "terminal");
   Quiet_CPU   : constant Boolean :=
     Ada.Environment_Variables.Value ("FLYOLOGY_BENCH_QUIESCENCE", Default => "0") = "1";
   Config      : constant Flyology_Bench.Configuration :=
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

   procedure Set_Data is
   begin
      Data (1 .. Current_Size) := [others => 65];
      SEA_Data (SEA_Index (1) .. SEA_Index (Current_Size)) := [others => 65];
      if Current_Scenario = Last_Match then
         Data (Current_Size) := Needles (Needles'Last);
         SEA_Data (SEA_Index (Current_Size)) := SEA_Needles (SEA_Needles'Last);
      end if;
   end Set_Data;

   procedure Validate is
      Expected : constant Algorithms.Search_Result := Ordinary_Find;
   begin
      for Which in Candidate loop
         if Scan_Once (Which) /= Expected then
            raise Program_Error with "benchmark validation failed for " & Candidate'Image (Which);
         end if;
      end loop;
   end Validate;

   procedure Maybe_Pin is
   begin
      if Ada.Environment_Variables.Exists ("FLYOLOGY_SIMD_BENCH_CPU") then
         declare
            CPU      : constant Natural :=
              Natural'Value (Ada.Environment_Variables.Value ("FLYOLOGY_SIMD_BENCH_CPU"));
            Strength : constant Flyology_Bench.Host_Control.Placement_Strength :=
              Flyology_Bench.Host_Control.Pin_Current_Thread (CPU);
         begin
            Put_Line ("placement_cpu=" & CPU'Image & " strength=" & Strength'Image);
         end;
      else
         Put_Line ("placement=uncontrolled (set FLYOLOGY_SIMD_BENCH_CPU)");
      end if;
   end Maybe_Pin;
begin
   for Needle of Needles loop
      Class (Needle) := True;
   end loop;

   Put_Line ("flyology_simd small-set scan statistical benchmark");
   Put_Line
     ("architecture="
      & Features.Architecture_Name
      & " best_backend="
      & Features.Name (Features.Best_Available));
   Put_Line ("compiler=" & Compiler.Version);
   Put_Line
     ("method=flyology_bench balanced_rounds equal_time warmup=0.25s "
      & "measurement=3s samples=75 seed=0x5EED0123");
   Put_Line ("set_size=" & Needles'Length'Image);
   Maybe_Pin;

   for Which_Scenario in Scenario loop
      Current_Scenario := Which_Scenario;
      for Size of Sizes loop
         Current_Size := Size;
         Set_Data;
         Validate;
         declare
            Result     : Flyology_Bench.Multi_Comparison;
            Run_Config : constant Flyology_Bench.Configuration :=
              (if Output_Mode = "terminal"
               then
                 Flyology_Bench.Reporters.Terminal_Mode
                   (Config, "find first of bytes=" & Size'Image & " scenario=" & Which_Scenario'Image)
               else Config);
         begin
            Compare_All (Config => Run_Config, Result => Result);
            Put_Line ("input_bytes=" & Size'Image & " scenario=" & Which_Scenario'Image);
            if Output_Mode = "terminal" then
               Put_Console (Result, Show_Individual_Details => True);
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
   end loop;
   Put_Line ("validation_checksum=" & Checksum'Image);
end Class_Scan_Benchmark;
