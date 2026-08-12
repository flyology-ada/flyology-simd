with System.Machine_Code;

package body Flyology_SIMD.Wide.Float_Reduce_Mechanism is
   use System.Machine_Code;

   function Reduce_Add (Value : F32x8) return F32 is
      Result : F32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov s2, wzr" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s0" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[1]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[2]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[3]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s1" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[1]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[2]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[3]" & ASCII.LF & ASCII.HT &
           "fadd s2, s2, s3" & ASCII.LF & ASCII.HT &
           "str s2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Add;

   function Reduce_Min_Number (Value : F32x8) return F32 is
      Result : F32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov s2, s0" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[1]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[2]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[3]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s1" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[1]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[2]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[3]" & ASCII.LF & ASCII.HT &
           "fminnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "str s2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Min_Number;

   function Reduce_Max_Number (Value : F32x8) return F32 is
      Result : F32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov s2, s0" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[2]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v0.s[3]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s1" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[2]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "dup v3.4s, v1.s[3]" & ASCII.LF & ASCII.HT &
           "fmaxnm s2, s2, s3" & ASCII.LF & ASCII.HT &
           "str s2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Max_Number;

   function Reduce_Add (Value : F64x4) return F64 is
      Result : F64;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov d2, xzr" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d0" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v0.d[1]" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d3" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d1" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v1.d[1]" & ASCII.LF & ASCII.HT &
           "fadd d2, d2, d3" & ASCII.LF & ASCII.HT &
           "str d2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Add;

   function Reduce_Min_Number (Value : F64x4) return F64 is
      Result : F64;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov d2, d0" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v0.d[1]" & ASCII.LF & ASCII.HT &
           "fminnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "fminnm d2, d2, d1" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v1.d[1]" & ASCII.LF & ASCII.HT &
           "fminnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "str d2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Min_Number;

   function Reduce_Max_Number (Value : F64x4) return F64 is
      Result : F64;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "fmov d2, d0" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v0.d[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "fmaxnm d2, d2, d1" & ASCII.LF & ASCII.HT &
           "dup v3.2d, v1.d[1]" & ASCII.LF & ASCII.HT &
           "fmaxnm d2, d2, d3" & ASCII.LF & ASCII.HT &
           "str d2, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Reduce_Max_Number;
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
