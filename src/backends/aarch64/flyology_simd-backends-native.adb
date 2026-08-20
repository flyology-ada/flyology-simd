with Ada.Unchecked_Conversion;
with System.Machine_Code;
with System.Storage_Elements;

package body Flyology_SIMD.Backends.Native is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Integer_64;
   use type System.Storage_Elements.Integer_Address;
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

   function Count_Set_Bits
     (Bits : Interfaces.Unsigned_32) return Natural
   is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template => "fmov s0, %w1" & ASCII.LF & ASCII.HT &
                     "cnt v0.8b, v0.8b" & ASCII.LF & ASCII.HT &
                     "uaddlv h0, v0.8b" & ASCII.LF & ASCII.HT &
                     "umov %w0, v0.h[0]",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Clobber => "v0",
         Volatile => True);
      return Natural (Result);
   end Count_Set_Bits;
   pragma Inline_Always (Count_Set_Bits);


   --  BEGIN GENERATED FULL-FAMILY NEON BODIES
   --  Assembly leaves below take and return this machine vector type so
   --  that 128-bit values stay in NEON registers across a chain of
   --  operations instead of spilling to memory between them.
   type Machine_Vector is array (0 .. 15) of Interfaces.Unsigned_8;
   for Machine_Vector'Alignment use 16;
   pragma Machine_Attribute (Machine_Vector, "vector_type");

   generic
      type Vector_Type is private;
   function NEON_Multiply_64_128 (Left, Right : Vector_Type) return Vector_Type;
   function NEON_Multiply_64_128 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Left_Low, Left_High, Right_Low, Right_High, Cross : Machine_Vector;
   begin
      Asm (Template => "uzp1 %1.4s, %6.4s, %6.4s" & ASCII.LF & ASCII.HT &
           "uzp2 %2.4s, %6.4s, %6.4s" & ASCII.LF & ASCII.HT &
           "uzp1 %3.4s, %7.4s, %7.4s" & ASCII.LF & ASCII.HT &
           "uzp2 %4.4s, %7.4s, %7.4s" & ASCII.LF & ASCII.HT &
           "umull %0.2d, %1.2s, %3.2s" & ASCII.LF & ASCII.HT &
           "mul %5.2s, %1.2s, %4.2s" & ASCII.LF & ASCII.HT &
           "mla %5.2s, %2.2s, %3.2s" & ASCII.LF & ASCII.HT &
           "shll %5.2d, %5.2s, #32" & ASCII.LF & ASCII.HT &
           "add %0.2d, %0.2d, %5.2d",
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Left_Low), Machine_Vector'Asm_Output ("=&w", Left_High), Machine_Vector'Asm_Output ("=&w", Right_Low), Machine_Vector'Asm_Output ("=&w", Right_High), Machine_Vector'Asm_Output ("=&w", Cross)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Left)), Machine_Vector'Asm_Input ("w", To_Machine (Right))]);
      return To_Vector (Result);
   end NEON_Multiply_64_128;

   generic
      type Vector_Type is private;
      type Map_Type is private;
   function NEON_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type;
   function NEON_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function Map_To_Machine is new Ada.Unchecked_Conversion (Map_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => "tbl %0.16b, {%1.16b}, %2.16b",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Value)), Machine_Vector'Asm_Input ("w", Map_To_Machine (Map))]);
      return To_Vector (Result);
   end NEON_Permute_128;

   generic
      type Vector_Type is private;
      type Map_Type is private;
   function NEON_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type;
   function NEON_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function Map_To_Machine is new Ada.Unchecked_Conversion (Map_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result, Adjusted_Map : Machine_Vector;
   begin
      Asm (Template => "movi %1.16b, #16" & ASCII.LF & ASCII.HT &
           "sub %1.16b, %4.16b, %1.16b" & ASCII.LF & ASCII.HT &
           "tbl %0.16b, {%2.16b}, %4.16b" & ASCII.LF & ASCII.HT &
           "tbx %0.16b, {%3.16b}, %1.16b",
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Adjusted_Map)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Left)), Machine_Vector'Asm_Input ("w", To_Machine (Right)), Machine_Vector'Asm_Input ("w", Map_To_Machine (Map))]);
      return To_Vector (Result);
   end NEON_Permute_2_128;

   generic
      type Vector_Type is private;
   function NEON_Zero_128 return Vector_Type;
   function NEON_Zero_128 return Vector_Type is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      pragma Warnings (Off, "code statement with no inputs*");
      Asm (Template => "movi %0.16b, #0",
           Outputs => Machine_Vector'Asm_Output ("=w", Result));
      pragma Warnings (On, "code statement with no inputs*");
      return To_Vector (Result);
   end NEON_Zero_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Duplicate_Instruction : String;
   function NEON_Splat_Integer_128 (Value : Scalar_Type) return Vector_Type;
   function NEON_Splat_Integer_128 (Value : Scalar_Type) return Vector_Type is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Duplicate_Instruction,
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Scalar_Type'Asm_Input ("r", Value));
      return To_Vector (Result);
   end NEON_Splat_Integer_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Duplicate_Instruction : String;
   function NEON_Splat_Float_128 (Value : Scalar_Type) return Vector_Type;
   function NEON_Splat_Float_128 (Value : Scalar_Type) return Vector_Type is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Duplicate_Instruction,
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Scalar_Type'Asm_Input ("w", Value));
      return To_Vector (Result);
   end NEON_Splat_Float_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function NEON_Integer_Reduce_128 (Value : Vector_Type) return Scalar_Type;
   function NEON_Integer_Reduce_128 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Folded : Machine_Vector;
      Spare : Machine_Vector;
      Extra : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&w", Folded), Machine_Vector'Asm_Output ("=&w", Spare), Machine_Vector'Asm_Output ("=&w", Extra)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return Result;
   end NEON_Integer_Reduce_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function NEON_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type;
   function NEON_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Folded : Machine_Vector;
      Spare : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=w", Result), Machine_Vector'Asm_Output ("=&w", Folded), Machine_Vector'Asm_Output ("=&w", Spare)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return Result;
   end NEON_Float_Reduce_128;

   generic
      type Vector_Type is private;
      Instruction : String;
      Compact : String;
   function NEON_Compare_128 (Left, Right : Vector_Type; Weights : Machine_Vector) return Interfaces.Unsigned_8;
   function NEON_Compare_128 (Left, Right : Vector_Type; Weights : Machine_Vector) return Interfaces.Unsigned_8 is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Interfaces.Unsigned_32;
      Half : Interfaces.Unsigned_32;
      Truths : Machine_Vector;
      Spare : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Compact,
           Outputs => [Interfaces.Unsigned_32'Asm_Output ("=&r", Result), Interfaces.Unsigned_32'Asm_Output ("=&r", Half), Machine_Vector'Asm_Output ("=&w", Truths), Machine_Vector'Asm_Output ("=&w", Spare)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Left)), Machine_Vector'Asm_Input ("w", To_Machine (Right)), Machine_Vector'Asm_Input ("w", Weights)]);
      return Interfaces.Unsigned_8 (Result and 16#FF#);
   end NEON_Compare_128;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Compare_16_Lanes (Left, Right : Vector_Type; Weights : Machine_Vector) return Interfaces.Unsigned_16;
   function NEON_Compare_16_Lanes (Left, Right : Vector_Type; Weights : Machine_Vector) return Interfaces.Unsigned_16 is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Interfaces.Unsigned_32;
      Half : Interfaces.Unsigned_32;
      Low : Machine_Vector;
      High : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT &
           "and %2.16b, %2.16b, %6.16b" & ASCII.LF & ASCII.HT &
           "ext %3.16b, %2.16b, %2.16b, #8" & ASCII.LF & ASCII.HT &
           "uaddlv %h2, %2.8b" & ASCII.LF & ASCII.HT &
           "uaddlv %h3, %3.8b" & ASCII.LF & ASCII.HT &
           "umov %w0, %2.h[0]" & ASCII.LF & ASCII.HT &
           "umov %w1, %3.h[0]" & ASCII.LF & ASCII.HT &
           "orr %w0, %w0, %w1, lsl #8",
           Outputs => [Interfaces.Unsigned_32'Asm_Output ("=&r", Result), Interfaces.Unsigned_32'Asm_Output ("=&r", Half), Machine_Vector'Asm_Output ("=&w", Low), Machine_Vector'Asm_Output ("=&w", High)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Left)), Machine_Vector'Asm_Input ("w", To_Machine (Right)), Machine_Vector'Asm_Input ("w", Weights)]);
      return Interfaces.Unsigned_16 (Result and 16#FFFF#);
   end NEON_Compare_16_Lanes;

   generic
      type Vector_Type is private;
      Dup_Instruction : String;
      Test_Instruction : String;
   function NEON_Select_128 (Bits : Interfaces.Unsigned_64; Weights : Machine_Vector; If_True, If_False : Vector_Type) return Vector_Type;
   function NEON_Select_128 (Bits : Interfaces.Unsigned_64; Weights : Machine_Vector; If_True, If_False : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Dup_Instruction & ASCII.LF & ASCII.HT & Test_Instruction & ASCII.LF & ASCII.HT &
           "bsl %0.16b, %3.16b, %4.16b",
           Outputs => Machine_Vector'Asm_Output ("=&w", Result),
           Inputs => [Interfaces.Unsigned_64'Asm_Input ("r", Bits), Machine_Vector'Asm_Input ("w", Weights), Machine_Vector'Asm_Input ("w", To_Machine (If_True)), Machine_Vector'Asm_Input ("w", To_Machine (If_False))]);
      return To_Vector (Result);
   end NEON_Select_128;

   generic
      type Vector_Type is private;
   function NEON_Select_16_Lanes_128 (Bits : Interfaces.Unsigned_16; Weights : Machine_Vector; If_True, If_False : Vector_Type) return Vector_Type;
   function NEON_Select_16_Lanes_128 (Bits : Interfaces.Unsigned_16; Weights : Machine_Vector; If_True, If_False : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Spread : Machine_Vector;
      Upper : Interfaces.Unsigned_32;
   begin
      Asm (Template => "dup %0.16b, %w3" & ASCII.LF & ASCII.HT &
           "lsr %w2, %w3, #8" & ASCII.LF & ASCII.HT & "dup %1.16b, %w2" & ASCII.LF & ASCII.HT &
           "ins %0.d[1], %1.d[0]" & ASCII.LF & ASCII.HT &
           "cmtst %0.16b, %0.16b, %4.16b" & ASCII.LF & ASCII.HT &
           "bsl %0.16b, %5.16b, %6.16b",
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Spread), Interfaces.Unsigned_32'Asm_Output ("=&r", Upper)],
           Inputs => [Interfaces.Unsigned_16'Asm_Input ("r", Bits), Machine_Vector'Asm_Input ("w", Weights), Machine_Vector'Asm_Input ("w", To_Machine (If_True)), Machine_Vector'Asm_Input ("w", To_Machine (If_False))]);
      return To_Vector (Result);
   end NEON_Select_16_Lanes_128;

   generic
      type Vector_Type is private;
      Dup_Instruction : String;
      Shift_Instruction : String;
   function NEON_Shift_128 (Value : Vector_Type; Amount : Interfaces.Integer_64) return Vector_Type;
   function NEON_Shift_128 (Value : Vector_Type; Amount : Interfaces.Integer_64) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Spread : Machine_Vector;
   begin
      Asm (Template => Dup_Instruction & ASCII.LF & ASCII.HT & Shift_Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Spread)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Value)), Interfaces.Integer_64'Asm_Input ("r", Amount)]);
      return To_Vector (Result);
   end NEON_Shift_128;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Binary_128_S0 (Left, Right : Vector_Type) return Vector_Type;
   function NEON_Binary_128_S0 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Left)), Machine_Vector'Asm_Input ("w", To_Machine (Right))]);
      return To_Vector (Result);
   end NEON_Binary_128_S0;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Binary_128_S1 (Left, Right : Vector_Type) return Vector_Type;
   function NEON_Binary_128_S1 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Scratch_1)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Left)), Machine_Vector'Asm_Input ("w", To_Machine (Right))]);
      return To_Vector (Result);
   end NEON_Binary_128_S1;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Unary_128_S0 (Value : Vector_Type) return Vector_Type;
   function NEON_Unary_128_S0 (Value : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return To_Vector (Result);
   end NEON_Unary_128_S0;

   generic
      type Vector_Type is private;
      Instruction : String;
   function NEON_Unary_128_S1 (Value : Vector_Type) return Vector_Type;
   function NEON_Unary_128_S1 (Value : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Scratch_1)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return To_Vector (Result);
   end NEON_Unary_128_S1;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
   function NEON_Convert_Pair_128_S0 (Low, High : Source_Type) return Result_Type;
   function NEON_Convert_Pair_128_S0 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result)],
           Inputs => [Machine_Vector'Asm_Input ("w", To_Machine (Low)), Machine_Vector'Asm_Input ("w", To_Machine (High))]);
      return To_Result (Result);
   end NEON_Convert_Pair_128_S0;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
   function NEON_Convert_128_S0 (Value : Source_Type) return Result_Type;
   function NEON_Convert_128_S0 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return To_Result (Result);
   end NEON_Convert_128_S0;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
   function NEON_Convert_128_S1 (Value : Source_Type) return Result_Type;
   function NEON_Convert_128_S1 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Scratch_1)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return To_Result (Result);
   end NEON_Convert_128_S1;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
   function NEON_Convert_128_S2 (Value : Source_Type) return Result_Type;
   function NEON_Convert_128_S2 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&w", Result), Machine_Vector'Asm_Output ("=&w", Scratch_1), Machine_Vector'Asm_Output ("=&w", Scratch_2)],
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return To_Result (Result);
   end NEON_Convert_128_S2;

   Weights_Vector_8x16 : constant Machine_Vector := [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];
   Weights_Vector_16x8 : constant Machine_Vector := [1, 0, 2, 0, 4, 0, 8, 0, 16, 0, 32, 0, 64, 0, 128, 0];
   Weights_Vector_32x4 : constant Machine_Vector := [1, 0, 0, 0, 2, 0, 0, 0, 4, 0, 0, 0, 8, 0, 0, 0];
   Weights_Vector_64x2 : constant Machine_Vector := [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0];

   function Native_Bit_Cast_U8x16_To_I8x16 is new Ada.Unchecked_Conversion (U8x16, I8x16);
   pragma Inline_Always (Native_Bit_Cast_U8x16_To_I8x16);
   function Bit_Cast (Value : U8x16) return I8x16 is
     (Native_Bit_Cast_U8x16_To_I8x16 (Value));
   function Native_Bit_Cast_I8x16_To_U8x16 is new Ada.Unchecked_Conversion (I8x16, U8x16);
   pragma Inline_Always (Native_Bit_Cast_I8x16_To_U8x16);
   function Bit_Cast (Value : I8x16) return U8x16 is
     (Native_Bit_Cast_I8x16_To_U8x16 (Value));
   function Native_Bit_Cast_U16x8_To_I16x8 is new Ada.Unchecked_Conversion (U16x8, I16x8);
   pragma Inline_Always (Native_Bit_Cast_U16x8_To_I16x8);
   function Bit_Cast (Value : U16x8) return I16x8 is
     (Native_Bit_Cast_U16x8_To_I16x8 (Value));
   function Native_Bit_Cast_I16x8_To_U16x8 is new Ada.Unchecked_Conversion (I16x8, U16x8);
   pragma Inline_Always (Native_Bit_Cast_I16x8_To_U16x8);
   function Bit_Cast (Value : I16x8) return U16x8 is
     (Native_Bit_Cast_I16x8_To_U16x8 (Value));
   function Native_Bit_Cast_U32x4_To_I32x4 is new Ada.Unchecked_Conversion (U32x4, I32x4);
   pragma Inline_Always (Native_Bit_Cast_U32x4_To_I32x4);
   function Bit_Cast (Value : U32x4) return I32x4 is
     (Native_Bit_Cast_U32x4_To_I32x4 (Value));
   function Native_Bit_Cast_U32x4_To_F32x4 is new Ada.Unchecked_Conversion (U32x4, F32x4);
   pragma Inline_Always (Native_Bit_Cast_U32x4_To_F32x4);
   function Bit_Cast (Value : U32x4) return F32x4 is
     (Native_Bit_Cast_U32x4_To_F32x4 (Value));
   function Native_Bit_Cast_I32x4_To_U32x4 is new Ada.Unchecked_Conversion (I32x4, U32x4);
   pragma Inline_Always (Native_Bit_Cast_I32x4_To_U32x4);
   function Bit_Cast (Value : I32x4) return U32x4 is
     (Native_Bit_Cast_I32x4_To_U32x4 (Value));
   function Native_Bit_Cast_I32x4_To_F32x4 is new Ada.Unchecked_Conversion (I32x4, F32x4);
   pragma Inline_Always (Native_Bit_Cast_I32x4_To_F32x4);
   function Bit_Cast (Value : I32x4) return F32x4 is
     (Native_Bit_Cast_I32x4_To_F32x4 (Value));
   function Native_Bit_Cast_F32x4_To_U32x4 is new Ada.Unchecked_Conversion (F32x4, U32x4);
   pragma Inline_Always (Native_Bit_Cast_F32x4_To_U32x4);
   function Bit_Cast (Value : F32x4) return U32x4 is
     (Native_Bit_Cast_F32x4_To_U32x4 (Value));
   function Native_Bit_Cast_F32x4_To_I32x4 is new Ada.Unchecked_Conversion (F32x4, I32x4);
   pragma Inline_Always (Native_Bit_Cast_F32x4_To_I32x4);
   function Bit_Cast (Value : F32x4) return I32x4 is
     (Native_Bit_Cast_F32x4_To_I32x4 (Value));
   function Native_Bit_Cast_U64x2_To_I64x2 is new Ada.Unchecked_Conversion (U64x2, I64x2);
   pragma Inline_Always (Native_Bit_Cast_U64x2_To_I64x2);
   function Bit_Cast (Value : U64x2) return I64x2 is
     (Native_Bit_Cast_U64x2_To_I64x2 (Value));
   function Native_Bit_Cast_U64x2_To_F64x2 is new Ada.Unchecked_Conversion (U64x2, F64x2);
   pragma Inline_Always (Native_Bit_Cast_U64x2_To_F64x2);
   function Bit_Cast (Value : U64x2) return F64x2 is
     (Native_Bit_Cast_U64x2_To_F64x2 (Value));
   function Native_Bit_Cast_I64x2_To_U64x2 is new Ada.Unchecked_Conversion (I64x2, U64x2);
   pragma Inline_Always (Native_Bit_Cast_I64x2_To_U64x2);
   function Bit_Cast (Value : I64x2) return U64x2 is
     (Native_Bit_Cast_I64x2_To_U64x2 (Value));
   function Native_Bit_Cast_I64x2_To_F64x2 is new Ada.Unchecked_Conversion (I64x2, F64x2);
   pragma Inline_Always (Native_Bit_Cast_I64x2_To_F64x2);
   function Bit_Cast (Value : I64x2) return F64x2 is
     (Native_Bit_Cast_I64x2_To_F64x2 (Value));
   function Native_Bit_Cast_F64x2_To_U64x2 is new Ada.Unchecked_Conversion (F64x2, U64x2);
   pragma Inline_Always (Native_Bit_Cast_F64x2_To_U64x2);
   function Bit_Cast (Value : F64x2) return U64x2 is
     (Native_Bit_Cast_F64x2_To_U64x2 (Value));
   function Native_Bit_Cast_F64x2_To_I64x2 is new Ada.Unchecked_Conversion (F64x2, I64x2);
   pragma Inline_Always (Native_Bit_Cast_F64x2_To_I64x2);
   function Bit_Cast (Value : F64x2) return I64x2 is
     (Native_Bit_Cast_F64x2_To_I64x2 (Value));
   function Native_Widen_Low_U8x16_To_U16x8 is new NEON_Convert_128_S0 (U8x16, U16x8, "uxtl %0.8h, %1.8b");
   pragma Inline_Always (Native_Widen_Low_U8x16_To_U16x8);
   function Widen_Low (Value : U8x16) return U16x8 is (Native_Widen_Low_U8x16_To_U16x8 (Value));
   function Native_Widen_High_U8x16_To_U16x8 is new NEON_Convert_128_S0 (U8x16, U16x8, "uxtl2 %0.8h, %1.16b");
   pragma Inline_Always (Native_Widen_High_U8x16_To_U16x8);
   function Widen_High (Value : U8x16) return U16x8 is (Native_Widen_High_U8x16_To_U16x8 (Value));
   function Native_Widen_Low_I8x16_To_I16x8 is new NEON_Convert_128_S0 (I8x16, I16x8, "sxtl %0.8h, %1.8b");
   pragma Inline_Always (Native_Widen_Low_I8x16_To_I16x8);
   function Widen_Low (Value : I8x16) return I16x8 is (Native_Widen_Low_I8x16_To_I16x8 (Value));
   function Native_Widen_High_I8x16_To_I16x8 is new NEON_Convert_128_S0 (I8x16, I16x8, "sxtl2 %0.8h, %1.16b");
   pragma Inline_Always (Native_Widen_High_I8x16_To_I16x8);
   function Widen_High (Value : I8x16) return I16x8 is (Native_Widen_High_I8x16_To_I16x8 (Value));
   function Native_Widen_Low_U16x8_To_U32x4 is new NEON_Convert_128_S0 (U16x8, U32x4, "uxtl %0.4s, %1.4h");
   pragma Inline_Always (Native_Widen_Low_U16x8_To_U32x4);
   function Widen_Low (Value : U16x8) return U32x4 is (Native_Widen_Low_U16x8_To_U32x4 (Value));
   function Native_Widen_High_U16x8_To_U32x4 is new NEON_Convert_128_S0 (U16x8, U32x4, "uxtl2 %0.4s, %1.8h");
   pragma Inline_Always (Native_Widen_High_U16x8_To_U32x4);
   function Widen_High (Value : U16x8) return U32x4 is (Native_Widen_High_U16x8_To_U32x4 (Value));
   function Native_Widen_Low_I16x8_To_I32x4 is new NEON_Convert_128_S0 (I16x8, I32x4, "sxtl %0.4s, %1.4h");
   pragma Inline_Always (Native_Widen_Low_I16x8_To_I32x4);
   function Widen_Low (Value : I16x8) return I32x4 is (Native_Widen_Low_I16x8_To_I32x4 (Value));
   function Native_Widen_High_I16x8_To_I32x4 is new NEON_Convert_128_S0 (I16x8, I32x4, "sxtl2 %0.4s, %1.8h");
   pragma Inline_Always (Native_Widen_High_I16x8_To_I32x4);
   function Widen_High (Value : I16x8) return I32x4 is (Native_Widen_High_I16x8_To_I32x4 (Value));
   function Native_Widen_Low_U32x4_To_U64x2 is new NEON_Convert_128_S0 (U32x4, U64x2, "uxtl %0.2d, %1.2s");
   pragma Inline_Always (Native_Widen_Low_U32x4_To_U64x2);
   function Widen_Low (Value : U32x4) return U64x2 is (Native_Widen_Low_U32x4_To_U64x2 (Value));
   function Native_Widen_High_U32x4_To_U64x2 is new NEON_Convert_128_S0 (U32x4, U64x2, "uxtl2 %0.2d, %1.4s");
   pragma Inline_Always (Native_Widen_High_U32x4_To_U64x2);
   function Widen_High (Value : U32x4) return U64x2 is (Native_Widen_High_U32x4_To_U64x2 (Value));
   function Native_Widen_Low_I32x4_To_I64x2 is new NEON_Convert_128_S0 (I32x4, I64x2, "sxtl %0.2d, %1.2s");
   pragma Inline_Always (Native_Widen_Low_I32x4_To_I64x2);
   function Widen_Low (Value : I32x4) return I64x2 is (Native_Widen_Low_I32x4_To_I64x2 (Value));
   function Native_Widen_High_I32x4_To_I64x2 is new NEON_Convert_128_S0 (I32x4, I64x2, "sxtl2 %0.2d, %1.4s");
   pragma Inline_Always (Native_Widen_High_I32x4_To_I64x2);
   function Widen_High (Value : I32x4) return I64x2 is (Native_Widen_High_I32x4_To_I64x2 (Value));
   function Native_Widen_Low_F32x4_To_F64x2 is new NEON_Convert_128_S0 (F32x4, F64x2, "fcvtl %0.2d, %1.2s");
   pragma Inline_Always (Native_Widen_Low_F32x4_To_F64x2);
   function Widen_Low (Value : F32x4) return F64x2 is (Native_Widen_Low_F32x4_To_F64x2 (Value));
   function Native_Widen_High_F32x4_To_F64x2 is new NEON_Convert_128_S0 (F32x4, F64x2, "fcvtl2 %0.2d, %1.4s");
   pragma Inline_Always (Native_Widen_High_F32x4_To_F64x2);
   function Widen_High (Value : F32x4) return F64x2 is (Native_Widen_High_F32x4_To_F64x2 (Value));
   function Native_Narrow_Truncate_U16x8_To_U8x16 is new NEON_Convert_Pair_128_S0 (U16x8, U8x16, "xtn %0.8b, %1.8h" & ASCII.LF & ASCII.HT & "xtn2 %0.16b, %2.8h");
   pragma Inline_Always (Native_Narrow_Truncate_U16x8_To_U8x16);
   function Narrow_Truncate (Low, High : U16x8) return U8x16 is (Native_Narrow_Truncate_U16x8_To_U8x16 (Low, High));
   function Native_Narrow_Saturate_U16x8_To_U8x16 is new NEON_Convert_Pair_128_S0 (U16x8, U8x16, "uqxtn %0.8b, %1.8h" & ASCII.LF & ASCII.HT & "uqxtn2 %0.16b, %2.8h");
   pragma Inline_Always (Native_Narrow_Saturate_U16x8_To_U8x16);
   function Narrow_Saturate (Low, High : U16x8) return U8x16 is (Native_Narrow_Saturate_U16x8_To_U8x16 (Low, High));
   function Native_Narrow_Truncate_I16x8_To_I8x16 is new NEON_Convert_Pair_128_S0 (I16x8, I8x16, "xtn %0.8b, %1.8h" & ASCII.LF & ASCII.HT & "xtn2 %0.16b, %2.8h");
   pragma Inline_Always (Native_Narrow_Truncate_I16x8_To_I8x16);
   function Narrow_Truncate (Low, High : I16x8) return I8x16 is (Native_Narrow_Truncate_I16x8_To_I8x16 (Low, High));
   function Native_Narrow_Saturate_I16x8_To_I8x16 is new NEON_Convert_Pair_128_S0 (I16x8, I8x16, "sqxtn %0.8b, %1.8h" & ASCII.LF & ASCII.HT & "sqxtn2 %0.16b, %2.8h");
   pragma Inline_Always (Native_Narrow_Saturate_I16x8_To_I8x16);
   function Narrow_Saturate (Low, High : I16x8) return I8x16 is (Native_Narrow_Saturate_I16x8_To_I8x16 (Low, High));
   function Native_Narrow_Truncate_U32x4_To_U16x8 is new NEON_Convert_Pair_128_S0 (U32x4, U16x8, "xtn %0.4h, %1.4s" & ASCII.LF & ASCII.HT & "xtn2 %0.8h, %2.4s");
   pragma Inline_Always (Native_Narrow_Truncate_U32x4_To_U16x8);
   function Narrow_Truncate (Low, High : U32x4) return U16x8 is (Native_Narrow_Truncate_U32x4_To_U16x8 (Low, High));
   function Native_Narrow_Saturate_U32x4_To_U16x8 is new NEON_Convert_Pair_128_S0 (U32x4, U16x8, "uqxtn %0.4h, %1.4s" & ASCII.LF & ASCII.HT & "uqxtn2 %0.8h, %2.4s");
   pragma Inline_Always (Native_Narrow_Saturate_U32x4_To_U16x8);
   function Narrow_Saturate (Low, High : U32x4) return U16x8 is (Native_Narrow_Saturate_U32x4_To_U16x8 (Low, High));
   function Native_Narrow_Truncate_I32x4_To_I16x8 is new NEON_Convert_Pair_128_S0 (I32x4, I16x8, "xtn %0.4h, %1.4s" & ASCII.LF & ASCII.HT & "xtn2 %0.8h, %2.4s");
   pragma Inline_Always (Native_Narrow_Truncate_I32x4_To_I16x8);
   function Narrow_Truncate (Low, High : I32x4) return I16x8 is (Native_Narrow_Truncate_I32x4_To_I16x8 (Low, High));
   function Native_Narrow_Saturate_I32x4_To_I16x8 is new NEON_Convert_Pair_128_S0 (I32x4, I16x8, "sqxtn %0.4h, %1.4s" & ASCII.LF & ASCII.HT & "sqxtn2 %0.8h, %2.4s");
   pragma Inline_Always (Native_Narrow_Saturate_I32x4_To_I16x8);
   function Narrow_Saturate (Low, High : I32x4) return I16x8 is (Native_Narrow_Saturate_I32x4_To_I16x8 (Low, High));
   function Native_Narrow_Truncate_U64x2_To_U32x4 is new NEON_Convert_Pair_128_S0 (U64x2, U32x4, "xtn %0.2s, %1.2d" & ASCII.LF & ASCII.HT & "xtn2 %0.4s, %2.2d");
   pragma Inline_Always (Native_Narrow_Truncate_U64x2_To_U32x4);
   function Narrow_Truncate (Low, High : U64x2) return U32x4 is (Native_Narrow_Truncate_U64x2_To_U32x4 (Low, High));
   function Native_Narrow_Saturate_U64x2_To_U32x4 is new NEON_Convert_Pair_128_S0 (U64x2, U32x4, "uqxtn %0.2s, %1.2d" & ASCII.LF & ASCII.HT & "uqxtn2 %0.4s, %2.2d");
   pragma Inline_Always (Native_Narrow_Saturate_U64x2_To_U32x4);
   function Narrow_Saturate (Low, High : U64x2) return U32x4 is (Native_Narrow_Saturate_U64x2_To_U32x4 (Low, High));
   function Native_Narrow_Truncate_I64x2_To_I32x4 is new NEON_Convert_Pair_128_S0 (I64x2, I32x4, "xtn %0.2s, %1.2d" & ASCII.LF & ASCII.HT & "xtn2 %0.4s, %2.2d");
   pragma Inline_Always (Native_Narrow_Truncate_I64x2_To_I32x4);
   function Narrow_Truncate (Low, High : I64x2) return I32x4 is (Native_Narrow_Truncate_I64x2_To_I32x4 (Low, High));
   function Native_Narrow_Saturate_I64x2_To_I32x4 is new NEON_Convert_Pair_128_S0 (I64x2, I32x4, "sqxtn %0.2s, %1.2d" & ASCII.LF & ASCII.HT & "sqxtn2 %0.4s, %2.2d");
   pragma Inline_Always (Native_Narrow_Saturate_I64x2_To_I32x4);
   function Narrow_Saturate (Low, High : I64x2) return I32x4 is (Native_Narrow_Saturate_I64x2_To_I32x4 (Low, High));
   function Native_Narrow_Saturate_I16x8_To_U8x16 is new NEON_Convert_Pair_128_S0 (I16x8, U8x16, "sqxtun %0.8b, %1.8h" & ASCII.LF & ASCII.HT & "sqxtun2 %0.16b, %2.8h");
   pragma Inline_Always (Native_Narrow_Saturate_I16x8_To_U8x16);
   function Narrow_Saturate (Low, High : I16x8) return U8x16 is (Native_Narrow_Saturate_I16x8_To_U8x16 (Low, High));
   function Native_Narrow_Saturate_I32x4_To_U16x8 is new NEON_Convert_Pair_128_S0 (I32x4, U16x8, "sqxtun %0.4h, %1.4s" & ASCII.LF & ASCII.HT & "sqxtun2 %0.8h, %2.4s");
   pragma Inline_Always (Native_Narrow_Saturate_I32x4_To_U16x8);
   function Narrow_Saturate (Low, High : I32x4) return U16x8 is (Native_Narrow_Saturate_I32x4_To_U16x8 (Low, High));
   function Native_Narrow_Saturate_I64x2_To_U32x4 is new NEON_Convert_Pair_128_S0 (I64x2, U32x4, "sqxtun %0.2s, %1.2d" & ASCII.LF & ASCII.HT & "sqxtun2 %0.4s, %2.2d");
   pragma Inline_Always (Native_Narrow_Saturate_I64x2_To_U32x4);
   function Narrow_Saturate (Low, High : I64x2) return U32x4 is (Native_Narrow_Saturate_I64x2_To_U32x4 (Low, High));
   function Native_Narrow_Round_F64x2_To_F32x4 is new NEON_Convert_Pair_128_S0 (F64x2, F32x4, "fcvtn %0.2s, %1.2d" & ASCII.LF & ASCII.HT & "fcvtn2 %0.4s, %2.2d");
   pragma Inline_Always (Native_Narrow_Round_F64x2_To_F32x4);
   function Narrow_Round (Low, High : F64x2) return F32x4 is (Native_Narrow_Round_F64x2_To_F32x4 (Low, High));
   function Native_Convert_Round_I32x4_To_F32x4 is new NEON_Convert_128_S0 (I32x4, F32x4, "scvtf %0.4s, %1.4s");
   pragma Inline_Always (Native_Convert_Round_I32x4_To_F32x4);
   function Convert_Round (Value : I32x4) return F32x4 is (Native_Convert_Round_I32x4_To_F32x4 (Value));
   function Native_Convert_Round_U32x4_To_F32x4 is new NEON_Convert_128_S0 (U32x4, F32x4, "ucvtf %0.4s, %1.4s");
   pragma Inline_Always (Native_Convert_Round_U32x4_To_F32x4);
   function Convert_Round (Value : U32x4) return F32x4 is (Native_Convert_Round_U32x4_To_F32x4 (Value));
   function Native_Convert_Round_I64x2_To_F64x2 is new NEON_Convert_128_S0 (I64x2, F64x2, "scvtf %0.2d, %1.2d");
   pragma Inline_Always (Native_Convert_Round_I64x2_To_F64x2);
   function Convert_Round (Value : I64x2) return F64x2 is (Native_Convert_Round_I64x2_To_F64x2 (Value));
   function Native_Convert_Round_U64x2_To_F64x2 is new NEON_Convert_128_S0 (U64x2, F64x2, "ucvtf %0.2d, %1.2d");
   pragma Inline_Always (Native_Convert_Round_U64x2_To_F64x2);
   function Convert_Round (Value : U64x2) return F64x2 is (Native_Convert_Round_U64x2_To_F64x2 (Value));
   function Native_Convert_Truncate_Saturate_F32x4_To_I32x4 is new NEON_Convert_128_S0 (F32x4, I32x4, "fcvtzs %0.4s, %1.4s");
   pragma Inline_Always (Native_Convert_Truncate_Saturate_F32x4_To_I32x4);
   function Convert_Truncate_Saturate (Value : F32x4) return I32x4 is (Native_Convert_Truncate_Saturate_F32x4_To_I32x4 (Value));
   function Native_Convert_Truncate_Saturate_F32x4_To_U32x4 is new NEON_Convert_128_S0 (F32x4, U32x4, "fcvtzu %0.4s, %1.4s");
   pragma Inline_Always (Native_Convert_Truncate_Saturate_F32x4_To_U32x4);
   function Convert_Truncate_Saturate (Value : F32x4) return U32x4 is (Native_Convert_Truncate_Saturate_F32x4_To_U32x4 (Value));
   function Native_Convert_Truncate_Saturate_F64x2_To_I64x2 is new NEON_Convert_128_S0 (F64x2, I64x2, "fcvtzs %0.2d, %1.2d");
   pragma Inline_Always (Native_Convert_Truncate_Saturate_F64x2_To_I64x2);
   function Convert_Truncate_Saturate (Value : F64x2) return I64x2 is (Native_Convert_Truncate_Saturate_F64x2_To_I64x2 (Value));
   function Native_Convert_Truncate_Saturate_F64x2_To_U64x2 is new NEON_Convert_128_S0 (F64x2, U64x2, "fcvtzu %0.2d, %1.2d");
   pragma Inline_Always (Native_Convert_Truncate_Saturate_F64x2_To_U64x2);
   function Convert_Truncate_Saturate (Value : F64x2) return U64x2 is (Native_Convert_Truncate_Saturate_F64x2_To_U64x2 (Value));
   function Native_Convert_Saturate_I8x16_To_U8x16 is new NEON_Convert_128_S1 (I8x16, U8x16, "movi %1.2d, #0" & ASCII.LF & ASCII.HT & "smax %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Convert_Saturate_I8x16_To_U8x16);
   function Convert_Saturate (Value : I8x16) return U8x16 is (Native_Convert_Saturate_I8x16_To_U8x16 (Value));
   function Native_Convert_Saturate_U8x16_To_I8x16 is new NEON_Convert_128_S1 (U8x16, I8x16, "movi %1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr %1.16b, %1.16b, #1" & ASCII.LF & ASCII.HT & "umin %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Convert_Saturate_U8x16_To_I8x16);
   function Convert_Saturate (Value : U8x16) return I8x16 is (Native_Convert_Saturate_U8x16_To_I8x16 (Value));
   function Native_Convert_Saturate_I16x8_To_U16x8 is new NEON_Convert_128_S1 (I16x8, U16x8, "movi %1.2d, #0" & ASCII.LF & ASCII.HT & "smax %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_Convert_Saturate_I16x8_To_U16x8);
   function Convert_Saturate (Value : I16x8) return U16x8 is (Native_Convert_Saturate_I16x8_To_U16x8 (Value));
   function Native_Convert_Saturate_U16x8_To_I16x8 is new NEON_Convert_128_S1 (U16x8, I16x8, "movi %1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr %1.8h, %1.8h, #1" & ASCII.LF & ASCII.HT & "umin %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_Convert_Saturate_U16x8_To_I16x8);
   function Convert_Saturate (Value : U16x8) return I16x8 is (Native_Convert_Saturate_U16x8_To_I16x8 (Value));
   function Native_Convert_Saturate_I32x4_To_U32x4 is new NEON_Convert_128_S1 (I32x4, U32x4, "movi %1.2d, #0" & ASCII.LF & ASCII.HT & "smax %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_Convert_Saturate_I32x4_To_U32x4);
   function Convert_Saturate (Value : I32x4) return U32x4 is (Native_Convert_Saturate_I32x4_To_U32x4 (Value));
   function Native_Convert_Saturate_U32x4_To_I32x4 is new NEON_Convert_128_S1 (U32x4, I32x4, "movi %1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr %1.4s, %1.4s, #1" & ASCII.LF & ASCII.HT & "umin %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_Convert_Saturate_U32x4_To_I32x4);
   function Convert_Saturate (Value : U32x4) return I32x4 is (Native_Convert_Saturate_U32x4_To_I32x4 (Value));
   function Native_Convert_Saturate_I64x2_To_U64x2 is new NEON_Convert_128_S1 (I64x2, U64x2, "cmge %1.2d, %2.2d, #0" & ASCII.LF & ASCII.HT & "and %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Convert_Saturate_I64x2_To_U64x2);
   function Convert_Saturate (Value : I64x2) return U64x2 is (Native_Convert_Saturate_I64x2_To_U64x2 (Value));
   function Native_Convert_Saturate_U64x2_To_I64x2 is new NEON_Convert_128_S2 (U64x2, I64x2, "movi %1.16b, #0xff" & ASCII.LF & ASCII.HT & "ushr %1.2d, %1.2d, #1" & ASCII.LF & ASCII.HT & "cmhi %2.2d, %3.2d, %1.2d" & ASCII.LF & ASCII.HT & "bsl %2.16b, %1.16b, %3.16b" & ASCII.LF & ASCII.HT & "mov %0.16b, %2.16b");
   pragma Inline_Always (Native_Convert_Saturate_U64x2_To_I64x2);
   function Convert_Saturate (Value : U64x2) return I64x2 is (Native_Convert_Saturate_U64x2_To_I64x2 (Value));
   function Native_Table_Lookup_U8x16 is new NEON_Binary_128_S0 (U8x16, "tbl %0.16b, {%1.16b}, %2.16b");
   pragma Inline_Always (Native_Table_Lookup_U8x16);
   function Table_Lookup (Table, Indices : U8x16) return U8x16 is (Native_Table_Lookup_U8x16 (Table, Indices));

   function Native_Slide_Lanes_Toward_Low_U8x16_1 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_1);
   function Native_Slide_Lanes_Toward_Low_U8x16_2 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_2);
   function Native_Slide_Lanes_Toward_Low_U8x16_3 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_3);
   function Native_Slide_Lanes_Toward_Low_U8x16_4 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_4);
   function Native_Slide_Lanes_Toward_Low_U8x16_5 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_5);
   function Native_Slide_Lanes_Toward_Low_U8x16_6 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_6);
   function Native_Slide_Lanes_Toward_Low_U8x16_7 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_7);
   function Native_Slide_Lanes_Toward_Low_U8x16_8 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_8);
   function Native_Slide_Lanes_Toward_Low_U8x16_9 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_9);
   function Native_Slide_Lanes_Toward_Low_U8x16_10 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_10);
   function Native_Slide_Lanes_Toward_Low_U8x16_11 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_11);
   function Native_Slide_Lanes_Toward_Low_U8x16_12 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_12);
   function Native_Slide_Lanes_Toward_Low_U8x16_13 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_13);
   function Native_Slide_Lanes_Toward_Low_U8x16_14 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_14);
   function Native_Slide_Lanes_Toward_Low_U8x16_15 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_15);
   function Slide_Lanes_Toward_Low (Value : U8x16; Count : Natural) return U8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Zero
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
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_U8x16_1 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_1);
   function Native_Slide_Lanes_Toward_High_U8x16_2 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_2);
   function Native_Slide_Lanes_Toward_High_U8x16_3 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_3);
   function Native_Slide_Lanes_Toward_High_U8x16_4 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_4);
   function Native_Slide_Lanes_Toward_High_U8x16_5 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_5);
   function Native_Slide_Lanes_Toward_High_U8x16_6 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_6);
   function Native_Slide_Lanes_Toward_High_U8x16_7 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_7);
   function Native_Slide_Lanes_Toward_High_U8x16_8 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_8);
   function Native_Slide_Lanes_Toward_High_U8x16_9 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_9);
   function Native_Slide_Lanes_Toward_High_U8x16_10 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_10);
   function Native_Slide_Lanes_Toward_High_U8x16_11 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_11);
   function Native_Slide_Lanes_Toward_High_U8x16_12 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_12);
   function Native_Slide_Lanes_Toward_High_U8x16_13 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_13);
   function Native_Slide_Lanes_Toward_High_U8x16_14 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_14);
   function Native_Slide_Lanes_Toward_High_U8x16_15 is new NEON_Unary_128_S1 (U8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_15);
   function Slide_Lanes_Toward_High (Value : U8x16; Count : Natural) return U8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Zero
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
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_I8x16_1 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_1);
   function Native_Slide_Lanes_Toward_Low_I8x16_2 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_2);
   function Native_Slide_Lanes_Toward_Low_I8x16_3 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_3);
   function Native_Slide_Lanes_Toward_Low_I8x16_4 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_4);
   function Native_Slide_Lanes_Toward_Low_I8x16_5 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_5);
   function Native_Slide_Lanes_Toward_Low_I8x16_6 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_6);
   function Native_Slide_Lanes_Toward_Low_I8x16_7 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_7);
   function Native_Slide_Lanes_Toward_Low_I8x16_8 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_8);
   function Native_Slide_Lanes_Toward_Low_I8x16_9 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_9);
   function Native_Slide_Lanes_Toward_Low_I8x16_10 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_10);
   function Native_Slide_Lanes_Toward_Low_I8x16_11 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_11);
   function Native_Slide_Lanes_Toward_Low_I8x16_12 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_12);
   function Native_Slide_Lanes_Toward_Low_I8x16_13 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_13);
   function Native_Slide_Lanes_Toward_Low_I8x16_14 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_14);
   function Native_Slide_Lanes_Toward_Low_I8x16_15 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_15);
   function Slide_Lanes_Toward_Low (Value : I8x16; Count : Natural) return I8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Zero
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
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_I8x16_1 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #15");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_1);
   function Native_Slide_Lanes_Toward_High_I8x16_2 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_2);
   function Native_Slide_Lanes_Toward_High_I8x16_3 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #13");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_3);
   function Native_Slide_Lanes_Toward_High_I8x16_4 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_4);
   function Native_Slide_Lanes_Toward_High_I8x16_5 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #11");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_5);
   function Native_Slide_Lanes_Toward_High_I8x16_6 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_6);
   function Native_Slide_Lanes_Toward_High_I8x16_7 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #9");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_7);
   function Native_Slide_Lanes_Toward_High_I8x16_8 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_8);
   function Native_Slide_Lanes_Toward_High_I8x16_9 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #7");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_9);
   function Native_Slide_Lanes_Toward_High_I8x16_10 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_10);
   function Native_Slide_Lanes_Toward_High_I8x16_11 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #5");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_11);
   function Native_Slide_Lanes_Toward_High_I8x16_12 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_12);
   function Native_Slide_Lanes_Toward_High_I8x16_13 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #3");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_13);
   function Native_Slide_Lanes_Toward_High_I8x16_14 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_14);
   function Native_Slide_Lanes_Toward_High_I8x16_15 is new NEON_Unary_128_S1 (I8x16, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #1");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_15);
   function Slide_Lanes_Toward_High (Value : I8x16; Count : Natural) return I8x16 is
     (if Count = 0 then Value
      elsif Count >= 16 then Zero
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
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_U16x8_1 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_1);
   function Native_Slide_Lanes_Toward_Low_U16x8_2 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_2);
   function Native_Slide_Lanes_Toward_Low_U16x8_3 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_3);
   function Native_Slide_Lanes_Toward_Low_U16x8_4 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_4);
   function Native_Slide_Lanes_Toward_Low_U16x8_5 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_5);
   function Native_Slide_Lanes_Toward_Low_U16x8_6 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_6);
   function Native_Slide_Lanes_Toward_Low_U16x8_7 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_7);
   function Slide_Lanes_Toward_Low (Value : U16x8; Count : Natural) return U16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_U16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_U16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_Low_U16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_Low_U16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_Low_U16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_Low_U16x8_7 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_U16x8_1 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_1);
   function Native_Slide_Lanes_Toward_High_U16x8_2 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_2);
   function Native_Slide_Lanes_Toward_High_U16x8_3 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_3);
   function Native_Slide_Lanes_Toward_High_U16x8_4 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_4);
   function Native_Slide_Lanes_Toward_High_U16x8_5 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_5);
   function Native_Slide_Lanes_Toward_High_U16x8_6 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_6);
   function Native_Slide_Lanes_Toward_High_U16x8_7 is new NEON_Unary_128_S1 (U16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_7);
   function Slide_Lanes_Toward_High (Value : U16x8; Count : Natural) return U16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_U16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_U16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_High_U16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_High_U16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_High_U16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_High_U16x8_7 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_I16x8_1 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_1);
   function Native_Slide_Lanes_Toward_Low_I16x8_2 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_2);
   function Native_Slide_Lanes_Toward_Low_I16x8_3 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_3);
   function Native_Slide_Lanes_Toward_Low_I16x8_4 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_4);
   function Native_Slide_Lanes_Toward_Low_I16x8_5 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_5);
   function Native_Slide_Lanes_Toward_Low_I16x8_6 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_6);
   function Native_Slide_Lanes_Toward_Low_I16x8_7 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_7);
   function Slide_Lanes_Toward_Low (Value : I16x8; Count : Natural) return I16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_I16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_I16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_Low_I16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_Low_I16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_Low_I16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_Low_I16x8_7 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_I16x8_1 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #14");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_1);
   function Native_Slide_Lanes_Toward_High_I16x8_2 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_2);
   function Native_Slide_Lanes_Toward_High_I16x8_3 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #10");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_3);
   function Native_Slide_Lanes_Toward_High_I16x8_4 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_4);
   function Native_Slide_Lanes_Toward_High_I16x8_5 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #6");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_5);
   function Native_Slide_Lanes_Toward_High_I16x8_6 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_6);
   function Native_Slide_Lanes_Toward_High_I16x8_7 is new NEON_Unary_128_S1 (I16x8, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #2");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_7);
   function Slide_Lanes_Toward_High (Value : I16x8; Count : Natural) return I16x8 is
     (if Count = 0 then Value
      elsif Count >= 8 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I16x8_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_I16x8_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_I16x8_3 (Value),
         when 4 => Native_Slide_Lanes_Toward_High_I16x8_4 (Value),
         when 5 => Native_Slide_Lanes_Toward_High_I16x8_5 (Value),
         when 6 => Native_Slide_Lanes_Toward_High_I16x8_6 (Value),
         when 7 => Native_Slide_Lanes_Toward_High_I16x8_7 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_U32x4_1 is new NEON_Unary_128_S1 (U32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_1);
   function Native_Slide_Lanes_Toward_Low_U32x4_2 is new NEON_Unary_128_S1 (U32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_2);
   function Native_Slide_Lanes_Toward_Low_U32x4_3 is new NEON_Unary_128_S1 (U32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_3);
   function Slide_Lanes_Toward_Low (Value : U32x4; Count : Natural) return U32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_U32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_U32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_U32x4_1 is new NEON_Unary_128_S1 (U32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_1);
   function Native_Slide_Lanes_Toward_High_U32x4_2 is new NEON_Unary_128_S1 (U32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_2);
   function Native_Slide_Lanes_Toward_High_U32x4_3 is new NEON_Unary_128_S1 (U32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_3);
   function Slide_Lanes_Toward_High (Value : U32x4; Count : Natural) return U32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_U32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_U32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_I32x4_1 is new NEON_Unary_128_S1 (I32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_1);
   function Native_Slide_Lanes_Toward_Low_I32x4_2 is new NEON_Unary_128_S1 (I32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_2);
   function Native_Slide_Lanes_Toward_Low_I32x4_3 is new NEON_Unary_128_S1 (I32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_3);
   function Slide_Lanes_Toward_Low (Value : I32x4; Count : Natural) return I32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_I32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_I32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_I32x4_1 is new NEON_Unary_128_S1 (I32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_1);
   function Native_Slide_Lanes_Toward_High_I32x4_2 is new NEON_Unary_128_S1 (I32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_2);
   function Native_Slide_Lanes_Toward_High_I32x4_3 is new NEON_Unary_128_S1 (I32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_3);
   function Slide_Lanes_Toward_High (Value : I32x4; Count : Natural) return I32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_I32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_I32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_U64x2_1 is new NEON_Unary_128_S1 (U64x2, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U64x2_1);
   function Slide_Lanes_Toward_Low (Value : U64x2; Count : Natural) return U64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_U64x2_1 is new NEON_Unary_128_S1 (U64x2, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U64x2_1);
   function Slide_Lanes_Toward_High (Value : U64x2; Count : Natural) return U64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_I64x2_1 is new NEON_Unary_128_S1 (I64x2, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I64x2_1);
   function Slide_Lanes_Toward_Low (Value : I64x2; Count : Natural) return I64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_I64x2_1 is new NEON_Unary_128_S1 (I64x2, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I64x2_1);
   function Slide_Lanes_Toward_High (Value : I64x2; Count : Natural) return I64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_F32x4_1 is new NEON_Unary_128_S1 (F32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_1);
   function Native_Slide_Lanes_Toward_Low_F32x4_2 is new NEON_Unary_128_S1 (F32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_2);
   function Native_Slide_Lanes_Toward_Low_F32x4_3 is new NEON_Unary_128_S1 (F32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_3);
   function Slide_Lanes_Toward_Low (Value : F32x4; Count : Natural) return F32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_F32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_F32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_F32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_F32x4_1 is new NEON_Unary_128_S1 (F32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #12");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_1);
   function Native_Slide_Lanes_Toward_High_F32x4_2 is new NEON_Unary_128_S1 (F32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_2);
   function Native_Slide_Lanes_Toward_High_F32x4_3 is new NEON_Unary_128_S1 (F32x4, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #4");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_3);
   function Slide_Lanes_Toward_High (Value : F32x4; Count : Natural) return F32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_F32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_F32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_F32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_F64x2_1 is new NEON_Unary_128_S1 (F64x2, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %2.16b, %1.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F64x2_1);
   function Slide_Lanes_Toward_Low (Value : F64x2; Count : Natural) return F64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_F64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_F64x2_1 is new NEON_Unary_128_S1 (F64x2, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "ext %0.16b, %1.16b, %2.16b, #8");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F64x2_1);
   function Slide_Lanes_Toward_High (Value : F64x2; Count : Natural) return F64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_F64x2_1 (Value),
         when others => Zero));

   function Native_Add_Wrap_U8x16 is new NEON_Binary_128_S0 (U8x16, "add %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Add_Wrap_U8x16);
   function Add_Wrap (Left, Right : U8x16) return U8x16 is (Native_Add_Wrap_U8x16 (Left, Right));
   function Native_Subtract_Wrap_U8x16 is new NEON_Binary_128_S0 (U8x16, "sub %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Subtract_Wrap_U8x16);
   function Subtract_Wrap (Left, Right : U8x16) return U8x16 is (Native_Subtract_Wrap_U8x16 (Left, Right));
   function Native_Add_Saturate_U8x16 is new NEON_Binary_128_S0 (U8x16, "uqadd %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Add_Saturate_U8x16);
   function Add_Saturate (Left, Right : U8x16) return U8x16 is (Native_Add_Saturate_U8x16 (Left, Right));
   function Native_Subtract_Saturate_U8x16 is new NEON_Binary_128_S0 (U8x16, "uqsub %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Subtract_Saturate_U8x16);
   function Subtract_Saturate (Left, Right : U8x16) return U8x16 is (Native_Subtract_Saturate_U8x16 (Left, Right));
   function Native_Bitwise_And_U8x16 is new NEON_Binary_128_S0 (U8x16, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_U8x16);
   function Bitwise_And (Left, Right : U8x16) return U8x16 is (Native_Bitwise_And_U8x16 (Left, Right));
   function Native_Bitwise_Or_U8x16 is new NEON_Binary_128_S0 (U8x16, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_U8x16);
   function Bitwise_Or (Left, Right : U8x16) return U8x16 is (Native_Bitwise_Or_U8x16 (Left, Right));
   function Native_Bitwise_Xor_U8x16 is new NEON_Binary_128_S0 (U8x16, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_U8x16);
   function Bitwise_Xor (Left, Right : U8x16) return U8x16 is (Native_Bitwise_Xor_U8x16 (Left, Right));
   function Native_Min_U8x16 is new NEON_Binary_128_S0 (U8x16, "umin %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Min_U8x16);
   function Min (Left, Right : U8x16) return U8x16 is (Native_Min_U8x16 (Left, Right));
   function Native_Max_U8x16 is new NEON_Binary_128_S0 (U8x16, "umax %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Max_U8x16);
   function Max (Left, Right : U8x16) return U8x16 is (Native_Max_U8x16 (Left, Right));
   function Native_Interleave_Low_U8x16 is new NEON_Binary_128_S0 (U8x16, "zip1 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Interleave_Low_U8x16);
   function Interleave_Low (Left, Right : U8x16) return U8x16 is (Native_Interleave_Low_U8x16 (Left, Right));
   function Native_Interleave_High_U8x16 is new NEON_Binary_128_S0 (U8x16, "zip2 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Interleave_High_U8x16);
   function Interleave_High (Left, Right : U8x16) return U8x16 is (Native_Interleave_High_U8x16 (Left, Right));
   function Native_Deinterleave_Even_U8x16 is new NEON_Binary_128_S0 (U8x16, "uzp1 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Deinterleave_Even_U8x16);
   function Deinterleave_Even (Left, Right : U8x16) return U8x16 is (Native_Deinterleave_Even_U8x16 (Left, Right));
   function Native_Deinterleave_Odd_U8x16 is new NEON_Binary_128_S0 (U8x16, "uzp2 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Deinterleave_Odd_U8x16);
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16 is (Native_Deinterleave_Odd_U8x16 (Left, Right));
   function Native_Multiply_Wrap_U8x16 is new NEON_Binary_128_S0 (U8x16, "mul %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Multiply_Wrap_U8x16);
   function Multiply_Wrap (Left, Right : U8x16) return U8x16 is (Native_Multiply_Wrap_U8x16 (Left, Right));
   function Native_Not_U8x16 is new NEON_Unary_128_S0 (U8x16, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_U8x16);
   function Bitwise_Not (Value : U8x16) return U8x16 is (Native_Not_U8x16 (Value));
   function Native_Reverse_U8x16 is new NEON_Unary_128_S0 (U8x16, "rev64 %0.16b, %1.16b" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_U8x16);
   function Reverse_Lanes (Value : U8x16) return U8x16 is (Native_Reverse_U8x16 (Value));
   function Native_Zero_U8x16 is new NEON_Zero_128 (U8x16);
   pragma Inline_Always (Native_Zero_U8x16);
   function Zero return U8x16 is (Native_Zero_U8x16);
   function Native_Splat_U8x16 is new NEON_Splat_Integer_128 (U8x16, U8, "dup %0.16b, %w1");
   pragma Inline_Always (Native_Splat_U8x16);
   function Splat (Value : U8) return U8x16 is (Native_Splat_U8x16 (Value));
   function From_Lanes (Values : Lane_Values_8x16) return U8x16 is
     (Lanes => Values);
   function To_Lanes (Value : U8x16) return Lane_Values_8x16 is
     (Value.Lanes);
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8 is
     (Value.Lanes (Lane));
   function Replace (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16 is
      Result : U8x16 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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

   function Native_Shift_Left_Logical_U8x16 is new NEON_Shift_128 (U8x16, "dup %1.16b, %w3", "ushl %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Shift_Left_Logical_U8x16);
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16 is
     (Native_Shift_Left_Logical_U8x16 (Value, Interfaces.Integer_64 (Natural'Min (Count, 8))));
   function Native_Shift_Right_Logical_U8x16 is new NEON_Shift_128 (U8x16, "dup %1.16b, %w3", "ushl %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Shift_Right_Logical_U8x16);
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16 is
     (Native_Shift_Right_Logical_U8x16 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 8))));
   function Compare_U8x16 is new NEON_Compare_16_Lanes (U8x16, "cmeq %2.16b, %4.16b, %5.16b");
   pragma Inline_Always (Compare_U8x16);
   function Compare_Greater_U8x16 is new NEON_Compare_16_Lanes (U8x16, "cmhi %2.16b, %4.16b, %5.16b");
   pragma Inline_Always (Compare_Greater_U8x16);
   function Compare_Greater_Equal_U8x16 is new NEON_Compare_16_Lanes (U8x16, "cmhs %2.16b, %4.16b, %5.16b");
   pragma Inline_Always (Compare_Greater_Equal_U8x16);
   function Equal (Left, Right : U8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_U8x16 (Left, Right, Weights_Vector_8x16)));
   function Greater_Than (Left, Right : U8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_U8x16 (Left, Right, Weights_Vector_8x16)));
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U8x16 (Left, Right, Weights_Vector_8x16)));
   function Less_Than (Left, Right : U8x16) return Mask_8x16 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U8x16) return Mask_8x16 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U8x16 is new NEON_Select_16_Lanes_128 (U8x16);
   pragma Inline_Always (Native_Select_U8x16);
   function Select_Value (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16 is (Native_Select_U8x16 (Mask.Bits, Weights_Vector_8x16, If_True, If_False));
   function Native_Reduce_Add_Wrap_U8x16 is new NEON_Integer_Reduce_128 (U8x16, U8, "addv %b1, %4.16b", "umov %w0, %1.b[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_U8x16);
   function Reduce_Add_Wrap (Value : U8x16) return U8 is (Native_Reduce_Add_Wrap_U8x16 (Value));
   function Native_Reduce_Min_U8x16 is new NEON_Integer_Reduce_128 (U8x16, U8, "uminv %b1, %4.16b", "umov %w0, %1.b[0]");
   pragma Inline_Always (Native_Reduce_Min_U8x16);
   function Reduce_Min (Value : U8x16) return U8 is (Native_Reduce_Min_U8x16 (Value));
   function Native_Reduce_Max_U8x16 is new NEON_Integer_Reduce_128 (U8x16, U8, "umaxv %b1, %4.16b", "umov %w0, %1.b[0]");
   pragma Inline_Always (Native_Reduce_Max_U8x16);
   function Reduce_Max (Value : U8x16) return U8 is (Native_Reduce_Max_U8x16 (Value));
   function Is_Aligned_16 (Data : Byte_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : Byte_Array; Start : Natural) return U8x16 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U8x16);
      Source : constant Lane_Values_8x16 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_8x16'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
      function To_Machine is new Ada.Unchecked_Conversion (U8x16, Machine_Vector);
      Target : Lane_Values_8x16 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_8x16'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x16) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16) return U8x16 is
      Result : U8x16 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_8x16 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out Byte_Array; Start : Natural; Count : Lane_Count_8x16; Value : U8x16) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_8x16 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Horizontal_Sum (Value : U8x16) return Natural is
      function To_Machine is new Ada.Unchecked_Conversion (U8x16, Machine_Vector);
      Result : Interfaces.Unsigned_32;
      Total : Machine_Vector;
   begin
      Asm
        (Template =>
           "uaddlv %h1, %2.16b" & ASCII.LF & ASCII.HT &
                   "umov %w0, %1.h[0]",
         Outputs => [Interfaces.Unsigned_32'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&w", Total)],
         Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
      return Natural (Result);
   end Horizontal_Sum;
   function Reverse_Bytes (Value : U8x16) return U8x16 is (Reverse_Lanes (Value));
   function Native_Add_Wrap_I8x16 is new NEON_Binary_128_S0 (I8x16, "add %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Add_Wrap_I8x16);
   function Add_Wrap (Left, Right : I8x16) return I8x16 is (Native_Add_Wrap_I8x16 (Left, Right));
   function Native_Subtract_Wrap_I8x16 is new NEON_Binary_128_S0 (I8x16, "sub %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Subtract_Wrap_I8x16);
   function Subtract_Wrap (Left, Right : I8x16) return I8x16 is (Native_Subtract_Wrap_I8x16 (Left, Right));
   function Native_Add_Saturate_I8x16 is new NEON_Binary_128_S0 (I8x16, "sqadd %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Add_Saturate_I8x16);
   function Add_Saturate (Left, Right : I8x16) return I8x16 is (Native_Add_Saturate_I8x16 (Left, Right));
   function Native_Subtract_Saturate_I8x16 is new NEON_Binary_128_S0 (I8x16, "sqsub %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Subtract_Saturate_I8x16);
   function Subtract_Saturate (Left, Right : I8x16) return I8x16 is (Native_Subtract_Saturate_I8x16 (Left, Right));
   function Native_Bitwise_And_I8x16 is new NEON_Binary_128_S0 (I8x16, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_I8x16);
   function Bitwise_And (Left, Right : I8x16) return I8x16 is (Native_Bitwise_And_I8x16 (Left, Right));
   function Native_Bitwise_Or_I8x16 is new NEON_Binary_128_S0 (I8x16, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_I8x16);
   function Bitwise_Or (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Or_I8x16 (Left, Right));
   function Native_Bitwise_Xor_I8x16 is new NEON_Binary_128_S0 (I8x16, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_I8x16);
   function Bitwise_Xor (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Xor_I8x16 (Left, Right));
   function Native_Min_I8x16 is new NEON_Binary_128_S0 (I8x16, "smin %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Min_I8x16);
   function Min (Left, Right : I8x16) return I8x16 is (Native_Min_I8x16 (Left, Right));
   function Native_Max_I8x16 is new NEON_Binary_128_S0 (I8x16, "smax %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Max_I8x16);
   function Max (Left, Right : I8x16) return I8x16 is (Native_Max_I8x16 (Left, Right));
   function Native_Interleave_Low_I8x16 is new NEON_Binary_128_S0 (I8x16, "zip1 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Interleave_Low_I8x16);
   function Interleave_Low (Left, Right : I8x16) return I8x16 is (Native_Interleave_Low_I8x16 (Left, Right));
   function Native_Interleave_High_I8x16 is new NEON_Binary_128_S0 (I8x16, "zip2 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Interleave_High_I8x16);
   function Interleave_High (Left, Right : I8x16) return I8x16 is (Native_Interleave_High_I8x16 (Left, Right));
   function Native_Deinterleave_Even_I8x16 is new NEON_Binary_128_S0 (I8x16, "uzp1 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Deinterleave_Even_I8x16);
   function Deinterleave_Even (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Even_I8x16 (Left, Right));
   function Native_Deinterleave_Odd_I8x16 is new NEON_Binary_128_S0 (I8x16, "uzp2 %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Deinterleave_Odd_I8x16);
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Odd_I8x16 (Left, Right));
   function Native_Multiply_Wrap_I8x16 is new NEON_Binary_128_S0 (I8x16, "mul %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Multiply_Wrap_I8x16);
   function Multiply_Wrap (Left, Right : I8x16) return I8x16 is (Native_Multiply_Wrap_I8x16 (Left, Right));
   function Native_Not_I8x16 is new NEON_Unary_128_S0 (I8x16, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_I8x16);
   function Bitwise_Not (Value : I8x16) return I8x16 is (Native_Not_I8x16 (Value));
   function Native_Reverse_I8x16 is new NEON_Unary_128_S0 (I8x16, "rev64 %0.16b, %1.16b" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_I8x16);
   function Reverse_Lanes (Value : I8x16) return I8x16 is (Native_Reverse_I8x16 (Value));
   function Native_Zero_I8x16 is new NEON_Zero_128 (I8x16);
   pragma Inline_Always (Native_Zero_I8x16);
   function Zero return I8x16 is (Native_Zero_I8x16);
   function Native_Splat_I8x16 is new NEON_Splat_Integer_128 (I8x16, I8, "dup %0.16b, %w1");
   pragma Inline_Always (Native_Splat_I8x16);
   function Splat (Value : I8) return I8x16 is (Native_Splat_I8x16 (Value));
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16 is
     (Lanes => Values);
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16 is
     (Value.Lanes);
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8 is
     (Value.Lanes (Lane));
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16 is
      Result : I8x16 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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

   function Native_Shift_Left_Logical_I8x16 is new NEON_Shift_128 (I8x16, "dup %1.16b, %w3", "ushl %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Shift_Left_Logical_I8x16);
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16 is
     (Native_Shift_Left_Logical_I8x16 (Value, Interfaces.Integer_64 (Natural'Min (Count, 8))));
   function Native_Shift_Right_Logical_I8x16 is new NEON_Shift_128 (I8x16, "dup %1.16b, %w3", "ushl %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_Shift_Right_Logical_I8x16);
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16 is
     (Native_Shift_Right_Logical_I8x16 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 8))));
   function Native_SRA_I8x16 is new NEON_Shift_128 (I8x16, "dup %1.16b, %w3", "sshl %0.16b, %2.16b, %1.16b");
   pragma Inline_Always (Native_SRA_I8x16);
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16 is
     (Native_SRA_I8x16 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 8))));
   function Compare_I8x16 is new NEON_Compare_16_Lanes (I8x16, "cmeq %2.16b, %4.16b, %5.16b");
   pragma Inline_Always (Compare_I8x16);
   function Compare_Greater_I8x16 is new NEON_Compare_16_Lanes (I8x16, "cmgt %2.16b, %4.16b, %5.16b");
   pragma Inline_Always (Compare_Greater_I8x16);
   function Compare_Greater_Equal_I8x16 is new NEON_Compare_16_Lanes (I8x16, "cmge %2.16b, %4.16b, %5.16b");
   pragma Inline_Always (Compare_Greater_Equal_I8x16);
   function Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_I8x16 (Left, Right, Weights_Vector_8x16)));
   function Greater_Than (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_I8x16 (Left, Right, Weights_Vector_8x16)));
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I8x16 (Left, Right, Weights_Vector_8x16)));
   function Less_Than (Left, Right : I8x16) return Mask_8x16 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I8x16) return Mask_8x16 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I8x16 is new NEON_Select_16_Lanes_128 (I8x16);
   pragma Inline_Always (Native_Select_I8x16);
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16 is (Native_Select_I8x16 (Mask.Bits, Weights_Vector_8x16, If_True, If_False));
   function Native_Reduce_Add_Wrap_I8x16 is new NEON_Integer_Reduce_128 (I8x16, I8, "addv %b1, %4.16b", "umov %w0, %1.b[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_I8x16);
   function Reduce_Add_Wrap (Value : I8x16) return I8 is (Native_Reduce_Add_Wrap_I8x16 (Value));
   function Native_Reduce_Min_I8x16 is new NEON_Integer_Reduce_128 (I8x16, I8, "sminv %b1, %4.16b", "umov %w0, %1.b[0]");
   pragma Inline_Always (Native_Reduce_Min_I8x16);
   function Reduce_Min (Value : I8x16) return I8 is (Native_Reduce_Min_I8x16 (Value));
   function Native_Reduce_Max_I8x16 is new NEON_Integer_Reduce_128 (I8x16, I8, "smaxv %b1, %4.16b", "umov %w0, %1.b[0]");
   pragma Inline_Always (Native_Reduce_Max_I8x16);
   function Reduce_Max (Value : I8x16) return I8 is (Native_Reduce_Max_I8x16 (Value));
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I8x16);
      Source : constant Lane_Values_I8x16 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_I8x16'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
      function To_Machine is new Ada.Unchecked_Conversion (I8x16, Machine_Vector);
      Target : Lane_Values_I8x16 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_I8x16'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 is
      Result : I8x16 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_8x16 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_8x16 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Compare_U16x8 is new NEON_Compare_128 (U16x8, "cmeq %2.8h, %4.8h, %5.8h", "ushr %2.8h, %2.8h, #15" & ASCII.LF & ASCII.HT & "mul %2.8h, %2.8h, %6.8h" & ASCII.LF & ASCII.HT & "addv %h2, %2.8h" & ASCII.LF & ASCII.HT & "umov %w0, %2.h[0]");
   pragma Inline_Always (Compare_U16x8);
   function Compare_Greater_U16x8 is new NEON_Compare_128 (U16x8, "cmhi %2.8h, %4.8h, %5.8h", "ushr %2.8h, %2.8h, #15" & ASCII.LF & ASCII.HT & "mul %2.8h, %2.8h, %6.8h" & ASCII.LF & ASCII.HT & "addv %h2, %2.8h" & ASCII.LF & ASCII.HT & "umov %w0, %2.h[0]");
   pragma Inline_Always (Compare_Greater_U16x8);
   function Compare_Greater_Equal_U16x8 is new NEON_Compare_128 (U16x8, "cmhs %2.8h, %4.8h, %5.8h", "ushr %2.8h, %2.8h, #15" & ASCII.LF & ASCII.HT & "mul %2.8h, %2.8h, %6.8h" & ASCII.LF & ASCII.HT & "addv %h2, %2.8h" & ASCII.LF & ASCII.HT & "umov %w0, %2.h[0]");
   pragma Inline_Always (Compare_Greater_Equal_U16x8);
   function Native_Add_Wrap_U16x8 is new NEON_Binary_128_S0 (U16x8, "add %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Add_Wrap_U16x8);
   function Add_Wrap (Left, Right : U16x8) return U16x8 is (Native_Add_Wrap_U16x8 (Left, Right));
   function Native_Subtract_Wrap_U16x8 is new NEON_Binary_128_S0 (U16x8, "sub %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Subtract_Wrap_U16x8);
   function Subtract_Wrap (Left, Right : U16x8) return U16x8 is (Native_Subtract_Wrap_U16x8 (Left, Right));
   function Native_Add_Saturate_U16x8 is new NEON_Binary_128_S0 (U16x8, "uqadd %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Add_Saturate_U16x8);
   function Add_Saturate (Left, Right : U16x8) return U16x8 is (Native_Add_Saturate_U16x8 (Left, Right));
   function Native_Subtract_Saturate_U16x8 is new NEON_Binary_128_S0 (U16x8, "uqsub %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Subtract_Saturate_U16x8);
   function Subtract_Saturate (Left, Right : U16x8) return U16x8 is (Native_Subtract_Saturate_U16x8 (Left, Right));
   function Native_Bitwise_And_U16x8 is new NEON_Binary_128_S0 (U16x8, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_U16x8);
   function Bitwise_And (Left, Right : U16x8) return U16x8 is (Native_Bitwise_And_U16x8 (Left, Right));
   function Native_Bitwise_Or_U16x8 is new NEON_Binary_128_S0 (U16x8, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_U16x8);
   function Bitwise_Or (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Or_U16x8 (Left, Right));
   function Native_Bitwise_Xor_U16x8 is new NEON_Binary_128_S0 (U16x8, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_U16x8);
   function Bitwise_Xor (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Xor_U16x8 (Left, Right));
   function Native_Min_U16x8 is new NEON_Binary_128_S0 (U16x8, "umin %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Min_U16x8);
   function Min (Left, Right : U16x8) return U16x8 is (Native_Min_U16x8 (Left, Right));
   function Native_Max_U16x8 is new NEON_Binary_128_S0 (U16x8, "umax %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Max_U16x8);
   function Max (Left, Right : U16x8) return U16x8 is (Native_Max_U16x8 (Left, Right));
   function Native_Interleave_Low_U16x8 is new NEON_Binary_128_S0 (U16x8, "zip1 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Interleave_Low_U16x8);
   function Interleave_Low (Left, Right : U16x8) return U16x8 is (Native_Interleave_Low_U16x8 (Left, Right));
   function Native_Interleave_High_U16x8 is new NEON_Binary_128_S0 (U16x8, "zip2 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Interleave_High_U16x8);
   function Interleave_High (Left, Right : U16x8) return U16x8 is (Native_Interleave_High_U16x8 (Left, Right));
   function Native_Deinterleave_Even_U16x8 is new NEON_Binary_128_S0 (U16x8, "uzp1 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Deinterleave_Even_U16x8);
   function Deinterleave_Even (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Even_U16x8 (Left, Right));
   function Native_Deinterleave_Odd_U16x8 is new NEON_Binary_128_S0 (U16x8, "uzp2 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Deinterleave_Odd_U16x8);
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Odd_U16x8 (Left, Right));
   function Native_Multiply_Wrap_U16x8 is new NEON_Binary_128_S0 (U16x8, "mul %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Multiply_Wrap_U16x8);
   function Multiply_Wrap (Left, Right : U16x8) return U16x8 is (Native_Multiply_Wrap_U16x8 (Left, Right));
   function Native_Not_U16x8 is new NEON_Unary_128_S0 (U16x8, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_U16x8);
   function Bitwise_Not (Value : U16x8) return U16x8 is (Native_Not_U16x8 (Value));
   function Native_Reverse_U16x8 is new NEON_Unary_128_S0 (U16x8, "rev64 %0.8h, %1.8h" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_U16x8);
   function Reverse_Lanes (Value : U16x8) return U16x8 is (Native_Reverse_U16x8 (Value));
   function Native_Zero_U16x8 is new NEON_Zero_128 (U16x8);
   pragma Inline_Always (Native_Zero_U16x8);
   function Zero return U16x8 is (Native_Zero_U16x8);
   function Native_Splat_U16x8 is new NEON_Splat_Integer_128 (U16x8, U16, "dup %0.8h, %w1");
   pragma Inline_Always (Native_Splat_U16x8);
   function Splat (Value : U16) return U16x8 is (Native_Splat_U16x8 (Value));
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8 is
     (Lanes => Values);
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8 is
     (Value.Lanes);
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16 is
     (Value.Lanes (Lane));
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8 is
      Result : U16x8 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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

   function Native_Shift_Left_Logical_U16x8 is new NEON_Shift_128 (U16x8, "dup %1.8h, %w3", "ushl %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_Shift_Left_Logical_U16x8);
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8 is
     (Native_Shift_Left_Logical_U16x8 (Value, Interfaces.Integer_64 (Natural'Min (Count, 16))));
   function Native_Shift_Right_Logical_U16x8 is new NEON_Shift_128 (U16x8, "dup %1.8h, %w3", "ushl %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_Shift_Right_Logical_U16x8);
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8 is
     (Native_Shift_Right_Logical_U16x8 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 16))));
   function Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_U16x8 (Left, Right, Weights_Vector_16x8)));
   function Greater_Than (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_U16x8 (Left, Right, Weights_Vector_16x8)));
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U16x8 (Left, Right, Weights_Vector_16x8)));
   function Less_Than (Left, Right : U16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U16x8 is new NEON_Select_128 (U16x8, "dup %0.8h, %w1", "cmtst %0.8h, %0.8h, %2.8h");
   pragma Inline_Always (Native_Select_U16x8);
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8 is (Native_Select_U16x8 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_16x8, If_True, If_False));
   function Native_Reduce_Add_Wrap_U16x8 is new NEON_Integer_Reduce_128 (U16x8, U16, "addv %h1, %4.8h", "umov %w0, %1.h[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_U16x8);
   function Reduce_Add_Wrap (Value : U16x8) return U16 is (Native_Reduce_Add_Wrap_U16x8 (Value));
   function Native_Reduce_Min_U16x8 is new NEON_Integer_Reduce_128 (U16x8, U16, "uminv %h1, %4.8h", "umov %w0, %1.h[0]");
   pragma Inline_Always (Native_Reduce_Min_U16x8);
   function Reduce_Min (Value : U16x8) return U16 is (Native_Reduce_Min_U16x8 (Value));
   function Native_Reduce_Max_U16x8 is new NEON_Integer_Reduce_128 (U16x8, U16, "umaxv %h1, %4.8h", "umov %w0, %1.h[0]");
   pragma Inline_Always (Native_Reduce_Max_U16x8);
   function Reduce_Max (Value : U16x8) return U16 is (Native_Reduce_Max_U16x8 (Value));
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U16x8);
      Source : constant Lane_Values_U16x8 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_U16x8'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
      function To_Machine is new Ada.Unchecked_Conversion (U16x8, Machine_Vector);
      Target : Lane_Values_U16x8 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_U16x8'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 is
      Result : U16x8 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_16x8 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_16x8 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Compare_I16x8 is new NEON_Compare_128 (I16x8, "cmeq %2.8h, %4.8h, %5.8h", "ushr %2.8h, %2.8h, #15" & ASCII.LF & ASCII.HT & "mul %2.8h, %2.8h, %6.8h" & ASCII.LF & ASCII.HT & "addv %h2, %2.8h" & ASCII.LF & ASCII.HT & "umov %w0, %2.h[0]");
   pragma Inline_Always (Compare_I16x8);
   function Compare_Greater_I16x8 is new NEON_Compare_128 (I16x8, "cmgt %2.8h, %4.8h, %5.8h", "ushr %2.8h, %2.8h, #15" & ASCII.LF & ASCII.HT & "mul %2.8h, %2.8h, %6.8h" & ASCII.LF & ASCII.HT & "addv %h2, %2.8h" & ASCII.LF & ASCII.HT & "umov %w0, %2.h[0]");
   pragma Inline_Always (Compare_Greater_I16x8);
   function Compare_Greater_Equal_I16x8 is new NEON_Compare_128 (I16x8, "cmge %2.8h, %4.8h, %5.8h", "ushr %2.8h, %2.8h, #15" & ASCII.LF & ASCII.HT & "mul %2.8h, %2.8h, %6.8h" & ASCII.LF & ASCII.HT & "addv %h2, %2.8h" & ASCII.LF & ASCII.HT & "umov %w0, %2.h[0]");
   pragma Inline_Always (Compare_Greater_Equal_I16x8);
   function Native_Add_Wrap_I16x8 is new NEON_Binary_128_S0 (I16x8, "add %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Add_Wrap_I16x8);
   function Add_Wrap (Left, Right : I16x8) return I16x8 is (Native_Add_Wrap_I16x8 (Left, Right));
   function Native_Subtract_Wrap_I16x8 is new NEON_Binary_128_S0 (I16x8, "sub %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Subtract_Wrap_I16x8);
   function Subtract_Wrap (Left, Right : I16x8) return I16x8 is (Native_Subtract_Wrap_I16x8 (Left, Right));
   function Native_Add_Saturate_I16x8 is new NEON_Binary_128_S0 (I16x8, "sqadd %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Add_Saturate_I16x8);
   function Add_Saturate (Left, Right : I16x8) return I16x8 is (Native_Add_Saturate_I16x8 (Left, Right));
   function Native_Subtract_Saturate_I16x8 is new NEON_Binary_128_S0 (I16x8, "sqsub %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Subtract_Saturate_I16x8);
   function Subtract_Saturate (Left, Right : I16x8) return I16x8 is (Native_Subtract_Saturate_I16x8 (Left, Right));
   function Native_Bitwise_And_I16x8 is new NEON_Binary_128_S0 (I16x8, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_I16x8);
   function Bitwise_And (Left, Right : I16x8) return I16x8 is (Native_Bitwise_And_I16x8 (Left, Right));
   function Native_Bitwise_Or_I16x8 is new NEON_Binary_128_S0 (I16x8, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_I16x8);
   function Bitwise_Or (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Or_I16x8 (Left, Right));
   function Native_Bitwise_Xor_I16x8 is new NEON_Binary_128_S0 (I16x8, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_I16x8);
   function Bitwise_Xor (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Xor_I16x8 (Left, Right));
   function Native_Min_I16x8 is new NEON_Binary_128_S0 (I16x8, "smin %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Min_I16x8);
   function Min (Left, Right : I16x8) return I16x8 is (Native_Min_I16x8 (Left, Right));
   function Native_Max_I16x8 is new NEON_Binary_128_S0 (I16x8, "smax %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Max_I16x8);
   function Max (Left, Right : I16x8) return I16x8 is (Native_Max_I16x8 (Left, Right));
   function Native_Interleave_Low_I16x8 is new NEON_Binary_128_S0 (I16x8, "zip1 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Interleave_Low_I16x8);
   function Interleave_Low (Left, Right : I16x8) return I16x8 is (Native_Interleave_Low_I16x8 (Left, Right));
   function Native_Interleave_High_I16x8 is new NEON_Binary_128_S0 (I16x8, "zip2 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Interleave_High_I16x8);
   function Interleave_High (Left, Right : I16x8) return I16x8 is (Native_Interleave_High_I16x8 (Left, Right));
   function Native_Deinterleave_Even_I16x8 is new NEON_Binary_128_S0 (I16x8, "uzp1 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Deinterleave_Even_I16x8);
   function Deinterleave_Even (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Even_I16x8 (Left, Right));
   function Native_Deinterleave_Odd_I16x8 is new NEON_Binary_128_S0 (I16x8, "uzp2 %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Deinterleave_Odd_I16x8);
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Odd_I16x8 (Left, Right));
   function Native_Multiply_Wrap_I16x8 is new NEON_Binary_128_S0 (I16x8, "mul %0.8h, %1.8h, %2.8h");
   pragma Inline_Always (Native_Multiply_Wrap_I16x8);
   function Multiply_Wrap (Left, Right : I16x8) return I16x8 is (Native_Multiply_Wrap_I16x8 (Left, Right));
   function Native_Not_I16x8 is new NEON_Unary_128_S0 (I16x8, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_I16x8);
   function Bitwise_Not (Value : I16x8) return I16x8 is (Native_Not_I16x8 (Value));
   function Native_Reverse_I16x8 is new NEON_Unary_128_S0 (I16x8, "rev64 %0.8h, %1.8h" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_I16x8);
   function Reverse_Lanes (Value : I16x8) return I16x8 is (Native_Reverse_I16x8 (Value));
   function Native_Zero_I16x8 is new NEON_Zero_128 (I16x8);
   pragma Inline_Always (Native_Zero_I16x8);
   function Zero return I16x8 is (Native_Zero_I16x8);
   function Native_Splat_I16x8 is new NEON_Splat_Integer_128 (I16x8, I16, "dup %0.8h, %w1");
   pragma Inline_Always (Native_Splat_I16x8);
   function Splat (Value : I16) return I16x8 is (Native_Splat_I16x8 (Value));
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8 is
     (Lanes => Values);
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8 is
     (Value.Lanes);
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16 is
     (Value.Lanes (Lane));
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8 is
      Result : I16x8 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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

   function Native_Shift_Left_Logical_I16x8 is new NEON_Shift_128 (I16x8, "dup %1.8h, %w3", "ushl %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_Shift_Left_Logical_I16x8);
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8 is
     (Native_Shift_Left_Logical_I16x8 (Value, Interfaces.Integer_64 (Natural'Min (Count, 16))));
   function Native_Shift_Right_Logical_I16x8 is new NEON_Shift_128 (I16x8, "dup %1.8h, %w3", "ushl %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_Shift_Right_Logical_I16x8);
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8 is
     (Native_Shift_Right_Logical_I16x8 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 16))));
   function Native_SRA_I16x8 is new NEON_Shift_128 (I16x8, "dup %1.8h, %w3", "sshl %0.8h, %2.8h, %1.8h");
   pragma Inline_Always (Native_SRA_I16x8);
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8 is
     (Native_SRA_I16x8 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 16))));
   function Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_I16x8 (Left, Right, Weights_Vector_16x8)));
   function Greater_Than (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_I16x8 (Left, Right, Weights_Vector_16x8)));
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I16x8 (Left, Right, Weights_Vector_16x8)));
   function Less_Than (Left, Right : I16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I16x8 is new NEON_Select_128 (I16x8, "dup %0.8h, %w1", "cmtst %0.8h, %0.8h, %2.8h");
   pragma Inline_Always (Native_Select_I16x8);
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8 is (Native_Select_I16x8 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_16x8, If_True, If_False));
   function Native_Reduce_Add_Wrap_I16x8 is new NEON_Integer_Reduce_128 (I16x8, I16, "addv %h1, %4.8h", "umov %w0, %1.h[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_I16x8);
   function Reduce_Add_Wrap (Value : I16x8) return I16 is (Native_Reduce_Add_Wrap_I16x8 (Value));
   function Native_Reduce_Min_I16x8 is new NEON_Integer_Reduce_128 (I16x8, I16, "sminv %h1, %4.8h", "umov %w0, %1.h[0]");
   pragma Inline_Always (Native_Reduce_Min_I16x8);
   function Reduce_Min (Value : I16x8) return I16 is (Native_Reduce_Min_I16x8 (Value));
   function Native_Reduce_Max_I16x8 is new NEON_Integer_Reduce_128 (I16x8, I16, "smaxv %h1, %4.8h", "umov %w0, %1.h[0]");
   pragma Inline_Always (Native_Reduce_Max_I16x8);
   function Reduce_Max (Value : I16x8) return I16 is (Native_Reduce_Max_I16x8 (Value));
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I16x8);
      Source : constant Lane_Values_I16x8 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_I16x8'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
      function To_Machine is new Ada.Unchecked_Conversion (I16x8, Machine_Vector);
      Target : Lane_Values_I16x8 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_I16x8'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 is
      Result : I16x8 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_16x8 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_16x8 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Compare_U32x4 is new NEON_Compare_128 (U32x4, "cmeq %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_U32x4);
   function Compare_Greater_U32x4 is new NEON_Compare_128 (U32x4, "cmhi %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Greater_U32x4);
   function Compare_Greater_Equal_U32x4 is new NEON_Compare_128 (U32x4, "cmhs %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Greater_Equal_U32x4);
   function Native_Add_Wrap_U32x4 is new NEON_Binary_128_S0 (U32x4, "add %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Add_Wrap_U32x4);
   function Add_Wrap (Left, Right : U32x4) return U32x4 is (Native_Add_Wrap_U32x4 (Left, Right));
   function Native_Subtract_Wrap_U32x4 is new NEON_Binary_128_S0 (U32x4, "sub %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Subtract_Wrap_U32x4);
   function Subtract_Wrap (Left, Right : U32x4) return U32x4 is (Native_Subtract_Wrap_U32x4 (Left, Right));
   function Native_Add_Saturate_U32x4 is new NEON_Binary_128_S0 (U32x4, "uqadd %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Add_Saturate_U32x4);
   function Add_Saturate (Left, Right : U32x4) return U32x4 is (Native_Add_Saturate_U32x4 (Left, Right));
   function Native_Subtract_Saturate_U32x4 is new NEON_Binary_128_S0 (U32x4, "uqsub %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Subtract_Saturate_U32x4);
   function Subtract_Saturate (Left, Right : U32x4) return U32x4 is (Native_Subtract_Saturate_U32x4 (Left, Right));
   function Native_Bitwise_And_U32x4 is new NEON_Binary_128_S0 (U32x4, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_U32x4);
   function Bitwise_And (Left, Right : U32x4) return U32x4 is (Native_Bitwise_And_U32x4 (Left, Right));
   function Native_Bitwise_Or_U32x4 is new NEON_Binary_128_S0 (U32x4, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_U32x4);
   function Bitwise_Or (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Or_U32x4 (Left, Right));
   function Native_Bitwise_Xor_U32x4 is new NEON_Binary_128_S0 (U32x4, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_U32x4);
   function Bitwise_Xor (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Xor_U32x4 (Left, Right));
   function Native_Min_U32x4 is new NEON_Binary_128_S0 (U32x4, "umin %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Min_U32x4);
   function Min (Left, Right : U32x4) return U32x4 is (Native_Min_U32x4 (Left, Right));
   function Native_Max_U32x4 is new NEON_Binary_128_S0 (U32x4, "umax %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Max_U32x4);
   function Max (Left, Right : U32x4) return U32x4 is (Native_Max_U32x4 (Left, Right));
   function Native_Interleave_Low_U32x4 is new NEON_Binary_128_S0 (U32x4, "zip1 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Interleave_Low_U32x4);
   function Interleave_Low (Left, Right : U32x4) return U32x4 is (Native_Interleave_Low_U32x4 (Left, Right));
   function Native_Interleave_High_U32x4 is new NEON_Binary_128_S0 (U32x4, "zip2 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Interleave_High_U32x4);
   function Interleave_High (Left, Right : U32x4) return U32x4 is (Native_Interleave_High_U32x4 (Left, Right));
   function Native_Deinterleave_Even_U32x4 is new NEON_Binary_128_S0 (U32x4, "uzp1 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Deinterleave_Even_U32x4);
   function Deinterleave_Even (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Even_U32x4 (Left, Right));
   function Native_Deinterleave_Odd_U32x4 is new NEON_Binary_128_S0 (U32x4, "uzp2 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Deinterleave_Odd_U32x4);
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Odd_U32x4 (Left, Right));
   function Native_Multiply_Wrap_U32x4 is new NEON_Binary_128_S0 (U32x4, "mul %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Multiply_Wrap_U32x4);
   function Multiply_Wrap (Left, Right : U32x4) return U32x4 is (Native_Multiply_Wrap_U32x4 (Left, Right));
   function Native_Not_U32x4 is new NEON_Unary_128_S0 (U32x4, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_U32x4);
   function Bitwise_Not (Value : U32x4) return U32x4 is (Native_Not_U32x4 (Value));
   function Native_Reverse_U32x4 is new NEON_Unary_128_S0 (U32x4, "rev64 %0.4s, %1.4s" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_U32x4);
   function Reverse_Lanes (Value : U32x4) return U32x4 is (Native_Reverse_U32x4 (Value));
   function Native_Zero_U32x4 is new NEON_Zero_128 (U32x4);
   pragma Inline_Always (Native_Zero_U32x4);
   function Zero return U32x4 is (Native_Zero_U32x4);
   function Native_Splat_U32x4 is new NEON_Splat_Integer_128 (U32x4, U32, "dup %0.4s, %w1");
   pragma Inline_Always (Native_Splat_U32x4);
   function Splat (Value : U32) return U32x4 is (Native_Splat_U32x4 (Value));
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4 is
     (Lanes => Values);
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4 is
     (Value.Lanes);
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32 is
     (Value.Lanes (Lane));
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4 is
      Result : U32x4 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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

   function Native_Shift_Left_Logical_U32x4 is new NEON_Shift_128 (U32x4, "dup %1.4s, %w3", "ushl %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_Shift_Left_Logical_U32x4);
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4 is
     (Native_Shift_Left_Logical_U32x4 (Value, Interfaces.Integer_64 (Natural'Min (Count, 32))));
   function Native_Shift_Right_Logical_U32x4 is new NEON_Shift_128 (U32x4, "dup %1.4s, %w3", "ushl %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_Shift_Right_Logical_U32x4);
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4 is
     (Native_Shift_Right_Logical_U32x4 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 32))));
   function Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_U32x4 (Left, Right, Weights_Vector_32x4)));
   function Greater_Than (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_U32x4 (Left, Right, Weights_Vector_32x4)));
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U32x4 (Left, Right, Weights_Vector_32x4)));
   function Less_Than (Left, Right : U32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U32x4 is new NEON_Select_128 (U32x4, "dup %0.4s, %w1", "cmtst %0.4s, %0.4s, %2.4s");
   pragma Inline_Always (Native_Select_U32x4);
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4 is (Native_Select_U32x4 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_32x4, If_True, If_False));
   function Native_Reduce_Add_Wrap_U32x4 is new NEON_Integer_Reduce_128 (U32x4, U32, "addv %s1, %4.4s", "umov %w0, %1.s[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_U32x4);
   function Reduce_Add_Wrap (Value : U32x4) return U32 is (Native_Reduce_Add_Wrap_U32x4 (Value));
   function Native_Reduce_Min_U32x4 is new NEON_Integer_Reduce_128 (U32x4, U32, "uminv %s1, %4.4s", "umov %w0, %1.s[0]");
   pragma Inline_Always (Native_Reduce_Min_U32x4);
   function Reduce_Min (Value : U32x4) return U32 is (Native_Reduce_Min_U32x4 (Value));
   function Native_Reduce_Max_U32x4 is new NEON_Integer_Reduce_128 (U32x4, U32, "umaxv %s1, %4.4s", "umov %w0, %1.s[0]");
   pragma Inline_Always (Native_Reduce_Max_U32x4);
   function Reduce_Max (Value : U32x4) return U32 is (Native_Reduce_Max_U32x4 (Value));
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U32x4);
      Source : constant Lane_Values_U32x4 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_U32x4'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (U32x4, Machine_Vector);
      Target : Lane_Values_U32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_U32x4'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 is
      Result : U32x4 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_32x4 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_32x4 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Compare_I32x4 is new NEON_Compare_128 (I32x4, "cmeq %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_I32x4);
   function Compare_Greater_I32x4 is new NEON_Compare_128 (I32x4, "cmgt %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Greater_I32x4);
   function Compare_Greater_Equal_I32x4 is new NEON_Compare_128 (I32x4, "cmge %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Greater_Equal_I32x4);
   function Native_Add_Wrap_I32x4 is new NEON_Binary_128_S0 (I32x4, "add %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Add_Wrap_I32x4);
   function Add_Wrap (Left, Right : I32x4) return I32x4 is (Native_Add_Wrap_I32x4 (Left, Right));
   function Native_Subtract_Wrap_I32x4 is new NEON_Binary_128_S0 (I32x4, "sub %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Subtract_Wrap_I32x4);
   function Subtract_Wrap (Left, Right : I32x4) return I32x4 is (Native_Subtract_Wrap_I32x4 (Left, Right));
   function Native_Add_Saturate_I32x4 is new NEON_Binary_128_S0 (I32x4, "sqadd %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Add_Saturate_I32x4);
   function Add_Saturate (Left, Right : I32x4) return I32x4 is (Native_Add_Saturate_I32x4 (Left, Right));
   function Native_Subtract_Saturate_I32x4 is new NEON_Binary_128_S0 (I32x4, "sqsub %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Subtract_Saturate_I32x4);
   function Subtract_Saturate (Left, Right : I32x4) return I32x4 is (Native_Subtract_Saturate_I32x4 (Left, Right));
   function Native_Bitwise_And_I32x4 is new NEON_Binary_128_S0 (I32x4, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_I32x4);
   function Bitwise_And (Left, Right : I32x4) return I32x4 is (Native_Bitwise_And_I32x4 (Left, Right));
   function Native_Bitwise_Or_I32x4 is new NEON_Binary_128_S0 (I32x4, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_I32x4);
   function Bitwise_Or (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Or_I32x4 (Left, Right));
   function Native_Bitwise_Xor_I32x4 is new NEON_Binary_128_S0 (I32x4, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_I32x4);
   function Bitwise_Xor (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Xor_I32x4 (Left, Right));
   function Native_Min_I32x4 is new NEON_Binary_128_S0 (I32x4, "smin %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Min_I32x4);
   function Min (Left, Right : I32x4) return I32x4 is (Native_Min_I32x4 (Left, Right));
   function Native_Max_I32x4 is new NEON_Binary_128_S0 (I32x4, "smax %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Max_I32x4);
   function Max (Left, Right : I32x4) return I32x4 is (Native_Max_I32x4 (Left, Right));
   function Native_Interleave_Low_I32x4 is new NEON_Binary_128_S0 (I32x4, "zip1 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Interleave_Low_I32x4);
   function Interleave_Low (Left, Right : I32x4) return I32x4 is (Native_Interleave_Low_I32x4 (Left, Right));
   function Native_Interleave_High_I32x4 is new NEON_Binary_128_S0 (I32x4, "zip2 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Interleave_High_I32x4);
   function Interleave_High (Left, Right : I32x4) return I32x4 is (Native_Interleave_High_I32x4 (Left, Right));
   function Native_Deinterleave_Even_I32x4 is new NEON_Binary_128_S0 (I32x4, "uzp1 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Deinterleave_Even_I32x4);
   function Deinterleave_Even (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Even_I32x4 (Left, Right));
   function Native_Deinterleave_Odd_I32x4 is new NEON_Binary_128_S0 (I32x4, "uzp2 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Deinterleave_Odd_I32x4);
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Odd_I32x4 (Left, Right));
   function Native_Multiply_Wrap_I32x4 is new NEON_Binary_128_S0 (I32x4, "mul %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Multiply_Wrap_I32x4);
   function Multiply_Wrap (Left, Right : I32x4) return I32x4 is (Native_Multiply_Wrap_I32x4 (Left, Right));
   function Native_Not_I32x4 is new NEON_Unary_128_S0 (I32x4, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_I32x4);
   function Bitwise_Not (Value : I32x4) return I32x4 is (Native_Not_I32x4 (Value));
   function Native_Reverse_I32x4 is new NEON_Unary_128_S0 (I32x4, "rev64 %0.4s, %1.4s" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_I32x4);
   function Reverse_Lanes (Value : I32x4) return I32x4 is (Native_Reverse_I32x4 (Value));
   function Native_Zero_I32x4 is new NEON_Zero_128 (I32x4);
   pragma Inline_Always (Native_Zero_I32x4);
   function Zero return I32x4 is (Native_Zero_I32x4);
   function Native_Splat_I32x4 is new NEON_Splat_Integer_128 (I32x4, I32, "dup %0.4s, %w1");
   pragma Inline_Always (Native_Splat_I32x4);
   function Splat (Value : I32) return I32x4 is (Native_Splat_I32x4 (Value));
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4 is
     (Lanes => Values);
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4 is
     (Value.Lanes);
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32 is
     (Value.Lanes (Lane));
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4 is
      Result : I32x4 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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

   function Native_Shift_Left_Logical_I32x4 is new NEON_Shift_128 (I32x4, "dup %1.4s, %w3", "ushl %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_Shift_Left_Logical_I32x4);
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4 is
     (Native_Shift_Left_Logical_I32x4 (Value, Interfaces.Integer_64 (Natural'Min (Count, 32))));
   function Native_Shift_Right_Logical_I32x4 is new NEON_Shift_128 (I32x4, "dup %1.4s, %w3", "ushl %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_Shift_Right_Logical_I32x4);
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4 is
     (Native_Shift_Right_Logical_I32x4 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 32))));
   function Native_SRA_I32x4 is new NEON_Shift_128 (I32x4, "dup %1.4s, %w3", "sshl %0.4s, %2.4s, %1.4s");
   pragma Inline_Always (Native_SRA_I32x4);
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4 is
     (Native_SRA_I32x4 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 32))));
   function Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_I32x4 (Left, Right, Weights_Vector_32x4)));
   function Greater_Than (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_I32x4 (Left, Right, Weights_Vector_32x4)));
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I32x4 (Left, Right, Weights_Vector_32x4)));
   function Less_Than (Left, Right : I32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I32x4 is new NEON_Select_128 (I32x4, "dup %0.4s, %w1", "cmtst %0.4s, %0.4s, %2.4s");
   pragma Inline_Always (Native_Select_I32x4);
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4 is (Native_Select_I32x4 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_32x4, If_True, If_False));
   function Native_Reduce_Add_Wrap_I32x4 is new NEON_Integer_Reduce_128 (I32x4, I32, "addv %s1, %4.4s", "umov %w0, %1.s[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_I32x4);
   function Reduce_Add_Wrap (Value : I32x4) return I32 is (Native_Reduce_Add_Wrap_I32x4 (Value));
   function Native_Reduce_Min_I32x4 is new NEON_Integer_Reduce_128 (I32x4, I32, "sminv %s1, %4.4s", "umov %w0, %1.s[0]");
   pragma Inline_Always (Native_Reduce_Min_I32x4);
   function Reduce_Min (Value : I32x4) return I32 is (Native_Reduce_Min_I32x4 (Value));
   function Native_Reduce_Max_I32x4 is new NEON_Integer_Reduce_128 (I32x4, I32, "smaxv %s1, %4.4s", "umov %w0, %1.s[0]");
   pragma Inline_Always (Native_Reduce_Max_I32x4);
   function Reduce_Max (Value : I32x4) return I32 is (Native_Reduce_Max_I32x4 (Value));
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I32x4);
      Source : constant Lane_Values_I32x4 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_I32x4'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (I32x4, Machine_Vector);
      Target : Lane_Values_I32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_I32x4'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 is
      Result : I32x4 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_32x4 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_32x4 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Compare_U64x2 is new NEON_Compare_128 (U64x2, "cmeq %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_U64x2);
   function Compare_Greater_U64x2 is new NEON_Compare_128 (U64x2, "cmhi %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Greater_U64x2);
   function Compare_Greater_Equal_U64x2 is new NEON_Compare_128 (U64x2, "cmhs %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Greater_Equal_U64x2);
   function Native_Add_Wrap_U64x2 is new NEON_Binary_128_S0 (U64x2, "add %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Add_Wrap_U64x2);
   function Add_Wrap (Left, Right : U64x2) return U64x2 is (Native_Add_Wrap_U64x2 (Left, Right));
   function Native_Subtract_Wrap_U64x2 is new NEON_Binary_128_S0 (U64x2, "sub %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Subtract_Wrap_U64x2);
   function Subtract_Wrap (Left, Right : U64x2) return U64x2 is (Native_Subtract_Wrap_U64x2 (Left, Right));
   function Native_Add_Saturate_U64x2 is new NEON_Binary_128_S0 (U64x2, "uqadd %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Add_Saturate_U64x2);
   function Add_Saturate (Left, Right : U64x2) return U64x2 is (Native_Add_Saturate_U64x2 (Left, Right));
   function Native_Subtract_Saturate_U64x2 is new NEON_Binary_128_S0 (U64x2, "uqsub %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Subtract_Saturate_U64x2);
   function Subtract_Saturate (Left, Right : U64x2) return U64x2 is (Native_Subtract_Saturate_U64x2 (Left, Right));
   function Native_Bitwise_And_U64x2 is new NEON_Binary_128_S0 (U64x2, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_U64x2);
   function Bitwise_And (Left, Right : U64x2) return U64x2 is (Native_Bitwise_And_U64x2 (Left, Right));
   function Native_Bitwise_Or_U64x2 is new NEON_Binary_128_S0 (U64x2, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_U64x2);
   function Bitwise_Or (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Or_U64x2 (Left, Right));
   function Native_Bitwise_Xor_U64x2 is new NEON_Binary_128_S0 (U64x2, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_U64x2);
   function Bitwise_Xor (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Xor_U64x2 (Left, Right));
   function Native_Min_U64x2 is new NEON_Binary_128_S1 (U64x2, "cmhi %1.2d, %2.2d, %3.2d" & ASCII.LF & ASCII.HT & "mov %0.16b, %2.16b" & ASCII.LF & ASCII.HT & "bit %0.16b, %3.16b, %1.16b");
   pragma Inline_Always (Native_Min_U64x2);
   function Min (Left, Right : U64x2) return U64x2 is (Native_Min_U64x2 (Left, Right));
   function Native_Max_U64x2 is new NEON_Binary_128_S1 (U64x2, "cmhi %1.2d, %2.2d, %3.2d" & ASCII.LF & ASCII.HT & "mov %0.16b, %2.16b" & ASCII.LF & ASCII.HT & "bif %0.16b, %3.16b, %1.16b");
   pragma Inline_Always (Native_Max_U64x2);
   function Max (Left, Right : U64x2) return U64x2 is (Native_Max_U64x2 (Left, Right));
   function Native_Interleave_Low_U64x2 is new NEON_Binary_128_S0 (U64x2, "zip1 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Interleave_Low_U64x2);
   function Interleave_Low (Left, Right : U64x2) return U64x2 is (Native_Interleave_Low_U64x2 (Left, Right));
   function Native_Interleave_High_U64x2 is new NEON_Binary_128_S0 (U64x2, "zip2 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Interleave_High_U64x2);
   function Interleave_High (Left, Right : U64x2) return U64x2 is (Native_Interleave_High_U64x2 (Left, Right));
   function Native_Deinterleave_Even_U64x2 is new NEON_Binary_128_S0 (U64x2, "uzp1 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Deinterleave_Even_U64x2);
   function Deinterleave_Even (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Even_U64x2 (Left, Right));
   function Native_Deinterleave_Odd_U64x2 is new NEON_Binary_128_S0 (U64x2, "uzp2 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Deinterleave_Odd_U64x2);
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Odd_U64x2 (Left, Right));
   function Native_Not_U64x2 is new NEON_Unary_128_S0 (U64x2, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_U64x2);
   function Bitwise_Not (Value : U64x2) return U64x2 is (Native_Not_U64x2 (Value));
   function Native_Reverse_U64x2 is new NEON_Unary_128_S0 (U64x2, "ext %0.16b, %1.16b, %1.16b, #8");
   pragma Inline_Always (Native_Reverse_U64x2);
   function Reverse_Lanes (Value : U64x2) return U64x2 is (Native_Reverse_U64x2 (Value));
   function Native_Zero_U64x2 is new NEON_Zero_128 (U64x2);
   pragma Inline_Always (Native_Zero_U64x2);
   function Zero return U64x2 is (Native_Zero_U64x2);
   function Native_Splat_U64x2 is new NEON_Splat_Integer_128 (U64x2, U64, "dup %0.2d, %x1");
   pragma Inline_Always (Native_Splat_U64x2);
   function Splat (Value : U64) return U64x2 is (Native_Splat_U64x2 (Value));
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2 is
     (Lanes => Values);
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2 is
     (Value.Lanes);
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64 is
     (Value.Lanes (Lane));
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2 is
      Result : U64x2 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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
   function Native_Shift_Left_Logical_U64x2 is new NEON_Shift_128 (U64x2, "dup %1.2d, %3", "ushl %0.2d, %2.2d, %1.2d");
   pragma Inline_Always (Native_Shift_Left_Logical_U64x2);
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2 is
     (Native_Shift_Left_Logical_U64x2 (Value, Interfaces.Integer_64 (Natural'Min (Count, 64))));
   function Native_Shift_Right_Logical_U64x2 is new NEON_Shift_128 (U64x2, "dup %1.2d, %3", "ushl %0.2d, %2.2d, %1.2d");
   pragma Inline_Always (Native_Shift_Right_Logical_U64x2);
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2 is
     (Native_Shift_Right_Logical_U64x2 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 64))));
   function Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_U64x2 (Left, Right, Weights_Vector_64x2)));
   function Greater_Than (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_U64x2 (Left, Right, Weights_Vector_64x2)));
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Equal_U64x2 (Left, Right, Weights_Vector_64x2)));
   function Less_Than (Left, Right : U64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_U64x2 is new NEON_Select_128 (U64x2, "dup %0.2d, %1", "cmtst %0.2d, %0.2d, %2.2d");
   pragma Inline_Always (Native_Select_U64x2);
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2 is (Native_Select_U64x2 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_64x2, If_True, If_False));
   function Native_Reduce_Add_Wrap_U64x2 is new NEON_Integer_Reduce_128 (U64x2, U64, "addp %d1, %4.2d", "umov %x0, %1.d[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_U64x2);
   function Reduce_Add_Wrap (Value : U64x2) return U64 is (Native_Reduce_Add_Wrap_U64x2 (Value));
   function Native_Reduce_Min_U64x2 is new NEON_Integer_Reduce_128 (U64x2, U64, "dup %2.2d, %4.d[1]" & ASCII.LF & ASCII.HT & "cmhi %3.2d, %4.2d, %2.2d" & ASCII.LF & ASCII.HT & "mov %1.16b, %4.16b" & ASCII.LF & ASCII.HT & "bit %1.16b, %2.16b, %3.16b", "umov %x0, %1.d[0]");
   pragma Inline_Always (Native_Reduce_Min_U64x2);
   function Reduce_Min (Value : U64x2) return U64 is (Native_Reduce_Min_U64x2 (Value));
   function Native_Reduce_Max_U64x2 is new NEON_Integer_Reduce_128 (U64x2, U64, "dup %2.2d, %4.d[1]" & ASCII.LF & ASCII.HT & "cmhi %3.2d, %4.2d, %2.2d" & ASCII.LF & ASCII.HT & "mov %1.16b, %4.16b" & ASCII.LF & ASCII.HT & "bif %1.16b, %2.16b, %3.16b", "umov %x0, %1.d[0]");
   pragma Inline_Always (Native_Reduce_Max_U64x2);
   function Reduce_Max (Value : U64x2) return U64 is (Native_Reduce_Max_U64x2 (Value));
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U64x2);
      Source : constant Lane_Values_U64x2 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_U64x2'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (U64x2, Machine_Vector);
      Target : Lane_Values_U64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_U64x2'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 is
      Result : U64x2 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_64x2 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_64x2 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Compare_I64x2 is new NEON_Compare_128 (I64x2, "cmeq %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_I64x2);
   function Compare_Greater_I64x2 is new NEON_Compare_128 (I64x2, "cmgt %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Greater_I64x2);
   function Compare_Greater_Equal_I64x2 is new NEON_Compare_128 (I64x2, "cmge %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Greater_Equal_I64x2);
   function Native_Add_Wrap_I64x2 is new NEON_Binary_128_S0 (I64x2, "add %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Add_Wrap_I64x2);
   function Add_Wrap (Left, Right : I64x2) return I64x2 is (Native_Add_Wrap_I64x2 (Left, Right));
   function Native_Subtract_Wrap_I64x2 is new NEON_Binary_128_S0 (I64x2, "sub %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Subtract_Wrap_I64x2);
   function Subtract_Wrap (Left, Right : I64x2) return I64x2 is (Native_Subtract_Wrap_I64x2 (Left, Right));
   function Native_Add_Saturate_I64x2 is new NEON_Binary_128_S0 (I64x2, "sqadd %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Add_Saturate_I64x2);
   function Add_Saturate (Left, Right : I64x2) return I64x2 is (Native_Add_Saturate_I64x2 (Left, Right));
   function Native_Subtract_Saturate_I64x2 is new NEON_Binary_128_S0 (I64x2, "sqsub %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Subtract_Saturate_I64x2);
   function Subtract_Saturate (Left, Right : I64x2) return I64x2 is (Native_Subtract_Saturate_I64x2 (Left, Right));
   function Native_Bitwise_And_I64x2 is new NEON_Binary_128_S0 (I64x2, "and %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_And_I64x2);
   function Bitwise_And (Left, Right : I64x2) return I64x2 is (Native_Bitwise_And_I64x2 (Left, Right));
   function Native_Bitwise_Or_I64x2 is new NEON_Binary_128_S0 (I64x2, "orr %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Or_I64x2);
   function Bitwise_Or (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Or_I64x2 (Left, Right));
   function Native_Bitwise_Xor_I64x2 is new NEON_Binary_128_S0 (I64x2, "eor %0.16b, %1.16b, %2.16b");
   pragma Inline_Always (Native_Bitwise_Xor_I64x2);
   function Bitwise_Xor (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Xor_I64x2 (Left, Right));
   function Native_Min_I64x2 is new NEON_Binary_128_S1 (I64x2, "cmgt %1.2d, %2.2d, %3.2d" & ASCII.LF & ASCII.HT & "mov %0.16b, %2.16b" & ASCII.LF & ASCII.HT & "bit %0.16b, %3.16b, %1.16b");
   pragma Inline_Always (Native_Min_I64x2);
   function Min (Left, Right : I64x2) return I64x2 is (Native_Min_I64x2 (Left, Right));
   function Native_Max_I64x2 is new NEON_Binary_128_S1 (I64x2, "cmgt %1.2d, %2.2d, %3.2d" & ASCII.LF & ASCII.HT & "mov %0.16b, %2.16b" & ASCII.LF & ASCII.HT & "bif %0.16b, %3.16b, %1.16b");
   pragma Inline_Always (Native_Max_I64x2);
   function Max (Left, Right : I64x2) return I64x2 is (Native_Max_I64x2 (Left, Right));
   function Native_Interleave_Low_I64x2 is new NEON_Binary_128_S0 (I64x2, "zip1 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Interleave_Low_I64x2);
   function Interleave_Low (Left, Right : I64x2) return I64x2 is (Native_Interleave_Low_I64x2 (Left, Right));
   function Native_Interleave_High_I64x2 is new NEON_Binary_128_S0 (I64x2, "zip2 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Interleave_High_I64x2);
   function Interleave_High (Left, Right : I64x2) return I64x2 is (Native_Interleave_High_I64x2 (Left, Right));
   function Native_Deinterleave_Even_I64x2 is new NEON_Binary_128_S0 (I64x2, "uzp1 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Deinterleave_Even_I64x2);
   function Deinterleave_Even (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Even_I64x2 (Left, Right));
   function Native_Deinterleave_Odd_I64x2 is new NEON_Binary_128_S0 (I64x2, "uzp2 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Deinterleave_Odd_I64x2);
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Odd_I64x2 (Left, Right));
   function Native_Not_I64x2 is new NEON_Unary_128_S0 (I64x2, "mvn %0.16b, %1.16b");
   pragma Inline_Always (Native_Not_I64x2);
   function Bitwise_Not (Value : I64x2) return I64x2 is (Native_Not_I64x2 (Value));
   function Native_Reverse_I64x2 is new NEON_Unary_128_S0 (I64x2, "ext %0.16b, %1.16b, %1.16b, #8");
   pragma Inline_Always (Native_Reverse_I64x2);
   function Reverse_Lanes (Value : I64x2) return I64x2 is (Native_Reverse_I64x2 (Value));
   function Native_Zero_I64x2 is new NEON_Zero_128 (I64x2);
   pragma Inline_Always (Native_Zero_I64x2);
   function Zero return I64x2 is (Native_Zero_I64x2);
   function Native_Splat_I64x2 is new NEON_Splat_Integer_128 (I64x2, I64, "dup %0.2d, %x1");
   pragma Inline_Always (Native_Splat_I64x2);
   function Splat (Value : I64) return I64x2 is (Native_Splat_I64x2 (Value));
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2 is
     (Lanes => Values);
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2 is
     (Value.Lanes);
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64 is
     (Value.Lanes (Lane));
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2 is
      Result : I64x2 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
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
   function Native_Shift_Left_Logical_I64x2 is new NEON_Shift_128 (I64x2, "dup %1.2d, %3", "ushl %0.2d, %2.2d, %1.2d");
   pragma Inline_Always (Native_Shift_Left_Logical_I64x2);
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2 is
     (Native_Shift_Left_Logical_I64x2 (Value, Interfaces.Integer_64 (Natural'Min (Count, 64))));
   function Native_Shift_Right_Logical_I64x2 is new NEON_Shift_128 (I64x2, "dup %1.2d, %3", "ushl %0.2d, %2.2d, %1.2d");
   pragma Inline_Always (Native_Shift_Right_Logical_I64x2);
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2 is
     (Native_Shift_Right_Logical_I64x2 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 64))));
   function Native_SRA_I64x2 is new NEON_Shift_128 (I64x2, "dup %1.2d, %3", "sshl %0.2d, %2.2d, %1.2d");
   pragma Inline_Always (Native_SRA_I64x2);
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2 is
     (Native_SRA_I64x2 (Value, -Interfaces.Integer_64 (Natural'Min (Count, 64))));
   function Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_I64x2 (Left, Right, Weights_Vector_64x2)));
   function Greater_Than (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_I64x2 (Left, Right, Weights_Vector_64x2)));
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Equal_I64x2 (Left, Right, Weights_Vector_64x2)));
   function Less_Than (Left, Right : I64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Select_I64x2 is new NEON_Select_128 (I64x2, "dup %0.2d, %1", "cmtst %0.2d, %0.2d, %2.2d");
   pragma Inline_Always (Native_Select_I64x2);
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2 is (Native_Select_I64x2 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_64x2, If_True, If_False));
   function Native_Reduce_Add_Wrap_I64x2 is new NEON_Integer_Reduce_128 (I64x2, I64, "addp %d1, %4.2d", "umov %x0, %1.d[0]");
   pragma Inline_Always (Native_Reduce_Add_Wrap_I64x2);
   function Reduce_Add_Wrap (Value : I64x2) return I64 is (Native_Reduce_Add_Wrap_I64x2 (Value));
   function Native_Reduce_Min_I64x2 is new NEON_Integer_Reduce_128 (I64x2, I64, "dup %2.2d, %4.d[1]" & ASCII.LF & ASCII.HT & "cmgt %3.2d, %4.2d, %2.2d" & ASCII.LF & ASCII.HT & "mov %1.16b, %4.16b" & ASCII.LF & ASCII.HT & "bit %1.16b, %2.16b, %3.16b", "umov %x0, %1.d[0]");
   pragma Inline_Always (Native_Reduce_Min_I64x2);
   function Reduce_Min (Value : I64x2) return I64 is (Native_Reduce_Min_I64x2 (Value));
   function Native_Reduce_Max_I64x2 is new NEON_Integer_Reduce_128 (I64x2, I64, "dup %2.2d, %4.d[1]" & ASCII.LF & ASCII.HT & "cmgt %3.2d, %4.2d, %2.2d" & ASCII.LF & ASCII.HT & "mov %1.16b, %4.16b" & ASCII.LF & ASCII.HT & "bif %1.16b, %2.16b, %3.16b", "umov %x0, %1.d[0]");
   pragma Inline_Always (Native_Reduce_Max_I64x2);
   function Reduce_Max (Value : I64x2) return I64 is (Native_Reduce_Max_I64x2 (Value));
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I64x2);
      Source : constant Lane_Values_I64x2 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_I64x2'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (I64x2, Machine_Vector);
      Target : Lane_Values_I64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_I64x2'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 is
      Result : I64x2 := (Lanes => [others => 0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_64x2 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_64x2 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Native_Add_F32x4 is new NEON_Binary_128_S0 (F32x4, "fadd %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Add_F32x4);
   function Add (Left, Right : F32x4) return F32x4 is (Native_Add_F32x4 (Left, Right));
   function Native_Subtract_F32x4 is new NEON_Binary_128_S0 (F32x4, "fsub %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Subtract_F32x4);
   function Subtract (Left, Right : F32x4) return F32x4 is (Native_Subtract_F32x4 (Left, Right));
   function Native_Multiply_F32x4 is new NEON_Binary_128_S0 (F32x4, "fmul %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Multiply_F32x4);
   function Multiply (Left, Right : F32x4) return F32x4 is (Native_Multiply_F32x4 (Left, Right));
   function Native_Divide_F32x4 is new NEON_Binary_128_S0 (F32x4, "fdiv %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Divide_F32x4);
   function Divide (Left, Right : F32x4) return F32x4 is (Native_Divide_F32x4 (Left, Right));
   function Native_Min_Number_F32x4 is new NEON_Binary_128_S0 (F32x4, "fminnm %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Min_Number_F32x4);
   function Min_Number (Left, Right : F32x4) return F32x4 is (Native_Min_Number_F32x4 (Left, Right));
   function Native_Max_Number_F32x4 is new NEON_Binary_128_S0 (F32x4, "fmaxnm %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Max_Number_F32x4);
   function Max_Number (Left, Right : F32x4) return F32x4 is (Native_Max_Number_F32x4 (Left, Right));
   function Native_Interleave_Low_F32x4 is new NEON_Binary_128_S0 (F32x4, "zip1 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Interleave_Low_F32x4);
   function Interleave_Low (Left, Right : F32x4) return F32x4 is (Native_Interleave_Low_F32x4 (Left, Right));
   function Native_Interleave_High_F32x4 is new NEON_Binary_128_S0 (F32x4, "zip2 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Interleave_High_F32x4);
   function Interleave_High (Left, Right : F32x4) return F32x4 is (Native_Interleave_High_F32x4 (Left, Right));
   function Native_Deinterleave_Even_F32x4 is new NEON_Binary_128_S0 (F32x4, "uzp1 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Deinterleave_Even_F32x4);
   function Deinterleave_Even (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Even_F32x4 (Left, Right));
   function Native_Deinterleave_Odd_F32x4 is new NEON_Binary_128_S0 (F32x4, "uzp2 %0.4s, %1.4s, %2.4s");
   pragma Inline_Always (Native_Deinterleave_Odd_F32x4);
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Odd_F32x4 (Left, Right));
   function Native_Reverse_F32x4 is new NEON_Unary_128_S0 (F32x4, "rev64 %0.4s, %1.4s" & ASCII.LF & ASCII.HT & "ext %0.16b, %0.16b, %0.16b, #8");
   pragma Inline_Always (Native_Reverse_F32x4);
   function Reverse_Lanes (Value : F32x4) return F32x4 is (Native_Reverse_F32x4 (Value));
   function Compare_Equal_F32x4 is new NEON_Compare_128 (F32x4, "fcmeq %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Equal_F32x4);
   function Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Equal_F32x4 (Left, Right, Weights_Vector_32x4)));
   function Compare_Greater_Than_F32x4 is new NEON_Compare_128 (F32x4, "fcmgt %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Greater_Than_F32x4);
   function Greater_Than (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Than_F32x4 (Left, Right, Weights_Vector_32x4)));
   function Compare_Greater_Equal_F32x4 is new NEON_Compare_128 (F32x4, "fcmge %2.4s, %4.4s, %5.4s", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Greater_Equal_F32x4);
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Greater_Equal_F32x4 (Left, Right, Weights_Vector_32x4)));
   function Compare_Unordered_F32x4 is new NEON_Compare_128 (F32x4, "fcmeq %2.4s, %4.4s, %4.4s" & ASCII.LF & ASCII.HT & "fcmeq %3.4s, %5.4s, %5.4s" & ASCII.LF & ASCII.HT & "and %2.16b, %2.16b, %3.16b" & ASCII.LF & ASCII.HT & "mvn %2.16b, %2.16b", "ushr %2.4s, %2.4s, #31" & ASCII.LF & ASCII.HT & "mul %2.4s, %2.4s, %6.4s" & ASCII.LF & ASCII.HT & "addv %s2, %2.4s" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]");
   pragma Inline_Always (Compare_Unordered_F32x4);
   function Unordered (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Compare_Unordered_F32x4 (Left, Right, Weights_Vector_32x4)));
   function Less_Than (Left, Right : F32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : F32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Zero_F32x4 is new NEON_Zero_128 (F32x4);
   pragma Inline_Always (Native_Zero_F32x4);
   function Zero return F32x4 is (Native_Zero_F32x4);
   function Native_Splat_F32x4 is new NEON_Splat_Float_128 (F32x4, F32, "dup %0.4s, %1.s[0]");
   pragma Inline_Always (Native_Splat_F32x4);
   function Splat (Value : F32) return F32x4 is (Native_Splat_F32x4 (Value));
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4 is
     (Lanes => Values);
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4 is
     (Value.Lanes);
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32 is
     (Value.Lanes (Lane));
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4 is
      Result : F32x4 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
   function Native_Permute_F32x4 is new NEON_Permute_128 (F32x4, Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_F32x4);
   function Permute_Lanes (Value : F32x4; Map : Lane_Map_32x4) return F32x4 is (Native_Permute_F32x4 (Value, Map));
   function Native_Permute_2_F32x4 is new NEON_Permute_2_128 (F32x4, Two_Source_Lane_Map_32x4);
   pragma Inline_Always (Native_Permute_2_F32x4);
   function Permute_Lanes (Left, Right : F32x4; Map : Two_Source_Lane_Map_32x4) return F32x4 is (Native_Permute_2_F32x4 (Left, Right, Map));
   function Native_Select_F32x4 is new NEON_Select_128 (F32x4, "dup %0.4s, %w1", "cmtst %0.4s, %0.4s, %2.4s");
   pragma Inline_Always (Native_Select_F32x4);
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4 is (Native_Select_F32x4 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_32x4, If_True, If_False));
   function Native_Reduce_Add_F32x4 is new NEON_Float_Reduce_128 (F32x4, F32, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[0]" & ASCII.LF & ASCII.HT & "fadd %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[1]" & ASCII.LF & ASCII.HT & "fadd %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[2]" & ASCII.LF & ASCII.HT & "fadd %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[3]" & ASCII.LF & ASCII.HT & "fadd %s1, %s1, %s2", "fmov %s0, %s1");
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

   function Native_Reduce_Min_Number_F32x4 is new NEON_Float_Reduce_128 (F32x4, F32, "mov %1.16b, %3.16b" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[1]" & ASCII.LF & ASCII.HT & "fminnm %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[2]" & ASCII.LF & ASCII.HT & "fminnm %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[3]" & ASCII.LF & ASCII.HT & "fminnm %s1, %s1, %s2", "fmov %s0, %s1");
   pragma Inline_Always (Native_Reduce_Min_Number_F32x4);
   function Reduce_Min_Number (Value : F32x4) return F32 is (Native_Reduce_Min_Number_F32x4 (Value));
   function Native_Reduce_Max_Number_F32x4 is new NEON_Float_Reduce_128 (F32x4, F32, "mov %1.16b, %3.16b" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[1]" & ASCII.LF & ASCII.HT & "fmaxnm %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[2]" & ASCII.LF & ASCII.HT & "fmaxnm %s1, %s1, %s2" & ASCII.LF & ASCII.HT & "dup %2.4s, %3.s[3]" & ASCII.LF & ASCII.HT & "fmaxnm %s1, %s1, %s2", "fmov %s0, %s1");
   pragma Inline_Always (Native_Reduce_Max_Number_F32x4);
   function Reduce_Max_Number (Value : F32x4) return F32 is (Native_Reduce_Max_Number_F32x4 (Value));
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, F32x4);
      Source : constant Lane_Values_F32x4 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_F32x4'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (F32x4, Machine_Vector);
      Target : Lane_Values_F32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_F32x4'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 is
      Result : F32x4 := (Lanes => [others => 0.0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_32x4 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_32x4 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Native_Add_F64x2 is new NEON_Binary_128_S0 (F64x2, "fadd %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Add_F64x2);
   function Add (Left, Right : F64x2) return F64x2 is (Native_Add_F64x2 (Left, Right));
   function Native_Subtract_F64x2 is new NEON_Binary_128_S0 (F64x2, "fsub %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Subtract_F64x2);
   function Subtract (Left, Right : F64x2) return F64x2 is (Native_Subtract_F64x2 (Left, Right));
   function Native_Multiply_F64x2 is new NEON_Binary_128_S0 (F64x2, "fmul %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Multiply_F64x2);
   function Multiply (Left, Right : F64x2) return F64x2 is (Native_Multiply_F64x2 (Left, Right));
   function Native_Divide_F64x2 is new NEON_Binary_128_S0 (F64x2, "fdiv %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Divide_F64x2);
   function Divide (Left, Right : F64x2) return F64x2 is (Native_Divide_F64x2 (Left, Right));
   function Native_Min_Number_F64x2 is new NEON_Binary_128_S0 (F64x2, "fminnm %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Min_Number_F64x2);
   function Min_Number (Left, Right : F64x2) return F64x2 is (Native_Min_Number_F64x2 (Left, Right));
   function Native_Max_Number_F64x2 is new NEON_Binary_128_S0 (F64x2, "fmaxnm %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Max_Number_F64x2);
   function Max_Number (Left, Right : F64x2) return F64x2 is (Native_Max_Number_F64x2 (Left, Right));
   function Native_Interleave_Low_F64x2 is new NEON_Binary_128_S0 (F64x2, "zip1 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Interleave_Low_F64x2);
   function Interleave_Low (Left, Right : F64x2) return F64x2 is (Native_Interleave_Low_F64x2 (Left, Right));
   function Native_Interleave_High_F64x2 is new NEON_Binary_128_S0 (F64x2, "zip2 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Interleave_High_F64x2);
   function Interleave_High (Left, Right : F64x2) return F64x2 is (Native_Interleave_High_F64x2 (Left, Right));
   function Native_Deinterleave_Even_F64x2 is new NEON_Binary_128_S0 (F64x2, "uzp1 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Deinterleave_Even_F64x2);
   function Deinterleave_Even (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Even_F64x2 (Left, Right));
   function Native_Deinterleave_Odd_F64x2 is new NEON_Binary_128_S0 (F64x2, "uzp2 %0.2d, %1.2d, %2.2d");
   pragma Inline_Always (Native_Deinterleave_Odd_F64x2);
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Odd_F64x2 (Left, Right));
   function Native_Reverse_F64x2 is new NEON_Unary_128_S0 (F64x2, "ext %0.16b, %1.16b, %1.16b, #8");
   pragma Inline_Always (Native_Reverse_F64x2);
   function Reverse_Lanes (Value : F64x2) return F64x2 is (Native_Reverse_F64x2 (Value));
   function Compare_Equal_F64x2 is new NEON_Compare_128 (F64x2, "fcmeq %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Equal_F64x2);
   function Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Equal_F64x2 (Left, Right, Weights_Vector_64x2)));
   function Compare_Greater_Than_F64x2 is new NEON_Compare_128 (F64x2, "fcmgt %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Greater_Than_F64x2);
   function Greater_Than (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Than_F64x2 (Left, Right, Weights_Vector_64x2)));
   function Compare_Greater_Equal_F64x2 is new NEON_Compare_128 (F64x2, "fcmge %2.2d, %4.2d, %5.2d", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Greater_Equal_F64x2);
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Greater_Equal_F64x2 (Left, Right, Weights_Vector_64x2)));
   function Compare_Unordered_F64x2 is new NEON_Compare_128 (F64x2, "fcmeq %2.2d, %4.2d, %4.2d" & ASCII.LF & ASCII.HT & "fcmeq %3.2d, %5.2d, %5.2d" & ASCII.LF & ASCII.HT & "and %2.16b, %2.16b, %3.16b" & ASCII.LF & ASCII.HT & "mvn %2.16b, %2.16b", "ushr %2.2d, %2.2d, #63" & ASCII.LF & ASCII.HT & "umov %w0, %2.s[0]" & ASCII.LF & ASCII.HT & "umov %w1, %2.s[2]" & ASCII.LF & ASCII.HT & "orr %w0, %w0, %w1, lsl #1");
   pragma Inline_Always (Compare_Unordered_F64x2);
   function Unordered (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Compare_Unordered_F64x2 (Left, Right, Weights_Vector_64x2)));
   function Less_Than (Left, Right : F64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : F64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Native_Zero_F64x2 is new NEON_Zero_128 (F64x2);
   pragma Inline_Always (Native_Zero_F64x2);
   function Zero return F64x2 is (Native_Zero_F64x2);
   function Native_Splat_F64x2 is new NEON_Splat_Float_128 (F64x2, F64, "dup %0.2d, %1.d[0]");
   pragma Inline_Always (Native_Splat_F64x2);
   function Splat (Value : F64) return F64x2 is (Native_Splat_F64x2 (Value));
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2 is
     (Lanes => Values);
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2 is
     (Value.Lanes);
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64 is
     (Value.Lanes (Lane));
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2 is
      Result : F64x2 := Value;
   begin
      Result.Lanes (Lane) := With_Value;
      return Result;
   end Replace;
   function Native_Permute_F64x2 is new NEON_Permute_128 (F64x2, Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_F64x2);
   function Permute_Lanes (Value : F64x2; Map : Lane_Map_64x2) return F64x2 is (Native_Permute_F64x2 (Value, Map));
   function Native_Permute_2_F64x2 is new NEON_Permute_2_128 (F64x2, Two_Source_Lane_Map_64x2);
   pragma Inline_Always (Native_Permute_2_F64x2);
   function Permute_Lanes (Left, Right : F64x2; Map : Two_Source_Lane_Map_64x2) return F64x2 is (Native_Permute_2_F64x2 (Left, Right, Map));
   function Native_Select_F64x2 is new NEON_Select_128 (F64x2, "dup %0.2d, %1", "cmtst %0.2d, %0.2d, %2.2d");
   pragma Inline_Always (Native_Select_F64x2);
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2 is (Native_Select_F64x2 (Interfaces.Unsigned_64 (Mask.Bits), Weights_Vector_64x2, If_True, If_False));
   function Native_Reduce_Add_F64x2 is new NEON_Float_Reduce_128 (F64x2, F64, "movi %1.16b, #0" & ASCII.LF & ASCII.HT & "dup %2.2d, %3.d[0]" & ASCII.LF & ASCII.HT & "fadd %d1, %d1, %d2" & ASCII.LF & ASCII.HT & "dup %2.2d, %3.d[1]" & ASCII.LF & ASCII.HT & "fadd %d1, %d1, %d2", "fmov %d0, %d1");
   pragma Inline_Always (Native_Reduce_Add_F64x2);
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

   function Native_Reduce_Min_Number_F64x2 is new NEON_Float_Reduce_128 (F64x2, F64, "mov %1.16b, %3.16b" & ASCII.LF & ASCII.HT & "dup %2.2d, %3.d[1]" & ASCII.LF & ASCII.HT & "fminnm %d1, %d1, %d2", "fmov %d0, %d1");
   pragma Inline_Always (Native_Reduce_Min_Number_F64x2);
   function Reduce_Min_Number (Value : F64x2) return F64 is (Native_Reduce_Min_Number_F64x2 (Value));
   function Native_Reduce_Max_Number_F64x2 is new NEON_Float_Reduce_128 (F64x2, F64, "mov %1.16b, %3.16b" & ASCII.LF & ASCII.HT & "dup %2.2d, %3.d[1]" & ASCII.LF & ASCII.HT & "fmaxnm %d1, %d1, %d2", "fmov %d0, %d1");
   pragma Inline_Always (Native_Reduce_Max_Number_F64x2);
   function Reduce_Max_Number (Value : F64x2) return F64 is (Native_Reduce_Max_Number_F64x2 (Value));
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean is
     (Start in Data'Range and then
      System.Storage_Elements.To_Integer (Data (Start)'Address) mod
        System.Storage_Elements.Integer_Address (16) = 0);
   function Load (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store;
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, F64x2);
      Source : constant Lane_Values_F64x2 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "ldr %q0, %1",
           Outputs => Machine_Vector'Asm_Output ("=w", Result),
           Inputs => Lane_Values_F64x2'Asm_Input ("Q", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (F64x2, Machine_Vector);
      Target : Lane_Values_F64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "str %q1, %0",
           Outputs => Lane_Values_F64x2'Asm_Output ("=Q", Target),
           Inputs => Machine_Vector'Asm_Input ("w", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 is (Load_Unaligned (Data, Start));
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 is
      Result : F64x2 := (Lanes => [others => 0.0]);
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Result.Lanes (Lane_Index_64x2 (Lane)) := Data (Start + Lane);
         end loop;
      end if;
      return Result;
   end Load_Partial;
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) is
   begin
      if Count > 0 then
         for Lane in Natural range 0 .. Count - 1 loop
            Data (Start + Lane) := Value.Lanes (Lane_Index_64x2 (Lane));
         end loop;
      end if;
   end Store_Partial;
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16) return Mask_8x16 is
     (Bits => Bits and 65535);
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Mask.Bits and 65535);
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => (Left.Bits and Right.Bits) and 65535);
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => (Left.Bits or Right.Bits) and 65535);
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16 is
     (Bits => (Left.Bits xor Right.Bits) and 65535);
   function Mask_Not (Value : Mask_8x16) return Mask_8x16 is
     (Bits => (not Value.Bits) and 65535);
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean is
     ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_8x16) return Boolean is
     (Mask.Bits /= 0);
   function All_True (Mask : Mask_8x16) return Boolean is
     ((Mask.Bits and 65535) = 65535);
   function None_True (Mask : Mask_8x16) return Boolean is
     (Mask.Bits = 0);
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16 is (Count_Set_Bits (Interfaces.Unsigned_32 (Mask.Bits)));
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 16));
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 16));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8 is
     (Bits => Bits and 255);
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8 is
     (Mask.Bits and 255);
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8 is
     (Bits => (Left.Bits and Right.Bits) and 255);
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8 is
     (Bits => (Left.Bits or Right.Bits) and 255);
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8 is
     (Bits => (Left.Bits xor Right.Bits) and 255);
   function Mask_Not (Value : Mask_16x8) return Mask_16x8 is
     (Bits => (not Value.Bits) and 255);
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean is
     ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_16x8) return Boolean is
     (Mask.Bits /= 0);
   function All_True (Mask : Mask_16x8) return Boolean is
     ((Mask.Bits and 255) = 255);
   function None_True (Mask : Mask_16x8) return Boolean is
     (Mask.Bits = 0);
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8 is (Count_Set_Bits (Interfaces.Unsigned_32 (Mask.Bits)));
   function First_True (Mask : Mask_16x8) return Lane_Count_16x8 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 8));
   function Last_True (Mask : Mask_16x8) return Lane_Count_16x8 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 8));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4 is
     (Bits => Bits and 15);
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8 is
     (Mask.Bits and 15);
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4 is
     (Bits => (Left.Bits and Right.Bits) and 15);
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4 is
     (Bits => (Left.Bits or Right.Bits) and 15);
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4 is
     (Bits => (Left.Bits xor Right.Bits) and 15);
   function Mask_Not (Value : Mask_32x4) return Mask_32x4 is
     (Bits => (not Value.Bits) and 15);
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean is
     ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_32x4) return Boolean is
     (Mask.Bits /= 0);
   function All_True (Mask : Mask_32x4) return Boolean is
     ((Mask.Bits and 15) = 15);
   function None_True (Mask : Mask_32x4) return Boolean is
     (Mask.Bits = 0);
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4 is (Count_Set_Bits (Interfaces.Unsigned_32 (Mask.Bits)));
   function First_True (Mask : Mask_32x4) return Lane_Count_32x4 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 4));
   function Last_True (Mask : Mask_32x4) return Lane_Count_32x4 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 4));
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2 is
     (Bits => Bits and 3);
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8 is
     (Mask.Bits and 3);
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2 is
     (Bits => (Left.Bits and Right.Bits) and 3);
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2 is
     (Bits => (Left.Bits or Right.Bits) and 3);
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2 is
     (Bits => (Left.Bits xor Right.Bits) and 3);
   function Mask_Not (Value : Mask_64x2) return Mask_64x2 is
     (Bits => (not Value.Bits) and 3);
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean is
     ((Mask.Bits and Interfaces.Shift_Left (Interfaces.Unsigned_8'(1), Lane)) /= 0);
   function Any_True (Mask : Mask_64x2) return Boolean is
     (Mask.Bits /= 0);
   function All_True (Mask : Mask_64x2) return Boolean is
     ((Mask.Bits and 3) = 3);
   function None_True (Mask : Mask_64x2) return Boolean is
     (Mask.Bits = 0);
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2 is (Count_Set_Bits (Interfaces.Unsigned_32 (Mask.Bits)));
   function First_True (Mask : Mask_64x2) return Lane_Count_64x2 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 2));
   function Last_True (Mask : Mask_64x2) return Lane_Count_64x2 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), 2));
   --  END GENERATED FULL-FAMILY NEON BODIES
end Flyology_SIMD.Backends.Native;
