package body Flyology_SIMD.Wide.Permute_Mechanism is
   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : U8x32) return U8x32 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : U8x32) return U8x32 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U8x32) return U8x32 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U8x32) return U8x32 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U8x32) return U8x32 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : I8x32) return I8x32 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : I8x32) return I8x32 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I8x32) return I8x32 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I8x32) return I8x32 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I8x32) return I8x32 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : U16x16) return U16x16 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : U16x16) return U16x16 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U16x16) return U16x16 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U16x16) return U16x16 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U16x16) return U16x16 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : I16x16) return I16x16 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : I16x16) return I16x16 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I16x16) return I16x16 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I16x16) return I16x16 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I16x16) return I16x16 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : U32x8) return U32x8 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : U32x8) return U32x8 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U32x8) return U32x8 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U32x8) return U32x8 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U32x8) return U32x8 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : I32x8) return I32x8 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : I32x8) return I32x8 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I32x8) return I32x8 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I32x8) return I32x8 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I32x8) return I32x8 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : U64x4) return U64x4 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : U64x4) return U64x4 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U64x4) return U64x4 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U64x4) return U64x4 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U64x4) return U64x4 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : I64x4) return I64x4 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : I64x4) return I64x4 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : I64x4) return I64x4 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : I64x4) return I64x4 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : I64x4) return I64x4 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4 is
     (Flyology_SIMD.Wide.Permute_Lanes (Value, Map));
   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4 is
     (Flyology_SIMD.Wide.Permute_Lanes (Left, Right, Map));
   function Reverse_Lanes (Value : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Reverse_Lanes (Value));
   function Interleave_Low (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Deinterleave_Odd (Left, Right));
   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_Low (Value, Count));
   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4 is
     (Flyology_SIMD.Wide.Slide_Lanes_Toward_High (Value, Count));
end Flyology_SIMD.Wide.Permute_Mechanism;
