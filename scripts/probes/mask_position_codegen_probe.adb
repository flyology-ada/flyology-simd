with Flyology_SIMD.Backends.Native;
with Interfaces;

package body Mask_Position_Codegen_Probe is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;

   function Algebra_8
     (Left, Right : Interfaces.Unsigned_16;
      Lane : Flyology_SIMD.Lane_Index_8x16) return Boolean
   is
      use Flyology_SIMD.Backends.Native;
      L : constant Flyology_SIMD.Mask_8x16 := Mask_From_Bit_Mask (Left);
      R : constant Flyology_SIMD.Mask_8x16 := Mask_From_Bit_Mask (Right);
      Combined : constant Flyology_SIMD.Mask_8x16 :=
        Mask_Xor (Mask_Or (Mask_And (L, R), Mask_Not (R)), L);
   begin
      return To_Bit_Mask (Combined) /= 0
        and then Test (Combined, Lane)
        and then Any_True (Combined)
        and then not All_True (Combined)
        and then not None_True (Combined);
   end Algebra_8;

   function Algebra_16
     (Left, Right : Interfaces.Unsigned_8;
      Lane : Flyology_SIMD.Lane_Index_16x8) return Boolean
   is
      use Flyology_SIMD.Backends.Native;
      L : constant Flyology_SIMD.Mask_16x8 := Mask_From_Bit_Mask (Left);
      R : constant Flyology_SIMD.Mask_16x8 := Mask_From_Bit_Mask (Right);
      Combined : constant Flyology_SIMD.Mask_16x8 :=
        Mask_Xor (Mask_Or (Mask_And (L, R), Mask_Not (R)), L);
   begin
      return To_Bit_Mask (Combined) /= 0
        and then Test (Combined, Lane)
        and then Any_True (Combined)
        and then not All_True (Combined)
        and then not None_True (Combined);
   end Algebra_16;

   function Algebra_32
     (Left, Right : Interfaces.Unsigned_8;
      Lane : Flyology_SIMD.Lane_Index_32x4) return Boolean
   is
      use Flyology_SIMD.Backends.Native;
      L : constant Flyology_SIMD.Mask_32x4 := Mask_From_Bit_Mask (Left);
      R : constant Flyology_SIMD.Mask_32x4 := Mask_From_Bit_Mask (Right);
      Combined : constant Flyology_SIMD.Mask_32x4 :=
        Mask_Xor (Mask_Or (Mask_And (L, R), Mask_Not (R)), L);
   begin
      return To_Bit_Mask (Combined) /= 0
        and then Test (Combined, Lane)
        and then Any_True (Combined)
        and then not All_True (Combined)
        and then not None_True (Combined);
   end Algebra_32;

   function Algebra_64
     (Left, Right : Interfaces.Unsigned_8;
      Lane : Flyology_SIMD.Lane_Index_64x2) return Boolean
   is
      use Flyology_SIMD.Backends.Native;
      L : constant Flyology_SIMD.Mask_64x2 := Mask_From_Bit_Mask (Left);
      R : constant Flyology_SIMD.Mask_64x2 := Mask_From_Bit_Mask (Right);
      Combined : constant Flyology_SIMD.Mask_64x2 :=
        Mask_Xor (Mask_Or (Mask_And (L, R), Mask_Not (R)), L);
   begin
      return To_Bit_Mask (Combined) /= 0
        and then Test (Combined, Lane)
        and then Any_True (Combined)
        and then not All_True (Combined)
        and then not None_True (Combined);
   end Algebra_64;

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
