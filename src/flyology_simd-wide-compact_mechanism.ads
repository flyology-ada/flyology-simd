private package Flyology_SIMD.Wide.Compact_Mechanism
  with Preelaborate
is
   --  Target-selected mechanism for Wide stable mask movement.

   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4
     with Inline_Always;
   --  Stably pack true-mask lanes and zero-fill the suffix.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4
     with Inline_Always;
   --  Place packed lanes at true-mask positions and zero-fill false positions.
   --  @param Value The input lanes.
   --  @param Mask The semantic selection mask.
   --  @return The moved lanes and defined zero fill.
end Flyology_SIMD.Wide.Compact_Mechanism;
