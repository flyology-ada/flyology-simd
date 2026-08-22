with Ada.Environment_Variables;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Flyology_Bench;
with Flyology_Bench.Host_Control;
with Flyology_Bench.Reporters;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Native_Floating;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar_Floating;
with Flyology_SIMD.Features;
with GNAT.Compiler_Version;
with Interfaces;

procedure Dot_Product_Benchmark is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   use type Flyology_SIMD.F64;
   use type Interfaces.Unsigned_64;

   package Compiler is new GNAT.Compiler_Version;

   type Candidate is (Ada_Grouped, Scalar, Native, Runtime);
   type Precision is (Binary32, Binary64);
   type Size_List is array (Positive range <>) of Positive;
   Sizes : constant Size_List := [3, 4, 5, 7, 8, 9, 4_096, 1_048_576];

   type F32_Array_Access is access all F32_Array;
   type F64_Array_Access is access all F64_Array;
   F32_Left          : constant F32_Array_Access := new F32_Array (1 .. Sizes (Sizes'Last));
   F32_Right         : constant F32_Array_Access := new F32_Array (1 .. Sizes (Sizes'Last));
   F64_Left          : constant F64_Array_Access := new F64_Array (1 .. Sizes (Sizes'Last));
   F64_Right         : constant F64_Array_Access := new F64_Array (1 .. Sizes (Sizes'Last));
   Current_Size      : Positive := Sizes (Sizes'First);
   Current_Precision : Precision := Binary32;
   Checksum          : Interfaces.Unsigned_64 := 0;
   pragma Volatile (Checksum);

   function F32_Bits is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);
   function F64_Bits is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);

   function Ordinary_Dot_Product (Left, Right : F32_Array) return F32 is
      Partial : Lane_Values_F32x4 := [others => 0.0];
      Result  : F32 := 0.0;
   begin
      for Index in Left'Range loop
         declare
            Lane : constant Lane_Index_32x4 := Lane_Index_32x4 ((Index - Left'First) mod 4);
         begin
            Partial (Lane) := Partial (Lane) + Left (Index) * Right (Index);
         end;
      end loop;
      for Lane in Partial'Range loop
         Result := Result + Partial (Lane);
      end loop;
      return Result;
   end Ordinary_Dot_Product;

   function Ordinary_Dot_Product (Left, Right : F64_Array) return F64 is
      Partial : Lane_Values_F64x2 := [others => 0.0];
      Result  : F64 := 0.0;
   begin
      for Index in Left'Range loop
         declare
            Lane : constant Lane_Index_64x2 := Lane_Index_64x2 ((Index - Left'First) mod 2);
         begin
            Partial (Lane) := Partial (Lane) + Left (Index) * Right (Index);
         end;
      end loop;
      for Lane in Partial'Range loop
         Result := Result + Partial (Lane);
      end loop;
      return Result;
   end Ordinary_Dot_Product;

   function Dot_Bits (Which : Candidate) return Interfaces.Unsigned_64 is
   begin
      case Current_Precision is
         when Binary32 =>
            declare
               Left  : F32_Array renames F32_Left.all (1 .. Current_Size);
               Right : F32_Array renames F32_Right.all (1 .. Current_Size);
               Value : F32;
            begin
               case Which is
                  when Ada_Grouped =>
                     Value := Ordinary_Dot_Product (Left, Right);

                  when Scalar      =>
                     Value := Algorithms.Scalar_Floating.Dot_Product (Left, Right);

                  when Native      =>
                     Value := Algorithms.Native_Floating.Dot_Product (Left, Right);

                  when Runtime     =>
                     Value := Algorithms.Runtime.Dot_Product (Left, Right);
               end case;
               return Interfaces.Unsigned_64 (F32_Bits (Value));
            end;

         when Binary64 =>
            declare
               Left  : F64_Array renames F64_Left.all (1 .. Current_Size);
               Right : F64_Array renames F64_Right.all (1 .. Current_Size);
               Value : F64;
            begin
               case Which is
                  when Ada_Grouped =>
                     Value := Ordinary_Dot_Product (Left, Right);

                  when Scalar      =>
                     Value := Algorithms.Scalar_Floating.Dot_Product (Left, Right);

                  when Native      =>
                     Value := Algorithms.Native_Floating.Dot_Product (Left, Right);

                  when Runtime     =>
                     Value := Algorithms.Runtime.Dot_Product (Left, Right);
               end case;
               return F64_Bits (Value);
            end;
      end case;
   end Dot_Bits;

   procedure Batch (Which : Candidate; Iterations : Flyology_Bench.Iteration_Count) is
      Local : Interfaces.Unsigned_64 := 0;
   begin
      for Iteration in Flyology_Bench.Iteration_Count range 1 .. Iterations loop
         Local := Local + Dot_Bits (Which);
      end loop;
      Checksum :=
        Checksum
        + Local
        + Interfaces.Unsigned_64 (Candidate'Pos (Which) + 1)
        + Interfaces.Unsigned_64 (Precision'Pos (Current_Precision) + 1)
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
            Put_Line ("placement_cpu=" & CPU'Image & " strength=" & Strength'Image);
         end;
      else
         Put_Line ("placement=uncontrolled (set FLYOLOGY_SIMD_BENCH_CPU)");
      end if;
   end Maybe_Pin;

   procedure Validate is
      Expected : constant Interfaces.Unsigned_64 := Dot_Bits (Ada_Grouped);
   begin
      for Which in Candidate loop
         if Dot_Bits (Which) /= Expected then
            raise Program_Error
              with
                "benchmark validation failed for "
                & Candidate'Image (Which)
                & " "
                & Precision'Image (Current_Precision);
         end if;
      end loop;
   end Validate;
begin
   for Index in F32_Left.all'Range loop
      F32_Left.all (Index) := F32 (Integer (Index mod 31) - 15);
      F32_Right.all (Index) := F32 (Integer ((Index * 7) mod 29) - 14);
      F64_Left.all (Index) := F64 (Integer ((Index * 5) mod 37) - 18);
      F64_Right.all (Index) := F64 (Integer ((Index * 11) mod 41) - 20);
   end loop;

   Put_Line ("flyology_simd dot-product statistical benchmark");
   Put_Line
     ("architecture="
      & Features.Architecture_Name
      & " best_backend="
      & Features.Name (Features.Best_Available));
   Put_Line ("compiler=" & Compiler.Version);
   Put_Line
     ("method=flyology_bench balanced_rounds equal_time warmup=0.25s "
      & "measurement=3s samples=75 seed=0x5EED0123");
   Put_Line ("timer_cost_subtraction=false fast_math=false");
   Maybe_Pin;

   for Selected_Precision in Precision loop
      Current_Precision := Selected_Precision;
      for Size of Sizes loop
         Current_Size := Size;
         Validate;
         declare
            Result            : Flyology_Bench.Multi_Comparison;
            Config            : constant Flyology_Bench.Configuration :=
              (if Output_Mode = "terminal"
               then
                 Flyology_Bench.Reporters.Terminal_Mode
                   (Base_Config, "dot elements=" & Size'Image & " precision=" & Selected_Precision'Image)
               else Base_Config);
            Bytes_Per_Element : constant Positive := (if Selected_Precision = Binary32 then 4 else 8);
            Input_Bytes       : constant Positive := 2 * Size * Bytes_Per_Element;
         begin
            Compare_All (Config => Config, Result => Result);
            Put_Line
              ("input_elements="
               & Size'Image
               & " input_bytes="
               & Input_Bytes'Image
               & " precision="
               & Selected_Precision'Image);
            if Output_Mode = "terminal" then
               Put_Console (Result, Show_Individual_Details => True);
               for Which in Candidate loop
                  declare
                     Position  : constant Flyology_Bench.Comparison_Case_Index :=
                       Flyology_Bench.Comparison_Case_Index (Candidate'Pos (Which) + 1);
                     Median_NS : constant Long_Float :=
                       Flyology_Bench.Median_Nanoseconds (Flyology_Bench.Case_Measurement (Result, Position));
                  begin
                     Put_Line
                       ("throughput backend="
                        & Candidate'Image (Which)
                        & " precision="
                        & Selected_Precision'Image
                        & " median_GB_s="
                        & Long_Float'Image (Long_Float (Input_Bytes) / Median_NS));
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
   end loop;
   Put_Line ("validation_checksum=" & Checksum'Image);
end Dot_Product_Benchmark;
