with Flyology_SIMD;
with Interfaces;

package Mask_Position_Codegen_Probe is
   function Algebra_8
     (Left, Right : Interfaces.Unsigned_16;
      Lane : Flyology_SIMD.Lane_Index_8x16) return Boolean;
   function Algebra_16
     (Left, Right : Interfaces.Unsigned_8;
      Lane : Flyology_SIMD.Lane_Index_16x8) return Boolean;
   function Algebra_32
     (Left, Right : Interfaces.Unsigned_8;
      Lane : Flyology_SIMD.Lane_Index_32x4) return Boolean;
   function Algebra_64
     (Left, Right : Interfaces.Unsigned_8;
      Lane : Flyology_SIMD.Lane_Index_64x2) return Boolean;
   function Count_8
     (Mask : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Lane_Count_8x16;
   function First_8
     (Mask : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Lane_Count_8x16;
   function Last_8
     (Mask : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Lane_Count_8x16;
   function Count_16
     (Mask : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Lane_Count_16x8;
   function First_16
     (Mask : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Lane_Count_16x8;
   function Last_16
     (Mask : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Lane_Count_16x8;
   function Count_32
     (Mask : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Lane_Count_32x4;
   function First_32
     (Mask : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Lane_Count_32x4;
   function Last_32
     (Mask : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Lane_Count_32x4;
   function Count_64
     (Mask : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Lane_Count_64x2;
   function First_64
     (Mask : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Lane_Count_64x2;
   function Last_64
     (Mask : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Lane_Count_64x2;
end Mask_Position_Codegen_Probe;
