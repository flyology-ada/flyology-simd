with Flyology_SIMD;

package Complete_Memory_Codegen_Probe is
   function U8_Load
     (Data : Flyology_SIMD.Byte_Array; Start : Natural)
      return Flyology_SIMD.U8x16;
   procedure U8_Store
     (Data : in out Flyology_SIMD.Byte_Array; Start : Natural;
      Value : Flyology_SIMD.U8x16);
   function U8_Load_Unaligned
     (Data : Flyology_SIMD.Byte_Array; Start : Natural)
      return Flyology_SIMD.U8x16;
   procedure U8_Store_Unaligned
     (Data : in out Flyology_SIMD.Byte_Array; Start : Natural;
      Value : Flyology_SIMD.U8x16);
   function U8_Load_Aligned
     (Data : Flyology_SIMD.Byte_Array; Start : Natural)
      return Flyology_SIMD.U8x16;
   procedure U8_Store_Aligned
     (Data : in out Flyology_SIMD.Byte_Array; Start : Natural;
      Value : Flyology_SIMD.U8x16);
   function I8_Load
     (Data : Flyology_SIMD.I8_Array; Start : Natural)
      return Flyology_SIMD.I8x16;
   procedure I8_Store
     (Data : in out Flyology_SIMD.I8_Array; Start : Natural;
      Value : Flyology_SIMD.I8x16);
   function I8_Load_Unaligned
     (Data : Flyology_SIMD.I8_Array; Start : Natural)
      return Flyology_SIMD.I8x16;
   procedure I8_Store_Unaligned
     (Data : in out Flyology_SIMD.I8_Array; Start : Natural;
      Value : Flyology_SIMD.I8x16);
   function I8_Load_Aligned
     (Data : Flyology_SIMD.I8_Array; Start : Natural)
      return Flyology_SIMD.I8x16;
   procedure I8_Store_Aligned
     (Data : in out Flyology_SIMD.I8_Array; Start : Natural;
      Value : Flyology_SIMD.I8x16);
   function U16_Load
     (Data : Flyology_SIMD.U16_Array; Start : Natural)
      return Flyology_SIMD.U16x8;
   procedure U16_Store
     (Data : in out Flyology_SIMD.U16_Array; Start : Natural;
      Value : Flyology_SIMD.U16x8);
   function U16_Load_Unaligned
     (Data : Flyology_SIMD.U16_Array; Start : Natural)
      return Flyology_SIMD.U16x8;
   procedure U16_Store_Unaligned
     (Data : in out Flyology_SIMD.U16_Array; Start : Natural;
      Value : Flyology_SIMD.U16x8);
   function U16_Load_Aligned
     (Data : Flyology_SIMD.U16_Array; Start : Natural)
      return Flyology_SIMD.U16x8;
   procedure U16_Store_Aligned
     (Data : in out Flyology_SIMD.U16_Array; Start : Natural;
      Value : Flyology_SIMD.U16x8);
   function I16_Load
     (Data : Flyology_SIMD.I16_Array; Start : Natural)
      return Flyology_SIMD.I16x8;
   procedure I16_Store
     (Data : in out Flyology_SIMD.I16_Array; Start : Natural;
      Value : Flyology_SIMD.I16x8);
   function I16_Load_Unaligned
     (Data : Flyology_SIMD.I16_Array; Start : Natural)
      return Flyology_SIMD.I16x8;
   procedure I16_Store_Unaligned
     (Data : in out Flyology_SIMD.I16_Array; Start : Natural;
      Value : Flyology_SIMD.I16x8);
   function I16_Load_Aligned
     (Data : Flyology_SIMD.I16_Array; Start : Natural)
      return Flyology_SIMD.I16x8;
   procedure I16_Store_Aligned
     (Data : in out Flyology_SIMD.I16_Array; Start : Natural;
      Value : Flyology_SIMD.I16x8);
   function U32_Load
     (Data : Flyology_SIMD.U32_Array; Start : Natural)
      return Flyology_SIMD.U32x4;
   procedure U32_Store
     (Data : in out Flyology_SIMD.U32_Array; Start : Natural;
      Value : Flyology_SIMD.U32x4);
   function U32_Load_Unaligned
     (Data : Flyology_SIMD.U32_Array; Start : Natural)
      return Flyology_SIMD.U32x4;
   procedure U32_Store_Unaligned
     (Data : in out Flyology_SIMD.U32_Array; Start : Natural;
      Value : Flyology_SIMD.U32x4);
   function U32_Load_Aligned
     (Data : Flyology_SIMD.U32_Array; Start : Natural)
      return Flyology_SIMD.U32x4;
   procedure U32_Store_Aligned
     (Data : in out Flyology_SIMD.U32_Array; Start : Natural;
      Value : Flyology_SIMD.U32x4);
   function I32_Load
     (Data : Flyology_SIMD.I32_Array; Start : Natural)
      return Flyology_SIMD.I32x4;
   procedure I32_Store
     (Data : in out Flyology_SIMD.I32_Array; Start : Natural;
      Value : Flyology_SIMD.I32x4);
   function I32_Load_Unaligned
     (Data : Flyology_SIMD.I32_Array; Start : Natural)
      return Flyology_SIMD.I32x4;
   procedure I32_Store_Unaligned
     (Data : in out Flyology_SIMD.I32_Array; Start : Natural;
      Value : Flyology_SIMD.I32x4);
   function I32_Load_Aligned
     (Data : Flyology_SIMD.I32_Array; Start : Natural)
      return Flyology_SIMD.I32x4;
   procedure I32_Store_Aligned
     (Data : in out Flyology_SIMD.I32_Array; Start : Natural;
      Value : Flyology_SIMD.I32x4);
   function U64_Load
     (Data : Flyology_SIMD.U64_Array; Start : Natural)
      return Flyology_SIMD.U64x2;
   procedure U64_Store
     (Data : in out Flyology_SIMD.U64_Array; Start : Natural;
      Value : Flyology_SIMD.U64x2);
   function U64_Load_Unaligned
     (Data : Flyology_SIMD.U64_Array; Start : Natural)
      return Flyology_SIMD.U64x2;
   procedure U64_Store_Unaligned
     (Data : in out Flyology_SIMD.U64_Array; Start : Natural;
      Value : Flyology_SIMD.U64x2);
   function U64_Load_Aligned
     (Data : Flyology_SIMD.U64_Array; Start : Natural)
      return Flyology_SIMD.U64x2;
   procedure U64_Store_Aligned
     (Data : in out Flyology_SIMD.U64_Array; Start : Natural;
      Value : Flyology_SIMD.U64x2);
   function I64_Load
     (Data : Flyology_SIMD.I64_Array; Start : Natural)
      return Flyology_SIMD.I64x2;
   procedure I64_Store
     (Data : in out Flyology_SIMD.I64_Array; Start : Natural;
      Value : Flyology_SIMD.I64x2);
   function I64_Load_Unaligned
     (Data : Flyology_SIMD.I64_Array; Start : Natural)
      return Flyology_SIMD.I64x2;
   procedure I64_Store_Unaligned
     (Data : in out Flyology_SIMD.I64_Array; Start : Natural;
      Value : Flyology_SIMD.I64x2);
   function I64_Load_Aligned
     (Data : Flyology_SIMD.I64_Array; Start : Natural)
      return Flyology_SIMD.I64x2;
   procedure I64_Store_Aligned
     (Data : in out Flyology_SIMD.I64_Array; Start : Natural;
      Value : Flyology_SIMD.I64x2);
   function F32_Load
     (Data : Flyology_SIMD.F32_Array; Start : Natural)
      return Flyology_SIMD.F32x4;
   procedure F32_Store
     (Data : in out Flyology_SIMD.F32_Array; Start : Natural;
      Value : Flyology_SIMD.F32x4);
   function F32_Load_Unaligned
     (Data : Flyology_SIMD.F32_Array; Start : Natural)
      return Flyology_SIMD.F32x4;
   procedure F32_Store_Unaligned
     (Data : in out Flyology_SIMD.F32_Array; Start : Natural;
      Value : Flyology_SIMD.F32x4);
   function F32_Load_Aligned
     (Data : Flyology_SIMD.F32_Array; Start : Natural)
      return Flyology_SIMD.F32x4;
   procedure F32_Store_Aligned
     (Data : in out Flyology_SIMD.F32_Array; Start : Natural;
      Value : Flyology_SIMD.F32x4);
   function F64_Load
     (Data : Flyology_SIMD.F64_Array; Start : Natural)
      return Flyology_SIMD.F64x2;
   procedure F64_Store
     (Data : in out Flyology_SIMD.F64_Array; Start : Natural;
      Value : Flyology_SIMD.F64x2);
   function F64_Load_Unaligned
     (Data : Flyology_SIMD.F64_Array; Start : Natural)
      return Flyology_SIMD.F64x2;
   procedure F64_Store_Unaligned
     (Data : in out Flyology_SIMD.F64_Array; Start : Natural;
      Value : Flyology_SIMD.F64x2);
   function F64_Load_Aligned
     (Data : Flyology_SIMD.F64_Array; Start : Natural)
      return Flyology_SIMD.F64x2;
   procedure F64_Store_Aligned
     (Data : in out Flyology_SIMD.F64_Array; Start : Natural;
      Value : Flyology_SIMD.F64x2);
end Complete_Memory_Codegen_Probe;
