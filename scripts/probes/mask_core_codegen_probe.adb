with Flyology_SIMD.Backends.Native;

package body Mask_Core_Codegen_Probe is
   function M8_Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits));

   function M8_To_Bit_Mask (Mask : Flyology_SIMD.Mask_8x16)
      return Interfaces.Unsigned_16 is
     (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask));

   function M8_Mask_And (Left, Right : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Mask_And (Left, Right));

   function M8_Mask_Or (Left, Right : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Mask_Or (Left, Right));

   function M8_Mask_Xor (Left, Right : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Mask_Xor (Left, Right));

   function M8_Mask_Not (Value : Flyology_SIMD.Mask_8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Mask_Not (Value));

   function M8_Test (Mask : Flyology_SIMD.Mask_8x16; Lane : Flyology_SIMD.Lane_Index_8x16)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Test (Mask, Lane));

   function M8_Any_True (Mask : Flyology_SIMD.Mask_8x16)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Any_True (Mask));

   function M8_All_True (Mask : Flyology_SIMD.Mask_8x16)
      return Boolean is
     (Flyology_SIMD.Backends.Native.All_True (Mask));

   function M8_None_True (Mask : Flyology_SIMD.Mask_8x16)
      return Boolean is
     (Flyology_SIMD.Backends.Native.None_True (Mask));

   function M16_Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits));

   function M16_To_Bit_Mask (Mask : Flyology_SIMD.Mask_16x8)
      return Interfaces.Unsigned_8 is
     (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask));

   function M16_Mask_And (Left, Right : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Mask_And (Left, Right));

   function M16_Mask_Or (Left, Right : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Mask_Or (Left, Right));

   function M16_Mask_Xor (Left, Right : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Mask_Xor (Left, Right));

   function M16_Mask_Not (Value : Flyology_SIMD.Mask_16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Mask_Not (Value));

   function M16_Test (Mask : Flyology_SIMD.Mask_16x8; Lane : Flyology_SIMD.Lane_Index_16x8)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Test (Mask, Lane));

   function M16_Any_True (Mask : Flyology_SIMD.Mask_16x8)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Any_True (Mask));

   function M16_All_True (Mask : Flyology_SIMD.Mask_16x8)
      return Boolean is
     (Flyology_SIMD.Backends.Native.All_True (Mask));

   function M16_None_True (Mask : Flyology_SIMD.Mask_16x8)
      return Boolean is
     (Flyology_SIMD.Backends.Native.None_True (Mask));

   function M32_Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits));

   function M32_To_Bit_Mask (Mask : Flyology_SIMD.Mask_32x4)
      return Interfaces.Unsigned_8 is
     (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask));

   function M32_Mask_And (Left, Right : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Mask_And (Left, Right));

   function M32_Mask_Or (Left, Right : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Mask_Or (Left, Right));

   function M32_Mask_Xor (Left, Right : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Mask_Xor (Left, Right));

   function M32_Mask_Not (Value : Flyology_SIMD.Mask_32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Mask_Not (Value));

   function M32_Test (Mask : Flyology_SIMD.Mask_32x4; Lane : Flyology_SIMD.Lane_Index_32x4)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Test (Mask, Lane));

   function M32_Any_True (Mask : Flyology_SIMD.Mask_32x4)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Any_True (Mask));

   function M32_All_True (Mask : Flyology_SIMD.Mask_32x4)
      return Boolean is
     (Flyology_SIMD.Backends.Native.All_True (Mask));

   function M32_None_True (Mask : Flyology_SIMD.Mask_32x4)
      return Boolean is
     (Flyology_SIMD.Backends.Native.None_True (Mask));

   function M64_Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Bits));

   function M64_To_Bit_Mask (Mask : Flyology_SIMD.Mask_64x2)
      return Interfaces.Unsigned_8 is
     (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask));

   function M64_Mask_And (Left, Right : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Mask_And (Left, Right));

   function M64_Mask_Or (Left, Right : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Mask_Or (Left, Right));

   function M64_Mask_Xor (Left, Right : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Mask_Xor (Left, Right));

   function M64_Mask_Not (Value : Flyology_SIMD.Mask_64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Mask_Not (Value));

   function M64_Test (Mask : Flyology_SIMD.Mask_64x2; Lane : Flyology_SIMD.Lane_Index_64x2)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Test (Mask, Lane));

   function M64_Any_True (Mask : Flyology_SIMD.Mask_64x2)
      return Boolean is
     (Flyology_SIMD.Backends.Native.Any_True (Mask));

   function M64_All_True (Mask : Flyology_SIMD.Mask_64x2)
      return Boolean is
     (Flyology_SIMD.Backends.Native.All_True (Mask));

   function M64_None_True (Mask : Flyology_SIMD.Mask_64x2)
      return Boolean is
     (Flyology_SIMD.Backends.Native.None_True (Mask));

end Mask_Core_Codegen_Probe;
