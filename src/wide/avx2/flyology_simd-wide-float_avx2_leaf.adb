with System.Machine_Code;

package body Flyology_SIMD.Wide.Float_AVX2_Leaf is
   use System.Machine_Code;

   function Add (Left, Right : F32x8) return F32x8 is
      Result : F32x8;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vaddps %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Add;
   function Subtract (Left, Right : F32x8) return F32x8 is
      Result : F32x8;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vsubps %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Subtract;
   function Multiply (Left, Right : F32x8) return F32x8 is
      Result : F32x8;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmulps %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Multiply;
   function Divide (Left, Right : F32x8) return F32x8 is
      Result : F32x8;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vdivps %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Divide;
   function Add (Left, Right : F64x4) return F64x4 is
      Result : F64x4;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vaddpd %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Add;
   function Subtract (Left, Right : F64x4) return F64x4 is
      Result : F64x4;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vsubpd %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Subtract;
   function Multiply (Left, Right : F64x4) return F64x4 is
      Result : F64x4;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmulpd %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Multiply;
   function Divide (Left, Right : F64x4) return F64x4 is
      Result : F64x4;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vdivpd %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Divide;
end Flyology_SIMD.Wide.Float_AVX2_Leaf;
