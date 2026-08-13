with Flyology_SIMD.Backends.Native;

package body U8_Value_Codegen_Probe is
   function Add_Wrap
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Add_Wrap (Left, Right));

   function Subtract_Wrap
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Subtract_Wrap (Left, Right));

   function Multiply_Wrap
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Multiply_Wrap (Left, Right));

   function Add_Saturate
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function Subtract_Saturate
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function Bitwise_And
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function Bitwise_Or
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function Bitwise_Xor
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));

   function Less_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));

   function Less_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));

   function Greater_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));

   function Greater_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));

   function Min
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function Max
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function Interleave_Low
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function Interleave_High
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function Deinterleave_Even
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function Bitwise_Not
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function Reduce_Add_Wrap
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function Reduce_Min
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function Reduce_Max
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function Reverse_Bytes
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Reverse_Bytes (Value));

   function Reverse_Lanes
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
end U8_Value_Codegen_Probe;
