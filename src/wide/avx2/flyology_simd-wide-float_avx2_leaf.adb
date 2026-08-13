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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
         Volatile => True);
      return Result;
   end Divide;
   function Min_Number (Left, Right : F32x8) return F32x8 is
      Result : F32x8;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm0, %%ymm6" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm7" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm2, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm6, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm7, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrld $9, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrld $9, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
         Volatile => True);
      return Result;
   end Min_Number;
   function Max_Number (Left, Right : F32x8) return F32x8 is
      Result : F32x8;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm0, %%ymm6" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm7" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm6, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm7, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrld $9, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $24, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrld $1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpslld $9, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrld $9, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
         Volatile => True);
      return Result;
   end Max_Number;
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
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
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
         Volatile => True);
      return Result;
   end Divide;
   function Min_Number (Left, Right : F64x4) return F64x4 is
      Result : F64x4;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm0, %%ymm6" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm7" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm0, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm0, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm2, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm6, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm7, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $63, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $12, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $63, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $12, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
         Volatile => True);
      return Result;
   end Min_Number;
   function Max_Number (Left, Right : F64x4) return F64x4 is
      Result : F64x4;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm0, %%ymm6" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm7" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm4, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm0, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm0, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm4, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm6, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm7, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm2, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm7, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $63, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $12, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $53, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm1, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm2, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpslld $31, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpcmpgtd %%ymm3, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufd $0xA0, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpor %%ymm1, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsllq $12, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufd $0xF5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpsrad $31, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm6, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqd %%ymm3, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsllq $63, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpsrlq $12, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm4, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm5, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm0, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqa %%ymm3, %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm0, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,memory",
         Volatile => True);
      return Result;
   end Max_Number;
end Flyology_SIMD.Wide.Float_AVX2_Leaf;
