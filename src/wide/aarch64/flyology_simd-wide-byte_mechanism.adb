with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Wide.Byte_Mechanism is
   package Native renames Flyology_SIMD.Backends.Native;

   function Add_Wrap (Left, Right : U8x32) return U8x32 is
     ((Native.Add_Wrap (Left.Low, Right.Low),
       Native.Add_Wrap (Left.High, Right.High)));
   function Add_Wrap (Left, Right : I8x32) return I8x32 is
     ((Native.Add_Wrap (Left.Low, Right.Low),
       Native.Add_Wrap (Left.High, Right.High)));
   function Subtract_Wrap (Left, Right : U8x32) return U8x32 is
     ((Native.Subtract_Wrap (Left.Low, Right.Low),
       Native.Subtract_Wrap (Left.High, Right.High)));
   function Subtract_Wrap (Left, Right : I8x32) return I8x32 is
     ((Native.Subtract_Wrap (Left.Low, Right.Low),
       Native.Subtract_Wrap (Left.High, Right.High)));
   function Multiply_Wrap (Left, Right : U8x32) return U8x32 is
     ((Native.Multiply_Wrap (Left.Low, Right.Low),
       Native.Multiply_Wrap (Left.High, Right.High)));
   function Multiply_Wrap (Left, Right : I8x32) return I8x32 is
     ((Native.Multiply_Wrap (Left.Low, Right.Low),
       Native.Multiply_Wrap (Left.High, Right.High)));
   function Add_Saturate (Left, Right : U8x32) return U8x32 is
     ((Native.Add_Saturate (Left.Low, Right.Low),
       Native.Add_Saturate (Left.High, Right.High)));
   function Add_Saturate (Left, Right : I8x32) return I8x32 is
     ((Native.Add_Saturate (Left.Low, Right.Low),
       Native.Add_Saturate (Left.High, Right.High)));
   function Subtract_Saturate (Left, Right : U8x32) return U8x32 is
     ((Native.Subtract_Saturate (Left.Low, Right.Low),
       Native.Subtract_Saturate (Left.High, Right.High)));
   function Subtract_Saturate (Left, Right : I8x32) return I8x32 is
     ((Native.Subtract_Saturate (Left.Low, Right.Low),
       Native.Subtract_Saturate (Left.High, Right.High)));
   function Bitwise_And (Left, Right : U8x32) return U8x32 is
     ((Native.Bitwise_And (Left.Low, Right.Low),
       Native.Bitwise_And (Left.High, Right.High)));
   function Bitwise_And (Left, Right : I8x32) return I8x32 is
     ((Native.Bitwise_And (Left.Low, Right.Low),
       Native.Bitwise_And (Left.High, Right.High)));
   function Bitwise_Or (Left, Right : U8x32) return U8x32 is
     ((Native.Bitwise_Or (Left.Low, Right.Low),
       Native.Bitwise_Or (Left.High, Right.High)));
   function Bitwise_Or (Left, Right : I8x32) return I8x32 is
     ((Native.Bitwise_Or (Left.Low, Right.Low),
       Native.Bitwise_Or (Left.High, Right.High)));
   function Bitwise_Xor (Left, Right : U8x32) return U8x32 is
     ((Native.Bitwise_Xor (Left.Low, Right.Low),
       Native.Bitwise_Xor (Left.High, Right.High)));
   function Bitwise_Xor (Left, Right : I8x32) return I8x32 is
     ((Native.Bitwise_Xor (Left.Low, Right.Low),
       Native.Bitwise_Xor (Left.High, Right.High)));
   function Bitwise_Not (Value : U8x32) return U8x32 is
     ((Native.Bitwise_Not (Value.Low), Native.Bitwise_Not (Value.High)));
   function Bitwise_Not (Value : I8x32) return I8x32 is
     ((Native.Bitwise_Not (Value.Low), Native.Bitwise_Not (Value.High)));
   function Min (Left, Right : U8x32) return U8x32 is
     ((Native.Min (Left.Low, Right.Low), Native.Min (Left.High, Right.High)));
   function Min (Left, Right : I8x32) return I8x32 is
     ((Native.Min (Left.Low, Right.Low), Native.Min (Left.High, Right.High)));
   function Max (Left, Right : U8x32) return U8x32 is
     ((Native.Max (Left.Low, Right.Low), Native.Max (Left.High, Right.High)));
   function Max (Left, Right : I8x32) return I8x32 is
     ((Native.Max (Left.Low, Right.Low), Native.Max (Left.High, Right.High)));
end Flyology_SIMD.Wide.Byte_Mechanism;
