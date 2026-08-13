with Flyology_SIMD.Backends.Native;

package body Mask_Position_Codegen_Probe is
   function Count_8
     (Mask : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Lane_Count_8x16 is
     (Flyology_SIMD.Backends.Native.Population_Count (Mask));
   function First_8
     (Mask : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Lane_Count_8x16 is
     (Flyology_SIMD.Backends.Native.First_True (Mask));
   function Last_8
     (Mask : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Lane_Count_8x16 is
     (Flyology_SIMD.Backends.Native.Last_True (Mask));
   function Count_16
     (Mask : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Lane_Count_16x8 is
     (Flyology_SIMD.Backends.Native.Population_Count (Mask));
   function First_16
     (Mask : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Lane_Count_16x8 is
     (Flyology_SIMD.Backends.Native.First_True (Mask));
   function Last_16
     (Mask : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Lane_Count_16x8 is
     (Flyology_SIMD.Backends.Native.Last_True (Mask));
   function Count_32
     (Mask : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Lane_Count_32x4 is
     (Flyology_SIMD.Backends.Native.Population_Count (Mask));
   function First_32
     (Mask : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Lane_Count_32x4 is
     (Flyology_SIMD.Backends.Native.First_True (Mask));
   function Last_32
     (Mask : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Lane_Count_32x4 is
     (Flyology_SIMD.Backends.Native.Last_True (Mask));
   function Count_64
     (Mask : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Lane_Count_64x2 is
     (Flyology_SIMD.Backends.Native.Population_Count (Mask));
   function First_64
     (Mask : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Lane_Count_64x2 is
     (Flyology_SIMD.Backends.Native.First_True (Mask));
   function Last_64
     (Mask : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Lane_Count_64x2 is
     (Flyology_SIMD.Backends.Native.Last_True (Mask));
end Mask_Position_Codegen_Probe;
