with Flyology_SIMD;

package Partial_Memory_Codegen_Probe is
   function Load_U8 (Data : Flyology_SIMD.Byte_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_8x16) return Flyology_SIMD.U8x16;
   procedure Store_U8 (Data : in out Flyology_SIMD.Byte_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_8x16; Value : Flyology_SIMD.U8x16);
   function Load_I8 (Data : Flyology_SIMD.I8_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_8x16) return Flyology_SIMD.I8x16;
   procedure Store_I8 (Data : in out Flyology_SIMD.I8_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_8x16; Value : Flyology_SIMD.I8x16);
   function Load_U16 (Data : Flyology_SIMD.U16_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_16x8) return Flyology_SIMD.U16x8;
   procedure Store_U16 (Data : in out Flyology_SIMD.U16_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_16x8; Value : Flyology_SIMD.U16x8);
   function Load_I16 (Data : Flyology_SIMD.I16_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_16x8) return Flyology_SIMD.I16x8;
   procedure Store_I16 (Data : in out Flyology_SIMD.I16_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_16x8; Value : Flyology_SIMD.I16x8);
   function Load_U32 (Data : Flyology_SIMD.U32_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_32x4) return Flyology_SIMD.U32x4;
   procedure Store_U32 (Data : in out Flyology_SIMD.U32_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_32x4; Value : Flyology_SIMD.U32x4);
   function Load_I32 (Data : Flyology_SIMD.I32_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_32x4) return Flyology_SIMD.I32x4;
   procedure Store_I32 (Data : in out Flyology_SIMD.I32_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_32x4; Value : Flyology_SIMD.I32x4);
   function Load_U64 (Data : Flyology_SIMD.U64_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_64x2) return Flyology_SIMD.U64x2;
   procedure Store_U64 (Data : in out Flyology_SIMD.U64_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_64x2; Value : Flyology_SIMD.U64x2);
   function Load_I64 (Data : Flyology_SIMD.I64_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_64x2) return Flyology_SIMD.I64x2;
   procedure Store_I64 (Data : in out Flyology_SIMD.I64_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_64x2; Value : Flyology_SIMD.I64x2);
   function Load_F32 (Data : Flyology_SIMD.F32_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_32x4) return Flyology_SIMD.F32x4;
   procedure Store_F32 (Data : in out Flyology_SIMD.F32_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_32x4; Value : Flyology_SIMD.F32x4);
   function Load_F64 (Data : Flyology_SIMD.F64_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_64x2) return Flyology_SIMD.F64x2;
   procedure Store_F64 (Data : in out Flyology_SIMD.F64_Array; Start : Natural; Count : Flyology_SIMD.Lane_Count_64x2; Value : Flyology_SIMD.F64x2);
end Partial_Memory_Codegen_Probe;
