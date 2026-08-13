with System.Machine_Code;

package body Flyology_SIMD.Backends.Native is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Integer_64;
   use System.Machine_Code;

   function Find_First_Set_Bit
     (Bits : Interfaces.Unsigned_32; Lane_Count : Natural) return Natural
   is
      Result : Interfaces.Unsigned_32;
   begin
      if Bits = 0 then
         return Lane_Count;
      end if;
      Asm
        (Template => "rbit %w0, %w1" & ASCII.LF & ASCII.HT &
                     "clz %w0, %w0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Volatile => True);
      return Natural (Result);
   end Find_First_Set_Bit;

   function Find_Last_Set_Bit
     (Bits : Interfaces.Unsigned_32; Lane_Count : Natural) return Natural
   is
      Result : Interfaces.Unsigned_32;
   begin
      if Bits = 0 then
         return Lane_Count;
      end if;
      Asm
        (Template => "clz %w0, %w1" & ASCII.LF & ASCII.HT &
                     "mov w9, #31" & ASCII.LF & ASCII.HT &
                     "sub %w0, w9, %w0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Clobber => "x9",
         Volatile => True);
      return Natural (Result);
   end Find_Last_Set_Bit;

   Weights_8x16 : aliased constant Lane_Values_8x16 :=
     [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];

   generic
      Instruction : String;
   function Binary_Operation (Left, Right : U8x16) return U8x16;

   function Binary_Operation (Left, Right : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address)],
         Clobber => "v0,v1,memory",
         Volatile => True);
      return Result;
   end Binary_Operation;

   generic
      Instruction : String;
   function Unary_Operation (Value : U8x16) return U8x16;

   function Unary_Operation (Value : U8x16) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,memory",
         Volatile => True);
      return Result;
   end Unary_Operation;

   generic
      Instruction : String;
   function Comparison_Bits
     (Left, Right : U8x16) return Interfaces.Unsigned_16;

   function Comparison_Bits
     (Left, Right : U8x16) return Interfaces.Unsigned_16
   is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "ldr q2, [%3]" & ASCII.LF & ASCII.HT &
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           Instruction & ASCII.LF & ASCII.HT &
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
            System.Address'Asm_Input ("r", Weights_8x16'Address)],
         Clobber => "v0,v1,v2,x9,memory",
         Volatile => True);
      return Interfaces.Unsigned_16 (Result and 16#0000_FFFF#);
   end Comparison_Bits;

   function NEON_Add_Wrap is new Binary_Operation
     ("add v0.16b, v0.16b, v1.16b");
   function NEON_Subtract_Wrap is new Binary_Operation
     ("sub v0.16b, v0.16b, v1.16b");
   function NEON_Multiply_Wrap is new Binary_Operation
     ("mul v0.16b, v0.16b, v1.16b");
   function NEON_Add_Saturate is new Binary_Operation
     ("uqadd v0.16b, v0.16b, v1.16b");
   function NEON_Subtract_Saturate is new Binary_Operation
     ("uqsub v0.16b, v0.16b, v1.16b");
   function NEON_Bitwise_And is new Binary_Operation
     ("and v0.16b, v0.16b, v1.16b");
   pragma Inline_Always (NEON_Bitwise_And);
   function NEON_Bitwise_Or is new Binary_Operation
     ("orr v0.16b, v0.16b, v1.16b");
   function NEON_Bitwise_Xor is new Binary_Operation
     ("eor v0.16b, v0.16b, v1.16b");
   function NEON_Bitwise_Not is new Unary_Operation ("mvn v0.16b, v0.16b");
   function NEON_Reverse_Bytes is new Unary_Operation
     ("rev64 v0.16b, v0.16b" & ASCII.LF & ASCII.HT &
      "ext v0.16b, v0.16b, v0.16b, #8");
   function NEON_Interleave_Low is new Binary_Operation
     ("zip1 v0.16b, v0.16b, v1.16b");
   function NEON_Interleave_High is new Binary_Operation
     ("zip2 v0.16b, v0.16b, v1.16b");
   function NEON_Deinterleave_Even is new Binary_Operation
     ("uzp1 v0.16b, v0.16b, v1.16b");
   function NEON_Deinterleave_Odd is new Binary_Operation
     ("uzp2 v0.16b, v0.16b, v1.16b");

   function Equal_Bits is new Comparison_Bits
     ("cmeq v0.16b, v0.16b, v1.16b");
   pragma Inline_Always (Equal_Bits);
   function Greater_Bits is new Comparison_Bits
     ("cmhi v0.16b, v0.16b, v1.16b");
   function Greater_Equal_Bits is new Comparison_Bits
     ("cmhs v0.16b, v0.16b, v1.16b");

   function Zero return U8x16 is (Lanes => [others => 0]);
   function Splat (Value : U8) return U8x16 is (Lanes => [others => Value]);
   function From_Lanes (Values : Lane_Values_8x16) return U8x16 is
     (Lanes => Values);
   function To_Lanes (Value : U8x16) return Lane_Values_8x16 is
     (Value.Lanes);
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8 is
     (Value.Lanes (Lane));
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16
   is
      Result : U8x16 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;

   function Add_Wrap (Left, Right : U8x16) return U8x16 is
     (NEON_Add_Wrap (Left, Right));
   function Subtract_Wrap (Left, Right : U8x16) return U8x16 is
     (NEON_Subtract_Wrap (Left, Right));
   function Multiply_Wrap (Left, Right : U8x16) return U8x16 is
     (NEON_Multiply_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U8x16) return U8x16 is
     (NEON_Add_Saturate (Left, Right));
   function Subtract_Saturate (Left, Right : U8x16) return U8x16 is
     (NEON_Subtract_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U8x16) return U8x16 is
     (NEON_Bitwise_And (Left, Right));
   function Bitwise_Or (Left, Right : U8x16) return U8x16 is
     (NEON_Bitwise_Or (Left, Right));
   function Bitwise_Xor (Left, Right : U8x16) return U8x16 is
     (NEON_Bitwise_Xor (Left, Right));
   function Bitwise_Not (Value : U8x16) return U8x16 is
     (NEON_Bitwise_Not (Value));

   function Shift_Left_Logical
     (Value : U8x16; Count : Natural) return U8x16
   is
      Result : U8x16;
   begin
      if Count >= 8 then
         return Zero;
      end if;
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "dup v1.16b, %w2" & ASCII.LF & ASCII.HT &
           "ushl v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            Natural'Asm_Input ("r", Count)],
         Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end Shift_Left_Logical;

   function Shift_Right_Logical
     (Value : U8x16; Count : Natural) return U8x16
   is
      Result : U8x16;
   begin
      if Count >= 8 then
         return Zero;
      end if;
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "neg w9, %w2" & ASCII.LF & ASCII.HT &
           "dup v1.16b, w9" & ASCII.LF & ASCII.HT &
           "ushl v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            Natural'Asm_Input ("r", Count)],
         Clobber => "v0,v1,x9,memory", Volatile => True);
      return Result;
   end Shift_Right_Logical;

   function Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Equal_Bits (Left, Right)));
   function Less_Than (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Greater_Bits (Left => Right, Right => Left)));
   function Less_Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask
        (Greater_Equal_Bits (Left => Right, Right => Left)));
   function Greater_Than (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Greater_Bits (Left, Right)));
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16 is
     (Mask_From_Bit_Mask (Greater_Equal_Bits (Left, Right)));

   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16
   is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "dup v3.16b, %w1" & ASCII.LF & ASCII.HT &
           "lsr w9, %w1, #8" & ASCII.LF & ASCII.HT &
           "dup v4.16b, w9" & ASCII.LF & ASCII.HT &
           "ins v3.d[1], v4.d[0]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%4]" & ASCII.LF & ASCII.HT &
           "cmtst v3.16b, v3.16b, v2.16b" & ASCII.LF & ASCII.HT &
           "ldr q0, [%2]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%3]" & ASCII.LF & ASCII.HT &
           "bsl v3.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            Interfaces.Unsigned_16'Asm_Input ("r", Mask.Bits),
            System.Address'Asm_Input ("r", If_True'Address),
            System.Address'Asm_Input ("r", If_False'Address),
            System.Address'Asm_Input ("r", Weights_8x16'Address)],
         Clobber => "v0,v1,v2,v3,v4,x9,memory", Volatile => True);
      return Result;
   end Select_Value;

   function NEON_Min is new Binary_Operation
     ("umin v0.16b, v0.16b, v1.16b");
   function NEON_Max is new Binary_Operation
     ("umax v0.16b, v0.16b, v1.16b");
   function Min (Left, Right : U8x16) return U8x16 is
     (NEON_Min (Left, Right));
   function Max (Left, Right : U8x16) return U8x16 is
     (NEON_Max (Left, Right));

   function Horizontal_Sum (Value : U8x16) return Natural is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "uaddlv h0, v0.16b" & ASCII.LF & ASCII.HT &
           "umov %w0, v0.h[0]",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => System.Address'Asm_Input ("r", Value'Address),
         Clobber => "v0,memory", Volatile => True);
      return Natural (Result);
   end Horizontal_Sum;

   function Reduce_Add_Wrap (Value : U8x16) return U8 is
     (U8 (Horizontal_Sum (Value) mod 256));
   function Reduce_Min (Value : U8x16) return U8 is
      Result : U8;
   begin
      Asm
        (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "uminv b0, v0.16b" & ASCII.LF & ASCII.HT & "str b0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,memory", Volatile => True);
      return Result;
   end Reduce_Min;
   function Reduce_Max (Value : U8x16) return U8 is
      Result : U8;
   begin
      Asm
        (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "umaxv b0, v0.16b" & ASCII.LF & ASCII.HT & "str b0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,memory", Volatile => True);
      return Result;
   end Reduce_Max;

   function Reverse_Bytes (Value : U8x16) return U8x16 is
     (NEON_Reverse_Bytes (Value));
   function Reverse_Lanes (Value : U8x16) return U8x16 is
     (Reverse_Bytes (Value));
   function Interleave_Low (Left, Right : U8x16) return U8x16 is
     (NEON_Interleave_Low (Left, Right));
   function Interleave_High (Left, Right : U8x16) return U8x16 is
     (NEON_Interleave_High (Left, Right));
   function Deinterleave_Even (Left, Right : U8x16) return U8x16 is
     (NEON_Deinterleave_Even (Left, Right));
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16 is
     (NEON_Deinterleave_Odd (Left, Right));

   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16 is
     (Bits => Bits);
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
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean is
     ((Mask.Bits and Interfaces.Shift_Left
         (Interfaces.Unsigned_16'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_8x16) return Boolean is (Mask.Bits /= 0);
   function All_True (Mask : Mask_8x16) return Boolean is
     (Mask.Bits = Interfaces.Unsigned_16'Last);
   function None_True (Mask : Mask_8x16) return Boolean is (Mask.Bits = 0);
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16 is
      Bits : Interfaces.Unsigned_16 := Mask.Bits;
      Result : Lane_Count_8x16 := 0;
   begin
      while Bits /= 0 loop
         Result := Result + 1;
         Bits := Bits and (Bits - 1);
      end loop;
      return Result;
   end Population_Count;
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16 is
     (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 16));
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16 is
     (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 16));

   function Load (Data : Byte_Array; Start : Natural) return U8x16 is
     (Load_Unaligned (Data, Start));
   procedure Store
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Store_Unaligned (Data, Start, Value);
   end Store;

   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
      Result : U8x16;
   begin
      Asm
        (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Data (Start)'Address)],
         Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;

   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Asm
        (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Data (Start)'Address),
            System.Address'Asm_Input ("r", Value'Address)],
         Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;

   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16 is
     (Load_Unaligned (Data, Start));
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Store_Unaligned (Data, Start, Value);
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

   --  BEGIN GENERATED FULL-FAMILY NEON BODIES
   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Binary_128 (Left, Right : Vector_Type) return Vector_Type;
   function NEON_Binary_128 (Left, Right : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address)],
           Clobber => "v0,v1,v2,memory", Volatile => True);
      return Result;
   end NEON_Binary_128;

   generic
      type Vector_Type is private;
   function NEON_Multiply_64_128 (Left, Right : Vector_Type) return Vector_Type;
   function NEON_Multiply_64_128 (Left, Right : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "uzp1 v2.4s, v0.4s, v0.4s" & ASCII.LF & ASCII.HT &
           "uzp2 v3.4s, v0.4s, v0.4s" & ASCII.LF & ASCII.HT &
           "uzp1 v4.4s, v1.4s, v1.4s" & ASCII.LF & ASCII.HT &
           "uzp2 v5.4s, v1.4s, v1.4s" & ASCII.LF & ASCII.HT &
           "umull v6.2d, v2.2s, v4.2s" & ASCII.LF & ASCII.HT &
           "mul v7.2s, v2.2s, v5.2s" & ASCII.LF & ASCII.HT &
           "mla v7.2s, v3.2s, v4.2s" & ASCII.LF & ASCII.HT &
           "shll v7.2d, v7.2s, #32" & ASCII.LF & ASCII.HT &
           "add v0.2d, v6.2d, v7.2d" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address)],
           Clobber => "v0,v1,v2,v3,v4,v5,v6,v7,memory", Volatile => True);
      return Result;
   end NEON_Multiply_64_128;

   generic
      type Vector_Type is private;
      type Map_Type is private;
   function NEON_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type;
   function NEON_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "tbl v0.16b, {v0.16b}, v1.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address), System.Address'Asm_Input ("r", Map'Address)],
           Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end NEON_Permute_128;

   generic
      type Vector_Type is private;
      type Map_Type is private;
   function NEON_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type;
   function NEON_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%3]" & ASCII.LF & ASCII.HT &
           "tbl v0.16b, {v0.16b, v1.16b}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address), System.Address'Asm_Input ("r", Map'Address)],
           Clobber => "v0,v1,v2,memory", Volatile => True);
      return Result;
   end NEON_Permute_2_128;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Unary_128 (Value : Vector_Type) return Vector_Type;
   function NEON_Unary_128 (Value : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address)],
           Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end NEON_Unary_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Store_Instruction : String;
   function NEON_Integer_Reduce_128 (Value : Vector_Type) return Scalar_Type;
   function NEON_Integer_Reduce_128 (Value : Vector_Type) return Scalar_Type is
      Result : Scalar_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Store_Instruction,
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address)],
           Clobber => "v0,v1,v2,memory", Volatile => True);
      return Result;
   end NEON_Integer_Reduce_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Store_Instruction : String;
   function NEON_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type;
   function NEON_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type is
      Result : Scalar_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Store_Instruction,
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address)],
           Clobber => "v0,v1,v2,memory", Volatile => True);
      return Result;
   end NEON_Float_Reduce_128;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
   function NEON_Convert_128 (Value : Source_Type) return Result_Type;
   function NEON_Convert_128 (Value : Source_Type) return Result_Type is
      Result : Result_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address)],
           Clobber => "v0,v1,v2,memory", Volatile => True);
      return Result;
   end NEON_Convert_128;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
   function NEON_Convert_Pair_128 (Low, High : Source_Type) return Result_Type;
   function NEON_Convert_Pair_128 (Low, High : Source_Type) return Result_Type is
      Result : Result_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "ldr q1, [%2]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Low'Address), System.Address'Asm_Input ("r", High'Address)],
           Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end NEON_Convert_Pair_128;

   generic
      type Vector_Type is private;
      Instruction : String;
      Compact : String;
   function NEON_Compare_128 (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_8;
   function NEON_Compare_128 (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_32;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "ldr q1, [%2]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Compact,
           Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
           Inputs => [System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address), System.Address'Asm_Input ("r", Weights)],
           Clobber => "v0,v1,v2,x9,memory", Volatile => True);
      return Interfaces.Unsigned_8 (Result and 16#FF#);
   end NEON_Compare_128;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Compare_16_Lanes (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_16;
   function NEON_Compare_16_Lanes (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_16 is
      Result : Interfaces.Unsigned_32;
   begin
      Asm (Template => "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "ldr q1, [%2]" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "and v0.16b, v0.16b, v2.16b" & ASCII.LF & ASCII.HT & "ext v1.16b, v0.16b, v0.16b, #8" & ASCII.LF & ASCII.HT & "uaddlv h0, v0.8b" & ASCII.LF & ASCII.HT & "uaddlv h1, v1.8b" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]" & ASCII.LF & ASCII.HT & "umov w9, v1.h[0]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #8",
           Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result), Inputs => [System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address), System.Address'Asm_Input ("r", Weights)], Clobber => "v0,v1,v2,x9,memory", Volatile => True);
      return Interfaces.Unsigned_16 (Result and 16#FFFF#);
   end NEON_Compare_16_Lanes;

   generic
      type Vector_Type is private;
      Dup_Instruction : String;
      Test_Instruction : String;
   function NEON_Select_128 (Bits : Interfaces.Unsigned_64; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type;
   function NEON_Select_128 (Bits : Interfaces.Unsigned_64; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => Dup_Instruction & ASCII.LF & ASCII.HT &
           "ldr q3, [%4]" & ASCII.LF & ASCII.HT & Test_Instruction & ASCII.LF & ASCII.HT &
           "ldr q0, [%2]" & ASCII.LF & ASCII.HT & "ldr q1, [%3]" & ASCII.LF & ASCII.HT &
           "bsl v2.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT & "str q2, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), Interfaces.Unsigned_64'Asm_Input ("r", Bits), System.Address'Asm_Input ("r", If_True'Address), System.Address'Asm_Input ("r", If_False'Address), System.Address'Asm_Input ("r", Weights)],
           Clobber => "v0,v1,v2,v3,memory", Volatile => True);
      return Result;
   end NEON_Select_128;

   generic
      type Vector_Type is private;
   function NEON_Select_16_Lanes_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type;
   function NEON_Select_16_Lanes_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "dup v2.16b, %w1" & ASCII.LF & ASCII.HT &
           "lsr w9, %w1, #8" & ASCII.LF & ASCII.HT & "dup v3.16b, w9" & ASCII.LF & ASCII.HT &
           "ins v2.d[1], v3.d[0]" & ASCII.LF & ASCII.HT & "ldr q3, [%4]" & ASCII.LF & ASCII.HT &
           "cmtst v2.16b, v2.16b, v3.16b" & ASCII.LF & ASCII.HT &
           "ldr q0, [%2]" & ASCII.LF & ASCII.HT & "ldr q1, [%3]" & ASCII.LF & ASCII.HT &
           "bsl v2.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT & "str q2, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), Interfaces.Unsigned_16'Asm_Input ("r", Bits), System.Address'Asm_Input ("r", If_True'Address), System.Address'Asm_Input ("r", If_False'Address), System.Address'Asm_Input ("r", Weights)],
           Clobber => "v0,v1,v2,v3,x9,memory", Volatile => True);
      return Result;
   end NEON_Select_16_Lanes_128;

   generic
      type Vector_Type is private;
      Dup_Instruction : String;
      Shift_Instruction : String;
   function NEON_Shift_128 (Value : Vector_Type; Amount : Interfaces.Integer_64) return Vector_Type;
   function NEON_Shift_128 (Value : Vector_Type; Amount : Interfaces.Integer_64) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & Dup_Instruction & ASCII.LF & ASCII.HT & Shift_Instruction & ASCII.LF & ASCII.HT & "str q0, [%0]",
           Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address), Interfaces.Integer_64'Asm_Input ("r", Amount)],
           Clobber => "v0,v1,memory", Volatile => True);
      return Result;
   end NEON_Shift_128;

   Weights_16x8 : aliased constant Lane_Values_U16x8 := [1, 2, 4, 8, 16, 32, 64, 128];
   Weights_32x4 : aliased constant Lane_Values_U32x4 := [1, 2, 4, 8];
   Weights_64x2 : aliased constant Lane_Values_U64x2 := [1, 2];

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
   function Native_Widen_Low_U8x16_To_U16x8 is new NEON_Convert_128 (U8x16, U16x8, "uxtl v0.8h, v0.8b");
   function Widen_Low (Value : U8x16) return U16x8 is (Native_Widen_Low_U8x16_To_U16x8 (Value));
   function Native_Widen_High_U8x16_To_U16x8 is new NEON_Convert_128 (U8x16, U16x8, "uxtl2 v0.8h, v0.16b");
   function Widen_High (Value : U8x16) return U16x8 is (Native_Widen_High_U8x16_To_U16x8 (Value));
   function Native_Widen_Low_I8x16_To_I16x8 is new NEON_Convert_128 (I8x16, I16x8, "sxtl v0.8h, v0.8b");
   function Widen_Low (Value : I8x16) return I16x8 is (Native_Widen_Low_I8x16_To_I16x8 (Value));
   function Native_Widen_High_I8x16_To_I16x8 is new NEON_Convert_128 (I8x16, I16x8, "sxtl2 v0.8h, v0.16b");
   function Widen_High (Value : I8x16) return I16x8 is (Native_Widen_High_I8x16_To_I16x8 (Value));
   function Native_Widen_Low_U16x8_To_U32x4 is new NEON_Convert_128 (U16x8, U32x4, "uxtl v0.4s, v0.4h");
   function Widen_Low (Value : U16x8) return U32x4 is (Native_Widen_Low_U16x8_To_U32x4 (Value));
   function Native_Widen_High_U16x8_To_U32x4 is new NEON_Convert_128 (U16x8, U32x4, "uxtl2 v0.4s, v0.8h");
   function Widen_High (Value : U16x8) return U32x4 is (Native_Widen_High_U16x8_To_U32x4 (Value));
   function Native_Widen_Low_I16x8_To_I32x4 is new NEON_Convert_128 (I16x8, I32x4, "sxtl v0.4s, v0.4h");
   function Widen_Low (Value : I16x8) return I32x4 is (Native_Widen_Low_I16x8_To_I32x4 (Value));
   function Native_Widen_High_I16x8_To_I32x4 is new NEON_Convert_128 (I16x8, I32x4, "sxtl2 v0.4s, v0.8h");
   function Widen_High (Value : I16x8) return I32x4 is (Native_Widen_High_I16x8_To_I32x4 (Value));
   function Native_Widen_Low_U32x4_To_U64x2 is new NEON_Convert_128 (U32x4, U64x2, "uxtl v0.2d, v0.2s");
   function Widen_Low (Value : U32x4) return U64x2 is (Native_Widen_Low_U32x4_To_U64x2 (Value));
   function Native_Widen_High_U32x4_To_U64x2 is new NEON_Convert_128 (U32x4, U64x2, "uxtl2 v0.2d, v0.4s");
   function Widen_High (Value : U32x4) return U64x2 is (Native_Widen_High_U32x4_To_U64x2 (Value));
   function Native_Widen_Low_I32x4_To_I64x2 is new NEON_Convert_128 (I32x4, I64x2, "sxtl v0.2d, v0.2s");
   function Widen_Low (Value : I32x4) return I64x2 is (Native_Widen_Low_I32x4_To_I64x2 (Value));
   function Native_Widen_High_I32x4_To_I64x2 is new NEON_Convert_128 (I32x4, I64x2, "sxtl2 v0.2d, v0.4s");
   function Widen_High (Value : I32x4) return I64x2 is (Native_Widen_High_I32x4_To_I64x2 (Value));
   function Native_Widen_Low_F32x4_To_F64x2 is new NEON_Convert_128 (F32x4, F64x2, "fcvtl v0.2d, v0.2s");
   function Widen_Low (Value : F32x4) return F64x2 is (Native_Widen_Low_F32x4_To_F64x2 (Value));
   function Native_Widen_High_F32x4_To_F64x2 is new NEON_Convert_128 (F32x4, F64x2, "fcvtl2 v0.2d, v0.4s");
   function Widen_High (Value : F32x4) return F64x2 is (Native_Widen_High_F32x4_To_F64x2 (Value));
   function Native_Narrow_Truncate_U16x8_To_U8x16 is new NEON_Convert_Pair_128 (U16x8, U8x16, "xtn v0.8b, v0.8h" & ASCII.LF & ASCII.HT & "xtn2 v0.16b, v1.8h");
   function Narrow_Truncate (Low, High : U16x8) return U8x16 is (Native_Narrow_Truncate_U16x8_To_U8x16 (Low, High));
   function Native_Narrow_Saturate_U16x8_To_U8x16 is new NEON_Convert_Pair_128 (U16x8, U8x16, "uqxtn v0.8b, v0.8h" & ASCII.LF & ASCII.HT & "uqxtn2 v0.16b, v1.8h");
   function Narrow_Saturate (Low, High : U16x8) return U8x16 is (Native_Narrow_Saturate_U16x8_To_U8x16 (Low, High));
   function Native_Narrow_Truncate_I16x8_To_I8x16 is new NEON_Convert_Pair_128 (I16x8, I8x16, "xtn v0.8b, v0.8h" & ASCII.LF & ASCII.HT & "xtn2 v0.16b, v1.8h");
   function Narrow_Truncate (Low, High : I16x8) return I8x16 is (Native_Narrow_Truncate_I16x8_To_I8x16 (Low, High));
   function Native_Narrow_Saturate_I16x8_To_I8x16 is new NEON_Convert_Pair_128 (I16x8, I8x16, "sqxtn v0.8b, v0.8h" & ASCII.LF & ASCII.HT & "sqxtn2 v0.16b, v1.8h");
   function Narrow_Saturate (Low, High : I16x8) return I8x16 is (Native_Narrow_Saturate_I16x8_To_I8x16 (Low, High));
   function Native_Narrow_Truncate_U32x4_To_U16x8 is new NEON_Convert_Pair_128 (U32x4, U16x8, "xtn v0.4h, v0.4s" & ASCII.LF & ASCII.HT & "xtn2 v0.8h, v1.4s");
   function Narrow_Truncate (Low, High : U32x4) return U16x8 is (Native_Narrow_Truncate_U32x4_To_U16x8 (Low, High));
   function Native_Narrow_Saturate_U32x4_To_U16x8 is new NEON_Convert_Pair_128 (U32x4, U16x8, "uqxtn v0.4h, v0.4s" & ASCII.LF & ASCII.HT & "uqxtn2 v0.8h, v1.4s");
   function Narrow_Saturate (Low, High : U32x4) return U16x8 is (Native_Narrow_Saturate_U32x4_To_U16x8 (Low, High));
   function Native_Narrow_Truncate_I32x4_To_I16x8 is new NEON_Convert_Pair_128 (I32x4, I16x8, "xtn v0.4h, v0.4s" & ASCII.LF & ASCII.HT & "xtn2 v0.8h, v1.4s");
   function Narrow_Truncate (Low, High : I32x4) return I16x8 is (Native_Narrow_Truncate_I32x4_To_I16x8 (Low, High));
   function Native_Narrow_Saturate_I32x4_To_I16x8 is new NEON_Convert_Pair_128 (I32x4, I16x8, "sqxtn v0.4h, v0.4s" & ASCII.LF & ASCII.HT & "sqxtn2 v0.8h, v1.4s");
   function Narrow_Saturate (Low, High : I32x4) return I16x8 is (Native_Narrow_Saturate_I32x4_To_I16x8 (Low, High));
   function Native_Narrow_Truncate_U64x2_To_U32x4 is new NEON_Convert_Pair_128 (U64x2, U32x4, "xtn v0.2s, v0.2d" & ASCII.LF & ASCII.HT & "xtn2 v0.4s, v1.2d");
   function Narrow_Truncate (Low, High : U64x2) return U32x4 is (Native_Narrow_Truncate_U64x2_To_U32x4 (Low, High));
   function Native_Narrow_Saturate_U64x2_To_U32x4 is new NEON_Convert_Pair_128 (U64x2, U32x4, "uqxtn v0.2s, v0.2d" & ASCII.LF & ASCII.HT & "uqxtn2 v0.4s, v1.2d");
   function Narrow_Saturate (Low, High : U64x2) return U32x4 is (Native_Narrow_Saturate_U64x2_To_U32x4 (Low, High));
   function Native_Narrow_Truncate_I64x2_To_I32x4 is new NEON_Convert_Pair_128 (I64x2, I32x4, "xtn v0.2s, v0.2d" & ASCII.LF & ASCII.HT & "xtn2 v0.4s, v1.2d");
   function Narrow_Truncate (Low, High : I64x2) return I32x4 is (Native_Narrow_Truncate_I64x2_To_I32x4 (Low, High));
   function Native_Narrow_Saturate_I64x2_To_I32x4 is new NEON_Convert_Pair_128 (I64x2, I32x4, "sqxtn v0.2s, v0.2d" & ASCII.LF & ASCII.HT & "sqxtn2 v0.4s, v1.2d");
   function Narrow_Saturate (Low, High : I64x2) return I32x4 is (Native_Narrow_Saturate_I64x2_To_I32x4 (Low, High));
   function Native_Narrow_Saturate_I16x8_To_U8x16 is new NEON_Convert_Pair_128 (I16x8, U8x16, "sqxtun v0.8b, v0.8h" & ASCII.LF & ASCII.HT & "sqxtun2 v0.16b, v1.8h");
   function Narrow_Saturate (Low, High : I16x8) return U8x16 is (Native_Narrow_Saturate_I16x8_To_U8x16 (Low, High));
   function Native_Narrow_Saturate_I32x4_To_U16x8 is new NEON_Convert_Pair_128 (I32x4, U16x8, "sqxtun v0.4h, v0.4s" & ASCII.LF & ASCII.HT & "sqxtun2 v0.8h, v1.4s");
   function Narrow_Saturate (Low, High : I32x4) return U16x8 is (Native_Narrow_Saturate_I32x4_To_U16x8 (Low, High));
   function Native_Narrow_Saturate_I64x2_To_U32x4 is new NEON_Convert_Pair_128 (I64x2, U32x4, "sqxtun v0.2s, v0.2d" & ASCII.LF & ASCII.HT & "sqxtun2 v0.4s, v1.2d");
   function Narrow_Saturate (Low, High : I64x2) return U32x4 is (Native_Narrow_Saturate_I64x2_To_U32x4 (Low, High));
   function Native_Narrow_Round_F64x2_To_F32x4 is new NEON_Convert_Pair_128 (F64x2, F32x4, "fcvtn v0.2s, v0.2d" & ASCII.LF & ASCII.HT & "fcvtn2 v0.4s, v1.2d");
   function Narrow_Round (Low, High : F64x2) return F32x4 is (Native_Narrow_Round_F64x2_To_F32x4 (Low, High));
   function Native_Convert_Round_I32x4_To_F32x4 is new NEON_Convert_128 (I32x4, F32x4, "scvtf v0.4s, v0.4s");
   function Convert_Round (Value : I32x4) return F32x4 is (Native_Convert_Round_I32x4_To_F32x4 (Value));
   function Native_Convert_Round_U32x4_To_F32x4 is new NEON_Convert_128 (U32x4, F32x4, "ucvtf v0.4s, v0.4s");
   function Convert_Round (Value : U32x4) return F32x4 is (Native_Convert_Round_U32x4_To_F32x4 (Value));
   function Native_Convert_Round_I64x2_To_F64x2 is new NEON_Convert_128 (I64x2, F64x2, "scvtf v0.2d, v0.2d");
   function Convert_Round (Value : I64x2) return F64x2 is (Native_Convert_Round_I64x2_To_F64x2 (Value));
   function Native_Convert_Round_U64x2_To_F64x2 is new NEON_Convert_128 (U64x2, F64x2, "ucvtf v0.2d, v0.2d");
   function Convert_Round (Value : U64x2) return F64x2 is (Native_Convert_Round_U64x2_To_F64x2 (Value));
   function Native_Convert_Truncate_Saturate_F32x4_To_I32x4 is new NEON_Convert_128 (F32x4, I32x4, "fcvtzs v0.4s, v0.4s");
   function Convert_Truncate_Saturate (Value : F32x4) return I32x4 is (Native_Convert_Truncate_Saturate_F32x4_To_I32x4 (Value));
   function Native_Convert_Truncate_Saturate_F32x4_To_U32x4 is new NEON_Convert_128 (F32x4, U32x4, "fcvtzu v0.4s, v0.4s");
   function Convert_Truncate_Saturate (Value : F32x4) return U32x4 is (Native_Convert_Truncate_Saturate_F32x4_To_U32x4 (Value));
   function Native_Convert_Truncate_Saturate_F64x2_To_I64x2 is new NEON_Convert_128 (F64x2, I64x2, "fcvtzs v0.2d, v0.2d");
   function Convert_Truncate_Saturate (Value : F64x2) return I64x2 is (Native_Convert_Truncate_Saturate_F64x2_To_I64x2 (Value));
   function Native_Convert_Truncate_Saturate_F64x2_To_U64x2 is new NEON_Convert_128 (F64x2, U64x2, "fcvtzu v0.2d, v0.2d");
   function Convert_Truncate_Saturate (Value : F64x2) return U64x2 is (Native_Convert_Truncate_Saturate_F64x2_To_U64x2 (Value));
   function Native_Convert_Saturate_I8x16_To_U8x16 is new NEON_Convert_128 (I8x16, U8x16, "movi v1.2d, #0" & ASCII.LF & ASCII.HT & "smax v0.16b, v0.16b, v1.16b");
   function Convert_Saturate (Value : I8x16) return U8x16 is (Native_Convert_Saturate_I8x16_To_U8x16 (Value));
   function Native_Convert_Saturate_U8x16_To_I8x16 is new NEON_Convert_128 (U8x16, I8x16, "movi v1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr v1.16b, v1.16b, #1" & ASCII.LF & ASCII.HT & "umin v0.16b, v0.16b, v1.16b");
   function Convert_Saturate (Value : U8x16) return I8x16 is (Native_Convert_Saturate_U8x16_To_I8x16 (Value));
   function Native_Convert_Saturate_I16x8_To_U16x8 is new NEON_Convert_128 (I16x8, U16x8, "movi v1.2d, #0" & ASCII.LF & ASCII.HT & "smax v0.8h, v0.8h, v1.8h");
   function Convert_Saturate (Value : I16x8) return U16x8 is (Native_Convert_Saturate_I16x8_To_U16x8 (Value));
   function Native_Convert_Saturate_U16x8_To_I16x8 is new NEON_Convert_128 (U16x8, I16x8, "movi v1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr v1.8h, v1.8h, #1" & ASCII.LF & ASCII.HT & "umin v0.8h, v0.8h, v1.8h");
   function Convert_Saturate (Value : U16x8) return I16x8 is (Native_Convert_Saturate_U16x8_To_I16x8 (Value));
   function Native_Convert_Saturate_I32x4_To_U32x4 is new NEON_Convert_128 (I32x4, U32x4, "movi v1.2d, #0" & ASCII.LF & ASCII.HT & "smax v0.4s, v0.4s, v1.4s");
   function Convert_Saturate (Value : I32x4) return U32x4 is (Native_Convert_Saturate_I32x4_To_U32x4 (Value));
   function Native_Convert_Saturate_U32x4_To_I32x4 is new NEON_Convert_128 (U32x4, I32x4, "movi v1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr v1.4s, v1.4s, #1" & ASCII.LF & ASCII.HT & "umin v0.4s, v0.4s, v1.4s");
   function Convert_Saturate (Value : U32x4) return I32x4 is (Native_Convert_Saturate_U32x4_To_I32x4 (Value));
   function Native_Convert_Saturate_I64x2_To_U64x2 is new NEON_Convert_128 (I64x2, U64x2, "cmge v1.2d, v0.2d, #0" & ASCII.LF & ASCII.HT & "and v0.16b, v0.16b, v1.16b");
   function Convert_Saturate (Value : I64x2) return U64x2 is (Native_Convert_Saturate_I64x2_To_U64x2 (Value));
   function Native_Convert_Saturate_U64x2_To_I64x2 is new NEON_Convert_128 (U64x2, I64x2, "movi v1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr v1.2d, v1.2d, #1" & ASCII.LF & ASCII.HT & "cmhi v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bsl v2.16b, v1.16b, v0.16b" & ASCII.LF & ASCII.HT & "mov v0.16b, v2.16b");
   function Convert_Saturate (Value : U64x2) return I64x2 is (Native_Convert_Saturate_U64x2_To_I64x2 (Value));
   function Native_Table_Lookup_U8x16 is new NEON_Binary_128 (U8x16, "tbl v0.16b, {v0.16b}, v1.16b");
   function Table_Lookup (Table, Indices : U8x16) return U8x16 is (Native_Table_Lookup_U8x16 (Table, Indices));
   function Native_Permute_U8x16 is new NEON_Permute_128 (U8x16, Lane_Map_8x16);
   pragma Inline_Always (Native_Permute_U8x16);
   function Permute_Lanes (Value : U8x16; Map : Lane_Map_8x16) return U8x16 is (Native_Permute_U8x16 (Value, Map));
   function Native_Permute_2_U8x16 is new NEON_Permute_2_128 (U8x16, Two_Source_Lane_Map_8x16);
   pragma Inline_Always (Native_Permute_2_U8x16);
   function Permute_Lanes (Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16) return U8x16 is (Native_Permute_2_U8x16 (Left, Right, Map));
   function Compress (Value : U8x16; Mask : Mask_8x16) return U8x16 is
      Map : Lane_Map_8x16;
      Bits : constant Interfaces.Unsigned_16 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_8x16 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 0 loop
               Map.Byte_Indices
                 (Result_Lane * 1 + Byte) :=
                   U8 (Source_Lane * 1 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 16 loop
         for Byte in Natural range 0 .. 0 loop
            Map.Byte_Indices
              (Result_Lane * 1 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_U8x16 (Value, Map);
   end Compress;

   function Expand (Value : U8x16; Mask : Mask_8x16) return U8x16 is
      Map : Lane_Map_8x16;
      Bits : constant Interfaces.Unsigned_16 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_8x16 loop
         for Byte in Natural range 0 .. 0 loop
            Map.Byte_Indices
              (Result_Lane * 1 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 1 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_U8x16 (Value, Map);
   end Expand;


   function Native_Slide_Lanes_Toward_Low_U8x16_1 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_1);
   function Native_Slide_Lanes_Toward_Low_U8x16_2 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_2);
   function Native_Slide_Lanes_Toward_Low_U8x16_3 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_3);
   function Native_Slide_Lanes_Toward_Low_U8x16_4 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_4);
   function Native_Slide_Lanes_Toward_Low_U8x16_5 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_5);
   function Native_Slide_Lanes_Toward_Low_U8x16_6 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_6);
   function Native_Slide_Lanes_Toward_Low_U8x16_7 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_7);
   function Native_Slide_Lanes_Toward_Low_U8x16_8 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_8);
   function Native_Slide_Lanes_Toward_Low_U8x16_9 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_9);
   function Native_Slide_Lanes_Toward_Low_U8x16_10 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_10);
   function Native_Slide_Lanes_Toward_Low_U8x16_11 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_11);
   function Native_Slide_Lanes_Toward_Low_U8x16_12 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_12);
   function Native_Slide_Lanes_Toward_Low_U8x16_13 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_13);
   function Native_Slide_Lanes_Toward_Low_U8x16_14 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_14);
   function Native_Slide_Lanes_Toward_Low_U8x16_15 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_15);
   function Slide_Lanes_Toward_Low (Value : U8x16; Count : Natural) return U8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U8x16_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_U8x16_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_U8x16_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_Low_U8x16_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_Low_U8x16_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_Low_U8x16_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_Low_U8x16_7 (Value),
         when 8 => Native_Slide_Lanes_Toward_Low_U8x16_8 (Value),
         when 9 => Native_Slide_Lanes_Toward_Low_U8x16_9 (Value),
         when 10 => Native_Slide_Lanes_Toward_Low_U8x16_10 (Value),
         when 11 => Native_Slide_Lanes_Toward_Low_U8x16_11 (Value),
         when 12 => Native_Slide_Lanes_Toward_Low_U8x16_12 (Value),
         when 13 => Native_Slide_Lanes_Toward_Low_U8x16_13 (Value),
         when 14 => Native_Slide_Lanes_Toward_Low_U8x16_14 (Value),
         when 15 => Native_Slide_Lanes_Toward_Low_U8x16_15 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_U8x16_1 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_1);
   function Native_Slide_Lanes_Toward_High_U8x16_2 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_2);
   function Native_Slide_Lanes_Toward_High_U8x16_3 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_3);
   function Native_Slide_Lanes_Toward_High_U8x16_4 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_4);
   function Native_Slide_Lanes_Toward_High_U8x16_5 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_5);
   function Native_Slide_Lanes_Toward_High_U8x16_6 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_6);
   function Native_Slide_Lanes_Toward_High_U8x16_7 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_7);
   function Native_Slide_Lanes_Toward_High_U8x16_8 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_8);
   function Native_Slide_Lanes_Toward_High_U8x16_9 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_9);
   function Native_Slide_Lanes_Toward_High_U8x16_10 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_10);
   function Native_Slide_Lanes_Toward_High_U8x16_11 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_11);
   function Native_Slide_Lanes_Toward_High_U8x16_12 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_12);
   function Native_Slide_Lanes_Toward_High_U8x16_13 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_13);
   function Native_Slide_Lanes_Toward_High_U8x16_14 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_14);
   function Native_Slide_Lanes_Toward_High_U8x16_15 is new NEON_Unary_128 (U8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_15);
   function Slide_Lanes_Toward_High (Value : U8x16; Count : Natural) return U8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U8x16_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_U8x16_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_U8x16_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_High_U8x16_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_High_U8x16_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_High_U8x16_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_High_U8x16_7 (Value),
         when 8 => Native_Slide_Lanes_Toward_High_U8x16_8 (Value),
         when 9 => Native_Slide_Lanes_Toward_High_U8x16_9 (Value),
         when 10 => Native_Slide_Lanes_Toward_High_U8x16_10 (Value),
         when 11 => Native_Slide_Lanes_Toward_High_U8x16_11 (Value),
         when 12 => Native_Slide_Lanes_Toward_High_U8x16_12 (Value),
         when 13 => Native_Slide_Lanes_Toward_High_U8x16_13 (Value),
         when 14 => Native_Slide_Lanes_Toward_High_U8x16_14 (Value),
         when 15 => Native_Slide_Lanes_Toward_High_U8x16_15 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_I8x16_1 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_1);
   function Native_Slide_Lanes_Toward_Low_I8x16_2 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_2);
   function Native_Slide_Lanes_Toward_Low_I8x16_3 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_3);
   function Native_Slide_Lanes_Toward_Low_I8x16_4 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_4);
   function Native_Slide_Lanes_Toward_Low_I8x16_5 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_5);
   function Native_Slide_Lanes_Toward_Low_I8x16_6 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_6);
   function Native_Slide_Lanes_Toward_Low_I8x16_7 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_7);
   function Native_Slide_Lanes_Toward_Low_I8x16_8 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_8);
   function Native_Slide_Lanes_Toward_Low_I8x16_9 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_9);
   function Native_Slide_Lanes_Toward_Low_I8x16_10 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_10);
   function Native_Slide_Lanes_Toward_Low_I8x16_11 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_11);
   function Native_Slide_Lanes_Toward_Low_I8x16_12 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_12);
   function Native_Slide_Lanes_Toward_Low_I8x16_13 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_13);
   function Native_Slide_Lanes_Toward_Low_I8x16_14 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_14);
   function Native_Slide_Lanes_Toward_Low_I8x16_15 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_15);
   function Slide_Lanes_Toward_Low (Value : I8x16; Count : Natural) return I8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I8x16_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_I8x16_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_I8x16_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_Low_I8x16_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_Low_I8x16_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_Low_I8x16_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_Low_I8x16_7 (Value),
         when 8 => Native_Slide_Lanes_Toward_Low_I8x16_8 (Value),
         when 9 => Native_Slide_Lanes_Toward_Low_I8x16_9 (Value),
         when 10 => Native_Slide_Lanes_Toward_Low_I8x16_10 (Value),
         when 11 => Native_Slide_Lanes_Toward_Low_I8x16_11 (Value),
         when 12 => Native_Slide_Lanes_Toward_Low_I8x16_12 (Value),
         when 13 => Native_Slide_Lanes_Toward_Low_I8x16_13 (Value),
         when 14 => Native_Slide_Lanes_Toward_Low_I8x16_14 (Value),
         when 15 => Native_Slide_Lanes_Toward_Low_I8x16_15 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_I8x16_1 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_1);
   function Native_Slide_Lanes_Toward_High_I8x16_2 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_2);
   function Native_Slide_Lanes_Toward_High_I8x16_3 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_3);
   function Native_Slide_Lanes_Toward_High_I8x16_4 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_4);
   function Native_Slide_Lanes_Toward_High_I8x16_5 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_5);
   function Native_Slide_Lanes_Toward_High_I8x16_6 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_6);
   function Native_Slide_Lanes_Toward_High_I8x16_7 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_7);
   function Native_Slide_Lanes_Toward_High_I8x16_8 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_8);
   function Native_Slide_Lanes_Toward_High_I8x16_9 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_9);
   function Native_Slide_Lanes_Toward_High_I8x16_10 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_10);
   function Native_Slide_Lanes_Toward_High_I8x16_11 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_11);
   function Native_Slide_Lanes_Toward_High_I8x16_12 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_12);
   function Native_Slide_Lanes_Toward_High_I8x16_13 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_13);
   function Native_Slide_Lanes_Toward_High_I8x16_14 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_14);
   function Native_Slide_Lanes_Toward_High_I8x16_15 is new NEON_Unary_128 (I8x16, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_15);
   function Slide_Lanes_Toward_High (Value : I8x16; Count : Natural) return I8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I8x16_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_I8x16_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_I8x16_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_High_I8x16_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_High_I8x16_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_High_I8x16_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_High_I8x16_7 (Value),
         when 8 => Native_Slide_Lanes_Toward_High_I8x16_8 (Value),
         when 9 => Native_Slide_Lanes_Toward_High_I8x16_9 (Value),
         when 10 => Native_Slide_Lanes_Toward_High_I8x16_10 (Value),
         when 11 => Native_Slide_Lanes_Toward_High_I8x16_11 (Value),
         when 12 => Native_Slide_Lanes_Toward_High_I8x16_12 (Value),
         when 13 => Native_Slide_Lanes_Toward_High_I8x16_13 (Value),
         when 14 => Native_Slide_Lanes_Toward_High_I8x16_14 (Value),
         when 15 => Native_Slide_Lanes_Toward_High_I8x16_15 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_U16x8_1 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_1);
   function Native_Slide_Lanes_Toward_Low_U16x8_2 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_2);
   function Native_Slide_Lanes_Toward_Low_U16x8_3 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_3);
   function Native_Slide_Lanes_Toward_Low_U16x8_4 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_4);
   function Native_Slide_Lanes_Toward_Low_U16x8_5 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_5);
   function Native_Slide_Lanes_Toward_Low_U16x8_6 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_6);
   function Native_Slide_Lanes_Toward_Low_U16x8_7 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_7);
   function Slide_Lanes_Toward_Low (Value : U16x8; Count : Natural) return U16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_U16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_U16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_Low_U16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_Low_U16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_Low_U16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_Low_U16x8_7 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_U16x8_1 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_1);
   function Native_Slide_Lanes_Toward_High_U16x8_2 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_2);
   function Native_Slide_Lanes_Toward_High_U16x8_3 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_3);
   function Native_Slide_Lanes_Toward_High_U16x8_4 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_4);
   function Native_Slide_Lanes_Toward_High_U16x8_5 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_5);
   function Native_Slide_Lanes_Toward_High_U16x8_6 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_6);
   function Native_Slide_Lanes_Toward_High_U16x8_7 is new NEON_Unary_128 (U16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_7);
   function Slide_Lanes_Toward_High (Value : U16x8; Count : Natural) return U16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_U16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_U16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_High_U16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_High_U16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_High_U16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_High_U16x8_7 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_I16x8_1 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_1);
   function Native_Slide_Lanes_Toward_Low_I16x8_2 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_2);
   function Native_Slide_Lanes_Toward_Low_I16x8_3 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_3);
   function Native_Slide_Lanes_Toward_Low_I16x8_4 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_4);
   function Native_Slide_Lanes_Toward_Low_I16x8_5 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_5);
   function Native_Slide_Lanes_Toward_Low_I16x8_6 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_6);
   function Native_Slide_Lanes_Toward_Low_I16x8_7 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_7);
   function Slide_Lanes_Toward_Low (Value : I16x8; Count : Natural) return I16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_I16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_I16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_Low_I16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_Low_I16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_Low_I16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_Low_I16x8_7 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_I16x8_1 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_1);
   function Native_Slide_Lanes_Toward_High_I16x8_2 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_2);
   function Native_Slide_Lanes_Toward_High_I16x8_3 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_3);
   function Native_Slide_Lanes_Toward_High_I16x8_4 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_4);
   function Native_Slide_Lanes_Toward_High_I16x8_5 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_5);
   function Native_Slide_Lanes_Toward_High_I16x8_6 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_6);
   function Native_Slide_Lanes_Toward_High_I16x8_7 is new NEON_Unary_128 (I16x8, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_7);
   function Slide_Lanes_Toward_High (Value : I16x8; Count : Natural) return I16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_I16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_I16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_High_I16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_High_I16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_High_I16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_High_I16x8_7 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_U32x4_1 is new NEON_Unary_128 (U32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_1);
   function Native_Slide_Lanes_Toward_Low_U32x4_2 is new NEON_Unary_128 (U32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_2);
   function Native_Slide_Lanes_Toward_Low_U32x4_3 is new NEON_Unary_128 (U32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_3);
   function Slide_Lanes_Toward_Low (Value : U32x4; Count : Natural) return U32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_U32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_U32x4_3 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_U32x4_1 is new NEON_Unary_128 (U32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_1);
   function Native_Slide_Lanes_Toward_High_U32x4_2 is new NEON_Unary_128 (U32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_2);
   function Native_Slide_Lanes_Toward_High_U32x4_3 is new NEON_Unary_128 (U32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_3);
   function Slide_Lanes_Toward_High (Value : U32x4; Count : Natural) return U32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_U32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_U32x4_3 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_I32x4_1 is new NEON_Unary_128 (I32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_1);
   function Native_Slide_Lanes_Toward_Low_I32x4_2 is new NEON_Unary_128 (I32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_2);
   function Native_Slide_Lanes_Toward_Low_I32x4_3 is new NEON_Unary_128 (I32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_3);
   function Slide_Lanes_Toward_Low (Value : I32x4; Count : Natural) return I32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_I32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_I32x4_3 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_I32x4_1 is new NEON_Unary_128 (I32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_1);
   function Native_Slide_Lanes_Toward_High_I32x4_2 is new NEON_Unary_128 (I32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_2);
   function Native_Slide_Lanes_Toward_High_I32x4_3 is new NEON_Unary_128 (I32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_3);
   function Slide_Lanes_Toward_High (Value : I32x4; Count : Natural) return I32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_I32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_I32x4_3 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_U64x2_1 is new NEON_Unary_128 (U64x2, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U64x2_1);
   function Slide_Lanes_Toward_Low (Value : U64x2; Count : Natural) return U64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U64x2_1 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_U64x2_1 is new NEON_Unary_128 (U64x2, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U64x2_1);
   function Slide_Lanes_Toward_High (Value : U64x2; Count : Natural) return U64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U64x2_1 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_I64x2_1 is new NEON_Unary_128 (I64x2, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I64x2_1);
   function Slide_Lanes_Toward_Low (Value : I64x2; Count : Natural) return I64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I64x2_1 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_I64x2_1 is new NEON_Unary_128 (I64x2, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I64x2_1);
   function Slide_Lanes_Toward_High (Value : I64x2; Count : Natural) return I64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I64x2_1 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_F32x4_1 is new NEON_Unary_128 (F32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_1);
   function Native_Slide_Lanes_Toward_Low_F32x4_2 is new NEON_Unary_128 (F32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_2);
   function Native_Slide_Lanes_Toward_Low_F32x4_3 is new NEON_Unary_128 (F32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_3);
   function Slide_Lanes_Toward_Low (Value : F32x4; Count : Natural) return F32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_F32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_F32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_F32x4_3 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_F32x4_1 is new NEON_Unary_128 (F32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_1);
   function Native_Slide_Lanes_Toward_High_F32x4_2 is new NEON_Unary_128 (F32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_2);
   function Native_Slide_Lanes_Toward_High_F32x4_3 is new NEON_Unary_128 (F32x4, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_3);
   function Slide_Lanes_Toward_High (Value : F32x4; Count : Natural) return F32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_F32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_F32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_F32x4_3 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_Low_F64x2_1 is new NEON_Unary_128 (F64x2, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F64x2_1);
   function Slide_Lanes_Toward_Low (Value : F64x2; Count : Natural) return F64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_F64x2_1 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Slide_Lanes_Toward_High_F64x2_1 is new NEON_Unary_128 (F64x2, "movi v1.16b, #0" & ASCII.LF & ASCII.HT & "ext v0.16b, v1.16b, v0.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F64x2_1);
   function Slide_Lanes_Toward_High (Value : F64x2; Count : Natural) return F64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Flyology_SIMD.Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_F64x2_1 (Value),
         when others => Flyology_SIMD.Zero));

   function Native_Add_Wrap_I8x16 is new NEON_Binary_128 (I8x16, "add v0.16b, v0.16b, v1.16b");
   function Add_Wrap (Left, Right : I8x16) return I8x16 is (Native_Add_Wrap_I8x16 (Left, Right));
   function Native_Subtract_Wrap_I8x16 is new NEON_Binary_128 (I8x16, "sub v0.16b, v0.16b, v1.16b");
   function Subtract_Wrap (Left, Right : I8x16) return I8x16 is (Native_Subtract_Wrap_I8x16 (Left, Right));
   function Native_Add_Saturate_I8x16 is new NEON_Binary_128 (I8x16, "sqadd v0.16b, v0.16b, v1.16b");
   function Add_Saturate (Left, Right : I8x16) return I8x16 is (Native_Add_Saturate_I8x16 (Left, Right));
   function Native_Subtract_Saturate_I8x16 is new NEON_Binary_128 (I8x16, "sqsub v0.16b, v0.16b, v1.16b");
   function Subtract_Saturate (Left, Right : I8x16) return I8x16 is (Native_Subtract_Saturate_I8x16 (Left, Right));
   function Native_Bitwise_And_I8x16 is new NEON_Binary_128 (I8x16, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : I8x16) return I8x16 is (Native_Bitwise_And_I8x16 (Left, Right));
   function Native_Bitwise_Or_I8x16 is new NEON_Binary_128 (I8x16, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Or_I8x16 (Left, Right));
   function Native_Bitwise_Xor_I8x16 is new NEON_Binary_128 (I8x16, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Xor_I8x16 (Left, Right));
   function Native_Min_I8x16 is new NEON_Binary_128 (I8x16, "smin v0.16b, v0.16b, v1.16b");
   function Min (Left, Right : I8x16) return I8x16 is (Native_Min_I8x16 (Left, Right));
   function Native_Max_I8x16 is new NEON_Binary_128 (I8x16, "smax v0.16b, v0.16b, v1.16b");
   function Max (Left, Right : I8x16) return I8x16 is (Native_Max_I8x16 (Left, Right));
   function Native_Interleave_Low_I8x16 is new NEON_Binary_128 (I8x16, "zip1 v0.16b, v0.16b, v1.16b");
   function Interleave_Low (Left, Right : I8x16) return I8x16 is (Native_Interleave_Low_I8x16 (Left, Right));
   function Native_Interleave_High_I8x16 is new NEON_Binary_128 (I8x16, "zip2 v0.16b, v0.16b, v1.16b");
   function Interleave_High (Left, Right : I8x16) return I8x16 is (Native_Interleave_High_I8x16 (Left, Right));
   function Native_Deinterleave_Even_I8x16 is new NEON_Binary_128 (I8x16, "uzp1 v0.16b, v0.16b, v1.16b");
   function Deinterleave_Even (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Even_I8x16 (Left, Right));
   function Native_Deinterleave_Odd_I8x16 is new NEON_Binary_128 (I8x16, "uzp2 v0.16b, v0.16b, v1.16b");
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Odd_I8x16 (Left, Right));
   function Native_Multiply_Wrap_I8x16 is new NEON_Binary_128 (I8x16, "mul v0.16b, v0.16b, v1.16b");
   function Multiply_Wrap (Left, Right : I8x16) return I8x16 is (Native_Multiply_Wrap_I8x16 (Left, Right));
   function Native_Not_I8x16 is new NEON_Unary_128 (I8x16, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : I8x16) return I8x16 is (Native_Not_I8x16 (Value));
   function Native_Reverse_I8x16 is new NEON_Unary_128 (I8x16, "rev64 v0.16b, v0.16b" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : I8x16) return I8x16 is (Native_Reverse_I8x16 (Value));
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
   function Native_Permute_I8x16 is new NEON_Permute_128 (I8x16, Lane_Map_8x16);
   pragma Inline_Always (Native_Permute_I8x16);
   function Permute_Lanes (Value : I8x16; Map : Lane_Map_8x16) return I8x16 is (Native_Permute_I8x16 (Value, Map));
   function Native_Permute_2_I8x16 is new NEON_Permute_2_128 (I8x16, Two_Source_Lane_Map_8x16);
   pragma Inline_Always (Native_Permute_2_I8x16);
   function Permute_Lanes (Left, Right : I8x16; Map : Two_Source_Lane_Map_8x16) return I8x16 is (Native_Permute_2_I8x16 (Left, Right, Map));
   function Compress (Value : I8x16; Mask : Mask_8x16) return I8x16 is
      Map : Lane_Map_8x16;
      Bits : constant Interfaces.Unsigned_16 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_8x16 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 0 loop
               Map.Byte_Indices
                 (Result_Lane * 1 + Byte) :=
                   U8 (Source_Lane * 1 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 16 loop
         for Byte in Natural range 0 .. 0 loop
            Map.Byte_Indices
              (Result_Lane * 1 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_I8x16 (Value, Map);
   end Compress;

   function Expand (Value : I8x16; Mask : Mask_8x16) return I8x16 is
      Map : Lane_Map_8x16;
      Bits : constant Interfaces.Unsigned_16 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_8x16 loop
         for Byte in Natural range 0 .. 0 loop
            Map.Byte_Indices
              (Result_Lane * 1 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 1 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_I8x16 (Value, Map);
   end Expand;

   function Native_Shift_Left_Logical_I8x16 is new NEON_Shift_128 (I8x16, "dup v1.16b, %w2", "ushl v0.16b, v0.16b, v1.16b");
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16 is
     (if Count >= 8 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_I8x16 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_I8x16 is new NEON_Shift_128 (I8x16, "dup v1.16b, %w2", "ushl v0.16b, v0.16b, v1.16b");
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16 is
     (if Count >= 8 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_I8x16 (Value, -Interfaces.Integer_64 (Count)));
   function Native_SRA_I8x16 is new NEON_Shift_128 (I8x16, "dup v1.16b, %w2", "sshl v0.16b, v0.16b, v1.16b");
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16 is
     (if Count >= 8 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SRA_I8x16 (Value, -Interfaces.Integer_64 (Count)));
   function Compare_I8x16 is new NEON_Compare_16_Lanes (I8x16, "cmeq v0.16b, v0.16b, v1.16b");
   function Compare_Greater_I8x16 is new NEON_Compare_16_Lanes (I8x16, "cmgt v0.16b, v0.16b, v1.16b");
   function Compare_Greater_Equal_I8x16 is new NEON_Compare_16_Lanes (I8x16, "cmge v0.16b, v0.16b, v1.16b");
   function Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_I8x16 (Left, Right, Weights_8x16'Address)));
   function Greater_Than (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_I8x16 (Left, Right, Weights_8x16'Address)));
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I8x16 (Left, Right, Weights_8x16'Address)));
   function Less_Than (Left, Right : I8x16) return Mask_8x16 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I8x16) return Mask_8x16 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I8x16 is new NEON_Select_16_Lanes_128 (I8x16);
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16 is (Native_Select_I8x16 (Mask.Bits, Weights_8x16'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_I8x16 is new NEON_Integer_Reduce_128 (I8x16, I8, "addv b0, v0.16b", "str b0, [%0]");
   function Reduce_Add_Wrap (Value : I8x16) return I8 is (Native_Reduce_Add_Wrap_I8x16 (Value));
   function Native_Reduce_Min_I8x16 is new NEON_Integer_Reduce_128 (I8x16, I8, "sminv b0, v0.16b", "str b0, [%0]");
   function Reduce_Min (Value : I8x16) return I8 is (Native_Reduce_Min_I8x16 (Value));
   function Native_Reduce_Max_I8x16 is new NEON_Integer_Reduce_128 (I8x16, I8, "smaxv b0, v0.16b", "str b0, [%0]");
   function Reduce_Max (Value : I8x16) return I8 is (Native_Reduce_Max_I8x16 (Value));
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 is
      Result : I8x16;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Compare_U16x8 is new NEON_Compare_128 (U16x8, "cmeq v0.8h, v0.8h, v1.8h", "ushr v0.8h, v0.8h, #15" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.8h, v0.8h, v2.8h" & ASCII.LF & ASCII.HT & "addv h0, v0.8h" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]");
   function Compare_Greater_U16x8 is new NEON_Compare_128 (U16x8, "cmhi v0.8h, v0.8h, v1.8h", "ushr v0.8h, v0.8h, #15" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.8h, v0.8h, v2.8h" & ASCII.LF & ASCII.HT & "addv h0, v0.8h" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]");
   function Compare_Greater_Equal_U16x8 is new NEON_Compare_128 (U16x8, "cmhs v0.8h, v0.8h, v1.8h", "ushr v0.8h, v0.8h, #15" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.8h, v0.8h, v2.8h" & ASCII.LF & ASCII.HT & "addv h0, v0.8h" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]");
   function Native_Add_Wrap_U16x8 is new NEON_Binary_128 (U16x8, "add v0.8h, v0.8h, v1.8h");
   function Add_Wrap (Left, Right : U16x8) return U16x8 is (Native_Add_Wrap_U16x8 (Left, Right));
   function Native_Subtract_Wrap_U16x8 is new NEON_Binary_128 (U16x8, "sub v0.8h, v0.8h, v1.8h");
   function Subtract_Wrap (Left, Right : U16x8) return U16x8 is (Native_Subtract_Wrap_U16x8 (Left, Right));
   function Native_Add_Saturate_U16x8 is new NEON_Binary_128 (U16x8, "uqadd v0.8h, v0.8h, v1.8h");
   function Add_Saturate (Left, Right : U16x8) return U16x8 is (Native_Add_Saturate_U16x8 (Left, Right));
   function Native_Subtract_Saturate_U16x8 is new NEON_Binary_128 (U16x8, "uqsub v0.8h, v0.8h, v1.8h");
   function Subtract_Saturate (Left, Right : U16x8) return U16x8 is (Native_Subtract_Saturate_U16x8 (Left, Right));
   function Native_Bitwise_And_U16x8 is new NEON_Binary_128 (U16x8, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : U16x8) return U16x8 is (Native_Bitwise_And_U16x8 (Left, Right));
   function Native_Bitwise_Or_U16x8 is new NEON_Binary_128 (U16x8, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Or_U16x8 (Left, Right));
   function Native_Bitwise_Xor_U16x8 is new NEON_Binary_128 (U16x8, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Xor_U16x8 (Left, Right));
   function Native_Min_U16x8 is new NEON_Binary_128 (U16x8, "umin v0.8h, v0.8h, v1.8h");
   function Min (Left, Right : U16x8) return U16x8 is (Native_Min_U16x8 (Left, Right));
   function Native_Max_U16x8 is new NEON_Binary_128 (U16x8, "umax v0.8h, v0.8h, v1.8h");
   function Max (Left, Right : U16x8) return U16x8 is (Native_Max_U16x8 (Left, Right));
   function Native_Interleave_Low_U16x8 is new NEON_Binary_128 (U16x8, "zip1 v0.8h, v0.8h, v1.8h");
   function Interleave_Low (Left, Right : U16x8) return U16x8 is (Native_Interleave_Low_U16x8 (Left, Right));
   function Native_Interleave_High_U16x8 is new NEON_Binary_128 (U16x8, "zip2 v0.8h, v0.8h, v1.8h");
   function Interleave_High (Left, Right : U16x8) return U16x8 is (Native_Interleave_High_U16x8 (Left, Right));
   function Native_Deinterleave_Even_U16x8 is new NEON_Binary_128 (U16x8, "uzp1 v0.8h, v0.8h, v1.8h");
   function Deinterleave_Even (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Even_U16x8 (Left, Right));
   function Native_Deinterleave_Odd_U16x8 is new NEON_Binary_128 (U16x8, "uzp2 v0.8h, v0.8h, v1.8h");
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Odd_U16x8 (Left, Right));
   function Native_Multiply_Wrap_U16x8 is new NEON_Binary_128 (U16x8, "mul v0.8h, v0.8h, v1.8h");
   function Multiply_Wrap (Left, Right : U16x8) return U16x8 is (Native_Multiply_Wrap_U16x8 (Left, Right));
   function Native_Not_U16x8 is new NEON_Unary_128 (U16x8, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : U16x8) return U16x8 is (Native_Not_U16x8 (Value));
   function Native_Reverse_U16x8 is new NEON_Unary_128 (U16x8, "rev64 v0.8h, v0.8h" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : U16x8) return U16x8 is (Native_Reverse_U16x8 (Value));
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
   function Native_Permute_U16x8 is new NEON_Permute_128 (U16x8, Lane_Map_16x8);
   pragma Inline_Always (Native_Permute_U16x8);
   function Permute_Lanes (Value : U16x8; Map : Lane_Map_16x8) return U16x8 is (Native_Permute_U16x8 (Value, Map));
   function Native_Permute_2_U16x8 is new NEON_Permute_2_128 (U16x8, Two_Source_Lane_Map_16x8);
   pragma Inline_Always (Native_Permute_2_U16x8);
   function Permute_Lanes (Left, Right : U16x8; Map : Two_Source_Lane_Map_16x8) return U16x8 is (Native_Permute_2_U16x8 (Left, Right, Map));
   function Compress (Value : U16x8; Mask : Mask_16x8) return U16x8 is
      Map : Lane_Map_16x8;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_16x8 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 1 loop
               Map.Byte_Indices
                 (Result_Lane * 2 + Byte) :=
                   U8 (Source_Lane * 2 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 8 loop
         for Byte in Natural range 0 .. 1 loop
            Map.Byte_Indices
              (Result_Lane * 2 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_U16x8 (Value, Map);
   end Compress;

   function Expand (Value : U16x8; Mask : Mask_16x8) return U16x8 is
      Map : Lane_Map_16x8;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_16x8 loop
         for Byte in Natural range 0 .. 1 loop
            Map.Byte_Indices
              (Result_Lane * 2 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 2 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_U16x8 (Value, Map);
   end Expand;

   function Native_Shift_Left_Logical_U16x8 is new NEON_Shift_128 (U16x8, "dup v1.8h, %w2", "ushl v0.8h, v0.8h, v1.8h");
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8 is
     (if Count >= 16 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_U16x8 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_U16x8 is new NEON_Shift_128 (U16x8, "dup v1.8h, %w2", "ushl v0.8h, v0.8h, v1.8h");
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8 is
     (if Count >= 16 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_U16x8 (Value, -Interfaces.Integer_64 (Count)));
   function Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_U16x8 (Left, Right, Weights_16x8'Address)));
   function Greater_Than (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_U16x8 (Left, Right, Weights_16x8'Address)));
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U16x8 (Left, Right, Weights_16x8'Address)));
   function Less_Than (Left, Right : U16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U16x8 is new NEON_Select_128 (U16x8, "dup v2.8h, %w1", "cmtst v2.8h, v2.8h, v3.8h");
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8 is (Native_Select_U16x8 (Interfaces.Unsigned_64 (Mask.Bits), Weights_16x8'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_U16x8 is new NEON_Integer_Reduce_128 (U16x8, U16, "addv h0, v0.8h", "str h0, [%0]");
   function Reduce_Add_Wrap (Value : U16x8) return U16 is (Native_Reduce_Add_Wrap_U16x8 (Value));
   function Native_Reduce_Min_U16x8 is new NEON_Integer_Reduce_128 (U16x8, U16, "uminv h0, v0.8h", "str h0, [%0]");
   function Reduce_Min (Value : U16x8) return U16 is (Native_Reduce_Min_U16x8 (Value));
   function Native_Reduce_Max_U16x8 is new NEON_Integer_Reduce_128 (U16x8, U16, "umaxv h0, v0.8h", "str h0, [%0]");
   function Reduce_Max (Value : U16x8) return U16 is (Native_Reduce_Max_U16x8 (Value));
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 is
      Result : U16x8;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Compare_I16x8 is new NEON_Compare_128 (I16x8, "cmeq v0.8h, v0.8h, v1.8h", "ushr v0.8h, v0.8h, #15" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.8h, v0.8h, v2.8h" & ASCII.LF & ASCII.HT & "addv h0, v0.8h" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]");
   function Compare_Greater_I16x8 is new NEON_Compare_128 (I16x8, "cmgt v0.8h, v0.8h, v1.8h", "ushr v0.8h, v0.8h, #15" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.8h, v0.8h, v2.8h" & ASCII.LF & ASCII.HT & "addv h0, v0.8h" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]");
   function Compare_Greater_Equal_I16x8 is new NEON_Compare_128 (I16x8, "cmge v0.8h, v0.8h, v1.8h", "ushr v0.8h, v0.8h, #15" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.8h, v0.8h, v2.8h" & ASCII.LF & ASCII.HT & "addv h0, v0.8h" & ASCII.LF & ASCII.HT & "umov %w0, v0.h[0]");
   function Native_Add_Wrap_I16x8 is new NEON_Binary_128 (I16x8, "add v0.8h, v0.8h, v1.8h");
   function Add_Wrap (Left, Right : I16x8) return I16x8 is (Native_Add_Wrap_I16x8 (Left, Right));
   function Native_Subtract_Wrap_I16x8 is new NEON_Binary_128 (I16x8, "sub v0.8h, v0.8h, v1.8h");
   function Subtract_Wrap (Left, Right : I16x8) return I16x8 is (Native_Subtract_Wrap_I16x8 (Left, Right));
   function Native_Add_Saturate_I16x8 is new NEON_Binary_128 (I16x8, "sqadd v0.8h, v0.8h, v1.8h");
   function Add_Saturate (Left, Right : I16x8) return I16x8 is (Native_Add_Saturate_I16x8 (Left, Right));
   function Native_Subtract_Saturate_I16x8 is new NEON_Binary_128 (I16x8, "sqsub v0.8h, v0.8h, v1.8h");
   function Subtract_Saturate (Left, Right : I16x8) return I16x8 is (Native_Subtract_Saturate_I16x8 (Left, Right));
   function Native_Bitwise_And_I16x8 is new NEON_Binary_128 (I16x8, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : I16x8) return I16x8 is (Native_Bitwise_And_I16x8 (Left, Right));
   function Native_Bitwise_Or_I16x8 is new NEON_Binary_128 (I16x8, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Or_I16x8 (Left, Right));
   function Native_Bitwise_Xor_I16x8 is new NEON_Binary_128 (I16x8, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Xor_I16x8 (Left, Right));
   function Native_Min_I16x8 is new NEON_Binary_128 (I16x8, "smin v0.8h, v0.8h, v1.8h");
   function Min (Left, Right : I16x8) return I16x8 is (Native_Min_I16x8 (Left, Right));
   function Native_Max_I16x8 is new NEON_Binary_128 (I16x8, "smax v0.8h, v0.8h, v1.8h");
   function Max (Left, Right : I16x8) return I16x8 is (Native_Max_I16x8 (Left, Right));
   function Native_Interleave_Low_I16x8 is new NEON_Binary_128 (I16x8, "zip1 v0.8h, v0.8h, v1.8h");
   function Interleave_Low (Left, Right : I16x8) return I16x8 is (Native_Interleave_Low_I16x8 (Left, Right));
   function Native_Interleave_High_I16x8 is new NEON_Binary_128 (I16x8, "zip2 v0.8h, v0.8h, v1.8h");
   function Interleave_High (Left, Right : I16x8) return I16x8 is (Native_Interleave_High_I16x8 (Left, Right));
   function Native_Deinterleave_Even_I16x8 is new NEON_Binary_128 (I16x8, "uzp1 v0.8h, v0.8h, v1.8h");
   function Deinterleave_Even (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Even_I16x8 (Left, Right));
   function Native_Deinterleave_Odd_I16x8 is new NEON_Binary_128 (I16x8, "uzp2 v0.8h, v0.8h, v1.8h");
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Odd_I16x8 (Left, Right));
   function Native_Multiply_Wrap_I16x8 is new NEON_Binary_128 (I16x8, "mul v0.8h, v0.8h, v1.8h");
   function Multiply_Wrap (Left, Right : I16x8) return I16x8 is (Native_Multiply_Wrap_I16x8 (Left, Right));
   function Native_Not_I16x8 is new NEON_Unary_128 (I16x8, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : I16x8) return I16x8 is (Native_Not_I16x8 (Value));
   function Native_Reverse_I16x8 is new NEON_Unary_128 (I16x8, "rev64 v0.8h, v0.8h" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : I16x8) return I16x8 is (Native_Reverse_I16x8 (Value));
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
   function Native_Permute_I16x8 is new NEON_Permute_128 (I16x8, Lane_Map_16x8);
   pragma Inline_Always (Native_Permute_I16x8);
   function Permute_Lanes (Value : I16x8; Map : Lane_Map_16x8) return I16x8 is (Native_Permute_I16x8 (Value, Map));
   function Native_Permute_2_I16x8 is new NEON_Permute_2_128 (I16x8, Two_Source_Lane_Map_16x8);
   pragma Inline_Always (Native_Permute_2_I16x8);
   function Permute_Lanes (Left, Right : I16x8; Map : Two_Source_Lane_Map_16x8) return I16x8 is (Native_Permute_2_I16x8 (Left, Right, Map));
   function Compress (Value : I16x8; Mask : Mask_16x8) return I16x8 is
      Map : Lane_Map_16x8;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_16x8 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 1 loop
               Map.Byte_Indices
                 (Result_Lane * 2 + Byte) :=
                   U8 (Source_Lane * 2 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 8 loop
         for Byte in Natural range 0 .. 1 loop
            Map.Byte_Indices
              (Result_Lane * 2 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_I16x8 (Value, Map);
   end Compress;

   function Expand (Value : I16x8; Mask : Mask_16x8) return I16x8 is
      Map : Lane_Map_16x8;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_16x8 loop
         for Byte in Natural range 0 .. 1 loop
            Map.Byte_Indices
              (Result_Lane * 2 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 2 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_I16x8 (Value, Map);
   end Expand;

   function Native_Shift_Left_Logical_I16x8 is new NEON_Shift_128 (I16x8, "dup v1.8h, %w2", "ushl v0.8h, v0.8h, v1.8h");
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8 is
     (if Count >= 16 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_I16x8 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_I16x8 is new NEON_Shift_128 (I16x8, "dup v1.8h, %w2", "ushl v0.8h, v0.8h, v1.8h");
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8 is
     (if Count >= 16 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_I16x8 (Value, -Interfaces.Integer_64 (Count)));
   function Native_SRA_I16x8 is new NEON_Shift_128 (I16x8, "dup v1.8h, %w2", "sshl v0.8h, v0.8h, v1.8h");
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8 is
     (if Count >= 16 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SRA_I16x8 (Value, -Interfaces.Integer_64 (Count)));
   function Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_I16x8 (Left, Right, Weights_16x8'Address)));
   function Greater_Than (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_I16x8 (Left, Right, Weights_16x8'Address)));
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I16x8 (Left, Right, Weights_16x8'Address)));
   function Less_Than (Left, Right : I16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I16x8 is new NEON_Select_128 (I16x8, "dup v2.8h, %w1", "cmtst v2.8h, v2.8h, v3.8h");
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8 is (Native_Select_I16x8 (Interfaces.Unsigned_64 (Mask.Bits), Weights_16x8'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_I16x8 is new NEON_Integer_Reduce_128 (I16x8, I16, "addv h0, v0.8h", "str h0, [%0]");
   function Reduce_Add_Wrap (Value : I16x8) return I16 is (Native_Reduce_Add_Wrap_I16x8 (Value));
   function Native_Reduce_Min_I16x8 is new NEON_Integer_Reduce_128 (I16x8, I16, "sminv h0, v0.8h", "str h0, [%0]");
   function Reduce_Min (Value : I16x8) return I16 is (Native_Reduce_Min_I16x8 (Value));
   function Native_Reduce_Max_I16x8 is new NEON_Integer_Reduce_128 (I16x8, I16, "smaxv h0, v0.8h", "str h0, [%0]");
   function Reduce_Max (Value : I16x8) return I16 is (Native_Reduce_Max_I16x8 (Value));
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 is
      Result : I16x8;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Compare_U32x4 is new NEON_Compare_128 (U32x4, "cmeq v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Compare_Greater_U32x4 is new NEON_Compare_128 (U32x4, "cmhi v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Compare_Greater_Equal_U32x4 is new NEON_Compare_128 (U32x4, "cmhs v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Native_Add_Wrap_U32x4 is new NEON_Binary_128 (U32x4, "add v0.4s, v0.4s, v1.4s");
   function Add_Wrap (Left, Right : U32x4) return U32x4 is (Native_Add_Wrap_U32x4 (Left, Right));
   function Native_Subtract_Wrap_U32x4 is new NEON_Binary_128 (U32x4, "sub v0.4s, v0.4s, v1.4s");
   function Subtract_Wrap (Left, Right : U32x4) return U32x4 is (Native_Subtract_Wrap_U32x4 (Left, Right));
   function Native_Add_Saturate_U32x4 is new NEON_Binary_128 (U32x4, "uqadd v0.4s, v0.4s, v1.4s");
   function Add_Saturate (Left, Right : U32x4) return U32x4 is (Native_Add_Saturate_U32x4 (Left, Right));
   function Native_Subtract_Saturate_U32x4 is new NEON_Binary_128 (U32x4, "uqsub v0.4s, v0.4s, v1.4s");
   function Subtract_Saturate (Left, Right : U32x4) return U32x4 is (Native_Subtract_Saturate_U32x4 (Left, Right));
   function Native_Bitwise_And_U32x4 is new NEON_Binary_128 (U32x4, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : U32x4) return U32x4 is (Native_Bitwise_And_U32x4 (Left, Right));
   function Native_Bitwise_Or_U32x4 is new NEON_Binary_128 (U32x4, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Or_U32x4 (Left, Right));
   function Native_Bitwise_Xor_U32x4 is new NEON_Binary_128 (U32x4, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Xor_U32x4 (Left, Right));
   function Native_Min_U32x4 is new NEON_Binary_128 (U32x4, "umin v0.4s, v0.4s, v1.4s");
   function Min (Left, Right : U32x4) return U32x4 is (Native_Min_U32x4 (Left, Right));
   function Native_Max_U32x4 is new NEON_Binary_128 (U32x4, "umax v0.4s, v0.4s, v1.4s");
   function Max (Left, Right : U32x4) return U32x4 is (Native_Max_U32x4 (Left, Right));
   function Native_Interleave_Low_U32x4 is new NEON_Binary_128 (U32x4, "zip1 v0.4s, v0.4s, v1.4s");
   function Interleave_Low (Left, Right : U32x4) return U32x4 is (Native_Interleave_Low_U32x4 (Left, Right));
   function Native_Interleave_High_U32x4 is new NEON_Binary_128 (U32x4, "zip2 v0.4s, v0.4s, v1.4s");
   function Interleave_High (Left, Right : U32x4) return U32x4 is (Native_Interleave_High_U32x4 (Left, Right));
   function Native_Deinterleave_Even_U32x4 is new NEON_Binary_128 (U32x4, "uzp1 v0.4s, v0.4s, v1.4s");
   function Deinterleave_Even (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Even_U32x4 (Left, Right));
   function Native_Deinterleave_Odd_U32x4 is new NEON_Binary_128 (U32x4, "uzp2 v0.4s, v0.4s, v1.4s");
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Odd_U32x4 (Left, Right));
   function Native_Multiply_Wrap_U32x4 is new NEON_Binary_128 (U32x4, "mul v0.4s, v0.4s, v1.4s");
   function Multiply_Wrap (Left, Right : U32x4) return U32x4 is (Native_Multiply_Wrap_U32x4 (Left, Right));
   function Native_Not_U32x4 is new NEON_Unary_128 (U32x4, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : U32x4) return U32x4 is (Native_Not_U32x4 (Value));
   function Native_Reverse_U32x4 is new NEON_Unary_128 (U32x4, "rev64 v0.4s, v0.4s" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : U32x4) return U32x4 is (Native_Reverse_U32x4 (Value));
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
   function Native_Permute_U32x4 is new NEON_Permute_128 (U32x4, Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_U32x4);
   function Permute_Lanes (Value : U32x4; Map : Lane_Map_32x4) return U32x4 is (Native_Permute_U32x4 (Value, Map));
   function Native_Permute_2_U32x4 is new NEON_Permute_2_128 (U32x4, Two_Source_Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_2_U32x4);
   function Permute_Lanes (Left, Right : U32x4; Map : Two_Source_Lane_Map_32x4) return U32x4 is (Native_Permute_2_U32x4 (Left, Right, Map));
   function Compress (Value : U32x4; Mask : Mask_32x4) return U32x4 is
      Map : Lane_Map_32x4;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_32x4 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map.Byte_Indices
                 (Result_Lane * 4 + Byte) :=
                   U8 (Source_Lane * 4 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 4 loop
         for Byte in Natural range 0 .. 3 loop
            Map.Byte_Indices
              (Result_Lane * 4 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_U32x4 (Value, Map);
   end Compress;

   function Expand (Value : U32x4; Mask : Mask_32x4) return U32x4 is
      Map : Lane_Map_32x4;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_32x4 loop
         for Byte in Natural range 0 .. 3 loop
            Map.Byte_Indices
              (Result_Lane * 4 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 4 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_U32x4 (Value, Map);
   end Expand;

   function Native_Shift_Left_Logical_U32x4 is new NEON_Shift_128 (U32x4, "dup v1.4s, %w2", "ushl v0.4s, v0.4s, v1.4s");
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4 is
     (if Count >= 32 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_U32x4 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_U32x4 is new NEON_Shift_128 (U32x4, "dup v1.4s, %w2", "ushl v0.4s, v0.4s, v1.4s");
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4 is
     (if Count >= 32 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_U32x4 (Value, -Interfaces.Integer_64 (Count)));
   function Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_U32x4 (Left, Right, Weights_32x4'Address)));
   function Greater_Than (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_U32x4 (Left, Right, Weights_32x4'Address)));
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U32x4 (Left, Right, Weights_32x4'Address)));
   function Less_Than (Left, Right : U32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U32x4 is new NEON_Select_128 (U32x4, "dup v2.4s, %w1", "cmtst v2.4s, v2.4s, v3.4s");
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4 is (Native_Select_U32x4 (Interfaces.Unsigned_64 (Mask.Bits), Weights_32x4'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_U32x4 is new NEON_Integer_Reduce_128 (U32x4, U32, "addv s0, v0.4s", "str s0, [%0]");
   function Reduce_Add_Wrap (Value : U32x4) return U32 is (Native_Reduce_Add_Wrap_U32x4 (Value));
   function Native_Reduce_Min_U32x4 is new NEON_Integer_Reduce_128 (U32x4, U32, "uminv s0, v0.4s", "str s0, [%0]");
   function Reduce_Min (Value : U32x4) return U32 is (Native_Reduce_Min_U32x4 (Value));
   function Native_Reduce_Max_U32x4 is new NEON_Integer_Reduce_128 (U32x4, U32, "umaxv s0, v0.4s", "str s0, [%0]");
   function Reduce_Max (Value : U32x4) return U32 is (Native_Reduce_Max_U32x4 (Value));
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 is
      Result : U32x4;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Compare_I32x4 is new NEON_Compare_128 (I32x4, "cmeq v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Compare_Greater_I32x4 is new NEON_Compare_128 (I32x4, "cmgt v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Compare_Greater_Equal_I32x4 is new NEON_Compare_128 (I32x4, "cmge v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Native_Add_Wrap_I32x4 is new NEON_Binary_128 (I32x4, "add v0.4s, v0.4s, v1.4s");
   function Add_Wrap (Left, Right : I32x4) return I32x4 is (Native_Add_Wrap_I32x4 (Left, Right));
   function Native_Subtract_Wrap_I32x4 is new NEON_Binary_128 (I32x4, "sub v0.4s, v0.4s, v1.4s");
   function Subtract_Wrap (Left, Right : I32x4) return I32x4 is (Native_Subtract_Wrap_I32x4 (Left, Right));
   function Native_Add_Saturate_I32x4 is new NEON_Binary_128 (I32x4, "sqadd v0.4s, v0.4s, v1.4s");
   function Add_Saturate (Left, Right : I32x4) return I32x4 is (Native_Add_Saturate_I32x4 (Left, Right));
   function Native_Subtract_Saturate_I32x4 is new NEON_Binary_128 (I32x4, "sqsub v0.4s, v0.4s, v1.4s");
   function Subtract_Saturate (Left, Right : I32x4) return I32x4 is (Native_Subtract_Saturate_I32x4 (Left, Right));
   function Native_Bitwise_And_I32x4 is new NEON_Binary_128 (I32x4, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : I32x4) return I32x4 is (Native_Bitwise_And_I32x4 (Left, Right));
   function Native_Bitwise_Or_I32x4 is new NEON_Binary_128 (I32x4, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Or_I32x4 (Left, Right));
   function Native_Bitwise_Xor_I32x4 is new NEON_Binary_128 (I32x4, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Xor_I32x4 (Left, Right));
   function Native_Min_I32x4 is new NEON_Binary_128 (I32x4, "smin v0.4s, v0.4s, v1.4s");
   function Min (Left, Right : I32x4) return I32x4 is (Native_Min_I32x4 (Left, Right));
   function Native_Max_I32x4 is new NEON_Binary_128 (I32x4, "smax v0.4s, v0.4s, v1.4s");
   function Max (Left, Right : I32x4) return I32x4 is (Native_Max_I32x4 (Left, Right));
   function Native_Interleave_Low_I32x4 is new NEON_Binary_128 (I32x4, "zip1 v0.4s, v0.4s, v1.4s");
   function Interleave_Low (Left, Right : I32x4) return I32x4 is (Native_Interleave_Low_I32x4 (Left, Right));
   function Native_Interleave_High_I32x4 is new NEON_Binary_128 (I32x4, "zip2 v0.4s, v0.4s, v1.4s");
   function Interleave_High (Left, Right : I32x4) return I32x4 is (Native_Interleave_High_I32x4 (Left, Right));
   function Native_Deinterleave_Even_I32x4 is new NEON_Binary_128 (I32x4, "uzp1 v0.4s, v0.4s, v1.4s");
   function Deinterleave_Even (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Even_I32x4 (Left, Right));
   function Native_Deinterleave_Odd_I32x4 is new NEON_Binary_128 (I32x4, "uzp2 v0.4s, v0.4s, v1.4s");
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Odd_I32x4 (Left, Right));
   function Native_Multiply_Wrap_I32x4 is new NEON_Binary_128 (I32x4, "mul v0.4s, v0.4s, v1.4s");
   function Multiply_Wrap (Left, Right : I32x4) return I32x4 is (Native_Multiply_Wrap_I32x4 (Left, Right));
   function Native_Not_I32x4 is new NEON_Unary_128 (I32x4, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : I32x4) return I32x4 is (Native_Not_I32x4 (Value));
   function Native_Reverse_I32x4 is new NEON_Unary_128 (I32x4, "rev64 v0.4s, v0.4s" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : I32x4) return I32x4 is (Native_Reverse_I32x4 (Value));
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
   function Native_Permute_I32x4 is new NEON_Permute_128 (I32x4, Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_I32x4);
   function Permute_Lanes (Value : I32x4; Map : Lane_Map_32x4) return I32x4 is (Native_Permute_I32x4 (Value, Map));
   function Native_Permute_2_I32x4 is new NEON_Permute_2_128 (I32x4, Two_Source_Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_2_I32x4);
   function Permute_Lanes (Left, Right : I32x4; Map : Two_Source_Lane_Map_32x4) return I32x4 is (Native_Permute_2_I32x4 (Left, Right, Map));
   function Compress (Value : I32x4; Mask : Mask_32x4) return I32x4 is
      Map : Lane_Map_32x4;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_32x4 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map.Byte_Indices
                 (Result_Lane * 4 + Byte) :=
                   U8 (Source_Lane * 4 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 4 loop
         for Byte in Natural range 0 .. 3 loop
            Map.Byte_Indices
              (Result_Lane * 4 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_I32x4 (Value, Map);
   end Compress;

   function Expand (Value : I32x4; Mask : Mask_32x4) return I32x4 is
      Map : Lane_Map_32x4;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_32x4 loop
         for Byte in Natural range 0 .. 3 loop
            Map.Byte_Indices
              (Result_Lane * 4 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 4 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_I32x4 (Value, Map);
   end Expand;

   function Native_Shift_Left_Logical_I32x4 is new NEON_Shift_128 (I32x4, "dup v1.4s, %w2", "ushl v0.4s, v0.4s, v1.4s");
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4 is
     (if Count >= 32 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_I32x4 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_I32x4 is new NEON_Shift_128 (I32x4, "dup v1.4s, %w2", "ushl v0.4s, v0.4s, v1.4s");
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4 is
     (if Count >= 32 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_I32x4 (Value, -Interfaces.Integer_64 (Count)));
   function Native_SRA_I32x4 is new NEON_Shift_128 (I32x4, "dup v1.4s, %w2", "sshl v0.4s, v0.4s, v1.4s");
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4 is
     (if Count >= 32 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SRA_I32x4 (Value, -Interfaces.Integer_64 (Count)));
   function Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_I32x4 (Left, Right, Weights_32x4'Address)));
   function Greater_Than (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_I32x4 (Left, Right, Weights_32x4'Address)));
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I32x4 (Left, Right, Weights_32x4'Address)));
   function Less_Than (Left, Right : I32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I32x4 is new NEON_Select_128 (I32x4, "dup v2.4s, %w1", "cmtst v2.4s, v2.4s, v3.4s");
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4 is (Native_Select_I32x4 (Interfaces.Unsigned_64 (Mask.Bits), Weights_32x4'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_I32x4 is new NEON_Integer_Reduce_128 (I32x4, I32, "addv s0, v0.4s", "str s0, [%0]");
   function Reduce_Add_Wrap (Value : I32x4) return I32 is (Native_Reduce_Add_Wrap_I32x4 (Value));
   function Native_Reduce_Min_I32x4 is new NEON_Integer_Reduce_128 (I32x4, I32, "sminv s0, v0.4s", "str s0, [%0]");
   function Reduce_Min (Value : I32x4) return I32 is (Native_Reduce_Min_I32x4 (Value));
   function Native_Reduce_Max_I32x4 is new NEON_Integer_Reduce_128 (I32x4, I32, "smaxv s0, v0.4s", "str s0, [%0]");
   function Reduce_Max (Value : I32x4) return I32 is (Native_Reduce_Max_I32x4 (Value));
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 is
      Result : I32x4;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Compare_U64x2 is new NEON_Compare_128 (U64x2, "cmeq v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Compare_Greater_U64x2 is new NEON_Compare_128 (U64x2, "cmhi v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Compare_Greater_Equal_U64x2 is new NEON_Compare_128 (U64x2, "cmhs v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Native_Add_Wrap_U64x2 is new NEON_Binary_128 (U64x2, "add v0.2d, v0.2d, v1.2d");
   function Add_Wrap (Left, Right : U64x2) return U64x2 is (Native_Add_Wrap_U64x2 (Left, Right));
   function Native_Subtract_Wrap_U64x2 is new NEON_Binary_128 (U64x2, "sub v0.2d, v0.2d, v1.2d");
   function Subtract_Wrap (Left, Right : U64x2) return U64x2 is (Native_Subtract_Wrap_U64x2 (Left, Right));
   function Native_Add_Saturate_U64x2 is new NEON_Binary_128 (U64x2, "uqadd v0.2d, v0.2d, v1.2d");
   function Add_Saturate (Left, Right : U64x2) return U64x2 is (Native_Add_Saturate_U64x2 (Left, Right));
   function Native_Subtract_Saturate_U64x2 is new NEON_Binary_128 (U64x2, "uqsub v0.2d, v0.2d, v1.2d");
   function Subtract_Saturate (Left, Right : U64x2) return U64x2 is (Native_Subtract_Saturate_U64x2 (Left, Right));
   function Native_Bitwise_And_U64x2 is new NEON_Binary_128 (U64x2, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : U64x2) return U64x2 is (Native_Bitwise_And_U64x2 (Left, Right));
   function Native_Bitwise_Or_U64x2 is new NEON_Binary_128 (U64x2, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Or_U64x2 (Left, Right));
   function Native_Bitwise_Xor_U64x2 is new NEON_Binary_128 (U64x2, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Xor_U64x2 (Left, Right));
   function Native_Min_U64x2 is new NEON_Binary_128 (U64x2, "cmhi v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bit v0.16b, v1.16b, v2.16b");
   function Min (Left, Right : U64x2) return U64x2 is (Native_Min_U64x2 (Left, Right));
   function Native_Max_U64x2 is new NEON_Binary_128 (U64x2, "cmhi v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bif v0.16b, v1.16b, v2.16b");
   function Max (Left, Right : U64x2) return U64x2 is (Native_Max_U64x2 (Left, Right));
   function Native_Interleave_Low_U64x2 is new NEON_Binary_128 (U64x2, "zip1 v0.2d, v0.2d, v1.2d");
   function Interleave_Low (Left, Right : U64x2) return U64x2 is (Native_Interleave_Low_U64x2 (Left, Right));
   function Native_Interleave_High_U64x2 is new NEON_Binary_128 (U64x2, "zip2 v0.2d, v0.2d, v1.2d");
   function Interleave_High (Left, Right : U64x2) return U64x2 is (Native_Interleave_High_U64x2 (Left, Right));
   function Native_Deinterleave_Even_U64x2 is new NEON_Binary_128 (U64x2, "uzp1 v0.2d, v0.2d, v1.2d");
   function Deinterleave_Even (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Even_U64x2 (Left, Right));
   function Native_Deinterleave_Odd_U64x2 is new NEON_Binary_128 (U64x2, "uzp2 v0.2d, v0.2d, v1.2d");
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Odd_U64x2 (Left, Right));
   function Native_Not_U64x2 is new NEON_Unary_128 (U64x2, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : U64x2) return U64x2 is (Native_Not_U64x2 (Value));
   function Native_Reverse_U64x2 is new NEON_Unary_128 (U64x2, "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : U64x2) return U64x2 is (Native_Reverse_U64x2 (Value));
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
   function Native_Permute_U64x2 is new NEON_Permute_128 (U64x2, Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_U64x2);
   function Permute_Lanes (Value : U64x2; Map : Lane_Map_64x2) return U64x2 is (Native_Permute_U64x2 (Value, Map));
   function Native_Permute_2_U64x2 is new NEON_Permute_2_128 (U64x2, Two_Source_Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_2_U64x2);
   function Permute_Lanes (Left, Right : U64x2; Map : Two_Source_Lane_Map_64x2) return U64x2 is (Native_Permute_2_U64x2 (Left, Right, Map));
   function Compress (Value : U64x2; Mask : Mask_64x2) return U64x2 is
      Map : Lane_Map_64x2;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_64x2 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map.Byte_Indices
                 (Result_Lane * 8 + Byte) :=
                   U8 (Source_Lane * 8 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 2 loop
         for Byte in Natural range 0 .. 7 loop
            Map.Byte_Indices
              (Result_Lane * 8 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_U64x2 (Value, Map);
   end Compress;

   function Expand (Value : U64x2; Mask : Mask_64x2) return U64x2 is
      Map : Lane_Map_64x2;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_64x2 loop
         for Byte in Natural range 0 .. 7 loop
            Map.Byte_Indices
              (Result_Lane * 8 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 8 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_U64x2 (Value, Map);
   end Expand;

   function Native_Multiply_Wrap_U64x2 is new NEON_Multiply_64_128 (U64x2);
   function Multiply_Wrap (Left, Right : U64x2) return U64x2 is (Native_Multiply_Wrap_U64x2 (Left, Right));
   function Native_Shift_Left_Logical_U64x2 is new NEON_Shift_128 (U64x2, "dup v1.2d, %2", "ushl v0.2d, v0.2d, v1.2d");
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2 is
     (if Count >= 64 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_U64x2 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_U64x2 is new NEON_Shift_128 (U64x2, "dup v1.2d, %2", "ushl v0.2d, v0.2d, v1.2d");
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2 is
     (if Count >= 64 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_U64x2 (Value, -Interfaces.Integer_64 (Count)));
   function Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_U64x2 (Left, Right, Weights_64x2'Address)));
   function Greater_Than (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_U64x2 (Left, Right, Weights_64x2'Address)));
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U64x2 (Left, Right, Weights_64x2'Address)));
   function Less_Than (Left, Right : U64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U64x2 is new NEON_Select_128 (U64x2, "dup v2.2d, %1", "cmtst v2.2d, v2.2d, v3.2d");
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2 is (Native_Select_U64x2 (Interfaces.Unsigned_64 (Mask.Bits), Weights_64x2'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_U64x2 is new NEON_Integer_Reduce_128 (U64x2, U64, "addp d0, v0.2d", "str d0, [%0]");
   function Reduce_Add_Wrap (Value : U64x2) return U64 is (Native_Reduce_Add_Wrap_U64x2 (Value));
   function Native_Reduce_Min_U64x2 is new NEON_Integer_Reduce_128 (U64x2, U64, "dup v1.2d, v0.d[1]" & ASCII.LF & ASCII.HT & "cmhi v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bit v0.16b, v1.16b, v2.16b", "str d0, [%0]");
   function Reduce_Min (Value : U64x2) return U64 is (Native_Reduce_Min_U64x2 (Value));
   function Native_Reduce_Max_U64x2 is new NEON_Integer_Reduce_128 (U64x2, U64, "dup v1.2d, v0.d[1]" & ASCII.LF & ASCII.HT & "cmhi v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bif v0.16b, v1.16b, v2.16b", "str d0, [%0]");
   function Reduce_Max (Value : U64x2) return U64 is (Native_Reduce_Max_U64x2 (Value));
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 is
      Result : U64x2;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Compare_I64x2 is new NEON_Compare_128 (I64x2, "cmeq v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Compare_Greater_I64x2 is new NEON_Compare_128 (I64x2, "cmgt v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Compare_Greater_Equal_I64x2 is new NEON_Compare_128 (I64x2, "cmge v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Native_Add_Wrap_I64x2 is new NEON_Binary_128 (I64x2, "add v0.2d, v0.2d, v1.2d");
   function Add_Wrap (Left, Right : I64x2) return I64x2 is (Native_Add_Wrap_I64x2 (Left, Right));
   function Native_Subtract_Wrap_I64x2 is new NEON_Binary_128 (I64x2, "sub v0.2d, v0.2d, v1.2d");
   function Subtract_Wrap (Left, Right : I64x2) return I64x2 is (Native_Subtract_Wrap_I64x2 (Left, Right));
   function Native_Add_Saturate_I64x2 is new NEON_Binary_128 (I64x2, "sqadd v0.2d, v0.2d, v1.2d");
   function Add_Saturate (Left, Right : I64x2) return I64x2 is (Native_Add_Saturate_I64x2 (Left, Right));
   function Native_Subtract_Saturate_I64x2 is new NEON_Binary_128 (I64x2, "sqsub v0.2d, v0.2d, v1.2d");
   function Subtract_Saturate (Left, Right : I64x2) return I64x2 is (Native_Subtract_Saturate_I64x2 (Left, Right));
   function Native_Bitwise_And_I64x2 is new NEON_Binary_128 (I64x2, "and v0.16b, v0.16b, v1.16b");
   function Bitwise_And (Left, Right : I64x2) return I64x2 is (Native_Bitwise_And_I64x2 (Left, Right));
   function Native_Bitwise_Or_I64x2 is new NEON_Binary_128 (I64x2, "orr v0.16b, v0.16b, v1.16b");
   function Bitwise_Or (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Or_I64x2 (Left, Right));
   function Native_Bitwise_Xor_I64x2 is new NEON_Binary_128 (I64x2, "eor v0.16b, v0.16b, v1.16b");
   function Bitwise_Xor (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Xor_I64x2 (Left, Right));
   function Native_Min_I64x2 is new NEON_Binary_128 (I64x2, "cmgt v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bit v0.16b, v1.16b, v2.16b");
   function Min (Left, Right : I64x2) return I64x2 is (Native_Min_I64x2 (Left, Right));
   function Native_Max_I64x2 is new NEON_Binary_128 (I64x2, "cmgt v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bif v0.16b, v1.16b, v2.16b");
   function Max (Left, Right : I64x2) return I64x2 is (Native_Max_I64x2 (Left, Right));
   function Native_Interleave_Low_I64x2 is new NEON_Binary_128 (I64x2, "zip1 v0.2d, v0.2d, v1.2d");
   function Interleave_Low (Left, Right : I64x2) return I64x2 is (Native_Interleave_Low_I64x2 (Left, Right));
   function Native_Interleave_High_I64x2 is new NEON_Binary_128 (I64x2, "zip2 v0.2d, v0.2d, v1.2d");
   function Interleave_High (Left, Right : I64x2) return I64x2 is (Native_Interleave_High_I64x2 (Left, Right));
   function Native_Deinterleave_Even_I64x2 is new NEON_Binary_128 (I64x2, "uzp1 v0.2d, v0.2d, v1.2d");
   function Deinterleave_Even (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Even_I64x2 (Left, Right));
   function Native_Deinterleave_Odd_I64x2 is new NEON_Binary_128 (I64x2, "uzp2 v0.2d, v0.2d, v1.2d");
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Odd_I64x2 (Left, Right));
   function Native_Not_I64x2 is new NEON_Unary_128 (I64x2, "mvn v0.16b, v0.16b");
   function Bitwise_Not (Value : I64x2) return I64x2 is (Native_Not_I64x2 (Value));
   function Native_Reverse_I64x2 is new NEON_Unary_128 (I64x2, "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : I64x2) return I64x2 is (Native_Reverse_I64x2 (Value));
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
   function Native_Permute_I64x2 is new NEON_Permute_128 (I64x2, Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_I64x2);
   function Permute_Lanes (Value : I64x2; Map : Lane_Map_64x2) return I64x2 is (Native_Permute_I64x2 (Value, Map));
   function Native_Permute_2_I64x2 is new NEON_Permute_2_128 (I64x2, Two_Source_Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_2_I64x2);
   function Permute_Lanes (Left, Right : I64x2; Map : Two_Source_Lane_Map_64x2) return I64x2 is (Native_Permute_2_I64x2 (Left, Right, Map));
   function Compress (Value : I64x2; Mask : Mask_64x2) return I64x2 is
      Map : Lane_Map_64x2;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_64x2 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map.Byte_Indices
                 (Result_Lane * 8 + Byte) :=
                   U8 (Source_Lane * 8 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 2 loop
         for Byte in Natural range 0 .. 7 loop
            Map.Byte_Indices
              (Result_Lane * 8 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_I64x2 (Value, Map);
   end Compress;

   function Expand (Value : I64x2; Mask : Mask_64x2) return I64x2 is
      Map : Lane_Map_64x2;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_64x2 loop
         for Byte in Natural range 0 .. 7 loop
            Map.Byte_Indices
              (Result_Lane * 8 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 8 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_I64x2 (Value, Map);
   end Expand;

   function Native_Multiply_Wrap_I64x2 is new NEON_Multiply_64_128 (I64x2);
   function Multiply_Wrap (Left, Right : I64x2) return I64x2 is (Native_Multiply_Wrap_I64x2 (Left, Right));
   function Native_Shift_Left_Logical_I64x2 is new NEON_Shift_128 (I64x2, "dup v1.2d, %2", "ushl v0.2d, v0.2d, v1.2d");
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2 is
     (if Count >= 64 then Flyology_SIMD.Zero else Native_Shift_Left_Logical_I64x2 (Value, Interfaces.Integer_64 (Count)));
   function Native_Shift_Right_Logical_I64x2 is new NEON_Shift_128 (I64x2, "dup v1.2d, %2", "ushl v0.2d, v0.2d, v1.2d");
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2 is
     (if Count >= 64 then Flyology_SIMD.Zero else Native_Shift_Right_Logical_I64x2 (Value, -Interfaces.Integer_64 (Count)));
   function Native_SRA_I64x2 is new NEON_Shift_128 (I64x2, "dup v1.2d, %2", "sshl v0.2d, v0.2d, v1.2d");
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2 is
     (if Count >= 64 then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SRA_I64x2 (Value, -Interfaces.Integer_64 (Count)));
   function Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_I64x2 (Left, Right, Weights_64x2'Address)));
   function Greater_Than (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_I64x2 (Left, Right, Weights_64x2'Address)));
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I64x2 (Left, Right, Weights_64x2'Address)));
   function Less_Than (Left, Right : I64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I64x2 is new NEON_Select_128 (I64x2, "dup v2.2d, %1", "cmtst v2.2d, v2.2d, v3.2d");
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2 is (Native_Select_I64x2 (Interfaces.Unsigned_64 (Mask.Bits), Weights_64x2'Address, If_True, If_False));
   function Native_Reduce_Add_Wrap_I64x2 is new NEON_Integer_Reduce_128 (I64x2, I64, "addp d0, v0.2d", "str d0, [%0]");
   function Reduce_Add_Wrap (Value : I64x2) return I64 is (Native_Reduce_Add_Wrap_I64x2 (Value));
   function Native_Reduce_Min_I64x2 is new NEON_Integer_Reduce_128 (I64x2, I64, "dup v1.2d, v0.d[1]" & ASCII.LF & ASCII.HT & "cmgt v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bit v0.16b, v1.16b, v2.16b", "str d0, [%0]");
   function Reduce_Min (Value : I64x2) return I64 is (Native_Reduce_Min_I64x2 (Value));
   function Native_Reduce_Max_I64x2 is new NEON_Integer_Reduce_128 (I64x2, I64, "dup v1.2d, v0.d[1]" & ASCII.LF & ASCII.HT & "cmgt v2.2d, v0.2d, v1.2d" & ASCII.LF & ASCII.HT & "bif v0.16b, v1.16b, v2.16b", "str d0, [%0]");
   function Reduce_Max (Value : I64x2) return I64 is (Native_Reduce_Max_I64x2 (Value));
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 is
      Result : I64x2;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_F32x4 is new NEON_Binary_128 (F32x4, "fadd v0.4s, v0.4s, v1.4s");
   function Add (Left, Right : F32x4) return F32x4 is (Native_Add_F32x4 (Left, Right));
   function Native_Subtract_F32x4 is new NEON_Binary_128 (F32x4, "fsub v0.4s, v0.4s, v1.4s");
   function Subtract (Left, Right : F32x4) return F32x4 is (Native_Subtract_F32x4 (Left, Right));
   function Native_Multiply_F32x4 is new NEON_Binary_128 (F32x4, "fmul v0.4s, v0.4s, v1.4s");
   function Multiply (Left, Right : F32x4) return F32x4 is (Native_Multiply_F32x4 (Left, Right));
   function Native_Divide_F32x4 is new NEON_Binary_128 (F32x4, "fdiv v0.4s, v0.4s, v1.4s");
   function Divide (Left, Right : F32x4) return F32x4 is (Native_Divide_F32x4 (Left, Right));
   function Native_Min_Number_F32x4 is new NEON_Binary_128 (F32x4, "fminnm v0.4s, v0.4s, v1.4s");
   function Min_Number (Left, Right : F32x4) return F32x4 is (Native_Min_Number_F32x4 (Left, Right));
   function Native_Max_Number_F32x4 is new NEON_Binary_128 (F32x4, "fmaxnm v0.4s, v0.4s, v1.4s");
   function Max_Number (Left, Right : F32x4) return F32x4 is (Native_Max_Number_F32x4 (Left, Right));
   function Native_Interleave_Low_F32x4 is new NEON_Binary_128 (F32x4, "zip1 v0.4s, v0.4s, v1.4s");
   function Interleave_Low (Left, Right : F32x4) return F32x4 is (Native_Interleave_Low_F32x4 (Left, Right));
   function Native_Interleave_High_F32x4 is new NEON_Binary_128 (F32x4, "zip2 v0.4s, v0.4s, v1.4s");
   function Interleave_High (Left, Right : F32x4) return F32x4 is (Native_Interleave_High_F32x4 (Left, Right));
   function Native_Deinterleave_Even_F32x4 is new NEON_Binary_128 (F32x4, "uzp1 v0.4s, v0.4s, v1.4s");
   function Deinterleave_Even (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Even_F32x4 (Left, Right));
   function Native_Deinterleave_Odd_F32x4 is new NEON_Binary_128 (F32x4, "uzp2 v0.4s, v0.4s, v1.4s");
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Odd_F32x4 (Left, Right));
   function Native_Reverse_F32x4 is new NEON_Unary_128 (F32x4, "rev64 v0.4s, v0.4s" & ASCII.LF & ASCII.HT & "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : F32x4) return F32x4 is (Native_Reverse_F32x4 (Value));
   function Compare_Equal_F32x4 is new NEON_Compare_128 (F32x4, "fcmeq v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Equal_F32x4 (Left, Right, Weights_32x4'Address)));
   function Compare_Greater_Than_F32x4 is new NEON_Compare_128 (F32x4, "fcmgt v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Greater_Than (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Than_F32x4 (Left, Right, Weights_32x4'Address)));
   function Compare_Greater_Equal_F32x4 is new NEON_Compare_128 (F32x4, "fcmge v0.4s, v0.4s, v1.4s", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Equal_F32x4 (Left, Right, Weights_32x4'Address)));
   function Compare_Unordered_F32x4 is new NEON_Compare_128 (F32x4, "fcmeq v0.4s, v0.4s, v0.4s" & ASCII.LF & ASCII.HT & "fcmeq v1.4s, v1.4s, v1.4s" & ASCII.LF & ASCII.HT & "and v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT & "mvn v0.16b, v0.16b", "ushr v0.4s, v0.4s, #31" & ASCII.LF & ASCII.HT & "ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.4s, v0.4s, v2.4s" & ASCII.LF & ASCII.HT & "addv s0, v0.4s" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]");
   function Unordered (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Unordered_F32x4 (Left, Right, Weights_32x4'Address)));
   function Less_Than (Left, Right : F32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : F32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
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
   function Native_Permute_F32x4 is new NEON_Permute_128 (F32x4, Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_F32x4);
   function Permute_Lanes (Value : F32x4; Map : Lane_Map_32x4) return F32x4 is (Native_Permute_F32x4 (Value, Map));
   function Native_Permute_2_F32x4 is new NEON_Permute_2_128 (F32x4, Two_Source_Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_2_F32x4);
   function Permute_Lanes (Left, Right : F32x4; Map : Two_Source_Lane_Map_32x4) return F32x4 is (Native_Permute_2_F32x4 (Left, Right, Map));
   function Native_Select_F32x4 is new NEON_Select_128 (F32x4, "dup v2.4s, %w1", "cmtst v2.4s, v2.4s, v3.4s");
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4 is (Native_Select_F32x4 (Interfaces.Unsigned_64 (Mask.Bits), Weights_32x4'Address, If_True, If_False));
   function Native_Reduce_Add_F32x4 is new NEON_Float_Reduce_128 (F32x4, F32, "mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & "movi v0.16b, #0" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[0]" & ASCII.LF & ASCII.HT & "fadd s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[1]" & ASCII.LF & ASCII.HT & "fadd s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[2]" & ASCII.LF & ASCII.HT & "fadd s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[3]" & ASCII.LF & ASCII.HT & "fadd s0, s0, s1", "str s0, [%0]");
   function Reduce_Add (Value : F32x4) return F32 is (Native_Reduce_Add_F32x4 (Value));
   function Compress (Value : F32x4; Mask : Mask_32x4) return F32x4 is
      Map : Lane_Map_32x4;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_32x4 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map.Byte_Indices
                 (Result_Lane * 4 + Byte) :=
                   U8 (Source_Lane * 4 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 4 loop
         for Byte in Natural range 0 .. 3 loop
            Map.Byte_Indices
              (Result_Lane * 4 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_F32x4 (Value, Map);
   end Compress;

   function Expand (Value : F32x4; Mask : Mask_32x4) return F32x4 is
      Map : Lane_Map_32x4;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_32x4 loop
         for Byte in Natural range 0 .. 3 loop
            Map.Byte_Indices
              (Result_Lane * 4 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 4 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_F32x4 (Value, Map);
   end Expand;

   function Native_Reduce_Min_Number_F32x4 is new NEON_Float_Reduce_128 (F32x4, F32, "mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[1]" & ASCII.LF & ASCII.HT & "fminnm s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[2]" & ASCII.LF & ASCII.HT & "fminnm s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[3]" & ASCII.LF & ASCII.HT & "fminnm s0, s0, s1", "str s0, [%0]");
   function Reduce_Min_Number (Value : F32x4) return F32 is (Native_Reduce_Min_Number_F32x4 (Value));
   function Native_Reduce_Max_Number_F32x4 is new NEON_Float_Reduce_128 (F32x4, F32, "mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[1]" & ASCII.LF & ASCII.HT & "fmaxnm s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[2]" & ASCII.LF & ASCII.HT & "fmaxnm s0, s0, s1" & ASCII.LF & ASCII.HT & "dup v1.4s, v2.s[3]" & ASCII.LF & ASCII.HT & "fmaxnm s0, s0, s1", "str s0, [%0]");
   function Reduce_Max_Number (Value : F32x4) return F32 is (Native_Reduce_Max_Number_F32x4 (Value));
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 is
      Result : F32x4;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;
   function Native_Add_F64x2 is new NEON_Binary_128 (F64x2, "fadd v0.2d, v0.2d, v1.2d");
   function Add (Left, Right : F64x2) return F64x2 is (Native_Add_F64x2 (Left, Right));
   function Native_Subtract_F64x2 is new NEON_Binary_128 (F64x2, "fsub v0.2d, v0.2d, v1.2d");
   function Subtract (Left, Right : F64x2) return F64x2 is (Native_Subtract_F64x2 (Left, Right));
   function Native_Multiply_F64x2 is new NEON_Binary_128 (F64x2, "fmul v0.2d, v0.2d, v1.2d");
   function Multiply (Left, Right : F64x2) return F64x2 is (Native_Multiply_F64x2 (Left, Right));
   function Native_Divide_F64x2 is new NEON_Binary_128 (F64x2, "fdiv v0.2d, v0.2d, v1.2d");
   function Divide (Left, Right : F64x2) return F64x2 is (Native_Divide_F64x2 (Left, Right));
   function Native_Min_Number_F64x2 is new NEON_Binary_128 (F64x2, "fminnm v0.2d, v0.2d, v1.2d");
   function Min_Number (Left, Right : F64x2) return F64x2 is (Native_Min_Number_F64x2 (Left, Right));
   function Native_Max_Number_F64x2 is new NEON_Binary_128 (F64x2, "fmaxnm v0.2d, v0.2d, v1.2d");
   function Max_Number (Left, Right : F64x2) return F64x2 is (Native_Max_Number_F64x2 (Left, Right));
   function Native_Interleave_Low_F64x2 is new NEON_Binary_128 (F64x2, "zip1 v0.2d, v0.2d, v1.2d");
   function Interleave_Low (Left, Right : F64x2) return F64x2 is (Native_Interleave_Low_F64x2 (Left, Right));
   function Native_Interleave_High_F64x2 is new NEON_Binary_128 (F64x2, "zip2 v0.2d, v0.2d, v1.2d");
   function Interleave_High (Left, Right : F64x2) return F64x2 is (Native_Interleave_High_F64x2 (Left, Right));
   function Native_Deinterleave_Even_F64x2 is new NEON_Binary_128 (F64x2, "uzp1 v0.2d, v0.2d, v1.2d");
   function Deinterleave_Even (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Even_F64x2 (Left, Right));
   function Native_Deinterleave_Odd_F64x2 is new NEON_Binary_128 (F64x2, "uzp2 v0.2d, v0.2d, v1.2d");
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Odd_F64x2 (Left, Right));
   function Native_Reverse_F64x2 is new NEON_Unary_128 (F64x2, "ext v0.16b, v0.16b, v0.16b, #8");
   function Reverse_Lanes (Value : F64x2) return F64x2 is (Native_Reverse_F64x2 (Value));
   function Compare_Equal_F64x2 is new NEON_Compare_128 (F64x2, "fcmeq v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Equal_F64x2 (Left, Right, Weights_64x2'Address)));
   function Compare_Greater_Than_F64x2 is new NEON_Compare_128 (F64x2, "fcmgt v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Greater_Than (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Than_F64x2 (Left, Right, Weights_64x2'Address)));
   function Compare_Greater_Equal_F64x2 is new NEON_Compare_128 (F64x2, "fcmge v0.2d, v0.2d, v1.2d", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Equal_F64x2 (Left, Right, Weights_64x2'Address)));
   function Compare_Unordered_F64x2 is new NEON_Compare_128 (F64x2, "fcmeq v0.2d, v0.2d, v0.2d" & ASCII.LF & ASCII.HT & "fcmeq v1.2d, v1.2d, v1.2d" & ASCII.LF & ASCII.HT & "and v0.16b, v0.16b, v1.16b" & ASCII.LF & ASCII.HT & "mvn v0.16b, v0.16b", "ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & "umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, w9, lsl #1");
   function Unordered (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Unordered_F64x2 (Left, Right, Weights_64x2'Address)));
   function Less_Than (Left, Right : F64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : F64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
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
   function Native_Permute_F64x2 is new NEON_Permute_128 (F64x2, Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_F64x2);
   function Permute_Lanes (Value : F64x2; Map : Lane_Map_64x2) return F64x2 is (Native_Permute_F64x2 (Value, Map));
   function Native_Permute_2_F64x2 is new NEON_Permute_2_128 (F64x2, Two_Source_Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_2_F64x2);
   function Permute_Lanes (Left, Right : F64x2; Map : Two_Source_Lane_Map_64x2) return F64x2 is (Native_Permute_2_F64x2 (Left, Right, Map));
   function Native_Select_F64x2 is new NEON_Select_128 (F64x2, "dup v2.2d, %1", "cmtst v2.2d, v2.2d, v3.2d");
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2 is (Native_Select_F64x2 (Interfaces.Unsigned_64 (Mask.Bits), Weights_64x2'Address, If_True, If_False));
   function Native_Reduce_Add_F64x2 is new NEON_Float_Reduce_128 (F64x2, F64, "mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & "movi v0.16b, #0" & ASCII.LF & ASCII.HT & "dup v1.2d, v2.d[0]" & ASCII.LF & ASCII.HT & "fadd d0, d0, d1" & ASCII.LF & ASCII.HT & "dup v1.2d, v2.d[1]" & ASCII.LF & ASCII.HT & "fadd d0, d0, d1", "str d0, [%0]");
   function Reduce_Add (Value : F64x2) return F64 is (Native_Reduce_Add_F64x2 (Value));
   function Compress (Value : F64x2; Mask : Mask_64x2) return F64x2 is
      Map : Lane_Map_64x2;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Result_Lane : Natural := 0;
   begin
      for Source_Lane in Lane_Index_64x2 loop
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Source_Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map.Byte_Indices
                 (Result_Lane * 8 + Byte) :=
                   U8 (Source_Lane * 8 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      while Result_Lane < 2 loop
         for Byte in Natural range 0 .. 7 loop
            Map.Byte_Indices
              (Result_Lane * 8 + Byte) := 16;
         end loop;
         Result_Lane := Result_Lane + 1;
      end loop;
      return Native_Permute_F64x2 (Value, Map);
   end Compress;

   function Expand (Value : F64x2; Mask : Mask_64x2) return F64x2 is
      Map : Lane_Map_64x2;
      Bits : constant Interfaces.Unsigned_8 := Mask.Bits;
      Source_Lane : Natural := 0;
   begin
      for Result_Lane in Lane_Index_64x2 loop
         for Byte in Natural range 0 .. 7 loop
            Map.Byte_Indices
              (Result_Lane * 8 + Byte) :=
                (if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
                    U8 (Source_Lane * 8 + Byte)
                 else 16);
         end loop;
         if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Result_Lane)) /= 0 then
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Native_Permute_F64x2 (Value, Map);
   end Expand;

   function Native_Reduce_Min_Number_F64x2 is new NEON_Float_Reduce_128 (F64x2, F64, "mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & "dup v1.2d, v2.d[1]" & ASCII.LF & ASCII.HT & "fminnm d0, d0, d1", "str d0, [%0]");
   function Reduce_Min_Number (Value : F64x2) return F64 is (Native_Reduce_Min_Number_F64x2 (Value));
   function Native_Reduce_Max_Number_F64x2 is new NEON_Float_Reduce_128 (F64x2, F64, "mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & "dup v1.2d, v2.d[1]" & ASCII.LF & ASCII.HT & "fmaxnm d0, d0, d1", "str d0, [%0]");
   function Reduce_Max_Number (Value : F64x2) return F64 is (Native_Reduce_Max_Number_F64x2 (Value));
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean is
     (Flyology_SIMD.Is_Aligned_16 (Data, Start));
   function Load (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 is
      Result : F64x2;
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Data (Start)'Address)], Clobber => "v0,memory", Volatile => True);
      return Result;
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
   begin
      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT & "str q0, [%0]", Inputs => [System.Address'Asm_Input ("r", Data (Start)'Address), System.Address'Asm_Input ("r", Value'Address)], Clobber => "v0,memory", Volatile => True);
   end Store_Unaligned;
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
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
   function First_True (Mask : Mask_16x8) return Lane_Count_16x8 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 8));
   function Last_True (Mask : Mask_16x8) return Lane_Count_16x8 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 8));
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
   function First_True (Mask : Mask_32x4) return Lane_Count_32x4 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 4));
   function Last_True (Mask : Mask_32x4) return Lane_Count_32x4 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 4));
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
   function First_True (Mask : Mask_64x2) return Lane_Count_64x2 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 2));
   function Last_True (Mask : Mask_64x2) return Lane_Count_64x2 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 2));
   --  END GENERATED FULL-FAMILY NEON BODIES
end Flyology_SIMD.Backends.Native;
