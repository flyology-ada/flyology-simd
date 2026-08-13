with Flyology_SIMD.Backends.Native;

package body Complete_Memory_Codegen_Probe is
   function U8_Load
     (Data : Flyology_SIMD.Byte_Array; Start : Natural)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure U8_Store
     (Data : in out Flyology_SIMD.Byte_Array; Start : Natural;
      Value : Flyology_SIMD.U8x16) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end U8_Store;

   function U8_Load_Unaligned
     (Data : Flyology_SIMD.Byte_Array; Start : Natural)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure U8_Store_Unaligned
     (Data : in out Flyology_SIMD.Byte_Array; Start : Natural;
      Value : Flyology_SIMD.U8x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end U8_Store_Unaligned;

   function U8_Load_Aligned
     (Data : Flyology_SIMD.Byte_Array; Start : Natural)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure U8_Store_Aligned
     (Data : in out Flyology_SIMD.Byte_Array; Start : Natural;
      Value : Flyology_SIMD.U8x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end U8_Store_Aligned;

   function I8_Load
     (Data : Flyology_SIMD.I8_Array; Start : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure I8_Store
     (Data : in out Flyology_SIMD.I8_Array; Start : Natural;
      Value : Flyology_SIMD.I8x16) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end I8_Store;

   function I8_Load_Unaligned
     (Data : Flyology_SIMD.I8_Array; Start : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure I8_Store_Unaligned
     (Data : in out Flyology_SIMD.I8_Array; Start : Natural;
      Value : Flyology_SIMD.I8x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end I8_Store_Unaligned;

   function I8_Load_Aligned
     (Data : Flyology_SIMD.I8_Array; Start : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure I8_Store_Aligned
     (Data : in out Flyology_SIMD.I8_Array; Start : Natural;
      Value : Flyology_SIMD.I8x16) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end I8_Store_Aligned;

   function U16_Load
     (Data : Flyology_SIMD.U16_Array; Start : Natural)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure U16_Store
     (Data : in out Flyology_SIMD.U16_Array; Start : Natural;
      Value : Flyology_SIMD.U16x8) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end U16_Store;

   function U16_Load_Unaligned
     (Data : Flyology_SIMD.U16_Array; Start : Natural)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure U16_Store_Unaligned
     (Data : in out Flyology_SIMD.U16_Array; Start : Natural;
      Value : Flyology_SIMD.U16x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end U16_Store_Unaligned;

   function U16_Load_Aligned
     (Data : Flyology_SIMD.U16_Array; Start : Natural)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure U16_Store_Aligned
     (Data : in out Flyology_SIMD.U16_Array; Start : Natural;
      Value : Flyology_SIMD.U16x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end U16_Store_Aligned;

   function I16_Load
     (Data : Flyology_SIMD.I16_Array; Start : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure I16_Store
     (Data : in out Flyology_SIMD.I16_Array; Start : Natural;
      Value : Flyology_SIMD.I16x8) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end I16_Store;

   function I16_Load_Unaligned
     (Data : Flyology_SIMD.I16_Array; Start : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure I16_Store_Unaligned
     (Data : in out Flyology_SIMD.I16_Array; Start : Natural;
      Value : Flyology_SIMD.I16x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end I16_Store_Unaligned;

   function I16_Load_Aligned
     (Data : Flyology_SIMD.I16_Array; Start : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure I16_Store_Aligned
     (Data : in out Flyology_SIMD.I16_Array; Start : Natural;
      Value : Flyology_SIMD.I16x8) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end I16_Store_Aligned;

   function U32_Load
     (Data : Flyology_SIMD.U32_Array; Start : Natural)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure U32_Store
     (Data : in out Flyology_SIMD.U32_Array; Start : Natural;
      Value : Flyology_SIMD.U32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end U32_Store;

   function U32_Load_Unaligned
     (Data : Flyology_SIMD.U32_Array; Start : Natural)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure U32_Store_Unaligned
     (Data : in out Flyology_SIMD.U32_Array; Start : Natural;
      Value : Flyology_SIMD.U32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end U32_Store_Unaligned;

   function U32_Load_Aligned
     (Data : Flyology_SIMD.U32_Array; Start : Natural)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure U32_Store_Aligned
     (Data : in out Flyology_SIMD.U32_Array; Start : Natural;
      Value : Flyology_SIMD.U32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end U32_Store_Aligned;

   function I32_Load
     (Data : Flyology_SIMD.I32_Array; Start : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure I32_Store
     (Data : in out Flyology_SIMD.I32_Array; Start : Natural;
      Value : Flyology_SIMD.I32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end I32_Store;

   function I32_Load_Unaligned
     (Data : Flyology_SIMD.I32_Array; Start : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure I32_Store_Unaligned
     (Data : in out Flyology_SIMD.I32_Array; Start : Natural;
      Value : Flyology_SIMD.I32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end I32_Store_Unaligned;

   function I32_Load_Aligned
     (Data : Flyology_SIMD.I32_Array; Start : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure I32_Store_Aligned
     (Data : in out Flyology_SIMD.I32_Array; Start : Natural;
      Value : Flyology_SIMD.I32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end I32_Store_Aligned;

   function U64_Load
     (Data : Flyology_SIMD.U64_Array; Start : Natural)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure U64_Store
     (Data : in out Flyology_SIMD.U64_Array; Start : Natural;
      Value : Flyology_SIMD.U64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end U64_Store;

   function U64_Load_Unaligned
     (Data : Flyology_SIMD.U64_Array; Start : Natural)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure U64_Store_Unaligned
     (Data : in out Flyology_SIMD.U64_Array; Start : Natural;
      Value : Flyology_SIMD.U64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end U64_Store_Unaligned;

   function U64_Load_Aligned
     (Data : Flyology_SIMD.U64_Array; Start : Natural)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure U64_Store_Aligned
     (Data : in out Flyology_SIMD.U64_Array; Start : Natural;
      Value : Flyology_SIMD.U64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end U64_Store_Aligned;

   function I64_Load
     (Data : Flyology_SIMD.I64_Array; Start : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure I64_Store
     (Data : in out Flyology_SIMD.I64_Array; Start : Natural;
      Value : Flyology_SIMD.I64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end I64_Store;

   function I64_Load_Unaligned
     (Data : Flyology_SIMD.I64_Array; Start : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure I64_Store_Unaligned
     (Data : in out Flyology_SIMD.I64_Array; Start : Natural;
      Value : Flyology_SIMD.I64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end I64_Store_Unaligned;

   function I64_Load_Aligned
     (Data : Flyology_SIMD.I64_Array; Start : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure I64_Store_Aligned
     (Data : in out Flyology_SIMD.I64_Array; Start : Natural;
      Value : Flyology_SIMD.I64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end I64_Store_Aligned;

   function F32_Load
     (Data : Flyology_SIMD.F32_Array; Start : Natural)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure F32_Store
     (Data : in out Flyology_SIMD.F32_Array; Start : Natural;
      Value : Flyology_SIMD.F32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end F32_Store;

   function F32_Load_Unaligned
     (Data : Flyology_SIMD.F32_Array; Start : Natural)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure F32_Store_Unaligned
     (Data : in out Flyology_SIMD.F32_Array; Start : Natural;
      Value : Flyology_SIMD.F32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end F32_Store_Unaligned;

   function F32_Load_Aligned
     (Data : Flyology_SIMD.F32_Array; Start : Natural)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure F32_Store_Aligned
     (Data : in out Flyology_SIMD.F32_Array; Start : Natural;
      Value : Flyology_SIMD.F32x4) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end F32_Store_Aligned;

   function F64_Load
     (Data : Flyology_SIMD.F64_Array; Start : Natural)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Load (Data, Start));

   procedure F64_Store
     (Data : in out Flyology_SIMD.F64_Array; Start : Natural;
      Value : Flyology_SIMD.F64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store (Data, Start, Value);
   end F64_Store;

   function F64_Load_Unaligned
     (Data : Flyology_SIMD.F64_Array; Start : Natural)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Load_Unaligned (Data, Start));

   procedure F64_Store_Unaligned
     (Data : in out Flyology_SIMD.F64_Array; Start : Natural;
      Value : Flyology_SIMD.F64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store_Unaligned (Data, Start, Value);
   end F64_Store_Unaligned;

   function F64_Load_Aligned
     (Data : Flyology_SIMD.F64_Array; Start : Natural)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Load_Aligned (Data, Start));

   procedure F64_Store_Aligned
     (Data : in out Flyology_SIMD.F64_Array; Start : Natural;
      Value : Flyology_SIMD.F64x2) is
   begin
      Flyology_SIMD.Backends.Native.Store_Aligned (Data, Start, Value);
   end F64_Store_Aligned;

end Complete_Memory_Codegen_Probe;
