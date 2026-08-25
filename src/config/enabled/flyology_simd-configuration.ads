private package Flyology_SIMD.Configuration
  with Preelaborate, SPARK_Mode => On
is
   --  Build-time constants for optional implementation objects.
   AVX2_Compiled : constant Boolean := True;
   --  True when the build contains the optional AVX2 implementation.
end Flyology_SIMD.Configuration;
