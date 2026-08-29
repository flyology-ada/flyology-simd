pragma SPARK_Mode (On);

--  Complete-buffer byte algorithms instantiated with the scalar backend.
with Flyology_SIMD.Algorithms.Generic_Bytes;
with Flyology_SIMD.Backends.Scalar;

package Flyology_SIMD.Algorithms.Scalar is new
  Flyology_SIMD.Algorithms.Generic_Bytes
    (Backend_Splat           => Flyology_SIMD.Backends.Scalar.Splat,
     Backend_Bitwise_And     => Flyology_SIMD.Backends.Scalar.Bitwise_And,
     Backend_Equal           => Flyology_SIMD.Backends.Scalar.Equal,
     Backend_Less_Equal      => Flyology_SIMD.Backends.Scalar.Less_Equal,
     Backend_Greater_Equal   => Flyology_SIMD.Backends.Scalar.Greater_Equal,
     Backend_Mask_And        => Flyology_SIMD.Backends.Scalar.Mask_And,
     Backend_To_Bit_Mask     => Flyology_SIMD.Backends.Scalar.To_Bit_Mask,
     Backend_Load_Unaligned  => Flyology_SIMD.Backends.Scalar.Load_Unaligned,
     Backend_Store_Unaligned => Flyology_SIMD.Backends.Scalar.Store_Unaligned,
     Backend_Add_Saturate    => Flyology_SIMD.Backends.Scalar.Add_Saturate);
--  Complete-buffer byte algorithms instantiated with the scalar backend.
