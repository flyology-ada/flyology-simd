with Flyology_SIMD.Algorithms.Generic_Bytes;
with Flyology_SIMD.Backends.Native;

--  Complete-buffer byte algorithms instantiated with the compiled backend.
package Flyology_SIMD.Algorithms.Native is new
  Flyology_SIMD.Algorithms.Generic_Bytes
    (Backend_Splat          => Flyology_SIMD.Backends.Native.Splat,
     Backend_Bitwise_And    => Flyology_SIMD.Backends.Native.Bitwise_And,
     Backend_Equal          => Flyology_SIMD.Backends.Native.Equal,
     Backend_To_Bit_Mask    => Flyology_SIMD.Backends.Native.To_Bit_Mask,
     Backend_Load_Unaligned => Flyology_SIMD.Backends.Native.Load_Unaligned);
