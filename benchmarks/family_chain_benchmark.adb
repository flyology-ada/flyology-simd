with Ada.Environment_Variables;
with Ada.Text_IO;
with Flyology_Bench;
with Flyology_Bench.Host_Control;
with Flyology_Bench.Reporters;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Backends.Scalar;
with Flyology_SIMD.Features;
with GNAT.Compiler_Version;
with Interfaces;

--  Chains of dependent lane operations on the families outside the byte
--  family.  Each chain deliberately mixes construction, comparison, selection,
--  lane permutation, width conversion, wide multiplication and reduction,
--  because those are the leaves that no other benchmark reaches.  Every
--  iteration reads data that changes and folds its result into a volatile
--  checksum, so neither the chain nor the loop around it can be discarded.
procedure Family_Chain_Benchmark is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type Interfaces.IEEE_Float_32;

   package Compiler is new GNAT.Compiler_Version;

   type Candidate is (Scalar, Native);
   type Family is (Lanes_U16, Lanes_U32, Lanes_U64, Lanes_F32);
   type Size_List is array (Positive range <>) of Positive;
   Sizes : constant Size_List := [8, 16, 32, 64, 256, 4_096, 262_144];

   Widest    : constant Positive := Sizes (Sizes'Last);
   Data_U16  : U16_Array (0 .. Widest + 8) := [others => 0];
   Data_U32  : U32_Array (0 .. Widest + 4) := [others => 0];
   Data_U64  : U64_Array (0 .. Widest + 2) := [others => 0];
   Data_F32  : F32_Array (0 .. Widest + 4) := [others => 0.0];

   Current_Size   : Positive := Sizes (Sizes'First);
   Current_Family : Family := Lanes_U16;
   Checksum       : Interfaces.Unsigned_64 := 0;
   pragma Volatile (Checksum);

   Map_16 : constant Lane_Map_16x8 :=
     Make_Lane_Map ([1, 0, 3, 2, 5, 4, 7, 6]);
   Two_Map_16 : constant Two_Source_Lane_Map_16x8 :=
     Make_Two_Source_Lane_Map
       ([for Lane in Lane_Index_16x8 =>
           (if Lane mod 2 = 0 then Select_Left_Lane (Lane)
            else Select_Right_Lane (Lane))]);
   Map_32 : constant Lane_Map_32x4 := Make_Lane_Map ([3, 2, 1, 0]);
   Map_64 : constant Lane_Map_64x2 := Make_Lane_Map ([1, 0]);

   --  One chain per family, written once against a generic backend so the
   --  Scalar and Native candidates run identical Ada.
   generic
      with function Splat (Value : U16) return U16x8;
      with function Load_Unaligned
        (Data : U16_Array; Start : Natural) return U16x8;
      with function Greater_Than (Left, Right : U16x8) return Mask_16x8;
      with function Select_Value
        (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8;
      with function Permute_Lanes
        (Value : U16x8; Map : Lane_Map_16x8) return U16x8;
      with function Permute_Lanes
        (Left, Right : U16x8; Map : Two_Source_Lane_Map_16x8) return U16x8;
      with function Min (Left, Right : U16x8) return U16x8;
      with function Reduce_Add_Wrap (Value : U16x8) return U16;
   function Chain_U16 (Limit : Natural) return Interfaces.Unsigned_64;

   function Chain_U16 (Limit : Natural) return Interfaces.Unsigned_64 is
      Total : Interfaces.Unsigned_64 := 0;
      Start : Natural := 0;
   begin
      while Start + 8 <= Limit loop
         declare
            Block   : constant U16x8 := Load_Unaligned (Data_U16, Start);
            Pivot   : constant U16x8 := Splat (U16 (Start mod 251));
            Above   : constant Mask_16x8 := Greater_Than (Block, Pivot);
            Chosen  : constant U16x8 := Select_Value (Above, Block, Pivot);
            Rotated : constant U16x8 := Permute_Lanes (Chosen, Map_16);
            Woven   : constant U16x8 :=
              Permute_Lanes (Chosen, Rotated, Two_Map_16);
            Floored : constant U16x8 := Min (Woven, Rotated);
         begin
            Total := Total + Interfaces.Unsigned_64 (Reduce_Add_Wrap (Floored));
         end;
         Start := Start + 8;
      end loop;
      return Total;
   end Chain_U16;

   generic
      with function Splat (Value : U32) return U32x4;
      with function Load_Unaligned
        (Data : U32_Array; Start : Natural) return U32x4;
      with function Equal (Left, Right : U32x4) return Mask_32x4;
      with function Select_Value
        (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4;
      with function Permute_Lanes
        (Value : U32x4; Map : Lane_Map_32x4) return U32x4;
      with function Max (Left, Right : U32x4) return U32x4;
      with function Narrow_Truncate (Low, High : U32x4) return U16x8;
      with function Reduce_Add_Wrap (Value : U16x8) return U16;
   function Chain_U32 (Limit : Natural) return Interfaces.Unsigned_64;

   function Chain_U32 (Limit : Natural) return Interfaces.Unsigned_64 is
      Total : Interfaces.Unsigned_64 := 0;
      Start : Natural := 0;
   begin
      while Start + 4 <= Limit loop
         declare
            Block   : constant U32x4 := Load_Unaligned (Data_U32, Start);
            Pivot   : constant U32x4 := Splat (U32 (Start mod 65_521));
            Same    : constant Mask_32x4 := Equal (Block, Pivot);
            Chosen  : constant U32x4 := Select_Value (Same, Pivot, Block);
            Rotated : constant U32x4 := Permute_Lanes (Chosen, Map_32);
            Ceiling : constant U32x4 := Max (Chosen, Rotated);
            Packed  : constant U16x8 := Narrow_Truncate (Ceiling, Rotated);
         begin
            Total := Total + Interfaces.Unsigned_64 (Reduce_Add_Wrap (Packed));
         end;
         Start := Start + 4;
      end loop;
      return Total;
   end Chain_U32;

   generic
      with function Splat (Value : U64) return U64x2;
      with function Load_Unaligned
        (Data : U64_Array; Start : Natural) return U64x2;
      with function Multiply_Wrap (Left, Right : U64x2) return U64x2;
      with function Greater_Than (Left, Right : U64x2) return Mask_64x2;
      with function Select_Value
        (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2;
      with function Permute_Lanes
        (Value : U64x2; Map : Lane_Map_64x2) return U64x2;
      with function Reduce_Add_Wrap (Value : U64x2) return U64;
   function Chain_U64 (Limit : Natural) return Interfaces.Unsigned_64;

   function Chain_U64 (Limit : Natural) return Interfaces.Unsigned_64 is
      Total : Interfaces.Unsigned_64 := 0;
      Start : Natural := 0;
   begin
      while Start + 2 <= Limit loop
         declare
            Block   : constant U64x2 := Load_Unaligned (Data_U64, Start);
            Factor  : constant U64x2 := Splat (U64 (Start mod 1_000_003));
            Product : constant U64x2 := Multiply_Wrap (Block, Factor);
            Above   : constant Mask_64x2 := Greater_Than (Product, Block);
            Chosen  : constant U64x2 := Select_Value (Above, Product, Block);
            Swapped : constant U64x2 := Permute_Lanes (Chosen, Map_64);
         begin
            Total := Total + Interfaces.Unsigned_64 (Reduce_Add_Wrap (Swapped));
         end;
         Start := Start + 2;
      end loop;
      return Total;
   end Chain_U64;

   generic
      with function Splat (Value : F32) return F32x4;
      with function Load_Unaligned
        (Data : F32_Array; Start : Natural) return F32x4;
      with function Greater_Than (Left, Right : F32x4) return Mask_32x4;
      with function Select_Value
        (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4;
      with function Permute_Lanes
        (Value : F32x4; Map : Lane_Map_32x4) return F32x4;
      with function Min_Number (Left, Right : F32x4) return F32x4;
      with function Reduce_Add (Value : F32x4) return F32;
   function Chain_F32 (Limit : Natural) return Interfaces.Unsigned_64;

   function Chain_F32 (Limit : Natural) return Interfaces.Unsigned_64 is
      Total : Interfaces.Unsigned_64 := 0;
      Start : Natural := 0;
   begin
      while Start + 4 <= Limit loop
         declare
            Block   : constant F32x4 := Load_Unaligned (Data_F32, Start);
            Pivot   : constant F32x4 := Splat (F32 (Start mod 97));
            Above   : constant Mask_32x4 := Greater_Than (Block, Pivot);
            Chosen  : constant F32x4 := Select_Value (Above, Block, Pivot);
            Rotated : constant F32x4 := Permute_Lanes (Chosen, Map_32);
            Floored : constant F32x4 := Min_Number (Chosen, Rotated);
         begin
            Total := Total
              + Interfaces.Unsigned_64 (F32'Truncation (Reduce_Add (Floored)));
         end;
         Start := Start + 4;
      end loop;
      return Total;
   end Chain_F32;

   function Native_U16 is new Chain_U16
     (Backends.Native.Splat, Backends.Native.Load_Unaligned,
      Backends.Native.Greater_Than, Backends.Native.Select_Value,
      Backends.Native.Permute_Lanes, Backends.Native.Permute_Lanes,
      Backends.Native.Min, Backends.Native.Reduce_Add_Wrap);
   function Scalar_U16 is new Chain_U16
     (Backends.Scalar.Splat, Backends.Scalar.Load_Unaligned,
      Backends.Scalar.Greater_Than, Backends.Scalar.Select_Value,
      Backends.Scalar.Permute_Lanes, Backends.Scalar.Permute_Lanes,
      Backends.Scalar.Min, Backends.Scalar.Reduce_Add_Wrap);
   function Native_U32 is new Chain_U32
     (Backends.Native.Splat, Backends.Native.Load_Unaligned,
      Backends.Native.Equal, Backends.Native.Select_Value,
      Backends.Native.Permute_Lanes, Backends.Native.Max,
      Backends.Native.Narrow_Truncate, Backends.Native.Reduce_Add_Wrap);
   function Scalar_U32 is new Chain_U32
     (Backends.Scalar.Splat, Backends.Scalar.Load_Unaligned,
      Backends.Scalar.Equal, Backends.Scalar.Select_Value,
      Backends.Scalar.Permute_Lanes, Backends.Scalar.Max,
      Backends.Scalar.Narrow_Truncate, Backends.Scalar.Reduce_Add_Wrap);
   function Native_U64 is new Chain_U64
     (Backends.Native.Splat, Backends.Native.Load_Unaligned,
      Backends.Native.Multiply_Wrap, Backends.Native.Greater_Than,
      Backends.Native.Select_Value, Backends.Native.Permute_Lanes,
      Backends.Native.Reduce_Add_Wrap);
   function Scalar_U64 is new Chain_U64
     (Backends.Scalar.Splat, Backends.Scalar.Load_Unaligned,
      Backends.Scalar.Multiply_Wrap, Backends.Scalar.Greater_Than,
      Backends.Scalar.Select_Value, Backends.Scalar.Permute_Lanes,
      Backends.Scalar.Reduce_Add_Wrap);
   function Native_F32 is new Chain_F32
     (Backends.Native.Splat, Backends.Native.Load_Unaligned,
      Backends.Native.Greater_Than, Backends.Native.Select_Value,
      Backends.Native.Permute_Lanes, Backends.Native.Min_Number,
      Backends.Native.Reduce_Add);
   function Scalar_F32 is new Chain_F32
     (Backends.Scalar.Splat, Backends.Scalar.Load_Unaligned,
      Backends.Scalar.Greater_Than, Backends.Scalar.Select_Value,
      Backends.Scalar.Permute_Lanes, Backends.Scalar.Min_Number,
      Backends.Scalar.Reduce_Add);

   function Run_Once (Which : Candidate) return Interfaces.Unsigned_64 is
   begin
      case Current_Family is
         when Lanes_U16 =>
            return (if Which = Native then Native_U16 (Current_Size)
                    else Scalar_U16 (Current_Size));
         when Lanes_U32 =>
            return (if Which = Native then Native_U32 (Current_Size)
                    else Scalar_U32 (Current_Size));
         when Lanes_U64 =>
            return (if Which = Native then Native_U64 (Current_Size)
                    else Scalar_U64 (Current_Size));
         when Lanes_F32 =>
            return (if Which = Native then Native_F32 (Current_Size)
                    else Scalar_F32 (Current_Size));
      end case;
   end Run_Once;

   procedure Batch
     (Which : Candidate; Iterations : Flyology_Bench.Iteration_Count)
   is
      Local : Interfaces.Unsigned_64 := 0;
   begin
      for Iteration in Flyology_Bench.Iteration_Count range 1 .. Iterations loop
         Local := Local + Run_Once (Which);
      end loop;
      Checksum := Checksum + Local
        + Interfaces.Unsigned_64 (Candidate'Pos (Which) + 1)
        + Interfaces.Unsigned_64 (Current_Size);
   end Batch;

   procedure Compare_All is new Flyology_Bench.Compare_Many
     (Case_Id => Candidate, Batch => Batch);
   procedure Put_Console is new
     Flyology_Bench.Reporters.Put_Multi_Comparison_Console (Candidate);
   procedure Put_CSV is new
     Flyology_Bench.Reporters.Put_Multi_Comparison_CSV (Candidate);

   Output_Mode : constant String :=
     Ada.Environment_Variables.Value
       ("FLYOLOGY_BENCH_OUTPUT", Default => "terminal");
   Config : constant Flyology_Bench.Configuration :=
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
        (Enabled                     => False,
         Maximum_Average_CPU_Percent => 20.0,
         Maximum_Core_CPU_Percent    => 50.0,
         Stable_Time                 => 1.0,
         Poll_Interval               => 0.100,
         Timeout                     => 15.0),
      Collect_Process_Telemetry   => False,
      Progress                    => null,
      Progress_Name               => <>);

   procedure Fill_Data is
   begin
      for Index in Data_U16'Range loop
         Data_U16 (Index) := U16 ((Index * 37 + 11) mod 65_536);
      end loop;
      for Index in Data_U32'Range loop
         Data_U32 (Index) := U32 (Index) * 2_654_435_761;
      end loop;
      for Index in Data_U64'Range loop
         Data_U64 (Index) := U64 (Index) * 6_364_136_223_846_793_005;
      end loop;
      for Index in Data_F32'Range loop
         Data_F32 (Index) := F32 (Index mod 1_024) * 0.5;
      end loop;
   end Fill_Data;

   procedure Validate is
      Expected : constant Interfaces.Unsigned_64 := Run_Once (Scalar);
   begin
      if Run_Once (Native) /= Expected then
         raise Program_Error with
           "benchmark validation failed for " & Current_Family'Image &
           Current_Size'Image;
      end if;
   end Validate;
begin
   Fill_Data;
   Put_Line ("flyology_simd family lane-chain statistical benchmark");
   Put_Line
     ("architecture=" & Features.Architecture_Name &
      " best_backend=" & Features.Name (Features.Best_Available));
   Put_Line ("compiler=" & Compiler.Version);
   Put_Line
     ("method=flyology_bench balanced_rounds equal_time warmup=0.25s " &
      "measurement=3s samples=75 seed=0x5EED0123");

   for Which_Family in Family loop
      Current_Family := Which_Family;
      for Size of Sizes loop
         Current_Size := Size;
         Validate;
         declare
            Result : Flyology_Bench.Multi_Comparison;
            Run_Config : constant Flyology_Bench.Configuration :=
              (if Output_Mode = "terminal"
               then Flyology_Bench.Reporters.Terminal_Mode
                 (Config,
                  "family=" & Which_Family'Image & " lanes=" & Size'Image)
               else Config);
         begin
            Compare_All (Config => Run_Config, Result => Result);
            Put_Line
              ("family=" & Which_Family'Image & " input_lanes=" & Size'Image);
            if Output_Mode = "terminal" then
               Put_Console (Result, Show_Individual_Details => True);
            else
               Flyology_Bench.Reporters.Put_Multi_Comparison_CSV_Header;
               Put_CSV (Result);
            end if;
         end;
      end loop;
   end loop;
   Put_Line ("validation_checksum=" & Checksum'Image);
end Family_Chain_Benchmark;
