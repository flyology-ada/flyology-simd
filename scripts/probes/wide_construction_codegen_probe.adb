with Flyology_SIMD.Wide.Native;

package body Wide_Construction_Codegen_Probe is
   package Native renames Flyology_SIMD.Wide.Native;

   function U8_Zero return Flyology_SIMD.Wide.U8x32 is (Native.Zero);
   function U8_Splat (Value : Flyology_SIMD.U8) return Flyology_SIMD.Wide.U8x32 is (Native.Splat (Value));
   function U8_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_U8x32) return Flyology_SIMD.Wide.U8x32 is (Native.From_Lanes (Values));
   function U8_To_Lanes (Value : Flyology_SIMD.Wide.U8x32) return Flyology_SIMD.Wide.Lane_Values_U8x32 is (Native.To_Lanes (Value));
   function U8_Extract (Value : Flyology_SIMD.Wide.U8x32; Lane : Flyology_SIMD.Wide.Lane_Index_8x32) return Flyology_SIMD.U8 is (Native.Extract (Value, Lane));
   function U8_Replace (Value : Flyology_SIMD.Wide.U8x32; Lane : Flyology_SIMD.Wide.Lane_Index_8x32; With_Value : Flyology_SIMD.U8) return Flyology_SIMD.Wide.U8x32 is (Native.Replace (Value, Lane, With_Value));

   function I8_Zero return Flyology_SIMD.Wide.I8x32 is (Native.Zero);
   function I8_Splat (Value : Flyology_SIMD.I8) return Flyology_SIMD.Wide.I8x32 is (Native.Splat (Value));
   function I8_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_I8x32) return Flyology_SIMD.Wide.I8x32 is (Native.From_Lanes (Values));
   function I8_To_Lanes (Value : Flyology_SIMD.Wide.I8x32) return Flyology_SIMD.Wide.Lane_Values_I8x32 is (Native.To_Lanes (Value));
   function I8_Extract (Value : Flyology_SIMD.Wide.I8x32; Lane : Flyology_SIMD.Wide.Lane_Index_8x32) return Flyology_SIMD.I8 is (Native.Extract (Value, Lane));
   function I8_Replace (Value : Flyology_SIMD.Wide.I8x32; Lane : Flyology_SIMD.Wide.Lane_Index_8x32; With_Value : Flyology_SIMD.I8) return Flyology_SIMD.Wide.I8x32 is (Native.Replace (Value, Lane, With_Value));

   function U16_Zero return Flyology_SIMD.Wide.U16x16 is (Native.Zero);
   function U16_Splat (Value : Flyology_SIMD.U16) return Flyology_SIMD.Wide.U16x16 is (Native.Splat (Value));
   function U16_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_U16x16) return Flyology_SIMD.Wide.U16x16 is (Native.From_Lanes (Values));
   function U16_To_Lanes (Value : Flyology_SIMD.Wide.U16x16) return Flyology_SIMD.Wide.Lane_Values_U16x16 is (Native.To_Lanes (Value));
   function U16_Extract (Value : Flyology_SIMD.Wide.U16x16; Lane : Flyology_SIMD.Wide.Lane_Index_16x16) return Flyology_SIMD.U16 is (Native.Extract (Value, Lane));
   function U16_Replace (Value : Flyology_SIMD.Wide.U16x16; Lane : Flyology_SIMD.Wide.Lane_Index_16x16; With_Value : Flyology_SIMD.U16) return Flyology_SIMD.Wide.U16x16 is (Native.Replace (Value, Lane, With_Value));

   function I16_Zero return Flyology_SIMD.Wide.I16x16 is (Native.Zero);
   function I16_Splat (Value : Flyology_SIMD.I16) return Flyology_SIMD.Wide.I16x16 is (Native.Splat (Value));
   function I16_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_I16x16) return Flyology_SIMD.Wide.I16x16 is (Native.From_Lanes (Values));
   function I16_To_Lanes (Value : Flyology_SIMD.Wide.I16x16) return Flyology_SIMD.Wide.Lane_Values_I16x16 is (Native.To_Lanes (Value));
   function I16_Extract (Value : Flyology_SIMD.Wide.I16x16; Lane : Flyology_SIMD.Wide.Lane_Index_16x16) return Flyology_SIMD.I16 is (Native.Extract (Value, Lane));
   function I16_Replace (Value : Flyology_SIMD.Wide.I16x16; Lane : Flyology_SIMD.Wide.Lane_Index_16x16; With_Value : Flyology_SIMD.I16) return Flyology_SIMD.Wide.I16x16 is (Native.Replace (Value, Lane, With_Value));

   function U32_Zero return Flyology_SIMD.Wide.U32x8 is (Native.Zero);
   function U32_Splat (Value : Flyology_SIMD.U32) return Flyology_SIMD.Wide.U32x8 is (Native.Splat (Value));
   function U32_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_U32x8) return Flyology_SIMD.Wide.U32x8 is (Native.From_Lanes (Values));
   function U32_To_Lanes (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.Lane_Values_U32x8 is (Native.To_Lanes (Value));
   function U32_Extract (Value : Flyology_SIMD.Wide.U32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8) return Flyology_SIMD.U32 is (Native.Extract (Value, Lane));
   function U32_Replace (Value : Flyology_SIMD.Wide.U32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8; With_Value : Flyology_SIMD.U32) return Flyology_SIMD.Wide.U32x8 is (Native.Replace (Value, Lane, With_Value));

   function I32_Zero return Flyology_SIMD.Wide.I32x8 is (Native.Zero);
   function I32_Splat (Value : Flyology_SIMD.I32) return Flyology_SIMD.Wide.I32x8 is (Native.Splat (Value));
   function I32_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_I32x8) return Flyology_SIMD.Wide.I32x8 is (Native.From_Lanes (Values));
   function I32_To_Lanes (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.Lane_Values_I32x8 is (Native.To_Lanes (Value));
   function I32_Extract (Value : Flyology_SIMD.Wide.I32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8) return Flyology_SIMD.I32 is (Native.Extract (Value, Lane));
   function I32_Replace (Value : Flyology_SIMD.Wide.I32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8; With_Value : Flyology_SIMD.I32) return Flyology_SIMD.Wide.I32x8 is (Native.Replace (Value, Lane, With_Value));

   function U64_Zero return Flyology_SIMD.Wide.U64x4 is (Native.Zero);
   function U64_Splat (Value : Flyology_SIMD.U64) return Flyology_SIMD.Wide.U64x4 is (Native.Splat (Value));
   function U64_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_U64x4) return Flyology_SIMD.Wide.U64x4 is (Native.From_Lanes (Values));
   function U64_To_Lanes (Value : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.Lane_Values_U64x4 is (Native.To_Lanes (Value));
   function U64_Extract (Value : Flyology_SIMD.Wide.U64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4) return Flyology_SIMD.U64 is (Native.Extract (Value, Lane));
   function U64_Replace (Value : Flyology_SIMD.Wide.U64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4; With_Value : Flyology_SIMD.U64) return Flyology_SIMD.Wide.U64x4 is (Native.Replace (Value, Lane, With_Value));

   function I64_Zero return Flyology_SIMD.Wide.I64x4 is (Native.Zero);
   function I64_Splat (Value : Flyology_SIMD.I64) return Flyology_SIMD.Wide.I64x4 is (Native.Splat (Value));
   function I64_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_I64x4) return Flyology_SIMD.Wide.I64x4 is (Native.From_Lanes (Values));
   function I64_To_Lanes (Value : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.Lane_Values_I64x4 is (Native.To_Lanes (Value));
   function I64_Extract (Value : Flyology_SIMD.Wide.I64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4) return Flyology_SIMD.I64 is (Native.Extract (Value, Lane));
   function I64_Replace (Value : Flyology_SIMD.Wide.I64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4; With_Value : Flyology_SIMD.I64) return Flyology_SIMD.Wide.I64x4 is (Native.Replace (Value, Lane, With_Value));

   function F32_Zero return Flyology_SIMD.Wide.F32x8 is (Native.Zero);
   function F32_Splat (Value : Flyology_SIMD.F32) return Flyology_SIMD.Wide.F32x8 is (Native.Splat (Value));
   function F32_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_F32x8) return Flyology_SIMD.Wide.F32x8 is (Native.From_Lanes (Values));
   function F32_To_Lanes (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.Lane_Values_F32x8 is (Native.To_Lanes (Value));
   function F32_Extract (Value : Flyology_SIMD.Wide.F32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8) return Flyology_SIMD.F32 is (Native.Extract (Value, Lane));
   function F32_Replace (Value : Flyology_SIMD.Wide.F32x8; Lane : Flyology_SIMD.Wide.Lane_Index_32x8; With_Value : Flyology_SIMD.F32) return Flyology_SIMD.Wide.F32x8 is (Native.Replace (Value, Lane, With_Value));

   function F64_Zero return Flyology_SIMD.Wide.F64x4 is (Native.Zero);
   function F64_Splat (Value : Flyology_SIMD.F64) return Flyology_SIMD.Wide.F64x4 is (Native.Splat (Value));
   function F64_From_Lanes (Values : Flyology_SIMD.Wide.Lane_Values_F64x4) return Flyology_SIMD.Wide.F64x4 is (Native.From_Lanes (Values));
   function F64_To_Lanes (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.Lane_Values_F64x4 is (Native.To_Lanes (Value));
   function F64_Extract (Value : Flyology_SIMD.Wide.F64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4) return Flyology_SIMD.F64 is (Native.Extract (Value, Lane));
   function F64_Replace (Value : Flyology_SIMD.Wide.F64x4; Lane : Flyology_SIMD.Wide.Lane_Index_64x4; With_Value : Flyology_SIMD.F64) return Flyology_SIMD.Wide.F64x4 is (Native.Replace (Value, Lane, With_Value));

end Wide_Construction_Codegen_Probe;
