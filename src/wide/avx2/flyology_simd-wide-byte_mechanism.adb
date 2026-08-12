with Flyology_SIMD.Wide.Byte_AVX2_Leaf;

package body Flyology_SIMD.Wide.Byte_Mechanism is
   package Leaf renames Flyology_SIMD.Wide.Byte_AVX2_Leaf;

   function Add_Wrap (Left, Right : U8x32) return U8x32 is
     (Leaf.Add_Wrap (Left, Right));
   function Add_Wrap (Left, Right : I8x32) return I8x32 is
     (Leaf.Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : U8x32) return U8x32 is
     (Leaf.Subtract_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : I8x32) return I8x32 is
     (Leaf.Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U8x32) return U8x32 is
     (Leaf.Multiply_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : I8x32) return I8x32 is
     (Leaf.Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U8x32) return U8x32 is
     (Leaf.Add_Saturate (Left, Right));
   function Add_Saturate (Left, Right : I8x32) return I8x32 is
     (Leaf.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U8x32) return U8x32 is
     (Leaf.Subtract_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I8x32) return I8x32 is
     (Leaf.Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U8x32) return U8x32 is
     (Leaf.Bitwise_And (Left, Right));
   function Bitwise_And (Left, Right : I8x32) return I8x32 is
     (Leaf.Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : U8x32) return U8x32 is
     (Leaf.Bitwise_Or (Left, Right));
   function Bitwise_Or (Left, Right : I8x32) return I8x32 is
     (Leaf.Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U8x32) return U8x32 is
     (Leaf.Bitwise_Xor (Left, Right));
   function Bitwise_Xor (Left, Right : I8x32) return I8x32 is
     (Leaf.Bitwise_Xor (Left, Right));
   function Bitwise_Not (Value : U8x32) return U8x32 is
     (Leaf.Bitwise_Not (Value));
   function Bitwise_Not (Value : I8x32) return I8x32 is
     (Leaf.Bitwise_Not (Value));
   function Min (Left, Right : U8x32) return U8x32 is
     (Leaf.Min (Left, Right));
   function Min (Left, Right : I8x32) return I8x32 is
     (Leaf.Min (Left, Right));
   function Max (Left, Right : U8x32) return U8x32 is
     (Leaf.Max (Left, Right));
   function Max (Left, Right : I8x32) return I8x32 is
     (Leaf.Max (Left, Right));
end Flyology_SIMD.Wide.Byte_Mechanism;
