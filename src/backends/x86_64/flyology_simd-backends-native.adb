with System.Machine_Code;

package body Flyology_SIMD.Backends.Native is
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use System.Machine_Code;

   U8_Sign_Bits : aliased constant Lane_Values_8x16 := [others => 16#80#];
   U8_Weights : aliased constant Lane_Values_8x16 :=
     [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];

   generic
      Instruction : String;
   function U8_Binary (Left, Right : U8x16) return U8x16;
   function U8_Binary (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,memory",
         Volatile => True);
      return Result;
   end U8_Binary;

   generic
      Instruction : String;
   function U8_Unary (Value : U8x16) return U8x16;
   function U8_Unary (Value : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "xmm0,xmm1,xmm2,xmm3,memory", Volatile => True);
      return Result;
   end U8_Unary;

   function U8_Add_Wrap is new U8_Binary ("paddb %%xmm1, %%xmm0");
   function U8_Subtract_Wrap is new U8_Binary ("psubb %%xmm1, %%xmm0");
   function U8_Multiply_Wrap is new U8_Binary
     ("movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT &
      "movdqu %%xmm1, %%xmm4" & ASCII.LF & ASCII.HT &
      "movdqu %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT &
      "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
      "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT &
      "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
      "punpcklbw %%xmm3, %%xmm4" & ASCII.LF & ASCII.HT &
      "punpckhbw %%xmm3, %%xmm5" & ASCII.LF & ASCII.HT &
      "pmullw %%xmm4, %%xmm0" & ASCII.LF & ASCII.HT &
      "pmullw %%xmm5, %%xmm2" & ASCII.LF & ASCII.HT &
      "pcmpeqd %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
      "psrlw $8, %%xmm3" & ASCII.LF & ASCII.HT &
      "pand %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT &
      "pand %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
      "packuswb %%xmm2, %%xmm0");
   function U8_Add_Saturate is new U8_Binary ("paddusb %%xmm1, %%xmm0");
   function U8_Subtract_Saturate is new U8_Binary ("psubusb %%xmm1, %%xmm0");
   function U8_And is new U8_Binary ("pand %%xmm1, %%xmm0");
   pragma Inline_Always (U8_And);
   function U8_Or is new U8_Binary ("por %%xmm1, %%xmm0");
   function U8_Xor is new U8_Binary ("pxor %%xmm1, %%xmm0");
   function U8_Not is new U8_Unary
     ("pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT &
      "pxor %%xmm1, %%xmm0");
   function U8_Reverse is new U8_Unary
     ("movdqu %%xmm0, %%xmm1" & ASCII.LF & ASCII.HT &
      "psrlw $8, %%xmm0" & ASCII.LF & ASCII.HT &
      "psllw $8, %%xmm1" & ASCII.LF & ASCII.HT &
      "por %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
      "pshuflw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT &
      "pshufhw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT &
      "pshufd $0x4E, %%xmm0, %%xmm0");
   function U8_Interleave_Low is new U8_Binary
     ("punpcklbw %%xmm1, %%xmm0");
   function U8_Interleave_High is new U8_Binary
     ("punpckhbw %%xmm1, %%xmm0");
   function U8_Deinterleave_Even is new U8_Binary
     ("pcmpeqd %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT &
      "psrlw $8, %%xmm2" & ASCII.LF & ASCII.HT &
      "pand %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT &
      "pand %%xmm2, %%xmm1" & ASCII.LF & ASCII.HT &
      "packuswb %%xmm1, %%xmm0");
   function U8_Deinterleave_Odd is new U8_Binary
     ("psrlw $8, %%xmm0" & ASCII.LF & ASCII.HT &
      "psrlw $8, %%xmm1" & ASCII.LF & ASCII.HT &
      "packuswb %%xmm1, %%xmm0");

   function Equal_Mask (Left, Right : U8x16) return Interfaces.Unsigned_16 is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "pcmpeqb %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "pmovmskb %%xmm0, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs =>
           [System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "xmm0,xmm1,memory",
         Volatile => True);
      return Interfaces.Unsigned_16 (Result and 16#0000_FFFF#);
   end Equal_Mask;
   pragma Inline_Always (Equal_Mask);

   function Greater_Mask (Left, Right : U8x16) return Interfaces.Unsigned_16 is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "movdqu (%3), %%xmm2" & ASCII.LF & ASCII.HT &
           "pxor %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT &
           "pxor %%xmm2, %%xmm1" & ASCII.LF & ASCII.HT &
           "pcmpgtb %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "pmovmskb %%xmm0, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs =>
           [System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address),
            System.Address'Asm_Input ("r", U8_Sign_Bits'Address)],
         Clobber => "xmm0,xmm1,xmm2,memory", Volatile => True);
      return Interfaces.Unsigned_16 (Result and 16#0000_FFFF#);
   end Greater_Mask;

   function Zero return U8x16 is (Lanes => [others => 0]);
   function Splat (Value : U8) return U8x16 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_8x16) return U8x16 is (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U8x16) return Lane_Values_8x16 is (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8 is (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16 is (Flyology_SIMD.Replace (Value, Lane, With_Value));

   function Add_Wrap (Left, Right : U8x16) return U8x16 is
     (U8_Add_Wrap (Left, Right));

   function Add_Saturate (Left, Right : U8x16) return U8x16 is
     (U8_Add_Saturate (Left, Right));
   function Subtract_Wrap (Left, Right : U8x16) return U8x16 is
     (U8_Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U8x16) return U8x16 is
     (U8_Multiply_Wrap (Left, Right));
   function Subtract_Saturate (Left, Right : U8x16) return U8x16 is
     (U8_Subtract_Saturate (Left, Right));

   function Bitwise_And (Left, Right : U8x16) return U8x16 is
     (U8_And (Left, Right));
   function Bitwise_Or (Left, Right : U8x16) return U8x16 is
     (U8_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U8x16) return U8x16 is
     (U8_Xor (Left, Right));
   function Bitwise_Not (Value : U8x16) return U8x16 is (U8_Not (Value));
   function Shift_Left_Logical
     (Value : U8x16; Count : Natural) return U8x16
   is
      Result : U8x16;
      Local_Count : aliased Interfaces.Unsigned_32 :=
        Interfaces.Unsigned_32 (Count);
   begin
      if Count >= 8 then
         return Zero;
      end if;
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movd (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT &
           "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
           "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT &
           "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
           "psllw %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "psllw %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT &
           "pcmpeqd %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
           "psrlw $8, %%xmm3" & ASCII.LF & ASCII.HT &
           "pand %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT &
           "pand %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
           "packuswb %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Local_Count'Address)],
         Clobber => "xmm0,xmm1,xmm2,xmm3,memory", Volatile => True);
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical
     (Value : U8x16; Count : Natural) return U8x16
   is
      Result : U8x16;
      Local_Count : aliased Interfaces.Unsigned_32 :=
        Interfaces.Unsigned_32 (Count);
   begin
      if Count >= 8 then
         return Zero;
      end if;
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movd (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT &
           "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
           "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT &
           "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
           "psrlw %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "psrlw %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT &
           "packuswb %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Local_Count'Address)],
         Clobber => "xmm0,xmm1,xmm2,xmm3,memory", Volatile => True);
      return Result;
   end Shift_Right_Logical;

   function Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Equal_Mask (Left, Right)));
   function Less_Than (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask
        (Greater_Mask (Left => Right, Right => Left)));
   function Less_Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask
        (Greater_Mask (Left => Right, Right => Left)
         or Equal_Mask (Left, Right)));
   function Greater_Than (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Greater_Mask (Left, Right)));
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask
        (Greater_Mask (Left, Right) or Equal_Mask (Left, Right)));
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16 is
      Result : U8x16;
      Bits : aliased Interfaces.Unsigned_32 :=
        Interfaces.Unsigned_32 (To_Bit_Mask (Mask));
   begin
      Asm
        (Template =>
           "movd (%1), %%xmm2" & ASCII.LF & ASCII.HT &
           "punpcklbw %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT &
           "punpcklwd %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT &
           "punpckldq %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT &
           "pand (%2), %%xmm2" & ASCII.LF & ASCII.HT &
           "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
           "pcmpeqb %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
           "pcmpeqd %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT &
           "pxor %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm2, %%xmm3" & ASCII.LF & ASCII.HT &
           "pand (%3), %%xmm3" & ASCII.LF & ASCII.HT &
           "pandn (%4), %%xmm2" & ASCII.LF & ASCII.HT &
           "por %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm2, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Bits'Address),
            System.Address'Asm_Input ("r", U8_Weights'Address),
            System.Address'Asm_Input ("r", If_True'Address),
            System.Address'Asm_Input ("r", If_False'Address)],
         Clobber => "xmm2,xmm3,memory", Volatile => True);
      return Result;
   end Select_Value;
   function Min (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "pminub %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "xmm0,xmm1,memory", Volatile => True);
      return Result;
   end Min;

   function Max (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "pmaxub %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "xmm0,xmm1,memory", Volatile => True);
      return Result;
   end Max;
   function Horizontal_Sum (Value : U8x16) return Natural is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "pxor %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT &
           "psadbw %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "movhlps %%xmm0, %%xmm1" & ASCII.LF & ASCII.HT &
           "paddq %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "movd %%xmm0, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => System.Address'Asm_Input ("r", Value'Address),
         Clobber => "xmm0,xmm1,memory", Volatile => True);
      return Natural (Result);
   end Horizontal_Sum;
   function Reduce_Add_Wrap (Value : U8x16) return U8 is
     (U8 (Horizontal_Sum (Value) mod 256));
   function Reduce_Min (Value : U8x16) return U8 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U8x16) return U8 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Reverse_Bytes (Value : U8x16) return U8x16 is (U8_Reverse (Value));
   function Reverse_Lanes (Value : U8x16) return U8x16 is
     (Reverse_Bytes (Value));
   function Interleave_Low (Left, Right : U8x16) return U8x16 is
     (U8_Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U8x16) return U8x16 is
     (U8_Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U8x16) return U8x16 is
     (U8_Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16 is
     (U8_Deinterleave_Odd (Left, Right));
   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16 is (Bits => Bits);
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Mask.Bits);
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => Left.Bits and Right.Bits);
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => Left.Bits or Right.Bits);
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => Left.Bits xor Right.Bits);
   function Mask_Not (Value : Mask_8x16) return Mask_8x16 is
     (Bits => not Value.Bits);
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean is (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_8x16) return Boolean is (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_8x16) return Boolean is (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_8x16) return Boolean is (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16 is (Flyology_SIMD.Population_Count (Mask));
   function Load (Data : Byte_Array; Start : Natural) return U8x16 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16) is begin Store_Unaligned (Data, Start, Value); end Store;

   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Data (Start)'Address)],
         Clobber => "xmm0,memory",
         Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Data (Start)'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "xmm0,memory",
         Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Data (Start)'Address)],
         Clobber => "xmm0,memory", Volatile => True);
      return Result;
   end Load_Aligned;
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqa %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Data (Start)'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "xmm0,memory", Volatile => True);
   end Store_Aligned;
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16) is
   begin
      Flyology_SIMD.Store_Partial (Data, Start, Count, Value);
   end Store_Partial;

   --  BEGIN GENERATED FULL-FAMILY X86 BODIES
   Sign_8 : aliased constant Lane_Values_8x16 := [others => 16#80#];
   Sign_16 : aliased constant Lane_Values_8x16 := [for Lane in Lane_Index_8x16 => (if Lane mod 2 = 1 then 16#80# else 0)];
   Sign_32 : aliased constant Lane_Values_8x16 := [for Lane in Lane_Index_8x16 => (if Lane mod 4 = 3 then 16#80# else 0)];
   Weights_X86_8 : aliased constant Lane_Values_8x16 := [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];
   Weights_X86_16 : aliased constant Lane_Values_U16x8 := [1, 2, 4, 8, 16, 32, 64, 128];
   Weights_X86_32 : aliased constant Lane_Values_U32x4 := [1, 2, 4, 8];
   Weights_X86_64 : aliased constant Lane_Values_U64x2 := [1, 2];

   generic
      type Vector_Type is private;
      Instruction : String;
   function SSE2_Binary_128 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128 (Left, Right : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address)], Clobber => "xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory", Volatile => True);
      return Result;
   end SSE2_Binary_128;

   generic
      type Vector_Type is private;
      Instruction : String;
   function SSE2_Unary_128 (Value : Vector_Type) return Vector_Type;
   function SSE2_Unary_128 (Value : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,xmm1,xmm2,memory", Volatile => True);
      return Result;
   end SSE2_Unary_128;

   generic
      type Vector_Type is private;
      Lane_Bits : Positive;
      Instruction : String;
   function SSE2_Compare_128 (Left, Right : Vector_Type; Sign : System.Address) return Interfaces.Unsigned_16;
   function SSE2_Compare_128 (Left, Right : Vector_Type; Sign : System.Address) return Interfaces.Unsigned_16 is
      Raw, Packed : Interfaces.Unsigned_32;
   begin
      Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT & "movdqu (%3), %%xmm7" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "pmovmskb %%xmm0, %0", Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Raw), Inputs => [System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address), System.Address'Asm_Input ("r", Sign)], Clobber => "xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory", Volatile => True);
      case Lane_Bits is
         when 8 => Packed := Raw and 16#FFFF#;
         when 16 => Packed := Interfaces.Shift_Right (Raw, 1) and 16#5555#; Packed := (Packed or Interfaces.Shift_Right (Packed, 1)) and 16#3333#; Packed := (Packed or Interfaces.Shift_Right (Packed, 2)) and 16#0F0F#; Packed := (Packed or Interfaces.Shift_Right (Packed, 4)) and 16#00FF#;
         when 32 => Packed := Interfaces.Shift_Right (Raw, 3) and 16#1111#; Packed := (Packed or Interfaces.Shift_Right (Packed, 3)) and 16#0303#; Packed := (Packed or Interfaces.Shift_Right (Packed, 6)) and 16#000F#;
         when others => Packed := Interfaces.Shift_Right (Raw, 7) and 16#0101#; Packed := (Packed or Interfaces.Shift_Right (Packed, 7)) and 3;
      end case;
      return Interfaces.Unsigned_16 (Packed);
   end SSE2_Compare_128;

   generic
      type Vector_Type is private;
      Instruction : String;
   function SSE2_Shift_128 (Value : Vector_Type; Count : Interfaces.Unsigned_32) return Vector_Type;
   function SSE2_Shift_128 (Value : Vector_Type; Count : Interfaces.Unsigned_32) return Vector_Type is
      Result : Vector_Type; Local_Count : aliased Interfaces.Unsigned_32 := Count;
   begin
      Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movd (%2), %%xmm1" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address), System.Address'Asm_Input ("r", Local_Count'Address)], Clobber => "xmm0,xmm1,xmm2,memory", Volatile => True);
      return Result;
   end SSE2_Shift_128;

   generic
      type Vector_Type is private;
      Lane_Bits : Positive;
   function SSE2_Select_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type;
   function SSE2_Select_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type is
      Result : Vector_Type; Local_Bits : aliased Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (Bits);
      Expand : constant String := (case Lane_Bits is when 8 => "punpcklbw %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "punpckldq %%xmm2, %%xmm2", when 16 => "pshuflw $0, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm2, %%xmm2", when 32 => "pshufd $0, %%xmm2, %%xmm2", when others => "punpcklqdq %%xmm2, %%xmm2");
      Compare : constant String := (if Lane_Bits = 8 then "pcmpeqb" elsif Lane_Bits = 16 then "pcmpeqw" else "pcmpeqd");
      Replicate_64 : constant String := (if Lane_Bits = 64 then "pshufd $0xA0, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT else "");
   begin
      Asm (Template => "movd (%1), %%xmm2" & ASCII.LF & ASCII.HT & Expand & ASCII.LF & ASCII.HT & "pand (%2), %%xmm2" & ASCII.LF & ASCII.HT & "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & Compare & " %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & Replicate_64 & "pcmpeqd %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm2, %%xmm3" & ASCII.LF & ASCII.HT & "pand (%3), %%xmm3" & ASCII.LF & ASCII.HT & "pandn (%4), %%xmm2" & ASCII.LF & ASCII.HT & "por %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm2, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Local_Bits'Address), System.Address'Asm_Input ("r", Weights), System.Address'Asm_Input ("r", If_True'Address), System.Address'Asm_Input ("r", If_False'Address)], Clobber => "xmm2,xmm3,memory", Volatile => True);
      return Result;
   end SSE2_Select_128;

   function Bit_Cast (Value : U8x16) return I8x16 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : I8x16) return U8x16 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : U16x8) return I16x8 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : I16x8) return U16x8 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : U32x4) return I32x4 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : U32x4) return F32x4 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : I32x4) return U32x4 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : I32x4) return F32x4 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : F32x4) return U32x4 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : F32x4) return I32x4 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : U64x2) return I64x2 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : U64x2) return F64x2 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : I64x2) return U64x2 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : I64x2) return F64x2 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : F64x2) return U64x2 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Bit_Cast (Value : F64x2) return I64x2 is
     (Flyology_SIMD.Bit_Cast (Value));
   function Widen_Low (Value : U8x16) return U16x8 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : U8x16) return U16x8 is
     (Flyology_SIMD.Widen_High (Value));
   function Widen_Low (Value : I8x16) return I16x8 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : I8x16) return I16x8 is
     (Flyology_SIMD.Widen_High (Value));
   function Widen_Low (Value : U16x8) return U32x4 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : U16x8) return U32x4 is
     (Flyology_SIMD.Widen_High (Value));
   function Widen_Low (Value : I16x8) return I32x4 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : I16x8) return I32x4 is
     (Flyology_SIMD.Widen_High (Value));
   function Widen_Low (Value : U32x4) return U64x2 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : U32x4) return U64x2 is
     (Flyology_SIMD.Widen_High (Value));
   function Widen_Low (Value : I32x4) return I64x2 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : I32x4) return I64x2 is
     (Flyology_SIMD.Widen_High (Value));
   function Widen_Low (Value : F32x4) return F64x2 is
     (Flyology_SIMD.Widen_Low (Value));
   function Widen_High (Value : F32x4) return F64x2 is
     (Flyology_SIMD.Widen_High (Value));
   function Narrow_Truncate (Low, High : U16x8) return U8x16 is
     (Flyology_SIMD.Narrow_Truncate (Low, High));
   function Narrow_Saturate (Low, High : U16x8) return U8x16 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Truncate (Low, High : I16x8) return I8x16 is
     (Flyology_SIMD.Narrow_Truncate (Low, High));
   function Narrow_Saturate (Low, High : I16x8) return I8x16 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Truncate (Low, High : U32x4) return U16x8 is
     (Flyology_SIMD.Narrow_Truncate (Low, High));
   function Narrow_Saturate (Low, High : U32x4) return U16x8 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Truncate (Low, High : I32x4) return I16x8 is
     (Flyology_SIMD.Narrow_Truncate (Low, High));
   function Narrow_Saturate (Low, High : I32x4) return I16x8 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Truncate (Low, High : U64x2) return U32x4 is
     (Flyology_SIMD.Narrow_Truncate (Low, High));
   function Narrow_Saturate (Low, High : U64x2) return U32x4 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Truncate (Low, High : I64x2) return I32x4 is
     (Flyology_SIMD.Narrow_Truncate (Low, High));
   function Narrow_Saturate (Low, High : I64x2) return I32x4 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Saturate (Low, High : I16x8) return U8x16 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Saturate (Low, High : I32x4) return U16x8 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Narrow_Saturate (Low, High : I64x2) return U32x4 is
     (Flyology_SIMD.Narrow_Saturate (Low, High));
   function Native_Add_Wrap_I8x16 is new SSE2_Binary_128 (I8x16, "paddb %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : I8x16) return I8x16 is (Native_Add_Wrap_I8x16 (Left, Right));
   function Native_Subtract_Wrap_I8x16 is new SSE2_Binary_128 (I8x16, "psubb %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : I8x16) return I8x16 is (Native_Subtract_Wrap_I8x16 (Left, Right));
   function Native_Multiply_Wrap_I8x16 is new SSE2_Binary_128 (I8x16, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm4" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT & "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm3, %%xmm4" & ASCII.LF & ASCII.HT & "punpckhbw %%xmm3, %%xmm5" & ASCII.LF & ASCII.HT & "pmullw %%xmm4, %%xmm0" & ASCII.LF & ASCII.HT & "pmullw %%xmm5, %%xmm2" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm6, %%xmm6" & ASCII.LF & ASCII.HT & "psrlw $8, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm0" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm2" & ASCII.LF & ASCII.HT & "packuswb %%xmm2, %%xmm0");
   function Multiply_Wrap (Left, Right : I8x16) return I8x16 is (Native_Multiply_Wrap_I8x16 (Left, Right));
   function Native_Bitwise_And_I8x16 is new SSE2_Binary_128 (I8x16, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : I8x16) return I8x16 is (Native_Bitwise_And_I8x16 (Left, Right));
   function Native_Bitwise_Or_I8x16 is new SSE2_Binary_128 (I8x16, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Or_I8x16 (Left, Right));
   function Native_Bitwise_Xor_I8x16 is new SSE2_Binary_128 (I8x16, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Xor_I8x16 (Left, Right));
   function Native_Interleave_Low_I8x16 is new SSE2_Binary_128 (I8x16, "punpcklbw %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : I8x16) return I8x16 is (Native_Interleave_Low_I8x16 (Left, Right));
   function Native_Interleave_High_I8x16 is new SSE2_Binary_128 (I8x16, "punpckhbw %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : I8x16) return I8x16 is (Native_Interleave_High_I8x16 (Left, Right));
   function Native_Deinterleave_Even_I8x16 is new SSE2_Binary_128 (I8x16, "pcmpeqd %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "psrlw $8, %%xmm2" & ASCII.LF & ASCII.HT & "pand %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT & "pand %%xmm2, %%xmm1" & ASCII.LF & ASCII.HT & "packuswb %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Even_I8x16 (Left, Right));
   function Native_Deinterleave_Odd_I8x16 is new SSE2_Binary_128 (I8x16, "psrlw $8, %%xmm0" & ASCII.LF & ASCII.HT & "psrlw $8, %%xmm1" & ASCII.LF & ASCII.HT & "packuswb %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Odd_I8x16 (Left, Right));
   function Native_Add_Saturate_I8x16 is new SSE2_Binary_128 (I8x16, "paddsb %%xmm1, %%xmm0");
   function Add_Saturate (Left, Right : I8x16) return I8x16 is (Native_Add_Saturate_I8x16 (Left, Right));
   function Native_Subtract_Saturate_I8x16 is new SSE2_Binary_128 (I8x16, "psubsb %%xmm1, %%xmm0");
   function Subtract_Saturate (Left, Right : I8x16) return I8x16 is (Native_Subtract_Saturate_I8x16 (Left, Right));
   function Native_Not_I8x16 is new SSE2_Unary_128 (I8x16, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : I8x16) return I8x16 is (Native_Not_I8x16 (Value));
   function Native_Reverse_I8x16 is new SSE2_Unary_128 (I8x16, "movdqu %%xmm0, %%xmm1" & ASCII.LF & ASCII.HT & "psrlw $8, %%xmm0" & ASCII.LF & ASCII.HT & "psllw $8, %%xmm1" & ASCII.LF & ASCII.HT & "por %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "pshuflw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : I8x16) return I8x16 is (Native_Reverse_I8x16 (Value));
   function Compare_Equal_I8x16 is new SSE2_Compare_128 (I8x16, 8, "pcmpeqb %%xmm1, %%xmm0");
   function Compare_Greater_I8x16 is new SSE2_Compare_128 (I8x16, 8, "pcmpgtb %%xmm1, %%xmm0");
   function Native_Select_I8x16 is new SSE2_Select_128 (I8x16, 8);
   function Zero return I8x16 is (Flyology_SIMD.Zero);
   function Splat (Value : I8) return I8x16 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Native_SHL_I8x16 is new SSE2_Shift_128 (I8x16, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT & "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "psllw %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "psllw %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "psrlw $8, %%xmm3" & ASCII.LF & ASCII.HT & "pand %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT & "pand %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "packuswb %%xmm2, %%xmm0");
   function Native_SHR_I8x16 is new SSE2_Shift_128 (I8x16, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT & "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "psrlw %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "psrlw %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT & "packuswb %%xmm2, %%xmm0");
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16 is (if Count >= 8 then Flyology_SIMD.Zero else Native_SHL_I8x16 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16 is (if Count >= 8 then Flyology_SIMD.Zero else Native_SHR_I8x16 (Value, Interfaces.Unsigned_32 (Count)));
   function Native_SAR_I8x16 is new SSE2_Shift_128 (I8x16, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT & "punpckhbw %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "psllw $8, %%xmm0" & ASCII.LF & ASCII.HT & "psllw $8, %%xmm2" & ASCII.LF & ASCII.HT & "psraw $8, %%xmm0" & ASCII.LF & ASCII.HT & "psraw $8, %%xmm2" & ASCII.LF & ASCII.HT & "psraw %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "psraw %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT & "packsswb %%xmm2, %%xmm0");
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16 is (if Count >= 8 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SAR_I8x16 (Value, Interfaces.Unsigned_32 (Count)));
   function Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Equal_I8x16 (Left, Right, Sign_8'Address)));
   function Greater_Than (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_I8x16 (Left, Right, Sign_8'Address)));
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_I8x16 (Left, Right, Sign_8'Address) or Compare_Equal_I8x16 (Left, Right, Sign_8'Address)));
   function Less_Than (Left, Right : I8x16) return Mask_8x16 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I8x16) return Mask_8x16 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16 is (Native_Select_I8x16 (To_Bit_Mask (Mask), Weights_X86_8'Address, If_True, If_False));
   function Min (Left, Right : I8x16) return I8x16 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : I8x16) return I8x16 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Reduce_Add_Wrap (Value : I8x16) return I8 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I8x16) return I8 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I8x16) return I8 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 is
      Result : I8x16;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 is
      Result : I8x16;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_Wrap_U16x8 is new SSE2_Binary_128 (U16x8, "paddw %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : U16x8) return U16x8 is (Native_Add_Wrap_U16x8 (Left, Right));
   function Native_Subtract_Wrap_U16x8 is new SSE2_Binary_128 (U16x8, "psubw %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : U16x8) return U16x8 is (Native_Subtract_Wrap_U16x8 (Left, Right));
   function Native_Multiply_Wrap_U16x8 is new SSE2_Binary_128 (U16x8, "pmullw %%xmm1, %%xmm0");
   function Multiply_Wrap (Left, Right : U16x8) return U16x8 is (Native_Multiply_Wrap_U16x8 (Left, Right));
   function Native_Bitwise_And_U16x8 is new SSE2_Binary_128 (U16x8, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : U16x8) return U16x8 is (Native_Bitwise_And_U16x8 (Left, Right));
   function Native_Bitwise_Or_U16x8 is new SSE2_Binary_128 (U16x8, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Or_U16x8 (Left, Right));
   function Native_Bitwise_Xor_U16x8 is new SSE2_Binary_128 (U16x8, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Xor_U16x8 (Left, Right));
   function Native_Interleave_Low_U16x8 is new SSE2_Binary_128 (U16x8, "punpcklwd %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : U16x8) return U16x8 is (Native_Interleave_Low_U16x8 (Left, Right));
   function Native_Interleave_High_U16x8 is new SSE2_Binary_128 (U16x8, "punpckhwd %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : U16x8) return U16x8 is (Native_Interleave_High_U16x8 (Left, Right));
   function Native_Deinterleave_Even_U16x8 is new SSE2_Binary_128 (U16x8, "pshuflw $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Even_U16x8 (Left, Right));
   function Native_Deinterleave_Odd_U16x8 is new SSE2_Binary_128 (U16x8, "pshuflw $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshuflw $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Odd_U16x8 (Left, Right));
   function Native_Add_Saturate_U16x8 is new SSE2_Binary_128 (U16x8, "paddusw %%xmm1, %%xmm0");
   function Add_Saturate (Left, Right : U16x8) return U16x8 is (Native_Add_Saturate_U16x8 (Left, Right));
   function Native_Subtract_Saturate_U16x8 is new SSE2_Binary_128 (U16x8, "psubusw %%xmm1, %%xmm0");
   function Subtract_Saturate (Left, Right : U16x8) return U16x8 is (Native_Subtract_Saturate_U16x8 (Left, Right));
   function Native_Not_U16x8 is new SSE2_Unary_128 (U16x8, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : U16x8) return U16x8 is (Native_Not_U16x8 (Value));
   function Native_Reverse_U16x8 is new SSE2_Unary_128 (U16x8, "pshuflw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : U16x8) return U16x8 is (Native_Reverse_U16x8 (Value));
   function Compare_Equal_U16x8 is new SSE2_Compare_128 (U16x8, 16, "pcmpeqw %%xmm1, %%xmm0");
   function Compare_Greater_U16x8 is new SSE2_Compare_128 (U16x8, 16, "pxor %%xmm7, %%xmm0" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm1" & ASCII.LF & ASCII.HT & "pcmpgtw %%xmm1, %%xmm0");
   function Native_Select_U16x8 is new SSE2_Select_128 (U16x8, 16);
   function Zero return U16x8 is (Flyology_SIMD.Zero);
   function Splat (Value : U16) return U16x8 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Native_SHL_U16x8 is new SSE2_Shift_128 (U16x8, "psllw %%xmm1, %%xmm0");
   function Native_SHR_U16x8 is new SSE2_Shift_128 (U16x8, "psrlw %%xmm1, %%xmm0");
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8 is (if Count >= 16 then Flyology_SIMD.Zero else Native_SHL_U16x8 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8 is (if Count >= 16 then Flyology_SIMD.Zero else Native_SHR_U16x8 (Value, Interfaces.Unsigned_32 (Count)));
   function Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_U16x8 (Left, Right, Sign_16'Address))));
   function Greater_Than (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U16x8 (Left, Right, Sign_16'Address))));
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U16x8 (Left, Right, Sign_16'Address) or Compare_Equal_U16x8 (Left, Right, Sign_16'Address))));
   function Less_Than (Left, Right : U16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8 is (Native_Select_U16x8 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_16'Address, If_True, If_False));
   function Min (Left, Right : U16x8) return U16x8 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : U16x8) return U16x8 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Reduce_Add_Wrap (Value : U16x8) return U16 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U16x8) return U16 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U16x8) return U16 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 is
      Result : U16x8;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 is
      Result : U16x8;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_Wrap_I16x8 is new SSE2_Binary_128 (I16x8, "paddw %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : I16x8) return I16x8 is (Native_Add_Wrap_I16x8 (Left, Right));
   function Native_Subtract_Wrap_I16x8 is new SSE2_Binary_128 (I16x8, "psubw %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : I16x8) return I16x8 is (Native_Subtract_Wrap_I16x8 (Left, Right));
   function Native_Multiply_Wrap_I16x8 is new SSE2_Binary_128 (I16x8, "pmullw %%xmm1, %%xmm0");
   function Multiply_Wrap (Left, Right : I16x8) return I16x8 is (Native_Multiply_Wrap_I16x8 (Left, Right));
   function Native_Bitwise_And_I16x8 is new SSE2_Binary_128 (I16x8, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : I16x8) return I16x8 is (Native_Bitwise_And_I16x8 (Left, Right));
   function Native_Bitwise_Or_I16x8 is new SSE2_Binary_128 (I16x8, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Or_I16x8 (Left, Right));
   function Native_Bitwise_Xor_I16x8 is new SSE2_Binary_128 (I16x8, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Xor_I16x8 (Left, Right));
   function Native_Interleave_Low_I16x8 is new SSE2_Binary_128 (I16x8, "punpcklwd %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : I16x8) return I16x8 is (Native_Interleave_Low_I16x8 (Left, Right));
   function Native_Interleave_High_I16x8 is new SSE2_Binary_128 (I16x8, "punpckhwd %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : I16x8) return I16x8 is (Native_Interleave_High_I16x8 (Left, Right));
   function Native_Deinterleave_Even_I16x8 is new SSE2_Binary_128 (I16x8, "pshuflw $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Even_I16x8 (Left, Right));
   function Native_Deinterleave_Odd_I16x8 is new SSE2_Binary_128 (I16x8, "pshuflw $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshuflw $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Odd_I16x8 (Left, Right));
   function Native_Add_Saturate_I16x8 is new SSE2_Binary_128 (I16x8, "paddsw %%xmm1, %%xmm0");
   function Add_Saturate (Left, Right : I16x8) return I16x8 is (Native_Add_Saturate_I16x8 (Left, Right));
   function Native_Subtract_Saturate_I16x8 is new SSE2_Binary_128 (I16x8, "psubsw %%xmm1, %%xmm0");
   function Subtract_Saturate (Left, Right : I16x8) return I16x8 is (Native_Subtract_Saturate_I16x8 (Left, Right));
   function Native_Min_I16x8 is new SSE2_Binary_128 (I16x8, "pminsw %%xmm1, %%xmm0");
   function Min (Left, Right : I16x8) return I16x8 is (Native_Min_I16x8 (Left, Right));
   function Native_Max_I16x8 is new SSE2_Binary_128 (I16x8, "pmaxsw %%xmm1, %%xmm0");
   function Max (Left, Right : I16x8) return I16x8 is (Native_Max_I16x8 (Left, Right));
   function Native_Not_I16x8 is new SSE2_Unary_128 (I16x8, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : I16x8) return I16x8 is (Native_Not_I16x8 (Value));
   function Native_Reverse_I16x8 is new SSE2_Unary_128 (I16x8, "pshuflw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : I16x8) return I16x8 is (Native_Reverse_I16x8 (Value));
   function Compare_Equal_I16x8 is new SSE2_Compare_128 (I16x8, 16, "pcmpeqw %%xmm1, %%xmm0");
   function Compare_Greater_I16x8 is new SSE2_Compare_128 (I16x8, 16, "pcmpgtw %%xmm1, %%xmm0");
   function Native_Select_I16x8 is new SSE2_Select_128 (I16x8, 16);
   function Zero return I16x8 is (Flyology_SIMD.Zero);
   function Splat (Value : I16) return I16x8 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Native_SHL_I16x8 is new SSE2_Shift_128 (I16x8, "psllw %%xmm1, %%xmm0");
   function Native_SHR_I16x8 is new SSE2_Shift_128 (I16x8, "psrlw %%xmm1, %%xmm0");
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8 is (if Count >= 16 then Flyology_SIMD.Zero else Native_SHL_I16x8 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8 is (if Count >= 16 then Flyology_SIMD.Zero else Native_SHR_I16x8 (Value, Interfaces.Unsigned_32 (Count)));
   function Native_SAR_I16x8 is new SSE2_Shift_128 (I16x8, "psraw %%xmm1, %%xmm0");
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8 is (if Count >= 16 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SAR_I16x8 (Value, Interfaces.Unsigned_32 (Count)));
   function Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_I16x8 (Left, Right, Sign_16'Address))));
   function Greater_Than (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I16x8 (Left, Right, Sign_16'Address))));
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I16x8 (Left, Right, Sign_16'Address) or Compare_Equal_I16x8 (Left, Right, Sign_16'Address))));
   function Less_Than (Left, Right : I16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8 is (Native_Select_I16x8 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_16'Address, If_True, If_False));
   function Reduce_Add_Wrap (Value : I16x8) return I16 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I16x8) return I16 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I16x8) return I16 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 is
      Result : I16x8;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 is
      Result : I16x8;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_Wrap_U32x4 is new SSE2_Binary_128 (U32x4, "paddd %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : U32x4) return U32x4 is (Native_Add_Wrap_U32x4 (Left, Right));
   function Native_Subtract_Wrap_U32x4 is new SSE2_Binary_128 (U32x4, "psubd %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : U32x4) return U32x4 is (Native_Subtract_Wrap_U32x4 (Left, Right));
   function Native_Multiply_Wrap_U32x4 is new SSE2_Binary_128 (U32x4, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm2" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm3" & ASCII.LF & ASCII.HT & "pmuludq %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "pmuludq %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "punpckldq %%xmm2, %%xmm0");
   function Multiply_Wrap (Left, Right : U32x4) return U32x4 is (Native_Multiply_Wrap_U32x4 (Left, Right));
   function Native_Bitwise_And_U32x4 is new SSE2_Binary_128 (U32x4, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : U32x4) return U32x4 is (Native_Bitwise_And_U32x4 (Left, Right));
   function Native_Bitwise_Or_U32x4 is new SSE2_Binary_128 (U32x4, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Or_U32x4 (Left, Right));
   function Native_Bitwise_Xor_U32x4 is new SSE2_Binary_128 (U32x4, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Xor_U32x4 (Left, Right));
   function Native_Interleave_Low_U32x4 is new SSE2_Binary_128 (U32x4, "punpckldq %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : U32x4) return U32x4 is (Native_Interleave_Low_U32x4 (Left, Right));
   function Native_Interleave_High_U32x4 is new SSE2_Binary_128 (U32x4, "punpckhdq %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : U32x4) return U32x4 is (Native_Interleave_High_U32x4 (Left, Right));
   function Native_Deinterleave_Even_U32x4 is new SSE2_Binary_128 (U32x4, "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Even_U32x4 (Left, Right));
   function Native_Deinterleave_Odd_U32x4 is new SSE2_Binary_128 (U32x4, "pshufd $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Odd_U32x4 (Left, Right));
   function Native_Not_U32x4 is new SSE2_Unary_128 (U32x4, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : U32x4) return U32x4 is (Native_Not_U32x4 (Value));
   function Native_Reverse_U32x4 is new SSE2_Unary_128 (U32x4, "pshufd $0x1B, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : U32x4) return U32x4 is (Native_Reverse_U32x4 (Value));
   function Compare_Equal_U32x4 is new SSE2_Compare_128 (U32x4, 32, "pcmpeqd %%xmm1, %%xmm0");
   function Compare_Greater_U32x4 is new SSE2_Compare_128 (U32x4, 32, "pxor %%xmm7, %%xmm0" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm1" & ASCII.LF & ASCII.HT & "pcmpgtd %%xmm1, %%xmm0");
   function Native_Select_U32x4 is new SSE2_Select_128 (U32x4, 32);
   function Zero return U32x4 is (Flyology_SIMD.Zero);
   function Splat (Value : U32) return U32x4 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Saturate (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U32x4) return U32x4 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Native_SHL_U32x4 is new SSE2_Shift_128 (U32x4, "pslld %%xmm1, %%xmm0");
   function Native_SHR_U32x4 is new SSE2_Shift_128 (U32x4, "psrld %%xmm1, %%xmm0");
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4 is (if Count >= 32 then Flyology_SIMD.Zero else Native_SHL_U32x4 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4 is (if Count >= 32 then Flyology_SIMD.Zero else Native_SHR_U32x4 (Value, Interfaces.Unsigned_32 (Count)));
   function Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_U32x4 (Left, Right, Sign_32'Address))));
   function Greater_Than (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U32x4 (Left, Right, Sign_32'Address))));
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U32x4 (Left, Right, Sign_32'Address) or Compare_Equal_U32x4 (Left, Right, Sign_32'Address))));
   function Less_Than (Left, Right : U32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4 is (Native_Select_U32x4 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_32'Address, If_True, If_False));
   function Min (Left, Right : U32x4) return U32x4 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : U32x4) return U32x4 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Reduce_Add_Wrap (Value : U32x4) return U32 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U32x4) return U32 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U32x4) return U32 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 is
      Result : U32x4;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 is
      Result : U32x4;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_Wrap_I32x4 is new SSE2_Binary_128 (I32x4, "paddd %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : I32x4) return I32x4 is (Native_Add_Wrap_I32x4 (Left, Right));
   function Native_Subtract_Wrap_I32x4 is new SSE2_Binary_128 (I32x4, "psubd %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : I32x4) return I32x4 is (Native_Subtract_Wrap_I32x4 (Left, Right));
   function Native_Multiply_Wrap_I32x4 is new SSE2_Binary_128 (I32x4, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm2" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm3" & ASCII.LF & ASCII.HT & "pmuludq %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "pmuludq %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "punpckldq %%xmm2, %%xmm0");
   function Multiply_Wrap (Left, Right : I32x4) return I32x4 is (Native_Multiply_Wrap_I32x4 (Left, Right));
   function Native_Bitwise_And_I32x4 is new SSE2_Binary_128 (I32x4, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : I32x4) return I32x4 is (Native_Bitwise_And_I32x4 (Left, Right));
   function Native_Bitwise_Or_I32x4 is new SSE2_Binary_128 (I32x4, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Or_I32x4 (Left, Right));
   function Native_Bitwise_Xor_I32x4 is new SSE2_Binary_128 (I32x4, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Xor_I32x4 (Left, Right));
   function Native_Interleave_Low_I32x4 is new SSE2_Binary_128 (I32x4, "punpckldq %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : I32x4) return I32x4 is (Native_Interleave_Low_I32x4 (Left, Right));
   function Native_Interleave_High_I32x4 is new SSE2_Binary_128 (I32x4, "punpckhdq %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : I32x4) return I32x4 is (Native_Interleave_High_I32x4 (Left, Right));
   function Native_Deinterleave_Even_I32x4 is new SSE2_Binary_128 (I32x4, "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Even_I32x4 (Left, Right));
   function Native_Deinterleave_Odd_I32x4 is new SSE2_Binary_128 (I32x4, "pshufd $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Odd_I32x4 (Left, Right));
   function Native_Not_I32x4 is new SSE2_Unary_128 (I32x4, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : I32x4) return I32x4 is (Native_Not_I32x4 (Value));
   function Native_Reverse_I32x4 is new SSE2_Unary_128 (I32x4, "pshufd $0x1B, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : I32x4) return I32x4 is (Native_Reverse_I32x4 (Value));
   function Compare_Equal_I32x4 is new SSE2_Compare_128 (I32x4, 32, "pcmpeqd %%xmm1, %%xmm0");
   function Compare_Greater_I32x4 is new SSE2_Compare_128 (I32x4, 32, "pcmpgtd %%xmm1, %%xmm0");
   function Native_Select_I32x4 is new SSE2_Select_128 (I32x4, 32);
   function Zero return I32x4 is (Flyology_SIMD.Zero);
   function Splat (Value : I32) return I32x4 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Saturate (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I32x4) return I32x4 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Native_SHL_I32x4 is new SSE2_Shift_128 (I32x4, "pslld %%xmm1, %%xmm0");
   function Native_SHR_I32x4 is new SSE2_Shift_128 (I32x4, "psrld %%xmm1, %%xmm0");
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4 is (if Count >= 32 then Flyology_SIMD.Zero else Native_SHL_I32x4 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4 is (if Count >= 32 then Flyology_SIMD.Zero else Native_SHR_I32x4 (Value, Interfaces.Unsigned_32 (Count)));
   function Native_SAR_I32x4 is new SSE2_Shift_128 (I32x4, "psrad %%xmm1, %%xmm0");
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4 is (if Count >= 32 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SAR_I32x4 (Value, Interfaces.Unsigned_32 (Count)));
   function Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_I32x4 (Left, Right, Sign_32'Address))));
   function Greater_Than (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I32x4 (Left, Right, Sign_32'Address))));
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I32x4 (Left, Right, Sign_32'Address) or Compare_Equal_I32x4 (Left, Right, Sign_32'Address))));
   function Less_Than (Left, Right : I32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4 is (Native_Select_I32x4 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_32'Address, If_True, If_False));
   function Min (Left, Right : I32x4) return I32x4 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : I32x4) return I32x4 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Reduce_Add_Wrap (Value : I32x4) return I32 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I32x4) return I32 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I32x4) return I32 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 is
      Result : I32x4;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 is
      Result : I32x4;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_Wrap_U64x2 is new SSE2_Binary_128 (U64x2, "paddq %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : U64x2) return U64x2 is (Native_Add_Wrap_U64x2 (Left, Right));
   function Native_Subtract_Wrap_U64x2 is new SSE2_Binary_128 (U64x2, "psubq %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : U64x2) return U64x2 is (Native_Subtract_Wrap_U64x2 (Left, Right));
   function Native_Multiply_Wrap_U64x2 is new SSE2_Binary_128 (U64x2, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "pmuludq %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, %%xmm4" & ASCII.LF & ASCII.HT & "pmuludq %%xmm3, %%xmm4" & ASCII.LF & ASCII.HT & "paddq %%xmm4, %%xmm2" & ASCII.LF & ASCII.HT & "psllq $32, %%xmm2" & ASCII.LF & ASCII.HT & "pmuludq %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "paddq %%xmm2, %%xmm0");
   function Multiply_Wrap (Left, Right : U64x2) return U64x2 is (Native_Multiply_Wrap_U64x2 (Left, Right));
   function Native_Bitwise_And_U64x2 is new SSE2_Binary_128 (U64x2, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : U64x2) return U64x2 is (Native_Bitwise_And_U64x2 (Left, Right));
   function Native_Bitwise_Or_U64x2 is new SSE2_Binary_128 (U64x2, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Or_U64x2 (Left, Right));
   function Native_Bitwise_Xor_U64x2 is new SSE2_Binary_128 (U64x2, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Xor_U64x2 (Left, Right));
   function Native_Interleave_Low_U64x2 is new SSE2_Binary_128 (U64x2, "punpcklqdq %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : U64x2) return U64x2 is (Native_Interleave_Low_U64x2 (Left, Right));
   function Native_Interleave_High_U64x2 is new SSE2_Binary_128 (U64x2, "punpckhqdq %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : U64x2) return U64x2 is (Native_Interleave_High_U64x2 (Left, Right));
   function Native_Deinterleave_Even_U64x2 is new SSE2_Binary_128 (U64x2, "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Even_U64x2 (Left, Right));
   function Native_Deinterleave_Odd_U64x2 is new SSE2_Binary_128 (U64x2, "punpckhqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Odd_U64x2 (Left, Right));
   function Native_Not_U64x2 is new SSE2_Unary_128 (U64x2, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : U64x2) return U64x2 is (Native_Not_U64x2 (Value));
   function Native_Reverse_U64x2 is new SSE2_Unary_128 (U64x2, "pshufd $0x4E, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : U64x2) return U64x2 is (Native_Reverse_U64x2 (Value));
   function Compare_Equal_U64x2 is new SSE2_Compare_128 (U64x2, 64, "pcmpeqd %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pand %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %%xmm0, %%xmm0");
   function Compare_Greater_U64x2 is new SSE2_Compare_128 (U64x2, 64, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm2" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm3" & ASCII.LF & ASCII.HT & "pcmpgtd %%xmm3, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, %%xmm3" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm0" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm1" & ASCII.LF & ASCII.HT & "pcmpgtd %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pand %%xmm3, %%xmm0" & ASCII.LF & ASCII.HT & "por %%xmm2, %%xmm0");
   function Native_Select_U64x2 is new SSE2_Select_128 (U64x2, 64);
   function Zero return U64x2 is (Flyology_SIMD.Zero);
   function Splat (Value : U64) return U64x2 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Saturate (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U64x2) return U64x2 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Native_SHL_U64x2 is new SSE2_Shift_128 (U64x2, "psllq %%xmm1, %%xmm0");
   function Native_SHR_U64x2 is new SSE2_Shift_128 (U64x2, "psrlq %%xmm1, %%xmm0");
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2 is (if Count >= 64 then Flyology_SIMD.Zero else Native_SHL_U64x2 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2 is (if Count >= 64 then Flyology_SIMD.Zero else Native_SHR_U64x2 (Value, Interfaces.Unsigned_32 (Count)));
   function Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_U64x2 (Left, Right, Sign_32'Address))));
   function Greater_Than (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U64x2 (Left, Right, Sign_32'Address))));
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U64x2 (Left, Right, Sign_32'Address) or Compare_Equal_U64x2 (Left, Right, Sign_32'Address))));
   function Less_Than (Left, Right : U64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2 is (Native_Select_U64x2 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_64'Address, If_True, If_False));
   function Min (Left, Right : U64x2) return U64x2 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : U64x2) return U64x2 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Reduce_Add_Wrap (Value : U64x2) return U64 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : U64x2) return U64 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : U64x2) return U64 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 is
      Result : U64x2;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 is
      Result : U64x2;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_Wrap_I64x2 is new SSE2_Binary_128 (I64x2, "paddq %%xmm1, %%xmm0");
   function Add_Wrap (Left, Right : I64x2) return I64x2 is (Native_Add_Wrap_I64x2 (Left, Right));
   function Native_Subtract_Wrap_I64x2 is new SSE2_Binary_128 (I64x2, "psubq %%xmm1, %%xmm0");
   function Subtract_Wrap (Left, Right : I64x2) return I64x2 is (Native_Subtract_Wrap_I64x2 (Left, Right));
   function Native_Multiply_Wrap_I64x2 is new SSE2_Binary_128 (I64x2, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "pmuludq %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, %%xmm4" & ASCII.LF & ASCII.HT & "pmuludq %%xmm3, %%xmm4" & ASCII.LF & ASCII.HT & "paddq %%xmm4, %%xmm2" & ASCII.LF & ASCII.HT & "psllq $32, %%xmm2" & ASCII.LF & ASCII.HT & "pmuludq %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "paddq %%xmm2, %%xmm0");
   function Multiply_Wrap (Left, Right : I64x2) return I64x2 is (Native_Multiply_Wrap_I64x2 (Left, Right));
   function Native_Bitwise_And_I64x2 is new SSE2_Binary_128 (I64x2, "pand %%xmm1, %%xmm0");
   function Bitwise_And (Left, Right : I64x2) return I64x2 is (Native_Bitwise_And_I64x2 (Left, Right));
   function Native_Bitwise_Or_I64x2 is new SSE2_Binary_128 (I64x2, "por %%xmm1, %%xmm0");
   function Bitwise_Or (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Or_I64x2 (Left, Right));
   function Native_Bitwise_Xor_I64x2 is new SSE2_Binary_128 (I64x2, "pxor %%xmm1, %%xmm0");
   function Bitwise_Xor (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Xor_I64x2 (Left, Right));
   function Native_Interleave_Low_I64x2 is new SSE2_Binary_128 (I64x2, "punpcklqdq %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : I64x2) return I64x2 is (Native_Interleave_Low_I64x2 (Left, Right));
   function Native_Interleave_High_I64x2 is new SSE2_Binary_128 (I64x2, "punpckhqdq %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : I64x2) return I64x2 is (Native_Interleave_High_I64x2 (Left, Right));
   function Native_Deinterleave_Even_I64x2 is new SSE2_Binary_128 (I64x2, "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Even_I64x2 (Left, Right));
   function Native_Deinterleave_Odd_I64x2 is new SSE2_Binary_128 (I64x2, "punpckhqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Odd_I64x2 (Left, Right));
   function Native_Not_I64x2 is new SSE2_Unary_128 (I64x2, "pcmpeqd %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "pxor %%xmm1, %%xmm0");
   function Bitwise_Not (Value : I64x2) return I64x2 is (Native_Not_I64x2 (Value));
   function Native_Reverse_I64x2 is new SSE2_Unary_128 (I64x2, "pshufd $0x4E, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : I64x2) return I64x2 is (Native_Reverse_I64x2 (Value));
   function Compare_Equal_I64x2 is new SSE2_Compare_128 (I64x2, 64, "pcmpeqd %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pand %%xmm2, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %%xmm0, %%xmm0");
   function Compare_Greater_I64x2 is new SSE2_Compare_128 (I64x2, 64, "movdqu %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT & "pcmpgtd %%xmm1, %%xmm2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %%xmm2, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, %%xmm3" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm1, %%xmm3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, %%xmm4" & ASCII.LF & ASCII.HT & "movdqu %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "pxor %%xmm7, %%xmm5" & ASCII.LF & ASCII.HT & "pcmpgtd %%xmm5, %%xmm4" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pand %%xmm3, %%xmm4" & ASCII.LF & ASCII.HT & "por %%xmm4, %%xmm2" & ASCII.LF & ASCII.HT & "movdqu %%xmm2, %%xmm0");
   function Native_Select_I64x2 is new SSE2_Select_128 (I64x2, 64);
   function Zero return I64x2 is (Flyology_SIMD.Zero);
   function Splat (Value : I64) return I64x2 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Add_Saturate (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : I64x2) return I64x2 is
     (Flyology_SIMD.Subtract_Saturate (Left, Right));
   function Native_SHL_I64x2 is new SSE2_Shift_128 (I64x2, "psllq %%xmm1, %%xmm0");
   function Native_SHR_I64x2 is new SSE2_Shift_128 (I64x2, "psrlq %%xmm1, %%xmm0");
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2 is (if Count >= 64 then Flyology_SIMD.Zero else Native_SHL_I64x2 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2 is (if Count >= 64 then Flyology_SIMD.Zero else Native_SHR_I64x2 (Value, Interfaces.Unsigned_32 (Count)));
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2 is
     (Flyology_SIMD.Shift_Right_Arithmetic (Value, Count));
   function Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_I64x2 (Left, Right, Sign_32'Address))));
   function Greater_Than (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I64x2 (Left, Right, Sign_32'Address))));
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I64x2 (Left, Right, Sign_32'Address) or Compare_Equal_I64x2 (Left, Right, Sign_32'Address))));
   function Less_Than (Left, Right : I64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2 is (Native_Select_I64x2 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_64'Address, If_True, If_False));
   function Min (Left, Right : I64x2) return I64x2 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : I64x2) return I64x2 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Reduce_Add_Wrap (Value : I64x2) return I64 is
     (Flyology_SIMD.Reduce_Add_Wrap (Value));
   function Reduce_Min (Value : I64x2) return I64 is
     (Flyology_SIMD.Reduce_Min (Value));
   function Reduce_Max (Value : I64x2) return I64 is
     (Flyology_SIMD.Reduce_Max (Value));
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 is
      Result : I64x2;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 is
      Result : I64x2;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_F32x4 is new SSE2_Binary_128 (F32x4, "addps %%xmm1, %%xmm0");
   function Add (Left, Right : F32x4) return F32x4 is (Native_Add_F32x4 (Left, Right));
   function Native_Subtract_F32x4 is new SSE2_Binary_128 (F32x4, "subps %%xmm1, %%xmm0");
   function Subtract (Left, Right : F32x4) return F32x4 is (Native_Subtract_F32x4 (Left, Right));
   function Native_Multiply_F32x4 is new SSE2_Binary_128 (F32x4, "mulps %%xmm1, %%xmm0");
   function Multiply (Left, Right : F32x4) return F32x4 is (Native_Multiply_F32x4 (Left, Right));
   function Native_Divide_F32x4 is new SSE2_Binary_128 (F32x4, "divps %%xmm1, %%xmm0");
   function Divide (Left, Right : F32x4) return F32x4 is (Native_Divide_F32x4 (Left, Right));
   function Native_Interleave_Low_F32x4 is new SSE2_Binary_128 (F32x4, "unpcklps %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : F32x4) return F32x4 is (Native_Interleave_Low_F32x4 (Left, Right));
   function Native_Interleave_High_F32x4 is new SSE2_Binary_128 (F32x4, "unpckhps %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : F32x4) return F32x4 is (Native_Interleave_High_F32x4 (Left, Right));
   function Native_Deinterleave_Even_F32x4 is new SSE2_Binary_128 (F32x4, "pshufd $0x88, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Even_F32x4 (Left, Right));
   function Native_Deinterleave_Odd_F32x4 is new SSE2_Binary_128 (F32x4, "pshufd $0xDD, %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT & "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Odd_F32x4 (Left, Right));
   function Native_Reverse_F32x4 is new SSE2_Unary_128 (F32x4, "pshufd $0x1B, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : F32x4) return F32x4 is (Native_Reverse_F32x4 (Value));
   function Compare_Equal_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpeqps %%xmm1, %%xmm0");
   function Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_F32x4 (Left, Right, Sign_32'Address))));
   function Compare_Less_Than_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpltps %%xmm1, %%xmm0");
   function Less_Than (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Than_F32x4 (Left, Right, Sign_32'Address))));
   function Compare_Less_Equal_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpleps %%xmm1, %%xmm0");
   function Less_Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Equal_F32x4 (Left, Right, Sign_32'Address))));
   function Compare_Unordered_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpunordps %%xmm1, %%xmm0");
   function Unordered (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Unordered_F32x4 (Left, Right, Sign_32'Address))));
   function Greater_Than (Left, Right : F32x4) return Mask_32x4 is (Less_Than (Left => Right, Right => Left));
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4 is (Less_Equal (Left => Right, Right => Left));
   function Native_Select_F32x4 is new SSE2_Select_128 (F32x4, 32);
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4 is (Native_Select_F32x4 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_32'Address, If_True, If_False));
   function Zero return F32x4 is (Flyology_SIMD.Zero);
   function Splat (Value : F32) return F32x4 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Min_Number (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Min_Number (Left, Right));
   function Max_Number (Left, Right : F32x4) return F32x4 is
     (Flyology_SIMD.Max_Number (Left, Right));
   function Reduce_Add (Value : F32x4) return F32 is
     (Flyology_SIMD.Reduce_Add (Value));
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 is
      Result : F32x4;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 is
      Result : F32x4;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_F64x2 is new SSE2_Binary_128 (F64x2, "addpd %%xmm1, %%xmm0");
   function Add (Left, Right : F64x2) return F64x2 is (Native_Add_F64x2 (Left, Right));
   function Native_Subtract_F64x2 is new SSE2_Binary_128 (F64x2, "subpd %%xmm1, %%xmm0");
   function Subtract (Left, Right : F64x2) return F64x2 is (Native_Subtract_F64x2 (Left, Right));
   function Native_Multiply_F64x2 is new SSE2_Binary_128 (F64x2, "mulpd %%xmm1, %%xmm0");
   function Multiply (Left, Right : F64x2) return F64x2 is (Native_Multiply_F64x2 (Left, Right));
   function Native_Divide_F64x2 is new SSE2_Binary_128 (F64x2, "divpd %%xmm1, %%xmm0");
   function Divide (Left, Right : F64x2) return F64x2 is (Native_Divide_F64x2 (Left, Right));
   function Native_Interleave_Low_F64x2 is new SSE2_Binary_128 (F64x2, "unpcklpd %%xmm1, %%xmm0");
   function Interleave_Low (Left, Right : F64x2) return F64x2 is (Native_Interleave_Low_F64x2 (Left, Right));
   function Native_Interleave_High_F64x2 is new SSE2_Binary_128 (F64x2, "unpckhpd %%xmm1, %%xmm0");
   function Interleave_High (Left, Right : F64x2) return F64x2 is (Native_Interleave_High_F64x2 (Left, Right));
   function Native_Deinterleave_Even_F64x2 is new SSE2_Binary_128 (F64x2, "punpcklqdq %%xmm1, %%xmm0");
   function Deinterleave_Even (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Even_F64x2 (Left, Right));
   function Native_Deinterleave_Odd_F64x2 is new SSE2_Binary_128 (F64x2, "punpckhqdq %%xmm1, %%xmm0");
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Odd_F64x2 (Left, Right));
   function Native_Reverse_F64x2 is new SSE2_Unary_128 (F64x2, "pshufd $0x4E, %%xmm0, %%xmm0");
   function Reverse_Lanes (Value : F64x2) return F64x2 is (Native_Reverse_F64x2 (Value));
   function Compare_Equal_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmpeqpd %%xmm1, %%xmm0");
   function Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_F64x2 (Left, Right, Sign_32'Address))));
   function Compare_Less_Than_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmpltpd %%xmm1, %%xmm0");
   function Less_Than (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Than_F64x2 (Left, Right, Sign_32'Address))));
   function Compare_Less_Equal_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmplepd %%xmm1, %%xmm0");
   function Less_Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Equal_F64x2 (Left, Right, Sign_32'Address))));
   function Compare_Unordered_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmpunordpd %%xmm1, %%xmm0");
   function Unordered (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Unordered_F64x2 (Left, Right, Sign_32'Address))));
   function Greater_Than (Left, Right : F64x2) return Mask_64x2 is (Less_Than (Left => Right, Right => Left));
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2 is (Less_Equal (Left => Right, Right => Left));
   function Native_Select_F64x2 is new SSE2_Select_128 (F64x2, 64);
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2 is (Native_Select_F64x2 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_64'Address, If_True, If_False));
   function Zero return F64x2 is (Flyology_SIMD.Zero);
   function Splat (Value : F64) return F64x2 is
     (Flyology_SIMD.Splat (Value));
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2 is
     (Flyology_SIMD.From_Lanes (Values));
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2 is
     (Flyology_SIMD.To_Lanes (Value));
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64 is
     (Flyology_SIMD.Extract (Value, Lane));
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2 is
     (Flyology_SIMD.Replace (Value, Lane, With_Value));
   function Min_Number (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Min_Number (Left, Right));
   function Max_Number (Left, Right : F64x2) return F64x2 is
     (Flyology_SIMD.Max_Number (Left, Right));
   function Reduce_Add (Value : F64x2) return F64 is
     (Flyology_SIMD.Reduce_Add (Value));
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 is
      Result : F64x2;
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Unaligned;
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 is
      Result : F64x2;
   begin Asm (Template => "movdqa (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "xmm0,memory", Volatile => True); return Result; end Load_Aligned;
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
   begin Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "xmm0,memory", Volatile => True); end Store_Aligned;
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8 is
     (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_16x8) return Mask_16x8 is
     (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean is
     (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_16x8) return Boolean is
     (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_16x8) return Boolean is
     (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_16x8) return Boolean is
     (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8 is
     (Flyology_SIMD.Population_Count (Mask));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4 is
     (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_32x4) return Mask_32x4 is
     (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean is
     (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_32x4) return Boolean is
     (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_32x4) return Boolean is
     (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_32x4) return Boolean is
     (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4 is
     (Flyology_SIMD.Population_Count (Mask));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2 is
     (Flyology_SIMD.Mask_From_Bit_Mask (Bits));
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_And (Left, Right));
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_Or (Left, Right));
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_Xor (Left, Right));
   function Mask_Not (Value : Mask_64x2) return Mask_64x2 is
     (Flyology_SIMD.Mask_Not (Value));
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean is
     (Flyology_SIMD.Test (Mask, Lane));
   function Any_True (Mask : Mask_64x2) return Boolean is
     (Flyology_SIMD.Any_True (Mask));
   function All_True (Mask : Mask_64x2) return Boolean is
     (Flyology_SIMD.All_True (Mask));
   function None_True (Mask : Mask_64x2) return Boolean is
     (Flyology_SIMD.None_True (Mask));
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2 is
     (Flyology_SIMD.Population_Count (Mask));
   --  END GENERATED FULL-FAMILY X86 BODIES
end Flyology_SIMD.Backends.Native;
