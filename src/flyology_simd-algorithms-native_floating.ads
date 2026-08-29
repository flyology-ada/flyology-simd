pragma SPARK_Mode (On);

--  Complete-array floating algorithms instantiated with the compiled backend.
with Flyology_SIMD.Algorithms.Generic_Floating;
with Flyology_SIMD.Backends.Native;

package Flyology_SIMD.Algorithms.Native_Floating is new
  Flyology_SIMD.Algorithms.Generic_Floating
    (Backend_F32_Zero              => Flyology_SIMD.Backends.Native.Zero,
     Backend_F32_Load_Partial      => Flyology_SIMD.Backends.Native.Load_Partial,
     Backend_F32_Store_Partial     => Flyology_SIMD.Backends.Native.Store_Partial,
     Backend_F32_Splat             => Flyology_SIMD.Backends.Native.Splat,
     Backend_F32_Multiply          => Flyology_SIMD.Backends.Native.Multiply,
     Backend_F32_Add               => Flyology_SIMD.Backends.Native.Add,
     Backend_F32_Min_Number        => Flyology_SIMD.Backends.Native.Min_Number,
     Backend_F32_Max_Number        => Flyology_SIMD.Backends.Native.Max_Number,
     Backend_F32_Extract           => Flyology_SIMD.Backends.Native.Extract,
     Backend_F32_Reduce_Add        => Flyology_SIMD.Backends.Native.Reduce_Add,
     Backend_F32_Reduce_Min_Number => Flyology_SIMD.Backends.Native.Reduce_Min_Number,
     Backend_F32_Reduce_Max_Number => Flyology_SIMD.Backends.Native.Reduce_Max_Number,
     Backend_F64_Zero              => Flyology_SIMD.Backends.Native.Zero,
     Backend_F64_Load_Partial      => Flyology_SIMD.Backends.Native.Load_Partial,
     Backend_F64_Store_Partial     => Flyology_SIMD.Backends.Native.Store_Partial,
     Backend_F64_Splat             => Flyology_SIMD.Backends.Native.Splat,
     Backend_F64_Multiply          => Flyology_SIMD.Backends.Native.Multiply,
     Backend_F64_Add               => Flyology_SIMD.Backends.Native.Add,
     Backend_F64_Min_Number        => Flyology_SIMD.Backends.Native.Min_Number,
     Backend_F64_Max_Number        => Flyology_SIMD.Backends.Native.Max_Number,
     Backend_F64_Extract           => Flyology_SIMD.Backends.Native.Extract,
     Backend_F64_Reduce_Add        => Flyology_SIMD.Backends.Native.Reduce_Add,
     Backend_F64_Reduce_Min_Number => Flyology_SIMD.Backends.Native.Reduce_Min_Number,
     Backend_F64_Reduce_Max_Number => Flyology_SIMD.Backends.Native.Reduce_Max_Number);
