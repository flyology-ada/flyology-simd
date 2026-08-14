--  Complete-array floating algorithms instantiated with the scalar backend.
with Flyology_SIMD.Algorithms.Generic_Floating;
with Flyology_SIMD.Backends.Scalar;

package Flyology_SIMD.Algorithms.Scalar_Floating is new
  Flyology_SIMD.Algorithms.Generic_Floating
    (Backend_F32_Zero         => Flyology_SIMD.Backends.Scalar.Zero,
     Backend_F32_Load_Partial => Flyology_SIMD.Backends.Scalar.Load_Partial,
     Backend_F32_Multiply     => Flyology_SIMD.Backends.Scalar.Multiply,
     Backend_F32_Add          => Flyology_SIMD.Backends.Scalar.Add,
     Backend_F32_Reduce_Add   => Flyology_SIMD.Backends.Scalar.Reduce_Add,
     Backend_F64_Zero         => Flyology_SIMD.Backends.Scalar.Zero,
     Backend_F64_Load_Partial => Flyology_SIMD.Backends.Scalar.Load_Partial,
     Backend_F64_Multiply     => Flyology_SIMD.Backends.Scalar.Multiply,
     Backend_F64_Add          => Flyology_SIMD.Backends.Scalar.Add,
     Backend_F64_Reduce_Add   => Flyology_SIMD.Backends.Scalar.Reduce_Add);
--  Complete-array floating algorithms instantiated with the scalar backend.
