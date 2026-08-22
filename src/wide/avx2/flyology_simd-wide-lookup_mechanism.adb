with System.Machine_Code;

package body Flyology_SIMD.Wide.Lookup_Mechanism is
   use System.Machine_Code;

   function Table_Lookup_32 (Table, Indices : U8x32) return U8x32 is
      type Byte_Vector is array (Natural range 0 .. 31) of U8 with Pack, Size => 256;
      Lane_Bias  : aliased constant Byte_Vector := [0 .. 15 => 0, 16 .. 31 => 16];
      Sixteen    : aliased constant U8 := 16;
      Thirty_One : aliased constant U8 := 31;
      Result     : U8x32;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0"
           & ASCII.LF
           & ASCII.HT
           & "vmovdqu (%2), %%ymm1"
           & ASCII.LF
           & ASCII.HT
           & "vpshufb %%ymm1, %%ymm0, %%ymm2"
           & ASCII.LF
           & ASCII.HT
           & "vperm2i128 $1, %%ymm0, %%ymm0, %%ymm3"
           & ASCII.LF
           & ASCII.HT
           & "vpshufb %%ymm1, %%ymm3, %%ymm3"
           & ASCII.LF
           & ASCII.HT
           & "vmovdqu (%3), %%ymm4"
           & ASCII.LF
           & ASCII.HT
           & "vpxor %%ymm4, %%ymm1, %%ymm4"
           & ASCII.LF
           & ASCII.HT
           & "vpbroadcastb (%4), %%ymm5"
           & ASCII.LF
           & ASCII.HT
           & "vpand %%ymm5, %%ymm4, %%ymm4"
           & ASCII.LF
           & ASCII.HT
           & "vpxor %%ymm5, %%ymm5, %%ymm5"
           & ASCII.LF
           & ASCII.HT
           & "vpcmpeqb %%ymm5, %%ymm4, %%ymm4"
           & ASCII.LF
           & ASCII.HT
           & "vpand %%ymm4, %%ymm2, %%ymm2"
           & ASCII.LF
           & ASCII.HT
           & "vpandn %%ymm3, %%ymm4, %%ymm3"
           & ASCII.LF
           & ASCII.HT
           & "vpor %%ymm3, %%ymm2, %%ymm2"
           & ASCII.LF
           & ASCII.HT
           & "vpbroadcastb (%5), %%ymm4"
           & ASCII.LF
           & ASCII.HT
           & "vpsubusb %%ymm4, %%ymm1, %%ymm1"
           & ASCII.LF
           & ASCII.HT
           & "vpcmpeqb %%ymm5, %%ymm1, %%ymm1"
           & ASCII.LF
           & ASCII.HT
           & "vpand %%ymm1, %%ymm2, %%ymm2"
           & ASCII.LF
           & ASCII.HT
           & "vmovdqu %%ymm2, (%0)"
           & ASCII.LF
           & ASCII.HT
           & "vzeroupper",
         Inputs   =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Table'Address),
            System.Address'Asm_Input ("r", Indices'Address),
            System.Address'Asm_Input ("r", Lane_Bias'Address),
            System.Address'Asm_Input ("r", Sixteen'Address),
            System.Address'Asm_Input ("r", Thirty_One'Address)],
         Clobber  => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,memory",
         Volatile => True);
      return Result;
   end Table_Lookup_32;
end Flyology_SIMD.Wide.Lookup_Mechanism;
