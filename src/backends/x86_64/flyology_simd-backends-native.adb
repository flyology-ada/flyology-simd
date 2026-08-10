with System.Machine_Code;

package body Flyology_SIMD.Backends.Native is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;
   use System.Machine_Code;

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

   function Zero return U8x16 is (Lanes => [others => 0]);
   function Splat (Value : U8) return U8x16 is (Lanes => [others => Value]);

   function Add_Wrap (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         pragma Loop_Optimize (Vector);
         Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);
      end loop;
      return Result;
   end Add_Wrap;

   function Add_Saturate (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT &
           "paddusb %%xmm1, %%xmm0" & ASCII.LF & ASCII.HT &
           "movdqu %%xmm0, (%0)",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "xmm0,xmm1,memory", Volatile => True);
      return Result;
   end Add_Saturate;

   function Bitwise_And (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         pragma Loop_Optimize (Vector);
         Result.Lanes (Lane) := Left.Lanes (Lane) and Right.Lanes (Lane);
      end loop;
      return Result;
   end Bitwise_And;

   function Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Equal_Mask (Left, Right)));
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
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
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Mask.Bits);

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
end Flyology_SIMD.Backends.Native;
