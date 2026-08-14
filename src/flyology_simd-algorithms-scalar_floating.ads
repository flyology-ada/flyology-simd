--  Complete-array floating algorithms instantiated with the scalar backend.
with Flyology_SIMD.Algorithms.Generic_Floating;
with Flyology_SIMD.Backends.Scalar;

package Flyology_SIMD.Algorithms.Scalar_Floating is new
  Flyology_SIMD.Algorithms.Generic_Floating
    (Backend_F32_Zero          => Flyology_SIMD.Backends.Scalar.Zero,
     Backend_F32_Load_Partial  => Flyology_SIMD.Backends.Scalar.Load_Partial,
     Backend_F32_Store_Partial => Flyology_SIMD.Backends.Scalar.Store_Partial,
     Backend_F32_Splat         => Flyology_SIMD.Backends.Scalar.Splat,
     Backend_F32_Multiply      => Flyology_SIMD.Backends.Scalar.Multiply,
     Backend_F32_Add           => Flyology_SIMD.Backends.Scalar.Add,
     Backend_F32_Min_Number    => Flyology_SIMD.Backends.Scalar.Min_Number,
     Backend_F32_Max_Number    => Flyology_SIMD.Backends.Scalar.Max_Number,
     Backend_F32_Extract       => Flyology_SIMD.Backends.Scalar.Extract,
     Backend_F32_Reduce_Add    => Flyology_SIMD.Backends.Scalar.Reduce_Add,
     Backend_F32_Reduce_Min_Number =>
       Flyology_SIMD.Backends.Scalar.Reduce_Min_Number,
     Backend_F32_Reduce_Max_Number =>
       Flyology_SIMD.Backends.Scalar.Reduce_Max_Number,
     Backend_F64_Zero          => Flyology_SIMD.Backends.Scalar.Zero,
     Backend_F64_Load_Partial  => Flyology_SIMD.Backends.Scalar.Load_Partial,
     Backend_F64_Store_Partial => Flyology_SIMD.Backends.Scalar.Store_Partial,
     Backend_F64_Splat         => Flyology_SIMD.Backends.Scalar.Splat,
     Backend_F64_Multiply      => Flyology_SIMD.Backends.Scalar.Multiply,
     Backend_F64_Add           => Flyology_SIMD.Backends.Scalar.Add,
     Backend_F64_Min_Number    => Flyology_SIMD.Backends.Scalar.Min_Number,
     Backend_F64_Max_Number    => Flyology_SIMD.Backends.Scalar.Max_Number,
     Backend_F64_Extract       => Flyology_SIMD.Backends.Scalar.Extract,
     Backend_F64_Reduce_Add    => Flyology_SIMD.Backends.Scalar.Reduce_Add,
     Backend_F64_Reduce_Min_Number =>
       Flyology_SIMD.Backends.Scalar.Reduce_Min_Number,
     Backend_F64_Reduce_Max_Number =>
       Flyology_SIMD.Backends.Scalar.Reduce_Max_Number);
--  Complete-array floating algorithms instantiated with the scalar backend.
