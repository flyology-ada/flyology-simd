with Flyology_SIMD.Backends.Native;
with Interfaces;

package body Flyology_SIMD.Wide.Byte_Mechanism is
   pragma
     Compile_Time_Error
       (True, "FLYOLOGY_SIMD_WIDE_BACKEND=avx2 requires x86_64 and " & "FLYOLOGY_SIMD_AVX2=enabled");
   package Native renames Flyology_SIMD.Backends.Native;
   use type Interfaces.Unsigned_32;

   function Add_Wrap (Left, Right : U8x32) return U8x32
   is ((Low => Native.Add_Wrap (Left.Low, Right.Low), High => Native.Add_Wrap (Left.High, Right.High)));
   function Add_Wrap (Left, Right : I8x32) return I8x32
   is ((Native.Add_Wrap (Left.Low, Right.Low), Native.Add_Wrap (Left.High, Right.High)));
   function Subtract_Wrap (Left, Right : U8x32) return U8x32
   is ((Native.Subtract_Wrap (Left.Low, Right.Low), Native.Subtract_Wrap (Left.High, Right.High)));
   function Subtract_Wrap (Left, Right : I8x32) return I8x32
   is ((Native.Subtract_Wrap (Left.Low, Right.Low), Native.Subtract_Wrap (Left.High, Right.High)));
   function Multiply_Wrap (Left, Right : U8x32) return U8x32
   is ((Native.Multiply_Wrap (Left.Low, Right.Low), Native.Multiply_Wrap (Left.High, Right.High)));
   function Multiply_Wrap (Left, Right : I8x32) return I8x32
   is ((Native.Multiply_Wrap (Left.Low, Right.Low), Native.Multiply_Wrap (Left.High, Right.High)));
   function Add_Saturate (Left, Right : U8x32) return U8x32
   is ((Native.Add_Saturate (Left.Low, Right.Low), Native.Add_Saturate (Left.High, Right.High)));
   function Add_Saturate (Left, Right : I8x32) return I8x32
   is ((Native.Add_Saturate (Left.Low, Right.Low), Native.Add_Saturate (Left.High, Right.High)));
   function Subtract_Saturate (Left, Right : U8x32) return U8x32
   is ((Native.Subtract_Saturate (Left.Low, Right.Low), Native.Subtract_Saturate (Left.High, Right.High)));
   function Subtract_Saturate (Left, Right : I8x32) return I8x32
   is ((Native.Subtract_Saturate (Left.Low, Right.Low), Native.Subtract_Saturate (Left.High, Right.High)));
   function Bitwise_And (Left, Right : U8x32) return U8x32
   is ((Native.Bitwise_And (Left.Low, Right.Low), Native.Bitwise_And (Left.High, Right.High)));
   function Bitwise_And (Left, Right : I8x32) return I8x32
   is ((Native.Bitwise_And (Left.Low, Right.Low), Native.Bitwise_And (Left.High, Right.High)));
   function Bitwise_Or (Left, Right : U8x32) return U8x32
   is ((Native.Bitwise_Or (Left.Low, Right.Low), Native.Bitwise_Or (Left.High, Right.High)));
   function Bitwise_Or (Left, Right : I8x32) return I8x32
   is ((Native.Bitwise_Or (Left.Low, Right.Low), Native.Bitwise_Or (Left.High, Right.High)));
   function Bitwise_Xor (Left, Right : U8x32) return U8x32
   is ((Native.Bitwise_Xor (Left.Low, Right.Low), Native.Bitwise_Xor (Left.High, Right.High)));
   function Bitwise_Xor (Left, Right : I8x32) return I8x32
   is ((Native.Bitwise_Xor (Left.Low, Right.Low), Native.Bitwise_Xor (Left.High, Right.High)));
   function Bitwise_Not (Value : U8x32) return U8x32
   is ((Native.Bitwise_Not (Value.Low), Native.Bitwise_Not (Value.High)));
   function Bitwise_Not (Value : I8x32) return I8x32
   is ((Native.Bitwise_Not (Value.Low), Native.Bitwise_Not (Value.High)));
   function Min (Left, Right : U8x32) return U8x32
   is ((Native.Min (Left.Low, Right.Low), Native.Min (Left.High, Right.High)));
   function Min (Left, Right : I8x32) return I8x32
   is ((Native.Min (Left.Low, Right.Low), Native.Min (Left.High, Right.High)));
   function Max (Left, Right : U8x32) return U8x32
   is ((Native.Max (Left.Low, Right.Low), Native.Max (Left.High, Right.High)));
   function Max (Left, Right : I8x32) return I8x32
   is ((Native.Max (Left.Low, Right.Low), Native.Max (Left.High, Right.High)));

   function Combine (Low, High : Interfaces.Unsigned_16) return Mask_Bits_8x32
   is (Mask_Bits_8x32 (Low) or Interfaces.Shift_Left (Mask_Bits_8x32 (High), 16));
   function Equal (Left, Right : U8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Equal (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Equal (Left.High, Right.High))));
   function Equal (Left, Right : I8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Equal (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Equal (Left.High, Right.High))));
   function Less_Than (Left, Right : U8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Less_Than (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Less_Than (Left.High, Right.High))));
   function Less_Than (Left, Right : I8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Less_Than (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Less_Than (Left.High, Right.High))));
   function Less_Equal (Left, Right : U8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Less_Equal (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Less_Equal (Left.High, Right.High))));
   function Less_Equal (Left, Right : I8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Less_Equal (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Less_Equal (Left.High, Right.High))));
   function Greater_Than (Left, Right : U8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Greater_Than (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Greater_Than (Left.High, Right.High))));
   function Greater_Than (Left, Right : I8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Greater_Than (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Greater_Than (Left.High, Right.High))));
   function Greater_Equal (Left, Right : U8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Greater_Equal (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Greater_Equal (Left.High, Right.High))));
   function Greater_Equal (Left, Right : I8x32) return Mask_Bits_8x32
   is (Combine
         (Native.To_Bit_Mask (Native.Greater_Equal (Left.Low, Right.Low)),
          Native.To_Bit_Mask (Native.Greater_Equal (Left.High, Right.High))));
   function Select_Value (Bits : Mask_Bits_8x32; If_True, If_False : U8x32) return U8x32
   is ((Native.Select_Value
          (Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Bits and 16#FFFF#)), If_True.Low, If_False.Low),
        Native.Select_Value
          (Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Bits, 16))),
           If_True.High,
           If_False.High)));
   function Select_Value (Bits : Mask_Bits_8x32; If_True, If_False : I8x32) return I8x32
   is ((Native.Select_Value
          (Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Bits and 16#FFFF#)), If_True.Low, If_False.Low),
        Native.Select_Value
          (Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Bits, 16))),
           If_True.High,
           If_False.High)));
end Flyology_SIMD.Wide.Byte_Mechanism;
