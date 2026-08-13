with Flyology_SIMD.Wide.Native;

package body Wide_Movement_Codegen_Probe is
   package Native renames Flyology_SIMD.Wide.Native;
   function u8x32_permute_1 (Value : Wide.U8x32; Map : Wide.Lane_Map_8x32) return Wide.U8x32 is
     (Native.Permute_Lanes (Value, Map));
   function u8x32_permute_2 (Left, Right : Wide.U8x32; Map : Wide.Two_Source_Lane_Map_8x32) return Wide.U8x32 is
     (Native.Permute_Lanes (Left, Right, Map));
   function u8x32_reverse (Value : Wide.U8x32) return Wide.U8x32 is
     (Native.Reverse_Lanes (Value));
   function u8x32_interleave_low (Left, Right : Wide.U8x32) return Wide.U8x32 is
     (Native.Interleave_Low (Left, Right));
   function u8x32_interleave_high (Left, Right : Wide.U8x32) return Wide.U8x32 is
     (Native.Interleave_High (Left, Right));
   function u8x32_deinterleave_even (Left, Right : Wide.U8x32) return Wide.U8x32 is
     (Native.Deinterleave_Even (Left, Right));
   function u8x32_deinterleave_odd (Left, Right : Wide.U8x32) return Wide.U8x32 is
     (Native.Deinterleave_Odd (Left, Right));
   function u8x32_slide_low (Value : Wide.U8x32; Count : Natural) return Wide.U8x32 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function u8x32_slide_high (Value : Wide.U8x32; Count : Natural) return Wide.U8x32 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function i8x32_permute_1 (Value : Wide.I8x32; Map : Wide.Lane_Map_8x32) return Wide.I8x32 is
     (Native.Permute_Lanes (Value, Map));
   function i8x32_permute_2 (Left, Right : Wide.I8x32; Map : Wide.Two_Source_Lane_Map_8x32) return Wide.I8x32 is
     (Native.Permute_Lanes (Left, Right, Map));
   function i8x32_reverse (Value : Wide.I8x32) return Wide.I8x32 is
     (Native.Reverse_Lanes (Value));
   function i8x32_interleave_low (Left, Right : Wide.I8x32) return Wide.I8x32 is
     (Native.Interleave_Low (Left, Right));
   function i8x32_interleave_high (Left, Right : Wide.I8x32) return Wide.I8x32 is
     (Native.Interleave_High (Left, Right));
   function i8x32_deinterleave_even (Left, Right : Wide.I8x32) return Wide.I8x32 is
     (Native.Deinterleave_Even (Left, Right));
   function i8x32_deinterleave_odd (Left, Right : Wide.I8x32) return Wide.I8x32 is
     (Native.Deinterleave_Odd (Left, Right));
   function i8x32_slide_low (Value : Wide.I8x32; Count : Natural) return Wide.I8x32 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function i8x32_slide_high (Value : Wide.I8x32; Count : Natural) return Wide.I8x32 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function u16x16_permute_1 (Value : Wide.U16x16; Map : Wide.Lane_Map_16x16) return Wide.U16x16 is
     (Native.Permute_Lanes (Value, Map));
   function u16x16_permute_2 (Left, Right : Wide.U16x16; Map : Wide.Two_Source_Lane_Map_16x16) return Wide.U16x16 is
     (Native.Permute_Lanes (Left, Right, Map));
   function u16x16_reverse (Value : Wide.U16x16) return Wide.U16x16 is
     (Native.Reverse_Lanes (Value));
   function u16x16_interleave_low (Left, Right : Wide.U16x16) return Wide.U16x16 is
     (Native.Interleave_Low (Left, Right));
   function u16x16_interleave_high (Left, Right : Wide.U16x16) return Wide.U16x16 is
     (Native.Interleave_High (Left, Right));
   function u16x16_deinterleave_even (Left, Right : Wide.U16x16) return Wide.U16x16 is
     (Native.Deinterleave_Even (Left, Right));
   function u16x16_deinterleave_odd (Left, Right : Wide.U16x16) return Wide.U16x16 is
     (Native.Deinterleave_Odd (Left, Right));
   function u16x16_slide_low (Value : Wide.U16x16; Count : Natural) return Wide.U16x16 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function u16x16_slide_high (Value : Wide.U16x16; Count : Natural) return Wide.U16x16 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function i16x16_permute_1 (Value : Wide.I16x16; Map : Wide.Lane_Map_16x16) return Wide.I16x16 is
     (Native.Permute_Lanes (Value, Map));
   function i16x16_permute_2 (Left, Right : Wide.I16x16; Map : Wide.Two_Source_Lane_Map_16x16) return Wide.I16x16 is
     (Native.Permute_Lanes (Left, Right, Map));
   function i16x16_reverse (Value : Wide.I16x16) return Wide.I16x16 is
     (Native.Reverse_Lanes (Value));
   function i16x16_interleave_low (Left, Right : Wide.I16x16) return Wide.I16x16 is
     (Native.Interleave_Low (Left, Right));
   function i16x16_interleave_high (Left, Right : Wide.I16x16) return Wide.I16x16 is
     (Native.Interleave_High (Left, Right));
   function i16x16_deinterleave_even (Left, Right : Wide.I16x16) return Wide.I16x16 is
     (Native.Deinterleave_Even (Left, Right));
   function i16x16_deinterleave_odd (Left, Right : Wide.I16x16) return Wide.I16x16 is
     (Native.Deinterleave_Odd (Left, Right));
   function i16x16_slide_low (Value : Wide.I16x16; Count : Natural) return Wide.I16x16 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function i16x16_slide_high (Value : Wide.I16x16; Count : Natural) return Wide.I16x16 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function u32x8_permute_1 (Value : Wide.U32x8; Map : Wide.Lane_Map_32x8) return Wide.U32x8 is
     (Native.Permute_Lanes (Value, Map));
   function u32x8_permute_2 (Left, Right : Wide.U32x8; Map : Wide.Two_Source_Lane_Map_32x8) return Wide.U32x8 is
     (Native.Permute_Lanes (Left, Right, Map));
   function u32x8_reverse (Value : Wide.U32x8) return Wide.U32x8 is
     (Native.Reverse_Lanes (Value));
   function u32x8_interleave_low (Left, Right : Wide.U32x8) return Wide.U32x8 is
     (Native.Interleave_Low (Left, Right));
   function u32x8_interleave_high (Left, Right : Wide.U32x8) return Wide.U32x8 is
     (Native.Interleave_High (Left, Right));
   function u32x8_deinterleave_even (Left, Right : Wide.U32x8) return Wide.U32x8 is
     (Native.Deinterleave_Even (Left, Right));
   function u32x8_deinterleave_odd (Left, Right : Wide.U32x8) return Wide.U32x8 is
     (Native.Deinterleave_Odd (Left, Right));
   function u32x8_slide_low (Value : Wide.U32x8; Count : Natural) return Wide.U32x8 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function u32x8_slide_high (Value : Wide.U32x8; Count : Natural) return Wide.U32x8 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function i32x8_permute_1 (Value : Wide.I32x8; Map : Wide.Lane_Map_32x8) return Wide.I32x8 is
     (Native.Permute_Lanes (Value, Map));
   function i32x8_permute_2 (Left, Right : Wide.I32x8; Map : Wide.Two_Source_Lane_Map_32x8) return Wide.I32x8 is
     (Native.Permute_Lanes (Left, Right, Map));
   function i32x8_reverse (Value : Wide.I32x8) return Wide.I32x8 is
     (Native.Reverse_Lanes (Value));
   function i32x8_interleave_low (Left, Right : Wide.I32x8) return Wide.I32x8 is
     (Native.Interleave_Low (Left, Right));
   function i32x8_interleave_high (Left, Right : Wide.I32x8) return Wide.I32x8 is
     (Native.Interleave_High (Left, Right));
   function i32x8_deinterleave_even (Left, Right : Wide.I32x8) return Wide.I32x8 is
     (Native.Deinterleave_Even (Left, Right));
   function i32x8_deinterleave_odd (Left, Right : Wide.I32x8) return Wide.I32x8 is
     (Native.Deinterleave_Odd (Left, Right));
   function i32x8_slide_low (Value : Wide.I32x8; Count : Natural) return Wide.I32x8 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function i32x8_slide_high (Value : Wide.I32x8; Count : Natural) return Wide.I32x8 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function u64x4_permute_1 (Value : Wide.U64x4; Map : Wide.Lane_Map_64x4) return Wide.U64x4 is
     (Native.Permute_Lanes (Value, Map));
   function u64x4_permute_2 (Left, Right : Wide.U64x4; Map : Wide.Two_Source_Lane_Map_64x4) return Wide.U64x4 is
     (Native.Permute_Lanes (Left, Right, Map));
   function u64x4_reverse (Value : Wide.U64x4) return Wide.U64x4 is
     (Native.Reverse_Lanes (Value));
   function u64x4_interleave_low (Left, Right : Wide.U64x4) return Wide.U64x4 is
     (Native.Interleave_Low (Left, Right));
   function u64x4_interleave_high (Left, Right : Wide.U64x4) return Wide.U64x4 is
     (Native.Interleave_High (Left, Right));
   function u64x4_deinterleave_even (Left, Right : Wide.U64x4) return Wide.U64x4 is
     (Native.Deinterleave_Even (Left, Right));
   function u64x4_deinterleave_odd (Left, Right : Wide.U64x4) return Wide.U64x4 is
     (Native.Deinterleave_Odd (Left, Right));
   function u64x4_slide_low (Value : Wide.U64x4; Count : Natural) return Wide.U64x4 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function u64x4_slide_high (Value : Wide.U64x4; Count : Natural) return Wide.U64x4 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function i64x4_permute_1 (Value : Wide.I64x4; Map : Wide.Lane_Map_64x4) return Wide.I64x4 is
     (Native.Permute_Lanes (Value, Map));
   function i64x4_permute_2 (Left, Right : Wide.I64x4; Map : Wide.Two_Source_Lane_Map_64x4) return Wide.I64x4 is
     (Native.Permute_Lanes (Left, Right, Map));
   function i64x4_reverse (Value : Wide.I64x4) return Wide.I64x4 is
     (Native.Reverse_Lanes (Value));
   function i64x4_interleave_low (Left, Right : Wide.I64x4) return Wide.I64x4 is
     (Native.Interleave_Low (Left, Right));
   function i64x4_interleave_high (Left, Right : Wide.I64x4) return Wide.I64x4 is
     (Native.Interleave_High (Left, Right));
   function i64x4_deinterleave_even (Left, Right : Wide.I64x4) return Wide.I64x4 is
     (Native.Deinterleave_Even (Left, Right));
   function i64x4_deinterleave_odd (Left, Right : Wide.I64x4) return Wide.I64x4 is
     (Native.Deinterleave_Odd (Left, Right));
   function i64x4_slide_low (Value : Wide.I64x4; Count : Natural) return Wide.I64x4 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function i64x4_slide_high (Value : Wide.I64x4; Count : Natural) return Wide.I64x4 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function f32x8_permute_1 (Value : Wide.F32x8; Map : Wide.Lane_Map_32x8) return Wide.F32x8 is
     (Native.Permute_Lanes (Value, Map));
   function f32x8_permute_2 (Left, Right : Wide.F32x8; Map : Wide.Two_Source_Lane_Map_32x8) return Wide.F32x8 is
     (Native.Permute_Lanes (Left, Right, Map));
   function f32x8_reverse (Value : Wide.F32x8) return Wide.F32x8 is
     (Native.Reverse_Lanes (Value));
   function f32x8_interleave_low (Left, Right : Wide.F32x8) return Wide.F32x8 is
     (Native.Interleave_Low (Left, Right));
   function f32x8_interleave_high (Left, Right : Wide.F32x8) return Wide.F32x8 is
     (Native.Interleave_High (Left, Right));
   function f32x8_deinterleave_even (Left, Right : Wide.F32x8) return Wide.F32x8 is
     (Native.Deinterleave_Even (Left, Right));
   function f32x8_deinterleave_odd (Left, Right : Wide.F32x8) return Wide.F32x8 is
     (Native.Deinterleave_Odd (Left, Right));
   function f32x8_slide_low (Value : Wide.F32x8; Count : Natural) return Wide.F32x8 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function f32x8_slide_high (Value : Wide.F32x8; Count : Natural) return Wide.F32x8 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
   function f64x4_permute_1 (Value : Wide.F64x4; Map : Wide.Lane_Map_64x4) return Wide.F64x4 is
     (Native.Permute_Lanes (Value, Map));
   function f64x4_permute_2 (Left, Right : Wide.F64x4; Map : Wide.Two_Source_Lane_Map_64x4) return Wide.F64x4 is
     (Native.Permute_Lanes (Left, Right, Map));
   function f64x4_reverse (Value : Wide.F64x4) return Wide.F64x4 is
     (Native.Reverse_Lanes (Value));
   function f64x4_interleave_low (Left, Right : Wide.F64x4) return Wide.F64x4 is
     (Native.Interleave_Low (Left, Right));
   function f64x4_interleave_high (Left, Right : Wide.F64x4) return Wide.F64x4 is
     (Native.Interleave_High (Left, Right));
   function f64x4_deinterleave_even (Left, Right : Wide.F64x4) return Wide.F64x4 is
     (Native.Deinterleave_Even (Left, Right));
   function f64x4_deinterleave_odd (Left, Right : Wide.F64x4) return Wide.F64x4 is
     (Native.Deinterleave_Odd (Left, Right));
   function f64x4_slide_low (Value : Wide.F64x4; Count : Natural) return Wide.F64x4 is
     (Native.Slide_Lanes_Toward_Low (Value, Count));
   function f64x4_slide_high (Value : Wide.F64x4; Count : Natural) return Wide.F64x4 is
     (Native.Slide_Lanes_Toward_High (Value, Count));
end Wide_Movement_Codegen_Probe;
