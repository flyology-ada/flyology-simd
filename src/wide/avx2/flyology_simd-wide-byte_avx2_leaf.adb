with System.Machine_Code;

package body Flyology_SIMD.Wide.Byte_AVX2_Leaf is
   use System.Machine_Code;

   generic
      type Vector_Type is private;
      Instruction : String;
   function Binary_Operation
     (Left, Right : Vector_Type) return Vector_Type;

   function Binary_Operation
     (Left, Right : Vector_Type) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,memory",
         Volatile => True);
      return Result;
   end Binary_Operation;

   generic
      type Vector_Type is private;
      Instruction : String;
   function Unary_Operation (Value : Vector_Type) return Vector_Type;

   function Unary_Operation (Value : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "ymm0,ymm1,ymm2,memory",
         Volatile => True);
      return Result;
   end Unary_Operation;

   Multiply_Bytes : constant String :=
     "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
     "vpsrlw $8, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
     "vpand %%ymm2, %%ymm0, %%ymm3" & ASCII.LF & ASCII.HT &
     "vpand %%ymm2, %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
     "vpmullw %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
     "vpand %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
     "vpsrlw $8, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
     "vpsrlw $8, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
     "vpmullw %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
     "vpsllw $8, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
     "vpor %%ymm3, %%ymm0, %%ymm0";

   function U8_Add_Wrap is new Binary_Operation
     (U8x32, "vpaddb %%ymm1, %%ymm0, %%ymm0");
   function I8_Add_Wrap is new Binary_Operation
     (I8x32, "vpaddb %%ymm1, %%ymm0, %%ymm0");
   function U8_Subtract_Wrap is new Binary_Operation
     (U8x32, "vpsubb %%ymm1, %%ymm0, %%ymm0");
   function I8_Subtract_Wrap is new Binary_Operation
     (I8x32, "vpsubb %%ymm1, %%ymm0, %%ymm0");
   function U8_Multiply_Wrap is new Binary_Operation
     (U8x32, Multiply_Bytes);
   function I8_Multiply_Wrap is new Binary_Operation
     (I8x32, Multiply_Bytes);
   function U8_Add_Saturate is new Binary_Operation
     (U8x32, "vpaddusb %%ymm1, %%ymm0, %%ymm0");
   function I8_Add_Saturate is new Binary_Operation
     (I8x32, "vpaddsb %%ymm1, %%ymm0, %%ymm0");
   function U8_Subtract_Saturate is new Binary_Operation
     (U8x32, "vpsubusb %%ymm1, %%ymm0, %%ymm0");
   function I8_Subtract_Saturate is new Binary_Operation
     (I8x32, "vpsubsb %%ymm1, %%ymm0, %%ymm0");
   function U8_And is new Binary_Operation
     (U8x32, "vpand %%ymm1, %%ymm0, %%ymm0");
   function I8_And is new Binary_Operation
     (I8x32, "vpand %%ymm1, %%ymm0, %%ymm0");
   function U8_Or is new Binary_Operation
     (U8x32, "vpor %%ymm1, %%ymm0, %%ymm0");
   function I8_Or is new Binary_Operation
     (I8x32, "vpor %%ymm1, %%ymm0, %%ymm0");
   function U8_Xor is new Binary_Operation
     (U8x32, "vpxor %%ymm1, %%ymm0, %%ymm0");
   function I8_Xor is new Binary_Operation
     (I8x32, "vpxor %%ymm1, %%ymm0, %%ymm0");
   function U8_Not is new Unary_Operation
     (U8x32,
      "vpcmpeqd %%ymm1, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
      "vpxor %%ymm1, %%ymm0, %%ymm0");
   function I8_Not is new Unary_Operation
     (I8x32,
      "vpcmpeqd %%ymm1, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
      "vpxor %%ymm1, %%ymm0, %%ymm0");
   function U8_Min is new Binary_Operation
     (U8x32, "vpminub %%ymm1, %%ymm0, %%ymm0");
   function I8_Min is new Binary_Operation
     (I8x32, "vpminsb %%ymm1, %%ymm0, %%ymm0");
   function U8_Max is new Binary_Operation
     (U8x32, "vpmaxub %%ymm1, %%ymm0, %%ymm0");
   function I8_Max is new Binary_Operation
     (I8x32, "vpmaxsb %%ymm1, %%ymm0, %%ymm0");

   pragma Inline_Always
     (U8_Add_Wrap, I8_Add_Wrap, U8_Subtract_Wrap, I8_Subtract_Wrap,
      U8_Multiply_Wrap, I8_Multiply_Wrap, U8_Add_Saturate,
      I8_Add_Saturate, U8_Subtract_Saturate, I8_Subtract_Saturate,
      U8_And, I8_And, U8_Or, I8_Or, U8_Xor, I8_Xor, U8_Not, I8_Not,
      U8_Min, I8_Min, U8_Max, I8_Max);

   function Add_Wrap (Left, Right : U8x32) return U8x32 is
     (U8_Add_Wrap (Left, Right));
   function Add_Wrap (Left, Right : I8x32) return I8x32 is
     (I8_Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : U8x32) return U8x32 is
     (U8_Subtract_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : I8x32) return I8x32 is
     (I8_Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U8x32) return U8x32 is
     (U8_Multiply_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : I8x32) return I8x32 is
     (I8_Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U8x32) return U8x32 is
     (U8_Add_Saturate (Left, Right));
   function Add_Saturate (Left, Right : I8x32) return I8x32 is
     (I8_Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U8x32) return U8x32 is
     (U8_Subtract_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I8x32) return I8x32 is
     (I8_Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U8x32) return U8x32 is
     (U8_And (Left, Right));
   function Bitwise_And (Left, Right : I8x32) return I8x32 is
     (I8_And (Left, Right));
   function Bitwise_Or (Left, Right : U8x32) return U8x32 is
     (U8_Or (Left, Right));
   function Bitwise_Or (Left, Right : I8x32) return I8x32 is
     (I8_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U8x32) return U8x32 is
     (U8_Xor (Left, Right));
   function Bitwise_Xor (Left, Right : I8x32) return I8x32 is
     (I8_Xor (Left, Right));
   function Bitwise_Not (Value : U8x32) return U8x32 is
     (U8_Not (Value));
   function Bitwise_Not (Value : I8x32) return I8x32 is
     (I8_Not (Value));
   function Min (Left, Right : U8x32) return U8x32 is
     (U8_Min (Left, Right));
   function Min (Left, Right : I8x32) return I8x32 is
     (I8_Min (Left, Right));
   function Max (Left, Right : U8x32) return U8x32 is
     (U8_Max (Left, Right));
   function Max (Left, Right : I8x32) return I8x32 is
     (I8_Max (Left, Right));
end Flyology_SIMD.Wide.Byte_AVX2_Leaf;
