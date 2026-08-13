with Flyology_SIMD.Wide.Native;

package body Wide_Numeric_Conversion_Codegen_Probe is
   package Native renames Flyology_SIMD.Wide.Native;

   function u8_widen_low
     (Value : Flyology_SIMD.Wide.U8x32) return Flyology_SIMD.Wide.U16x16 is
     (Native.Widen_Low (Value));

   function u8_widen_high
     (Value : Flyology_SIMD.Wide.U8x32) return Flyology_SIMD.Wide.U16x16 is
     (Native.Widen_High (Value));

   function i8_widen_low
     (Value : Flyology_SIMD.Wide.I8x32) return Flyology_SIMD.Wide.I16x16 is
     (Native.Widen_Low (Value));

   function i8_widen_high
     (Value : Flyology_SIMD.Wide.I8x32) return Flyology_SIMD.Wide.I16x16 is
     (Native.Widen_High (Value));

   function u16_widen_low
     (Value : Flyology_SIMD.Wide.U16x16) return Flyology_SIMD.Wide.U32x8 is
     (Native.Widen_Low (Value));

   function u16_widen_high
     (Value : Flyology_SIMD.Wide.U16x16) return Flyology_SIMD.Wide.U32x8 is
     (Native.Widen_High (Value));

   function i16_widen_low
     (Value : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.I32x8 is
     (Native.Widen_Low (Value));

   function i16_widen_high
     (Value : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.I32x8 is
     (Native.Widen_High (Value));

   function u32_widen_low
     (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.U64x4 is
     (Native.Widen_Low (Value));

   function u32_widen_high
     (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.U64x4 is
     (Native.Widen_High (Value));

   function i32_widen_low
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.I64x4 is
     (Native.Widen_Low (Value));

   function i32_widen_high
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.I64x4 is
     (Native.Widen_High (Value));

   function f32_widen_low
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.F64x4 is
     (Native.Widen_Low (Value));

   function f32_widen_high
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.F64x4 is
     (Native.Widen_High (Value));

   function u16_narrow_truncate_u8
     (Low, High : Flyology_SIMD.Wide.U16x16) return Flyology_SIMD.Wide.U8x32 is
     (Native.Narrow_Truncate (Low, High));

   function i16_narrow_truncate_i8
     (Low, High : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.I8x32 is
     (Native.Narrow_Truncate (Low, High));

   function u32_narrow_truncate_u16
     (Low, High : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.U16x16 is
     (Native.Narrow_Truncate (Low, High));

   function i32_narrow_truncate_i16
     (Low, High : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.I16x16 is
     (Native.Narrow_Truncate (Low, High));

   function u64_narrow_truncate_u32
     (Low, High : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.U32x8 is
     (Native.Narrow_Truncate (Low, High));

   function i64_narrow_truncate_i32
     (Low, High : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.I32x8 is
     (Native.Narrow_Truncate (Low, High));

   function u16_narrow_saturate_u8
     (Low, High : Flyology_SIMD.Wide.U16x16) return Flyology_SIMD.Wide.U8x32 is
     (Native.Narrow_Saturate (Low, High));

   function i16_narrow_saturate_i8
     (Low, High : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.I8x32 is
     (Native.Narrow_Saturate (Low, High));

   function u32_narrow_saturate_u16
     (Low, High : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.U16x16 is
     (Native.Narrow_Saturate (Low, High));

   function i32_narrow_saturate_i16
     (Low, High : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.I16x16 is
     (Native.Narrow_Saturate (Low, High));

   function u64_narrow_saturate_u32
     (Low, High : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.U32x8 is
     (Native.Narrow_Saturate (Low, High));

   function i64_narrow_saturate_i32
     (Low, High : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.I32x8 is
     (Native.Narrow_Saturate (Low, High));

   function i16_narrow_saturate_u8
     (Low, High : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.U8x32 is
     (Native.Narrow_Saturate (Low, High));

   function i32_narrow_saturate_u16
     (Low, High : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.U16x16 is
     (Native.Narrow_Saturate (Low, High));

   function i64_narrow_saturate_u32
     (Low, High : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.U32x8 is
     (Native.Narrow_Saturate (Low, High));

   function f64_narrow_round_f32
     (Low, High : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.F32x8 is
     (Native.Narrow_Round (Low, High));

   function i8_convert_saturate_u8
     (Value : Flyology_SIMD.Wide.I8x32) return Flyology_SIMD.Wide.U8x32 is
     (Native.Convert_Saturate (Value));

   function u8_convert_saturate_i8
     (Value : Flyology_SIMD.Wide.U8x32) return Flyology_SIMD.Wide.I8x32 is
     (Native.Convert_Saturate (Value));

   function i16_convert_saturate_u16
     (Value : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.U16x16 is
     (Native.Convert_Saturate (Value));

   function u16_convert_saturate_i16
     (Value : Flyology_SIMD.Wide.U16x16) return Flyology_SIMD.Wide.I16x16 is
     (Native.Convert_Saturate (Value));

   function i32_convert_saturate_u32
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.U32x8 is
     (Native.Convert_Saturate (Value));

   function u32_convert_saturate_i32
     (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.I32x8 is
     (Native.Convert_Saturate (Value));

   function i64_convert_saturate_u64
     (Value : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.U64x4 is
     (Native.Convert_Saturate (Value));

   function u64_convert_saturate_i64
     (Value : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.I64x4 is
     (Native.Convert_Saturate (Value));
   function I32_To_F32
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.F32x8 is
     (Native.Convert_Round (Value));
   function U32_To_F32
     (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.F32x8 is
     (Native.Convert_Round (Value));
   function I64_To_F64
     (Value : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.F64x4 is
     (Native.Convert_Round (Value));
   function U64_To_F64
     (Value : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.F64x4 is
     (Native.Convert_Round (Value));
   function F32_To_I32
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.I32x8 is
     (Native.Convert_Truncate_Saturate (Value));
   function F32_To_U32
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.U32x8 is
     (Native.Convert_Truncate_Saturate (Value));
   function F64_To_I64
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.I64x4 is
     (Native.Convert_Truncate_Saturate (Value));
   function F64_To_U64
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.U64x4 is
     (Native.Convert_Truncate_Saturate (Value));
end Wide_Numeric_Conversion_Codegen_Probe;
