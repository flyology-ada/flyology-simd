with Flyology_SIMD;

package U8_Value_Codegen_Probe is
   function Add_Wrap
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Subtract_Wrap
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Multiply_Wrap
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Add_Saturate
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Subtract_Saturate
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Bitwise_And
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Bitwise_Or
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Bitwise_Xor
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function Less_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function Less_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function Greater_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function Greater_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function Min
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Max
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Interleave_Low
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Interleave_High
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Deinterleave_Even
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Bitwise_Not
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Reduce_Add_Wrap
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8;
   function Reduce_Min
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8;
   function Reduce_Max
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8;
   function Reverse_Bytes
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Reverse_Lanes
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
end U8_Value_Codegen_Probe;
