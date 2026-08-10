with System.Machine_Code;

package body Flyology_SIMD.Backends.Native is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;
   use System.Machine_Code;

   function Equal_Mask (Left, Right : U8x16) return Interfaces.Unsigned_16 is
      Result  : Interfaces.Unsigned_32;
      Weights : aliased constant Lane_Values_8x16 :=
        [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];
   begin
      Asm
        (Template =>
           "ldr q2, [%3]" & ASCII.LF & ASCII.HT &
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "cmeq v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "and v0.16b, v0.16b, v2.16b" & ASCII.LF & ASCII.HT &
           "ext v1.16b, v0.16b, v0.16b, #8" & ASCII.LF & ASCII.HT &
           "uaddlv h0, v0.8b" & ASCII.LF & ASCII.HT &
           "uaddlv h1, v1.8b" & ASCII.LF & ASCII.HT &
           "umov %w0, v0.h[0]" & ASCII.LF & ASCII.HT &
           "umov w9, v1.h[0]" & ASCII.LF & ASCII.HT &
           "orr %w0, %w0, w9, lsl #8",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs =>
           [System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address),
            System.Address'Asm_Input ("r", Weights'Address)],
         Clobber => "v0,v1,v2,x9,memory",
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
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "uqadd v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "v0,v1,memory",
         Volatile => True);
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
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "umin v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end Min;

   function Max (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "umax v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end Max;
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Mask.Bits);

   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Data (Start)'Address)],
         Clobber => "v0,memory",
         Volatile => True);
      return Result;
   end Load_Unaligned;

   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Data (Start)'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,memory",
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
