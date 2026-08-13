with Flyology_SIMD.Wide.Native;

package body Wide_Memory_Codegen_Probe is
   package Native renames Flyology_SIMD.Wide.Native;
   function u8_load (Data : SIMD.Byte_Array; Start : Natural) return Wide.U8x32 is
     (Native.Load (Data, Start));
   procedure u8_store (Data : in out SIMD.Byte_Array; Start : Natural; Value : Wide.U8x32) is
   begin
      Native.Store (Data, Start, Value);
   end u8_store;
   function u8_load_unaligned (Data : SIMD.Byte_Array; Start : Natural) return Wide.U8x32 is
     (Native.Load_Unaligned (Data, Start));
   procedure u8_store_unaligned (Data : in out SIMD.Byte_Array; Start : Natural; Value : Wide.U8x32) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end u8_store_unaligned;
   function u8_load_aligned (Data : SIMD.Byte_Array; Start : Natural) return Wide.U8x32 is
     (Native.Load_Aligned (Data, Start));
   procedure u8_store_aligned (Data : in out SIMD.Byte_Array; Start : Natural; Value : Wide.U8x32) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end u8_store_aligned;
   function u8_load_partial (Data : SIMD.Byte_Array; Start : Natural; Count : Wide.Lane_Count_8x32) return Wide.U8x32 is
     (Native.Load_Partial (Data, Start, Count));
   procedure u8_store_partial (Data : in out SIMD.Byte_Array; Start : Natural; Count : Wide.Lane_Count_8x32; Value : Wide.U8x32) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end u8_store_partial;
   function i8_load (Data : SIMD.I8_Array; Start : Natural) return Wide.I8x32 is
     (Native.Load (Data, Start));
   procedure i8_store (Data : in out SIMD.I8_Array; Start : Natural; Value : Wide.I8x32) is
   begin
      Native.Store (Data, Start, Value);
   end i8_store;
   function i8_load_unaligned (Data : SIMD.I8_Array; Start : Natural) return Wide.I8x32 is
     (Native.Load_Unaligned (Data, Start));
   procedure i8_store_unaligned (Data : in out SIMD.I8_Array; Start : Natural; Value : Wide.I8x32) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end i8_store_unaligned;
   function i8_load_aligned (Data : SIMD.I8_Array; Start : Natural) return Wide.I8x32 is
     (Native.Load_Aligned (Data, Start));
   procedure i8_store_aligned (Data : in out SIMD.I8_Array; Start : Natural; Value : Wide.I8x32) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end i8_store_aligned;
   function i8_load_partial (Data : SIMD.I8_Array; Start : Natural; Count : Wide.Lane_Count_8x32) return Wide.I8x32 is
     (Native.Load_Partial (Data, Start, Count));
   procedure i8_store_partial (Data : in out SIMD.I8_Array; Start : Natural; Count : Wide.Lane_Count_8x32; Value : Wide.I8x32) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end i8_store_partial;
   function u16_load (Data : SIMD.U16_Array; Start : Natural) return Wide.U16x16 is
     (Native.Load (Data, Start));
   procedure u16_store (Data : in out SIMD.U16_Array; Start : Natural; Value : Wide.U16x16) is
   begin
      Native.Store (Data, Start, Value);
   end u16_store;
   function u16_load_unaligned (Data : SIMD.U16_Array; Start : Natural) return Wide.U16x16 is
     (Native.Load_Unaligned (Data, Start));
   procedure u16_store_unaligned (Data : in out SIMD.U16_Array; Start : Natural; Value : Wide.U16x16) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end u16_store_unaligned;
   function u16_load_aligned (Data : SIMD.U16_Array; Start : Natural) return Wide.U16x16 is
     (Native.Load_Aligned (Data, Start));
   procedure u16_store_aligned (Data : in out SIMD.U16_Array; Start : Natural; Value : Wide.U16x16) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end u16_store_aligned;
   function u16_load_partial (Data : SIMD.U16_Array; Start : Natural; Count : Wide.Lane_Count_16x16) return Wide.U16x16 is
     (Native.Load_Partial (Data, Start, Count));
   procedure u16_store_partial (Data : in out SIMD.U16_Array; Start : Natural; Count : Wide.Lane_Count_16x16; Value : Wide.U16x16) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end u16_store_partial;
   function i16_load (Data : SIMD.I16_Array; Start : Natural) return Wide.I16x16 is
     (Native.Load (Data, Start));
   procedure i16_store (Data : in out SIMD.I16_Array; Start : Natural; Value : Wide.I16x16) is
   begin
      Native.Store (Data, Start, Value);
   end i16_store;
   function i16_load_unaligned (Data : SIMD.I16_Array; Start : Natural) return Wide.I16x16 is
     (Native.Load_Unaligned (Data, Start));
   procedure i16_store_unaligned (Data : in out SIMD.I16_Array; Start : Natural; Value : Wide.I16x16) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end i16_store_unaligned;
   function i16_load_aligned (Data : SIMD.I16_Array; Start : Natural) return Wide.I16x16 is
     (Native.Load_Aligned (Data, Start));
   procedure i16_store_aligned (Data : in out SIMD.I16_Array; Start : Natural; Value : Wide.I16x16) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end i16_store_aligned;
   function i16_load_partial (Data : SIMD.I16_Array; Start : Natural; Count : Wide.Lane_Count_16x16) return Wide.I16x16 is
     (Native.Load_Partial (Data, Start, Count));
   procedure i16_store_partial (Data : in out SIMD.I16_Array; Start : Natural; Count : Wide.Lane_Count_16x16; Value : Wide.I16x16) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end i16_store_partial;
   function u32_load (Data : SIMD.U32_Array; Start : Natural) return Wide.U32x8 is
     (Native.Load (Data, Start));
   procedure u32_store (Data : in out SIMD.U32_Array; Start : Natural; Value : Wide.U32x8) is
   begin
      Native.Store (Data, Start, Value);
   end u32_store;
   function u32_load_unaligned (Data : SIMD.U32_Array; Start : Natural) return Wide.U32x8 is
     (Native.Load_Unaligned (Data, Start));
   procedure u32_store_unaligned (Data : in out SIMD.U32_Array; Start : Natural; Value : Wide.U32x8) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end u32_store_unaligned;
   function u32_load_aligned (Data : SIMD.U32_Array; Start : Natural) return Wide.U32x8 is
     (Native.Load_Aligned (Data, Start));
   procedure u32_store_aligned (Data : in out SIMD.U32_Array; Start : Natural; Value : Wide.U32x8) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end u32_store_aligned;
   function u32_load_partial (Data : SIMD.U32_Array; Start : Natural; Count : Wide.Lane_Count_32x8) return Wide.U32x8 is
     (Native.Load_Partial (Data, Start, Count));
   procedure u32_store_partial (Data : in out SIMD.U32_Array; Start : Natural; Count : Wide.Lane_Count_32x8; Value : Wide.U32x8) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end u32_store_partial;
   function i32_load (Data : SIMD.I32_Array; Start : Natural) return Wide.I32x8 is
     (Native.Load (Data, Start));
   procedure i32_store (Data : in out SIMD.I32_Array; Start : Natural; Value : Wide.I32x8) is
   begin
      Native.Store (Data, Start, Value);
   end i32_store;
   function i32_load_unaligned (Data : SIMD.I32_Array; Start : Natural) return Wide.I32x8 is
     (Native.Load_Unaligned (Data, Start));
   procedure i32_store_unaligned (Data : in out SIMD.I32_Array; Start : Natural; Value : Wide.I32x8) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end i32_store_unaligned;
   function i32_load_aligned (Data : SIMD.I32_Array; Start : Natural) return Wide.I32x8 is
     (Native.Load_Aligned (Data, Start));
   procedure i32_store_aligned (Data : in out SIMD.I32_Array; Start : Natural; Value : Wide.I32x8) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end i32_store_aligned;
   function i32_load_partial (Data : SIMD.I32_Array; Start : Natural; Count : Wide.Lane_Count_32x8) return Wide.I32x8 is
     (Native.Load_Partial (Data, Start, Count));
   procedure i32_store_partial (Data : in out SIMD.I32_Array; Start : Natural; Count : Wide.Lane_Count_32x8; Value : Wide.I32x8) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end i32_store_partial;
   function u64_load (Data : SIMD.U64_Array; Start : Natural) return Wide.U64x4 is
     (Native.Load (Data, Start));
   procedure u64_store (Data : in out SIMD.U64_Array; Start : Natural; Value : Wide.U64x4) is
   begin
      Native.Store (Data, Start, Value);
   end u64_store;
   function u64_load_unaligned (Data : SIMD.U64_Array; Start : Natural) return Wide.U64x4 is
     (Native.Load_Unaligned (Data, Start));
   procedure u64_store_unaligned (Data : in out SIMD.U64_Array; Start : Natural; Value : Wide.U64x4) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end u64_store_unaligned;
   function u64_load_aligned (Data : SIMD.U64_Array; Start : Natural) return Wide.U64x4 is
     (Native.Load_Aligned (Data, Start));
   procedure u64_store_aligned (Data : in out SIMD.U64_Array; Start : Natural; Value : Wide.U64x4) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end u64_store_aligned;
   function u64_load_partial (Data : SIMD.U64_Array; Start : Natural; Count : Wide.Lane_Count_64x4) return Wide.U64x4 is
     (Native.Load_Partial (Data, Start, Count));
   procedure u64_store_partial (Data : in out SIMD.U64_Array; Start : Natural; Count : Wide.Lane_Count_64x4; Value : Wide.U64x4) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end u64_store_partial;
   function i64_load (Data : SIMD.I64_Array; Start : Natural) return Wide.I64x4 is
     (Native.Load (Data, Start));
   procedure i64_store (Data : in out SIMD.I64_Array; Start : Natural; Value : Wide.I64x4) is
   begin
      Native.Store (Data, Start, Value);
   end i64_store;
   function i64_load_unaligned (Data : SIMD.I64_Array; Start : Natural) return Wide.I64x4 is
     (Native.Load_Unaligned (Data, Start));
   procedure i64_store_unaligned (Data : in out SIMD.I64_Array; Start : Natural; Value : Wide.I64x4) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end i64_store_unaligned;
   function i64_load_aligned (Data : SIMD.I64_Array; Start : Natural) return Wide.I64x4 is
     (Native.Load_Aligned (Data, Start));
   procedure i64_store_aligned (Data : in out SIMD.I64_Array; Start : Natural; Value : Wide.I64x4) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end i64_store_aligned;
   function i64_load_partial (Data : SIMD.I64_Array; Start : Natural; Count : Wide.Lane_Count_64x4) return Wide.I64x4 is
     (Native.Load_Partial (Data, Start, Count));
   procedure i64_store_partial (Data : in out SIMD.I64_Array; Start : Natural; Count : Wide.Lane_Count_64x4; Value : Wide.I64x4) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end i64_store_partial;
   function f32_load (Data : SIMD.F32_Array; Start : Natural) return Wide.F32x8 is
     (Native.Load (Data, Start));
   procedure f32_store (Data : in out SIMD.F32_Array; Start : Natural; Value : Wide.F32x8) is
   begin
      Native.Store (Data, Start, Value);
   end f32_store;
   function f32_load_unaligned (Data : SIMD.F32_Array; Start : Natural) return Wide.F32x8 is
     (Native.Load_Unaligned (Data, Start));
   procedure f32_store_unaligned (Data : in out SIMD.F32_Array; Start : Natural; Value : Wide.F32x8) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end f32_store_unaligned;
   function f32_load_aligned (Data : SIMD.F32_Array; Start : Natural) return Wide.F32x8 is
     (Native.Load_Aligned (Data, Start));
   procedure f32_store_aligned (Data : in out SIMD.F32_Array; Start : Natural; Value : Wide.F32x8) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end f32_store_aligned;
   function f32_load_partial (Data : SIMD.F32_Array; Start : Natural; Count : Wide.Lane_Count_32x8) return Wide.F32x8 is
     (Native.Load_Partial (Data, Start, Count));
   procedure f32_store_partial (Data : in out SIMD.F32_Array; Start : Natural; Count : Wide.Lane_Count_32x8; Value : Wide.F32x8) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end f32_store_partial;
   function f64_load (Data : SIMD.F64_Array; Start : Natural) return Wide.F64x4 is
     (Native.Load (Data, Start));
   procedure f64_store (Data : in out SIMD.F64_Array; Start : Natural; Value : Wide.F64x4) is
   begin
      Native.Store (Data, Start, Value);
   end f64_store;
   function f64_load_unaligned (Data : SIMD.F64_Array; Start : Natural) return Wide.F64x4 is
     (Native.Load_Unaligned (Data, Start));
   procedure f64_store_unaligned (Data : in out SIMD.F64_Array; Start : Natural; Value : Wide.F64x4) is
   begin
      Native.Store_Unaligned (Data, Start, Value);
   end f64_store_unaligned;
   function f64_load_aligned (Data : SIMD.F64_Array; Start : Natural) return Wide.F64x4 is
     (Native.Load_Aligned (Data, Start));
   procedure f64_store_aligned (Data : in out SIMD.F64_Array; Start : Natural; Value : Wide.F64x4) is
   begin
      Native.Store_Aligned (Data, Start, Value);
   end f64_store_aligned;
   function f64_load_partial (Data : SIMD.F64_Array; Start : Natural; Count : Wide.Lane_Count_64x4) return Wide.F64x4 is
     (Native.Load_Partial (Data, Start, Count));
   procedure f64_store_partial (Data : in out SIMD.F64_Array; Start : Natural; Count : Wide.Lane_Count_64x4; Value : Wide.F64x4) is
   begin
      Native.Store_Partial (Data, Start, Count, Value);
   end f64_store_partial;
end Wide_Memory_Codegen_Probe;
