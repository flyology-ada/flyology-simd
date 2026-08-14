with Flyology_SIMD.Wide.Native;

package body Wide_Mask_Codegen_Probe is
   function M8_Mask_From_Bit_Mask (Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits));

   function M8_To_Bit_Mask (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask (Mask));

   function M8_Mask_And (Left, Right : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Mask_And (Left, Right));

   function M8_Mask_Or (Left, Right : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Mask_Or (Left, Right));

   function M8_Mask_Xor (Left, Right : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Mask_Xor (Left, Right));

   function M8_Mask_Not (Value : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Mask_Not (Value));

   function M8_Test (Mask : Flyology_SIMD.Wide.Mask_8x32; Lane : Flyology_SIMD.Wide.Lane_Index_8x32)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Test (Mask, Lane));

   function M8_Any_True (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Any_True (Mask));

   function M8_All_True (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Boolean is
     (Flyology_SIMD.Wide.Native.All_True (Mask));

   function M8_None_True (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Boolean is
     (Flyology_SIMD.Wide.Native.None_True (Mask));

   function M8_Population_Count (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Lane_Count_8x32 is
     (Flyology_SIMD.Wide.Native.Population_Count (Mask));

   function M8_First_True (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Lane_Count_8x32 is
     (Flyology_SIMD.Wide.Native.First_True (Mask));

   function M8_Last_True (Mask : Flyology_SIMD.Wide.Mask_8x32)
      return Flyology_SIMD.Wide.Lane_Count_8x32 is
     (Flyology_SIMD.Wide.Native.Last_True (Mask));

   function M16_Mask_From_Bit_Mask (Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits));

   function M16_To_Bit_Mask (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Mask_Bits_16x16 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask (Mask));

   function M16_Mask_And (Left, Right : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Mask_And (Left, Right));

   function M16_Mask_Or (Left, Right : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Mask_Or (Left, Right));

   function M16_Mask_Xor (Left, Right : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Mask_Xor (Left, Right));

   function M16_Mask_Not (Value : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Mask_Not (Value));

   function M16_Test (Mask : Flyology_SIMD.Wide.Mask_16x16; Lane : Flyology_SIMD.Wide.Lane_Index_16x16)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Test (Mask, Lane));

   function M16_Any_True (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Any_True (Mask));

   function M16_All_True (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Boolean is
     (Flyology_SIMD.Wide.Native.All_True (Mask));

   function M16_None_True (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Boolean is
     (Flyology_SIMD.Wide.Native.None_True (Mask));

   function M16_Population_Count (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Lane_Count_16x16 is
     (Flyology_SIMD.Wide.Native.Population_Count (Mask));

   function M16_First_True (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Lane_Count_16x16 is
     (Flyology_SIMD.Wide.Native.First_True (Mask));

   function M16_Last_True (Mask : Flyology_SIMD.Wide.Mask_16x16)
      return Flyology_SIMD.Wide.Lane_Count_16x16 is
     (Flyology_SIMD.Wide.Native.Last_True (Mask));

   function M32_Mask_From_Bit_Mask (Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits));

   function M32_To_Bit_Mask (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Mask_Bits_32x8 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask (Mask));

   function M32_Mask_And (Left, Right : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Mask_And (Left, Right));

   function M32_Mask_Or (Left, Right : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Mask_Or (Left, Right));

   function M32_Mask_Xor (Left, Right : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Mask_Xor (Left, Right));

   function M32_Mask_Not (Value : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Mask_Not (Value));

   function M32_Test (Mask : Flyology_SIMD.Wide.Mask_32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Test (Mask, Lane));

   function M32_Any_True (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Any_True (Mask));

   function M32_All_True (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Boolean is
     (Flyology_SIMD.Wide.Native.All_True (Mask));

   function M32_None_True (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Boolean is
     (Flyology_SIMD.Wide.Native.None_True (Mask));

   function M32_Population_Count (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Lane_Count_32x8 is
     (Flyology_SIMD.Wide.Native.Population_Count (Mask));

   function M32_First_True (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Lane_Count_32x8 is
     (Flyology_SIMD.Wide.Native.First_True (Mask));

   function M32_Last_True (Mask : Flyology_SIMD.Wide.Mask_32x8)
      return Flyology_SIMD.Wide.Lane_Count_32x8 is
     (Flyology_SIMD.Wide.Native.Last_True (Mask));

   function M64_Mask_From_Bit_Mask (Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits));

   function M64_To_Bit_Mask (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Mask_Bits_64x4 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask (Mask));

   function M64_Mask_And (Left, Right : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Mask_And (Left, Right));

   function M64_Mask_Or (Left, Right : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Mask_Or (Left, Right));

   function M64_Mask_Xor (Left, Right : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Mask_Xor (Left, Right));

   function M64_Mask_Not (Value : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Mask_Not (Value));

   function M64_Test (Mask : Flyology_SIMD.Wide.Mask_64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Test (Mask, Lane));

   function M64_Any_True (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Boolean is
     (Flyology_SIMD.Wide.Native.Any_True (Mask));

   function M64_All_True (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Boolean is
     (Flyology_SIMD.Wide.Native.All_True (Mask));

   function M64_None_True (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Boolean is
     (Flyology_SIMD.Wide.Native.None_True (Mask));

   function M64_Population_Count (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Lane_Count_64x4 is
     (Flyology_SIMD.Wide.Native.Population_Count (Mask));

   function M64_First_True (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Lane_Count_64x4 is
     (Flyology_SIMD.Wide.Native.First_True (Mask));

   function M64_Last_True (Mask : Flyology_SIMD.Wide.Mask_64x4)
      return Flyology_SIMD.Wide.Lane_Count_64x4 is
     (Flyology_SIMD.Wide.Native.Last_True (Mask));

end Wide_Mask_Codegen_Probe;
