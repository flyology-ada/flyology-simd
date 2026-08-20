with Ada.Unchecked_Conversion;
with System.Machine_Code;
with System.Storage_Elements;

package body Flyology_SIMD.Backends.Native is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
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
        (Template => "bsfl %1, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Clobber => "cc",
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
        (Template => "bsrl %1, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Clobber => "cc",
         Volatile => True);
      return Natural (Result);
   end Find_Last_Set_Bit;

   function Count_Set_Bits
     (Bits : Interfaces.Unsigned_32) return Natural
   is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template => "movl %1, %0" & ASCII.LF & ASCII.HT &
                     "movl %0, %%ecx" & ASCII.LF & ASCII.HT &
                     "shrl $1, %%ecx" & ASCII.LF & ASCII.HT &
                     "andl $0x55555555, %%ecx" & ASCII.LF & ASCII.HT &
                     "subl %%ecx, %0" & ASCII.LF & ASCII.HT &
                     "movl %0, %%ecx" & ASCII.LF & ASCII.HT &
                     "andl $0x33333333, %0" & ASCII.LF & ASCII.HT &
                     "shrl $2, %%ecx" & ASCII.LF & ASCII.HT &
                     "andl $0x33333333, %%ecx" & ASCII.LF & ASCII.HT &
                     "addl %%ecx, %0" & ASCII.LF & ASCII.HT &
                     "movl %0, %%ecx" & ASCII.LF & ASCII.HT &
                     "shrl $4, %%ecx" & ASCII.LF & ASCII.HT &
                     "addl %%ecx, %0" & ASCII.LF & ASCII.HT &
                     "andl $0x0f0f0f0f, %0" & ASCII.LF & ASCII.HT &
                     "imull $0x01010101, %0, %0" & ASCII.LF & ASCII.HT &
                     "shrl $24, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=&r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Clobber => "ecx,cc",
         Volatile => True);
      return Natural (Result);
   end Count_Set_Bits;
   pragma Inline_Always (Count_Set_Bits);


   --  BEGIN GENERATED FULL-FAMILY X86 BODIES
   --  Assembly leaves below take and return this machine vector type so
   --  that 128-bit values stay in SSE registers across a chain of
   --  operations instead of spilling to memory between them.
   type Machine_Vector is array (0 .. 15) of Interfaces.Unsigned_8;
   for Machine_Vector'Alignment use 16;
   pragma Machine_Attribute (Machine_Vector, "vector_type");

   Sign_Vector_8 : constant Machine_Vector := [others => 16#80#];
   Sign_Vector_16 : constant Machine_Vector := [0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#];
   Sign_Vector_32 : constant Machine_Vector := [0, 0, 0, 16#80#, 0, 0, 0, 16#80#, 0, 0, 0, 16#80#, 0, 0, 0, 16#80#];
   Weights_X86_Vector_8 : constant Machine_Vector := [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];
   Weights_X86_Vector_16 : constant Machine_Vector := [1, 0, 2, 0, 4, 0, 8, 0, 16, 0, 32, 0, 64, 0, 128, 0];
   Weights_X86_Vector_32 : constant Machine_Vector := [1, 0, 0, 0, 2, 0, 0, 0, 4, 0, 0, 0, 8, 0, 0, 0];
   Weights_X86_Vector_64 : constant Machine_Vector := [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0];

   generic
      type Vector_Type is private;
      type Map_Type is private;
      Instruction : String;
   function SSE2_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type;
   function SSE2_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Value'Address), System.Address'Asm_Input ("r", Map'Address)], Clobber => "xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory", Volatile => True);
      return Result;
   end SSE2_Permute_128;

   generic
      type Vector_Type is private;
      type Map_Type is private;
      Instruction : String;
   function SSE2_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type;
   function SSE2_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm (Template => "movdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT & "movdqu (%2), %%xmm1" & ASCII.LF & ASCII.HT & "movdqu (%3), %%xmm2" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)", Inputs => [System.Address'Asm_Input ("r", Result'Address), System.Address'Asm_Input ("r", Left'Address), System.Address'Asm_Input ("r", Right'Address), System.Address'Asm_Input ("r", Map'Address)], Clobber => "xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory", Volatile => True);
      return Result;
   end SSE2_Permute_2_128;

   generic
      type Vector_Type is private;
   function SSE2_Zero_128 return Vector_Type;
   function SSE2_Zero_128 return Vector_Type is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      pragma Warnings (Off, "code statement with no inputs*");
      Asm (Template => "pxor %0, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result));
      pragma Warnings (On, "code statement with no inputs*");
      return To_Vector (Result);
   end SSE2_Zero_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Duplicate_Instruction : String;
   function SSE2_Splat_Integer_128 (Value : Scalar_Type) return Vector_Type;
   function SSE2_Splat_Integer_128 (Value : Scalar_Type) return Vector_Type is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch : Interfaces.Unsigned_64;
   begin
      Asm (Template => Duplicate_Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=&x", Result), Interfaces.Unsigned_64'Asm_Output ("=&r", Scratch)],
           Inputs => Scalar_Type'Asm_Input ("r", Value));
      return To_Vector (Result);
   end SSE2_Splat_Integer_128;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Duplicate_Instruction : String;
   function SSE2_Splat_Float_128 (Value : Scalar_Type) return Vector_Type;
   function SSE2_Splat_Float_128 (Value : Scalar_Type) return Vector_Type is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Duplicate_Instruction,
           Outputs => Machine_Vector'Asm_Output ("=&x", Result),
           Inputs => Scalar_Type'Asm_Input ("x", Value));
      return To_Vector (Result);
   end SSE2_Splat_Float_128;


   generic
      type Vector_Type is private;
      Lane_Bits : Positive;
      Instruction : String;
   function SSE2_Compare_128 (Left, Right : Vector_Type; Sign : Machine_Vector) return Interfaces.Unsigned_16;
   function SSE2_Compare_128 (Left, Right : Vector_Type; Sign : Machine_Vector) return Interfaces.Unsigned_16 is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Raw, Packed : Interfaces.Unsigned_32;
      Truths, Other : Machine_Vector;
      First, Second, Third, Fourth : Machine_Vector;
   begin
      Asm (Template => "movdqa %7, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & "pmovmskb %1, %0",
           Outputs => [Interfaces.Unsigned_32'Asm_Output ("=&r", Raw), Machine_Vector'Asm_Output ("=&x", Truths), Machine_Vector'Asm_Output ("=&x", Other), Machine_Vector'Asm_Output ("=&x", First), Machine_Vector'Asm_Output ("=&x", Second), Machine_Vector'Asm_Output ("=&x", Third), Machine_Vector'Asm_Output ("=&x", Fourth)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right)), Machine_Vector'Asm_Input ("x", Sign)]);
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
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Amount : Machine_Vector;
      First_Scratch : Machine_Vector;
      Second_Scratch : Machine_Vector;
   begin
      Asm (Template => "movd %5, %1" & ASCII.LF & ASCII.HT & Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Amount), Machine_Vector'Asm_Output ("=&x", First_Scratch), Machine_Vector'Asm_Output ("=&x", Second_Scratch)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Value)), Interfaces.Unsigned_32'Asm_Input ("r", Count)]);
      return To_Vector (Result);
   end SSE2_Shift_128;

   generic
      type Vector_Type is private;
      Lane_Bits : Positive;
   function SSE2_Select_128 (Bits : Interfaces.Unsigned_16; Weights : Machine_Vector; If_True, If_False : Vector_Type) return Vector_Type;
   function SSE2_Select_128 (Bits : Interfaces.Unsigned_16; Weights : Machine_Vector; If_True, If_False : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Spare : Machine_Vector;
      Local_Bits : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (Bits);
      Expand : constant String := (case Lane_Bits is when 8 => "punpcklbw %0, %0" & ASCII.LF & ASCII.HT & "punpcklwd %0, %0" & ASCII.LF & ASCII.HT & "punpckldq %0, %0", when 16 => "pshuflw $0, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0", when 32 => "pshufd $0, %0, %0", when others => "punpcklqdq %0, %0");
      Compare : constant String := (if Lane_Bits = 8 then "pcmpeqb" elsif Lane_Bits = 16 then "pcmpeqw" else "pcmpeqd");
      Replicate_64 : constant String := (if Lane_Bits = 64 then "pshufd $0xA0, %0, %0" & ASCII.LF & ASCII.HT else "");
   begin
      Asm (Template => "movd %2, %0" & ASCII.LF & ASCII.HT & Expand & ASCII.LF & ASCII.HT &
           "pand %3, %0" & ASCII.LF & ASCII.HT & "pxor %1, %1" & ASCII.LF & ASCII.HT &
           Compare & " %1, %0" & ASCII.LF & ASCII.HT &
           "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0" & ASCII.LF & ASCII.HT &
           Replicate_64 & "movdqa %0, %1" & ASCII.LF & ASCII.HT &
           "pand %4, %1" & ASCII.LF & ASCII.HT & "pandn %5, %0" & ASCII.LF & ASCII.HT &
           "por %1, %0",
           Outputs => [Machine_Vector'Asm_Output ("=&x", Result), Machine_Vector'Asm_Output ("=&x", Spare)],
           Inputs => [Interfaces.Unsigned_32'Asm_Input ("r", Local_Bits), Machine_Vector'Asm_Input ("x", Weights), Machine_Vector'Asm_Input ("x", To_Machine (If_True)), Machine_Vector'Asm_Input ("x", To_Machine (If_False))]);
      return To_Vector (Result);
   end SSE2_Select_128;


   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S0 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S0 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S0;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S1 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S1 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S1;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S2 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S2 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S2;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S3 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S3 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S3;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S4 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S4 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S4;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S5 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S5 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S5;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S6 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S6 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S6;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Binary_128_S7 (Left, Right : Vector_Type) return Vector_Type;
   function SSE2_Binary_128_S7 (Left, Right : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
      Scratch_7 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6), Machine_Vector'Asm_Output ("=&x", Scratch_7)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Left)), Machine_Vector'Asm_Input ("x", To_Machine (Right))],
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Binary_128_S7;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Unary_128_S0 (Value : Vector_Type) return Vector_Type;
   function SSE2_Unary_128_S0 (Value : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Unary_128_S0;

   generic
      type Vector_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Unary_128_S1 (Value : Vector_Type) return Vector_Type;
   function SSE2_Unary_128_S1 (Value : Vector_Type) return Vector_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, Vector_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Vector (Result);
   end SSE2_Unary_128_S1;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_Pair_128_S0 (Low, High : Source_Type) return Result_Type;
   function SSE2_Convert_Pair_128_S0 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Low)), Machine_Vector'Asm_Input ("x", To_Machine (High))],
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_Pair_128_S0;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_Pair_128_S1 (Low, High : Source_Type) return Result_Type;
   function SSE2_Convert_Pair_128_S1 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Low)), Machine_Vector'Asm_Input ("x", To_Machine (High))],
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_Pair_128_S1;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_Pair_128_S2 (Low, High : Source_Type) return Result_Type;
   function SSE2_Convert_Pair_128_S2 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Low)), Machine_Vector'Asm_Input ("x", To_Machine (High))],
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_Pair_128_S2;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_Pair_128_S4 (Low, High : Source_Type) return Result_Type;
   function SSE2_Convert_Pair_128_S4 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Low)), Machine_Vector'Asm_Input ("x", To_Machine (High))],
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_Pair_128_S4;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_Pair_128_S5 (Low, High : Source_Type) return Result_Type;
   function SSE2_Convert_Pair_128_S5 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Low)), Machine_Vector'Asm_Input ("x", To_Machine (High))],
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_Pair_128_S5;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_Pair_128_S6 (Low, High : Source_Type) return Result_Type;
   function SSE2_Convert_Pair_128_S6 (Low, High : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6)],
           Inputs => [Machine_Vector'Asm_Input ("0", To_Machine (Low)), Machine_Vector'Asm_Input ("x", To_Machine (High))],
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_Pair_128_S6;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_128_S0 (Value : Source_Type) return Result_Type;
   function SSE2_Convert_128_S0 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_128_S0;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_128_S1 (Value : Source_Type) return Result_Type;
   function SSE2_Convert_128_S1 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_128_S1;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_128_S2 (Value : Source_Type) return Result_Type;
   function SSE2_Convert_128_S2 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_128_S2;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_128_S3 (Value : Source_Type) return Result_Type;
   function SSE2_Convert_128_S3 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_128_S3;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_128_S4 (Value : Source_Type) return Result_Type;
   function SSE2_Convert_128_S4 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_128_S4;

   generic
      type Source_Type is private;
      type Result_Type is private;
      Instruction : String;
      Clobber_List : String;
   function SSE2_Convert_128_S7 (Value : Source_Type) return Result_Type;
   function SSE2_Convert_128_S7 (Value : Source_Type) return Result_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Source_Type, Machine_Vector);
      function To_Result is new Ada.Unchecked_Conversion (Machine_Vector, Result_Type);
      Result : Machine_Vector;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
      Scratch_7 : Machine_Vector;
   begin
      Asm (Template => Instruction,
           Outputs => [Machine_Vector'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6), Machine_Vector'Asm_Output ("=&x", Scratch_7)],
           Inputs => Machine_Vector'Asm_Input ("0", To_Machine (Value)),
           Clobber => Clobber_List);
      return To_Result (Result);
   end SSE2_Convert_128_S7;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S2 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S2 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Integer_Reduce_128_S2;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S3 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S3 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Integer_Reduce_128_S3;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S4 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S4 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Integer_Reduce_128_S4;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S5 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S5 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Integer_Reduce_128_S5;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S5_Sign (Value : Vector_Type; Sign : Machine_Vector) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S5_Sign (Value : Vector_Type; Sign : Machine_Vector) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value)), Machine_Vector'Asm_Input ("x", Sign)]);
      return Result;
   end SSE2_Integer_Reduce_128_S5_Sign;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S6 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S6 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Integer_Reduce_128_S6;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S6_Sign (Value : Vector_Type; Sign : Machine_Vector) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S6_Sign (Value : Vector_Type; Sign : Machine_Vector) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value)), Machine_Vector'Asm_Input ("x", Sign)]);
      return Result;
   end SSE2_Integer_Reduce_128_S6_Sign;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Integer_Reduce_128_S7_Sign (Value : Vector_Type; Sign : Machine_Vector) return Scalar_Type;
   function SSE2_Integer_Reduce_128_S7_Sign (Value : Vector_Type; Sign : Machine_Vector) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
      Scratch_7 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6), Machine_Vector'Asm_Output ("=&x", Scratch_7)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value)), Machine_Vector'Asm_Input ("x", Sign)]);
      return Result;
   end SSE2_Integer_Reduce_128_S7_Sign;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Float_Reduce_128_S2 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Float_Reduce_128_S2 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Float_Reduce_128_S2;

   generic
      type Vector_Type is private;
      type Scalar_Type is private;
      Instruction : String;
      Extract_Instruction : String;
   function SSE2_Float_Reduce_128_S9 (Value : Vector_Type) return Scalar_Type;
   function SSE2_Float_Reduce_128_S9 (Value : Vector_Type) return Scalar_Type is
      function To_Machine is new Ada.Unchecked_Conversion (Vector_Type, Machine_Vector);
      Result : Scalar_Type;
      Scratch_1 : Machine_Vector;
      Scratch_2 : Machine_Vector;
      Scratch_3 : Machine_Vector;
      Scratch_4 : Machine_Vector;
      Scratch_5 : Machine_Vector;
      Scratch_6 : Machine_Vector;
      Scratch_7 : Machine_Vector;
      Scratch_8 : Machine_Vector;
      Scratch_9 : Machine_Vector;
   begin
      Asm (Template => Instruction & ASCII.LF & ASCII.HT & Extract_Instruction,
           Outputs => [Scalar_Type'Asm_Output ("=x", Result), Machine_Vector'Asm_Output ("=&x", Scratch_1), Machine_Vector'Asm_Output ("=&x", Scratch_2), Machine_Vector'Asm_Output ("=&x", Scratch_3), Machine_Vector'Asm_Output ("=&x", Scratch_4), Machine_Vector'Asm_Output ("=&x", Scratch_5), Machine_Vector'Asm_Output ("=&x", Scratch_6), Machine_Vector'Asm_Output ("=&x", Scratch_7), Machine_Vector'Asm_Output ("=&x", Scratch_8), Machine_Vector'Asm_Output ("=&x", Scratch_9)],
           Inputs => [Machine_Vector'Asm_Input ("x", To_Machine (Value))]);
      return Result;
   end SSE2_Float_Reduce_128_S9;

   function Native_Table_Lookup_U8x16 is new SSE2_Binary_128_S5 (U8x16, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pxor %2, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrlw $15, %5" & ASCII.LF & ASCII.HT & "packuswb %5, %5" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $1, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $2, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $3, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $4, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $5, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $6, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $7, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $8, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $9, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $10, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $11, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $12, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $13, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $14, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %3" & ASCII.LF & ASCII.HT & "psrldq $15, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %3" & ASCII.LF & ASCII.HT & "punpcklwd %3, %3" & ASCII.LF & ASCII.HT & "pshufd $0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqb %2, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "paddb %5, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "");
   function Table_Lookup (Table, Indices : U8x16) return U8x16 is (Native_Table_Lookup_U8x16 (Table, Indices));
   function Native_Slide_Lanes_Toward_Low_U8x16_1 is new SSE2_Unary_128_S0 (U8x16, "psrldq $1, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_1);
   function Native_Slide_Lanes_Toward_Low_U8x16_2 is new SSE2_Unary_128_S0 (U8x16, "psrldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_2);
   function Native_Slide_Lanes_Toward_Low_U8x16_3 is new SSE2_Unary_128_S0 (U8x16, "psrldq $3, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_3);
   function Native_Slide_Lanes_Toward_Low_U8x16_4 is new SSE2_Unary_128_S0 (U8x16, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_4);
   function Native_Slide_Lanes_Toward_Low_U8x16_5 is new SSE2_Unary_128_S0 (U8x16, "psrldq $5, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_5);
   function Native_Slide_Lanes_Toward_Low_U8x16_6 is new SSE2_Unary_128_S0 (U8x16, "psrldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_6);
   function Native_Slide_Lanes_Toward_Low_U8x16_7 is new SSE2_Unary_128_S0 (U8x16, "psrldq $7, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_7);
   function Native_Slide_Lanes_Toward_Low_U8x16_8 is new SSE2_Unary_128_S0 (U8x16, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_8);
   function Native_Slide_Lanes_Toward_Low_U8x16_9 is new SSE2_Unary_128_S0 (U8x16, "psrldq $9, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_9);
   function Native_Slide_Lanes_Toward_Low_U8x16_10 is new SSE2_Unary_128_S0 (U8x16, "psrldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_10);
   function Native_Slide_Lanes_Toward_Low_U8x16_11 is new SSE2_Unary_128_S0 (U8x16, "psrldq $11, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_11);
   function Native_Slide_Lanes_Toward_Low_U8x16_12 is new SSE2_Unary_128_S0 (U8x16, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_12);
   function Native_Slide_Lanes_Toward_Low_U8x16_13 is new SSE2_Unary_128_S0 (U8x16, "psrldq $13, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_13);
   function Native_Slide_Lanes_Toward_Low_U8x16_14 is new SSE2_Unary_128_S0 (U8x16, "psrldq $14, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U8x16_14);
   function Native_Slide_Lanes_Toward_Low_U8x16_15 is new SSE2_Unary_128_S0 (U8x16, "psrldq $15, %0", "");
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

   function Native_Slide_Lanes_Toward_High_U8x16_1 is new SSE2_Unary_128_S0 (U8x16, "pslldq $1, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_1);
   function Native_Slide_Lanes_Toward_High_U8x16_2 is new SSE2_Unary_128_S0 (U8x16, "pslldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_2);
   function Native_Slide_Lanes_Toward_High_U8x16_3 is new SSE2_Unary_128_S0 (U8x16, "pslldq $3, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_3);
   function Native_Slide_Lanes_Toward_High_U8x16_4 is new SSE2_Unary_128_S0 (U8x16, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_4);
   function Native_Slide_Lanes_Toward_High_U8x16_5 is new SSE2_Unary_128_S0 (U8x16, "pslldq $5, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_5);
   function Native_Slide_Lanes_Toward_High_U8x16_6 is new SSE2_Unary_128_S0 (U8x16, "pslldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_6);
   function Native_Slide_Lanes_Toward_High_U8x16_7 is new SSE2_Unary_128_S0 (U8x16, "pslldq $7, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_7);
   function Native_Slide_Lanes_Toward_High_U8x16_8 is new SSE2_Unary_128_S0 (U8x16, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_8);
   function Native_Slide_Lanes_Toward_High_U8x16_9 is new SSE2_Unary_128_S0 (U8x16, "pslldq $9, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_9);
   function Native_Slide_Lanes_Toward_High_U8x16_10 is new SSE2_Unary_128_S0 (U8x16, "pslldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_10);
   function Native_Slide_Lanes_Toward_High_U8x16_11 is new SSE2_Unary_128_S0 (U8x16, "pslldq $11, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_11);
   function Native_Slide_Lanes_Toward_High_U8x16_12 is new SSE2_Unary_128_S0 (U8x16, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_12);
   function Native_Slide_Lanes_Toward_High_U8x16_13 is new SSE2_Unary_128_S0 (U8x16, "pslldq $13, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_13);
   function Native_Slide_Lanes_Toward_High_U8x16_14 is new SSE2_Unary_128_S0 (U8x16, "pslldq $14, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U8x16_14);
   function Native_Slide_Lanes_Toward_High_U8x16_15 is new SSE2_Unary_128_S0 (U8x16, "pslldq $15, %0", "");
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

   function Native_Slide_Lanes_Toward_Low_I8x16_1 is new SSE2_Unary_128_S0 (I8x16, "psrldq $1, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_1);
   function Native_Slide_Lanes_Toward_Low_I8x16_2 is new SSE2_Unary_128_S0 (I8x16, "psrldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_2);
   function Native_Slide_Lanes_Toward_Low_I8x16_3 is new SSE2_Unary_128_S0 (I8x16, "psrldq $3, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_3);
   function Native_Slide_Lanes_Toward_Low_I8x16_4 is new SSE2_Unary_128_S0 (I8x16, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_4);
   function Native_Slide_Lanes_Toward_Low_I8x16_5 is new SSE2_Unary_128_S0 (I8x16, "psrldq $5, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_5);
   function Native_Slide_Lanes_Toward_Low_I8x16_6 is new SSE2_Unary_128_S0 (I8x16, "psrldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_6);
   function Native_Slide_Lanes_Toward_Low_I8x16_7 is new SSE2_Unary_128_S0 (I8x16, "psrldq $7, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_7);
   function Native_Slide_Lanes_Toward_Low_I8x16_8 is new SSE2_Unary_128_S0 (I8x16, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_8);
   function Native_Slide_Lanes_Toward_Low_I8x16_9 is new SSE2_Unary_128_S0 (I8x16, "psrldq $9, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_9);
   function Native_Slide_Lanes_Toward_Low_I8x16_10 is new SSE2_Unary_128_S0 (I8x16, "psrldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_10);
   function Native_Slide_Lanes_Toward_Low_I8x16_11 is new SSE2_Unary_128_S0 (I8x16, "psrldq $11, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_11);
   function Native_Slide_Lanes_Toward_Low_I8x16_12 is new SSE2_Unary_128_S0 (I8x16, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_12);
   function Native_Slide_Lanes_Toward_Low_I8x16_13 is new SSE2_Unary_128_S0 (I8x16, "psrldq $13, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_13);
   function Native_Slide_Lanes_Toward_Low_I8x16_14 is new SSE2_Unary_128_S0 (I8x16, "psrldq $14, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I8x16_14);
   function Native_Slide_Lanes_Toward_Low_I8x16_15 is new SSE2_Unary_128_S0 (I8x16, "psrldq $15, %0", "");
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

   function Native_Slide_Lanes_Toward_High_I8x16_1 is new SSE2_Unary_128_S0 (I8x16, "pslldq $1, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_1);
   function Native_Slide_Lanes_Toward_High_I8x16_2 is new SSE2_Unary_128_S0 (I8x16, "pslldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_2);
   function Native_Slide_Lanes_Toward_High_I8x16_3 is new SSE2_Unary_128_S0 (I8x16, "pslldq $3, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_3);
   function Native_Slide_Lanes_Toward_High_I8x16_4 is new SSE2_Unary_128_S0 (I8x16, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_4);
   function Native_Slide_Lanes_Toward_High_I8x16_5 is new SSE2_Unary_128_S0 (I8x16, "pslldq $5, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_5);
   function Native_Slide_Lanes_Toward_High_I8x16_6 is new SSE2_Unary_128_S0 (I8x16, "pslldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_6);
   function Native_Slide_Lanes_Toward_High_I8x16_7 is new SSE2_Unary_128_S0 (I8x16, "pslldq $7, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_7);
   function Native_Slide_Lanes_Toward_High_I8x16_8 is new SSE2_Unary_128_S0 (I8x16, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_8);
   function Native_Slide_Lanes_Toward_High_I8x16_9 is new SSE2_Unary_128_S0 (I8x16, "pslldq $9, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_9);
   function Native_Slide_Lanes_Toward_High_I8x16_10 is new SSE2_Unary_128_S0 (I8x16, "pslldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_10);
   function Native_Slide_Lanes_Toward_High_I8x16_11 is new SSE2_Unary_128_S0 (I8x16, "pslldq $11, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_11);
   function Native_Slide_Lanes_Toward_High_I8x16_12 is new SSE2_Unary_128_S0 (I8x16, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_12);
   function Native_Slide_Lanes_Toward_High_I8x16_13 is new SSE2_Unary_128_S0 (I8x16, "pslldq $13, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_13);
   function Native_Slide_Lanes_Toward_High_I8x16_14 is new SSE2_Unary_128_S0 (I8x16, "pslldq $14, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I8x16_14);
   function Native_Slide_Lanes_Toward_High_I8x16_15 is new SSE2_Unary_128_S0 (I8x16, "pslldq $15, %0", "");
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

   function Native_Slide_Lanes_Toward_Low_U16x8_1 is new SSE2_Unary_128_S0 (U16x8, "psrldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_1);
   function Native_Slide_Lanes_Toward_Low_U16x8_2 is new SSE2_Unary_128_S0 (U16x8, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_2);
   function Native_Slide_Lanes_Toward_Low_U16x8_3 is new SSE2_Unary_128_S0 (U16x8, "psrldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_3);
   function Native_Slide_Lanes_Toward_Low_U16x8_4 is new SSE2_Unary_128_S0 (U16x8, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_4);
   function Native_Slide_Lanes_Toward_Low_U16x8_5 is new SSE2_Unary_128_S0 (U16x8, "psrldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_5);
   function Native_Slide_Lanes_Toward_Low_U16x8_6 is new SSE2_Unary_128_S0 (U16x8, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U16x8_6);
   function Native_Slide_Lanes_Toward_Low_U16x8_7 is new SSE2_Unary_128_S0 (U16x8, "psrldq $14, %0", "");
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

   function Native_Slide_Lanes_Toward_High_U16x8_1 is new SSE2_Unary_128_S0 (U16x8, "pslldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_1);
   function Native_Slide_Lanes_Toward_High_U16x8_2 is new SSE2_Unary_128_S0 (U16x8, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_2);
   function Native_Slide_Lanes_Toward_High_U16x8_3 is new SSE2_Unary_128_S0 (U16x8, "pslldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_3);
   function Native_Slide_Lanes_Toward_High_U16x8_4 is new SSE2_Unary_128_S0 (U16x8, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_4);
   function Native_Slide_Lanes_Toward_High_U16x8_5 is new SSE2_Unary_128_S0 (U16x8, "pslldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_5);
   function Native_Slide_Lanes_Toward_High_U16x8_6 is new SSE2_Unary_128_S0 (U16x8, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U16x8_6);
   function Native_Slide_Lanes_Toward_High_U16x8_7 is new SSE2_Unary_128_S0 (U16x8, "pslldq $14, %0", "");
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

   function Native_Slide_Lanes_Toward_Low_I16x8_1 is new SSE2_Unary_128_S0 (I16x8, "psrldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_1);
   function Native_Slide_Lanes_Toward_Low_I16x8_2 is new SSE2_Unary_128_S0 (I16x8, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_2);
   function Native_Slide_Lanes_Toward_Low_I16x8_3 is new SSE2_Unary_128_S0 (I16x8, "psrldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_3);
   function Native_Slide_Lanes_Toward_Low_I16x8_4 is new SSE2_Unary_128_S0 (I16x8, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_4);
   function Native_Slide_Lanes_Toward_Low_I16x8_5 is new SSE2_Unary_128_S0 (I16x8, "psrldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_5);
   function Native_Slide_Lanes_Toward_Low_I16x8_6 is new SSE2_Unary_128_S0 (I16x8, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I16x8_6);
   function Native_Slide_Lanes_Toward_Low_I16x8_7 is new SSE2_Unary_128_S0 (I16x8, "psrldq $14, %0", "");
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

   function Native_Slide_Lanes_Toward_High_I16x8_1 is new SSE2_Unary_128_S0 (I16x8, "pslldq $2, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_1);
   function Native_Slide_Lanes_Toward_High_I16x8_2 is new SSE2_Unary_128_S0 (I16x8, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_2);
   function Native_Slide_Lanes_Toward_High_I16x8_3 is new SSE2_Unary_128_S0 (I16x8, "pslldq $6, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_3);
   function Native_Slide_Lanes_Toward_High_I16x8_4 is new SSE2_Unary_128_S0 (I16x8, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_4);
   function Native_Slide_Lanes_Toward_High_I16x8_5 is new SSE2_Unary_128_S0 (I16x8, "pslldq $10, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_5);
   function Native_Slide_Lanes_Toward_High_I16x8_6 is new SSE2_Unary_128_S0 (I16x8, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I16x8_6);
   function Native_Slide_Lanes_Toward_High_I16x8_7 is new SSE2_Unary_128_S0 (I16x8, "pslldq $14, %0", "");
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

   function Native_Slide_Lanes_Toward_Low_U32x4_1 is new SSE2_Unary_128_S0 (U32x4, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_1);
   function Native_Slide_Lanes_Toward_Low_U32x4_2 is new SSE2_Unary_128_S0 (U32x4, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_2);
   function Native_Slide_Lanes_Toward_Low_U32x4_3 is new SSE2_Unary_128_S0 (U32x4, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U32x4_3);
   function Slide_Lanes_Toward_Low (Value : U32x4; Count : Natural) return U32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_U32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_U32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_U32x4_1 is new SSE2_Unary_128_S0 (U32x4, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_1);
   function Native_Slide_Lanes_Toward_High_U32x4_2 is new SSE2_Unary_128_S0 (U32x4, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_2);
   function Native_Slide_Lanes_Toward_High_U32x4_3 is new SSE2_Unary_128_S0 (U32x4, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U32x4_3);
   function Slide_Lanes_Toward_High (Value : U32x4; Count : Natural) return U32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_U32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_U32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_I32x4_1 is new SSE2_Unary_128_S0 (I32x4, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_1);
   function Native_Slide_Lanes_Toward_Low_I32x4_2 is new SSE2_Unary_128_S0 (I32x4, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_2);
   function Native_Slide_Lanes_Toward_Low_I32x4_3 is new SSE2_Unary_128_S0 (I32x4, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I32x4_3);
   function Slide_Lanes_Toward_Low (Value : I32x4; Count : Natural) return I32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_I32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_I32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_I32x4_1 is new SSE2_Unary_128_S0 (I32x4, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_1);
   function Native_Slide_Lanes_Toward_High_I32x4_2 is new SSE2_Unary_128_S0 (I32x4, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_2);
   function Native_Slide_Lanes_Toward_High_I32x4_3 is new SSE2_Unary_128_S0 (I32x4, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I32x4_3);
   function Slide_Lanes_Toward_High (Value : I32x4; Count : Natural) return I32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_I32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_I32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_U64x2_1 is new SSE2_Unary_128_S0 (U64x2, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_U64x2_1);
   function Slide_Lanes_Toward_Low (Value : U64x2; Count : Natural) return U64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_U64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_U64x2_1 is new SSE2_Unary_128_S0 (U64x2, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_U64x2_1);
   function Slide_Lanes_Toward_High (Value : U64x2; Count : Natural) return U64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_U64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_I64x2_1 is new SSE2_Unary_128_S0 (I64x2, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_I64x2_1);
   function Slide_Lanes_Toward_Low (Value : I64x2; Count : Natural) return I64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_I64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_I64x2_1 is new SSE2_Unary_128_S0 (I64x2, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_I64x2_1);
   function Slide_Lanes_Toward_High (Value : I64x2; Count : Natural) return I64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_I64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_F32x4_1 is new SSE2_Unary_128_S0 (F32x4, "psrldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_1);
   function Native_Slide_Lanes_Toward_Low_F32x4_2 is new SSE2_Unary_128_S0 (F32x4, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_2);
   function Native_Slide_Lanes_Toward_Low_F32x4_3 is new SSE2_Unary_128_S0 (F32x4, "psrldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F32x4_3);
   function Slide_Lanes_Toward_Low (Value : F32x4; Count : Natural) return F32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_F32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_Low_F32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_Low_F32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_F32x4_1 is new SSE2_Unary_128_S0 (F32x4, "pslldq $4, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_1);
   function Native_Slide_Lanes_Toward_High_F32x4_2 is new SSE2_Unary_128_S0 (F32x4, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_2);
   function Native_Slide_Lanes_Toward_High_F32x4_3 is new SSE2_Unary_128_S0 (F32x4, "pslldq $12, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F32x4_3);
   function Slide_Lanes_Toward_High (Value : F32x4; Count : Natural) return F32x4 is
     (if Count = 0 then Value
      elsif Count >= 4 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_F32x4_1 (Value),
         when 2 => Native_Slide_Lanes_Toward_High_F32x4_2 (Value),
         when 3 => Native_Slide_Lanes_Toward_High_F32x4_3 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_Low_F64x2_1 is new SSE2_Unary_128_S0 (F64x2, "psrldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_Low_F64x2_1);
   function Slide_Lanes_Toward_Low (Value : F64x2; Count : Natural) return F64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_Low_F64x2_1 (Value),
         when others => Zero));

   function Native_Slide_Lanes_Toward_High_F64x2_1 is new SSE2_Unary_128_S0 (F64x2, "pslldq $8, %0", "");
   pragma Inline_Always (Native_Slide_Lanes_Toward_High_F64x2_1);
   function Slide_Lanes_Toward_High (Value : F64x2; Count : Natural) return F64x2 is
     (if Count = 0 then Value
      elsif Count >= 2 then Zero
      else (case Count is
         when 1 => Native_Slide_Lanes_Toward_High_F64x2_1 (Value),
         when others => Zero));

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
   function Native_Widen_Low_U8x16_To_U16x8 is new SSE2_Convert_128_S1 (U8x16, U16x8, "pxor %1, %1" & ASCII.LF & ASCII.HT & "punpcklbw %1, %0", "");
   pragma Inline_Always (Native_Widen_Low_U8x16_To_U16x8);
   function Widen_Low (Value : U8x16) return U16x8 is (Native_Widen_Low_U8x16_To_U16x8 (Value));
   function Native_Widen_High_U8x16_To_U16x8 is new SSE2_Convert_128_S1 (U8x16, U16x8, "pxor %1, %1" & ASCII.LF & ASCII.HT & "punpckhbw %1, %0", "");
   pragma Inline_Always (Native_Widen_High_U8x16_To_U16x8);
   function Widen_High (Value : U8x16) return U16x8 is (Native_Widen_High_U8x16_To_U16x8 (Value));
   function Native_Widen_Low_I8x16_To_I16x8 is new SSE2_Convert_128_S1 (I8x16, I16x8, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtb %0, %1" & ASCII.LF & ASCII.HT & "punpcklbw %1, %0", "");
   pragma Inline_Always (Native_Widen_Low_I8x16_To_I16x8);
   function Widen_Low (Value : I8x16) return I16x8 is (Native_Widen_Low_I8x16_To_I16x8 (Value));
   function Native_Widen_High_I8x16_To_I16x8 is new SSE2_Convert_128_S1 (I8x16, I16x8, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtb %0, %1" & ASCII.LF & ASCII.HT & "punpckhbw %1, %0", "");
   pragma Inline_Always (Native_Widen_High_I8x16_To_I16x8);
   function Widen_High (Value : I8x16) return I16x8 is (Native_Widen_High_I8x16_To_I16x8 (Value));
   function Native_Widen_Low_U16x8_To_U32x4 is new SSE2_Convert_128_S1 (U16x8, U32x4, "pxor %1, %1" & ASCII.LF & ASCII.HT & "punpcklwd %1, %0", "");
   pragma Inline_Always (Native_Widen_Low_U16x8_To_U32x4);
   function Widen_Low (Value : U16x8) return U32x4 is (Native_Widen_Low_U16x8_To_U32x4 (Value));
   function Native_Widen_High_U16x8_To_U32x4 is new SSE2_Convert_128_S1 (U16x8, U32x4, "pxor %1, %1" & ASCII.LF & ASCII.HT & "punpckhwd %1, %0", "");
   pragma Inline_Always (Native_Widen_High_U16x8_To_U32x4);
   function Widen_High (Value : U16x8) return U32x4 is (Native_Widen_High_U16x8_To_U32x4 (Value));
   function Native_Widen_Low_I16x8_To_I32x4 is new SSE2_Convert_128_S1 (I16x8, I32x4, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtw %0, %1" & ASCII.LF & ASCII.HT & "punpcklwd %1, %0", "");
   pragma Inline_Always (Native_Widen_Low_I16x8_To_I32x4);
   function Widen_Low (Value : I16x8) return I32x4 is (Native_Widen_Low_I16x8_To_I32x4 (Value));
   function Native_Widen_High_I16x8_To_I32x4 is new SSE2_Convert_128_S1 (I16x8, I32x4, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtw %0, %1" & ASCII.LF & ASCII.HT & "punpckhwd %1, %0", "");
   pragma Inline_Always (Native_Widen_High_I16x8_To_I32x4);
   function Widen_High (Value : I16x8) return I32x4 is (Native_Widen_High_I16x8_To_I32x4 (Value));
   function Native_Widen_Low_U32x4_To_U64x2 is new SSE2_Convert_128_S1 (U32x4, U64x2, "pxor %1, %1" & ASCII.LF & ASCII.HT & "punpckldq %1, %0", "");
   pragma Inline_Always (Native_Widen_Low_U32x4_To_U64x2);
   function Widen_Low (Value : U32x4) return U64x2 is (Native_Widen_Low_U32x4_To_U64x2 (Value));
   function Native_Widen_High_U32x4_To_U64x2 is new SSE2_Convert_128_S1 (U32x4, U64x2, "pxor %1, %1" & ASCII.LF & ASCII.HT & "punpckhdq %1, %0", "");
   pragma Inline_Always (Native_Widen_High_U32x4_To_U64x2);
   function Widen_High (Value : U32x4) return U64x2 is (Native_Widen_High_U32x4_To_U64x2 (Value));
   function Native_Widen_Low_I32x4_To_I64x2 is new SSE2_Convert_128_S1 (I32x4, I64x2, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtd %0, %1" & ASCII.LF & ASCII.HT & "punpckldq %1, %0", "");
   pragma Inline_Always (Native_Widen_Low_I32x4_To_I64x2);
   function Widen_Low (Value : I32x4) return I64x2 is (Native_Widen_Low_I32x4_To_I64x2 (Value));
   function Native_Widen_High_I32x4_To_I64x2 is new SSE2_Convert_128_S1 (I32x4, I64x2, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtd %0, %1" & ASCII.LF & ASCII.HT & "punpckhdq %1, %0", "");
   pragma Inline_Always (Native_Widen_High_I32x4_To_I64x2);
   function Widen_High (Value : I32x4) return I64x2 is (Native_Widen_High_I32x4_To_I64x2 (Value));
   function Native_Widen_Low_F32x4_To_F64x2 is new SSE2_Convert_128_S0 (F32x4, F64x2, "cvtps2pd %0, %0", "");
   pragma Inline_Always (Native_Widen_Low_F32x4_To_F64x2);
   function Widen_Low (Value : F32x4) return F64x2 is (Native_Widen_Low_F32x4_To_F64x2 (Value));
   function Native_Widen_High_F32x4_To_F64x2 is new SSE2_Convert_128_S0 (F32x4, F64x2, "pshufd $0xEE, %0, %0" & ASCII.LF & ASCII.HT & "cvtps2pd %0, %0", "");
   pragma Inline_Always (Native_Widen_High_F32x4_To_F64x2);
   function Widen_High (Value : F32x4) return F64x2 is (Native_Widen_High_F32x4_To_F64x2 (Value));
   function Native_Narrow_Truncate_U16x8_To_U8x16 is new SSE2_Convert_Pair_128_S2 (U16x8, U8x16, "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pand %1, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0", "");
   pragma Inline_Always (Native_Narrow_Truncate_U16x8_To_U8x16);
   function Narrow_Truncate (Low, High : U16x8) return U8x16 is (Native_Narrow_Truncate_U16x8_To_U8x16 (Low, High));
   function Native_Narrow_Saturate_U16x8_To_U8x16 is new SSE2_Convert_Pair_128_S5 (U16x8, U8x16, "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pxor %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlw $8, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "pcmpeqw %4, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pandn %3, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "pcmpeqw %4, %2" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "pandn %3, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "packuswb %5, %0", "");
   function Narrow_Saturate (Low, High : U16x8) return U8x16 is (Native_Narrow_Saturate_U16x8_To_U8x16 (Low, High));
   function Native_Narrow_Truncate_I16x8_To_I8x16 is new SSE2_Convert_Pair_128_S2 (I16x8, I8x16, "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pand %1, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0", "");
   pragma Inline_Always (Native_Narrow_Truncate_I16x8_To_I8x16);
   function Narrow_Truncate (Low, High : I16x8) return I8x16 is (Native_Narrow_Truncate_I16x8_To_I8x16 (Low, High));
   function Native_Narrow_Saturate_I16x8_To_I8x16 is new SSE2_Convert_Pair_128_S0 (I16x8, I8x16, "packsswb %2, %0", "");
   pragma Inline_Always (Native_Narrow_Saturate_I16x8_To_I8x16);
   function Narrow_Saturate (Low, High : I16x8) return I8x16 is (Native_Narrow_Saturate_I16x8_To_I8x16 (Low, High));
   function Native_Narrow_Truncate_U32x4_To_U16x8 is new SSE2_Convert_Pair_128_S1 (U32x4, U16x8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Narrow_Truncate_U32x4_To_U16x8);
   function Narrow_Truncate (Low, High : U32x4) return U16x8 is (Native_Narrow_Truncate_U32x4_To_U16x8 (Low, High));
   function Native_Narrow_Saturate_U32x4_To_U16x8 is new SSE2_Convert_Pair_128_S5 (U32x4, U16x8, "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pxor %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $16, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "psrld $16, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pandn %3, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "psrld $16, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %2" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "pandn %3, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %5, %5" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %5, %5" & ASCII.LF & ASCII.HT & "pshufd $0x88, %5, %5" & ASCII.LF & ASCII.HT & "punpcklqdq %5, %0", "");
   function Narrow_Saturate (Low, High : U32x4) return U16x8 is (Native_Narrow_Saturate_U32x4_To_U16x8 (Low, High));
   function Native_Narrow_Truncate_I32x4_To_I16x8 is new SSE2_Convert_Pair_128_S1 (I32x4, I16x8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Narrow_Truncate_I32x4_To_I16x8);
   function Narrow_Truncate (Low, High : I32x4) return I16x8 is (Native_Narrow_Truncate_I32x4_To_I16x8 (Low, High));
   function Native_Narrow_Saturate_I32x4_To_I16x8 is new SSE2_Convert_Pair_128_S0 (I32x4, I16x8, "packssdw %2, %0", "");
   pragma Inline_Always (Native_Narrow_Saturate_I32x4_To_I16x8);
   function Narrow_Saturate (Low, High : I32x4) return I16x8 is (Native_Narrow_Saturate_I32x4_To_I16x8 (Low, High));
   function Native_Narrow_Truncate_U64x2_To_U32x4 is new SSE2_Convert_Pair_128_S1 (U64x2, U32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Narrow_Truncate_U64x2_To_U32x4);
   function Narrow_Truncate (Low, High : U64x2) return U32x4 is (Native_Narrow_Truncate_U64x2_To_U32x4 (Low, High));
   function Native_Narrow_Saturate_U64x2_To_U32x4 is new SSE2_Convert_Pair_128_S5 (U64x2, U32x4, "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pxor %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "psrlq $32, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pandn %3, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "psrlq $32, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %2" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "pandn %3, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %5, %5" & ASCII.LF & ASCII.HT & "punpcklqdq %5, %0", "");
   function Narrow_Saturate (Low, High : U64x2) return U32x4 is (Native_Narrow_Saturate_U64x2_To_U32x4 (Low, High));
   function Native_Narrow_Truncate_I64x2_To_I32x4 is new SSE2_Convert_Pair_128_S1 (I64x2, I32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Narrow_Truncate_I64x2_To_I32x4);
   function Narrow_Truncate (Low, High : I64x2) return I32x4 is (Native_Narrow_Truncate_I64x2_To_I32x4 (Low, High));
   function Native_Narrow_Saturate_I64x2_To_I32x4 is new SSE2_Convert_Pair_128_S4 (I64x2, I32x4, "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %1, %1" & ASCII.LF & ASCII.HT & "movdqa %0, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %0, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pandn %2, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %1, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %1" & ASCII.LF & ASCII.HT & "por %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %4, %4" & ASCII.LF & ASCII.HT & "punpcklqdq %4, %0", "");
   function Narrow_Saturate (Low, High : I64x2) return I32x4 is (Native_Narrow_Saturate_I64x2_To_I32x4 (Low, High));
   function Native_Narrow_Saturate_I16x8_To_U8x16 is new SSE2_Convert_Pair_128_S0 (I16x8, U8x16, "packuswb %2, %0", "");
   pragma Inline_Always (Native_Narrow_Saturate_I16x8_To_U8x16);
   function Narrow_Saturate (Low, High : I16x8) return U8x16 is (Native_Narrow_Saturate_I16x8_To_U8x16 (Low, High));
   function Native_Narrow_Saturate_I32x4_To_U16x8 is new SSE2_Convert_Pair_128_S6 (I32x4, U16x8, "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pxor %5, %5" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psrld $16, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pcmpgtd %0, %1" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %3" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "pandn %1, %2" & ASCII.LF & ASCII.HT & "por %3, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pcmpgtd %6, %1" & ASCII.LF & ASCII.HT & "pandn %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %3" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "pandn %1, %2" & ASCII.LF & ASCII.HT & "por %3, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %6, %6" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %6, %6" & ASCII.LF & ASCII.HT & "pshufd $0x88, %6, %6" & ASCII.LF & ASCII.HT & "punpcklqdq %6, %0", "");
   function Narrow_Saturate (Low, High : I32x4) return U16x8 is (Native_Narrow_Saturate_I32x4_To_U16x8 (Low, High));
   function Native_Narrow_Saturate_I64x2_To_U32x4 is new SSE2_Convert_Pair_128_S5 (I64x2, U32x4, "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pxor %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %1, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "pandn %3, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %1, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %1" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "pandn %3, %1" & ASCII.LF & ASCII.HT & "por %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %5, %5" & ASCII.LF & ASCII.HT & "punpcklqdq %5, %0", "");
   function Narrow_Saturate (Low, High : I64x2) return U32x4 is (Native_Narrow_Saturate_I64x2_To_U32x4 (Low, High));
   function Native_Narrow_Round_F64x2_To_F32x4 is new SSE2_Convert_Pair_128_S1 (F64x2, F32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "cvtpd2ps %0, %0" & ASCII.LF & ASCII.HT & "cvtpd2ps %1, %1" & ASCII.LF & ASCII.HT & "movlhps %1, %0", "");
   pragma Inline_Always (Native_Narrow_Round_F64x2_To_F32x4);
   function Narrow_Round (Low, High : F64x2) return F32x4 is (Native_Narrow_Round_F64x2_To_F32x4 (Low, High));
   function Native_Convert_Round_I32x4_To_F32x4 is new SSE2_Convert_128_S0 (I32x4, F32x4, "cvtdq2ps %0, %0", "");
   pragma Inline_Always (Native_Convert_Round_I32x4_To_F32x4);
   function Convert_Round (Value : I32x4) return F32x4 is (Native_Convert_Round_I32x4_To_F32x4 (Value));
   function Native_Convert_Round_U32x4_To_F32x4 is new SSE2_Convert_128_S4 (U32x4, F32x4, "pxor %2, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %0, %2" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "psrld $1, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $31, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %4" & ASCII.LF & ASCII.HT & "pand %3, %4" & ASCII.LF & ASCII.HT & "por %4, %1" & ASCII.LF & ASCII.HT & "cvtdq2ps %1, %1" & ASCII.LF & ASCII.HT & "addps %1, %1" & ASCII.LF & ASCII.HT & "cvtdq2ps %0, %0" & ASCII.LF & ASCII.HT & "movdqa %2, %4" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %0, %2" & ASCII.LF & ASCII.HT & "por %4, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0", "");
   function Convert_Round (Value : U32x4) return F32x4 is (Native_Convert_Round_U32x4_To_F32x4 (Value));
   function Native_Convert_Round_I64x2_To_F64x2 is new SSE2_Convert_128_S2 (I64x2, F64x2, "movq %0, %%rax" & ASCII.LF & ASCII.HT & "cvtsi2sdq %%rax, %1" & ASCII.LF & ASCII.HT & "psrldq $8, %0" & ASCII.LF & ASCII.HT & "movq %0, %%rax" & ASCII.LF & ASCII.HT & "cvtsi2sdq %%rax, %2" & ASCII.LF & ASCII.HT & "unpcklpd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "rax,cc");
   pragma Inline_Always (Native_Convert_Round_I64x2_To_F64x2);
   function Convert_Round (Value : I64x2) return F64x2 is (Native_Convert_Round_I64x2_To_F64x2 (Value));
   function Native_Convert_Round_U64x2_To_F64x2 is new SSE2_Convert_128_S2 (U64x2, F64x2, "movq %0, %%rax" & ASCII.LF & ASCII.HT & "testq %%rax, %%rax" & ASCII.LF & ASCII.HT & "js 1f" & ASCII.LF & ASCII.HT & "cvtsi2sdq %%rax, %1" & ASCII.LF & ASCII.HT & "jmp 2f" & ASCII.LF & ASCII.HT & "1:" & ASCII.LF & ASCII.HT & "movq %%rax, %%rcx" & ASCII.LF & ASCII.HT & "shrq $1, %%rcx" & ASCII.LF & ASCII.HT & "andq $1, %%rax" & ASCII.LF & ASCII.HT & "orq %%rax, %%rcx" & ASCII.LF & ASCII.HT & "cvtsi2sdq %%rcx, %1" & ASCII.LF & ASCII.HT & "addsd %1, %1" & ASCII.LF & ASCII.HT & "2:" & ASCII.LF & ASCII.HT & "psrldq $8, %0" & ASCII.LF & ASCII.HT & "movq %0, %%rax" & ASCII.LF & ASCII.HT & "testq %%rax, %%rax" & ASCII.LF & ASCII.HT & "js 3f" & ASCII.LF & ASCII.HT & "cvtsi2sdq %%rax, %2" & ASCII.LF & ASCII.HT & "jmp 4f" & ASCII.LF & ASCII.HT & "3:" & ASCII.LF & ASCII.HT & "movq %%rax, %%rcx" & ASCII.LF & ASCII.HT & "shrq $1, %%rcx" & ASCII.LF & ASCII.HT & "andq $1, %%rax" & ASCII.LF & ASCII.HT & "orq %%rax, %%rcx" & ASCII.LF & ASCII.HT & "cvtsi2sdq %%rcx, %2" & ASCII.LF & ASCII.HT & "addsd %2, %2" & ASCII.LF & ASCII.HT & "4:" & ASCII.LF & ASCII.HT & "unpcklpd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "rax,rcx,cc");
   function Convert_Round (Value : U64x2) return F64x2 is (Native_Convert_Round_U64x2_To_F64x2 (Value));
   function Native_Convert_Truncate_Saturate_F32x4_To_I32x4 is new SSE2_Convert_128_S7 (F32x4, I32x4, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "cvttps2dq %1, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %6, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %7" & ASCII.LF & ASCII.HT & "psrld $28, %7" & ASCII.LF & ASCII.HT & "pslld $24, %7" & ASCII.LF & ASCII.HT & "psrld $31, %6" & ASCII.LF & ASCII.HT & "pslld $30, %6" & ASCII.LF & ASCII.HT & "por %7, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "cmpleps %0, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %7, %7" & ASCII.LF & ASCII.HT & "pslld $31, %7" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %4" & ASCII.LF & ASCII.HT & "cmpleps %3, %4" & ASCII.LF & ASCII.HT & "movdqa %0, %5" & ASCII.LF & ASCII.HT & "cmpunordps %5, %5" & ASCII.LF & ASCII.HT & "pcmpeqd %6, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "pandn %1, %2" & ASCII.LF & ASCII.HT & "por %3, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "pandn %2, %4" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %0", "");
   function Convert_Truncate_Saturate (Value : F32x4) return I32x4 is (Native_Convert_Truncate_Saturate_F32x4_To_I32x4 (Value));
   function Native_Convert_Truncate_Saturate_F32x4_To_U32x4 is new SSE2_Convert_128_S7 (F32x4, U32x4, "pcmpeqd %6, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %7" & ASCII.LF & ASCII.HT & "psrld $28, %7" & ASCII.LF & ASCII.HT & "pslld $24, %7" & ASCII.LF & ASCII.HT & "psrld $31, %6" & ASCII.LF & ASCII.HT & "pslld $30, %6" & ASCII.LF & ASCII.HT & "por %7, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "cmpleps %0, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "addps %3, %3" & ASCII.LF & ASCII.HT & "cmpleps %0, %3" & ASCII.LF & ASCII.HT & "movdqa %0, %4" & ASCII.LF & ASCII.HT & "cmpunordps %4, %4" & ASCII.LF & ASCII.HT & "pxor %7, %7" & ASCII.LF & ASCII.HT & "movdqa %0, %5" & ASCII.LF & ASCII.HT & "cmpltps %7, %5" & ASCII.LF & ASCII.HT & "por %5, %4" & ASCII.LF & ASCII.HT & "movdqa %0, %1" & ASCII.LF & ASCII.HT & "cvttps2dq %1, %1" & ASCII.LF & ASCII.HT & "movdqa %0, %5" & ASCII.LF & ASCII.HT & "subps %6, %5" & ASCII.LF & ASCII.HT & "cvttps2dq %5, %5" & ASCII.LF & ASCII.HT & "pcmpeqd %7, %7" & ASCII.LF & ASCII.HT & "pslld $31, %7" & ASCII.LF & ASCII.HT & "paddd %7, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pand %5, %6" & ASCII.LF & ASCII.HT & "pandn %1, %2" & ASCII.LF & ASCII.HT & "por %6, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %6, %6" & ASCII.LF & ASCII.HT & "pand %3, %6" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %6, %3" & ASCII.LF & ASCII.HT & "pandn %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %0", "");
   function Convert_Truncate_Saturate (Value : F32x4) return U32x4 is (Native_Convert_Truncate_Saturate_F32x4_To_U32x4 (Value));
   function Native_Convert_Truncate_Saturate_F64x2_To_I64x2 is new SSE2_Convert_128_S2 (F64x2, I64x2, "movq %0, %%rax" & ASCII.LF & ASCII.HT & "cvttsd2siq %0, %%rcx" & ASCII.LF & ASCII.HT & "movq %%rax, %%r8" & ASCII.LF & ASCII.HT & "movabsq $0x7fffffffffffffff, %%rdx" & ASCII.LF & ASCII.HT & "andq %%rdx, %%r8" & ASCII.LF & ASCII.HT & "movabsq $0x7ff0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%r8" & ASCII.LF & ASCII.HT & "ja 1f" & ASCII.LF & ASCII.HT & "movabsq $0x8000000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rcx" & ASCII.LF & ASCII.HT & "jne 3f" & ASCII.LF & ASCII.HT & "testq %%rax, %%rax" & ASCII.LF & ASCII.HT & "js 3f" & ASCII.LF & ASCII.HT & "movabsq $0x7fffffffffffffff, %%rcx" & ASCII.LF & ASCII.HT & "jmp 3f" & ASCII.LF & ASCII.HT & "1:" & ASCII.LF & ASCII.HT & "xorq %%rcx, %%rcx" & ASCII.LF & ASCII.HT & "3:" & ASCII.LF & ASCII.HT & "movq %%rcx, %1" & ASCII.LF & ASCII.HT & "psrldq $8, %0" & ASCII.LF & ASCII.HT & "movq %0, %%rax" & ASCII.LF & ASCII.HT & "cvttsd2siq %0, %%rcx" & ASCII.LF & ASCII.HT & "movq %%rax, %%r8" & ASCII.LF & ASCII.HT & "movabsq $0x7fffffffffffffff, %%rdx" & ASCII.LF & ASCII.HT & "andq %%rdx, %%r8" & ASCII.LF & ASCII.HT & "movabsq $0x7ff0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%r8" & ASCII.LF & ASCII.HT & "ja 5f" & ASCII.LF & ASCII.HT & "movabsq $0x8000000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rcx" & ASCII.LF & ASCII.HT & "jne 7f" & ASCII.LF & ASCII.HT & "testq %%rax, %%rax" & ASCII.LF & ASCII.HT & "js 7f" & ASCII.LF & ASCII.HT & "movabsq $0x7fffffffffffffff, %%rcx" & ASCII.LF & ASCII.HT & "jmp 7f" & ASCII.LF & ASCII.HT & "5:" & ASCII.LF & ASCII.HT & "xorq %%rcx, %%rcx" & ASCII.LF & ASCII.HT & "7:" & ASCII.LF & ASCII.HT & "movq %%rcx, %2" & ASCII.LF & ASCII.HT & "punpcklqdq %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "r8,rax,rcx,rdx,cc");
   function Convert_Truncate_Saturate (Value : F64x2) return I64x2 is (Native_Convert_Truncate_Saturate_F64x2_To_I64x2 (Value));
   function Native_Convert_Truncate_Saturate_F64x2_To_U64x2 is new SSE2_Convert_128_S4 (F64x2, U64x2, "movq %0, %%rax" & ASCII.LF & ASCII.HT & "testq %%rax, %%rax" & ASCII.LF & ASCII.HT & "js 1f" & ASCII.LF & ASCII.HT & "movabsq $0x7ff0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rax" & ASCII.LF & ASCII.HT & "ja 1f" & ASCII.LF & ASCII.HT & "movabsq $0x43f0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rax" & ASCII.LF & ASCII.HT & "jae 2f" & ASCII.LF & ASCII.HT & "movabsq $0x43e0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rax" & ASCII.LF & ASCII.HT & "jae 3f" & ASCII.LF & ASCII.HT & "cvttsd2siq %0, %%rcx" & ASCII.LF & ASCII.HT & "jmp 4f" & ASCII.LF & ASCII.HT & "3:" & ASCII.LF & ASCII.HT & "movabsq $0x43e0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "movq %%rdx, %2" & ASCII.LF & ASCII.HT & "movapd %0, %1" & ASCII.LF & ASCII.HT & "subsd %2, %1" & ASCII.LF & ASCII.HT & "cvttsd2siq %1, %%rcx" & ASCII.LF & ASCII.HT & "movabsq $0x8000000000000000, %%rdx" & ASCII.LF & ASCII.HT & "orq %%rdx, %%rcx" & ASCII.LF & ASCII.HT & "jmp 4f" & ASCII.LF & ASCII.HT & "2:" & ASCII.LF & ASCII.HT & "movabsq $0xffffffffffffffff, %%rcx" & ASCII.LF & ASCII.HT & "jmp 4f" & ASCII.LF & ASCII.HT & "1:" & ASCII.LF & ASCII.HT & "xorq %%rcx, %%rcx" & ASCII.LF & ASCII.HT & "4:" & ASCII.LF & ASCII.HT & "movq %%rcx, %3" & ASCII.LF & ASCII.HT & "psrldq $8, %0" & ASCII.LF & ASCII.HT & "movq %0, %%rax" & ASCII.LF & ASCII.HT & "testq %%rax, %%rax" & ASCII.LF & ASCII.HT & "js 6f" & ASCII.LF & ASCII.HT & "movabsq $0x7ff0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rax" & ASCII.LF & ASCII.HT & "ja 6f" & ASCII.LF & ASCII.HT & "movabsq $0x43f0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rax" & ASCII.LF & ASCII.HT & "jae 7f" & ASCII.LF & ASCII.HT & "movabsq $0x43e0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "cmpq %%rdx, %%rax" & ASCII.LF & ASCII.HT & "jae 8f" & ASCII.LF & ASCII.HT & "cvttsd2siq %0, %%rcx" & ASCII.LF & ASCII.HT & "jmp 9f" & ASCII.LF & ASCII.HT & "8:" & ASCII.LF & ASCII.HT & "movabsq $0x43e0000000000000, %%rdx" & ASCII.LF & ASCII.HT & "movq %%rdx, %2" & ASCII.LF & ASCII.HT & "movapd %0, %1" & ASCII.LF & ASCII.HT & "subsd %2, %1" & ASCII.LF & ASCII.HT & "cvttsd2siq %1, %%rcx" & ASCII.LF & ASCII.HT & "movabsq $0x8000000000000000, %%rdx" & ASCII.LF & ASCII.HT & "orq %%rdx, %%rcx" & ASCII.LF & ASCII.HT & "jmp 9f" & ASCII.LF & ASCII.HT & "7:" & ASCII.LF & ASCII.HT & "movabsq $0xffffffffffffffff, %%rcx" & ASCII.LF & ASCII.HT & "jmp 9f" & ASCII.LF & ASCII.HT & "6:" & ASCII.LF & ASCII.HT & "xorq %%rcx, %%rcx" & ASCII.LF & ASCII.HT & "9:" & ASCII.LF & ASCII.HT & "movq %%rcx, %4" & ASCII.LF & ASCII.HT & "punpcklqdq %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "rax,rcx,rdx,cc");
   function Convert_Truncate_Saturate (Value : F64x2) return U64x2 is (Native_Convert_Truncate_Saturate_F64x2_To_U64x2 (Value));
   function Native_Convert_Saturate_I8x16_To_U8x16 is new SSE2_Convert_128_S1 (I8x16, U8x16, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtb %0, %1" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "");
   pragma Inline_Always (Native_Convert_Saturate_I8x16_To_U8x16);
   function Convert_Saturate (Value : I8x16) return U8x16 is (Native_Convert_Saturate_I8x16_To_U8x16 (Value));
   function Native_Convert_Saturate_U8x16_To_I8x16 is new SSE2_Convert_128_S3 (U8x16, I8x16, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtb %0, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psrlw $9, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %1" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Convert_Saturate (Value : U8x16) return I8x16 is (Native_Convert_Saturate_U8x16_To_I8x16 (Value));
   function Native_Convert_Saturate_I16x8_To_U16x8 is new SSE2_Convert_128_S1 (I16x8, U16x8, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtw %0, %1" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "");
   pragma Inline_Always (Native_Convert_Saturate_I16x8_To_U16x8);
   function Convert_Saturate (Value : I16x8) return U16x8 is (Native_Convert_Saturate_I16x8_To_U16x8 (Value));
   function Native_Convert_Saturate_U16x8_To_I16x8 is new SSE2_Convert_128_S3 (U16x8, I16x8, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtw %0, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psrlw $1, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %1" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Convert_Saturate (Value : U16x8) return I16x8 is (Native_Convert_Saturate_U16x8_To_I16x8 (Value));
   function Native_Convert_Saturate_I32x4_To_U32x4 is new SSE2_Convert_128_S1 (I32x4, U32x4, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtd %0, %1" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "");
   pragma Inline_Always (Native_Convert_Saturate_I32x4_To_U32x4);
   function Convert_Saturate (Value : I32x4) return U32x4 is (Native_Convert_Saturate_I32x4_To_U32x4 (Value));
   function Native_Convert_Saturate_U32x4_To_I32x4 is new SSE2_Convert_128_S3 (U32x4, I32x4, "pxor %1, %1" & ASCII.LF & ASCII.HT & "pcmpgtd %0, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psrld $1, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %1" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Convert_Saturate (Value : U32x4) return I32x4 is (Native_Convert_Saturate_U32x4_To_I32x4 (Value));
   function Native_Convert_Saturate_I64x2_To_U64x2 is new SSE2_Convert_128_S1 (I64x2, U64x2, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %1, %1" & ASCII.LF & ASCII.HT & "psrad $31, %1" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0", "");
   pragma Inline_Always (Native_Convert_Saturate_I64x2_To_U64x2);
   function Convert_Saturate (Value : I64x2) return U64x2 is (Native_Convert_Saturate_I64x2_To_U64x2 (Value));
   function Native_Convert_Saturate_U64x2_To_I64x2 is new SSE2_Convert_128_S3 (U64x2, I64x2, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %1, %1" & ASCII.LF & ASCII.HT & "psrad $31, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %1" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Convert_Saturate (Value : U64x2) return I64x2 is (Native_Convert_Saturate_U64x2_To_I64x2 (Value));
   function Native_Add_Wrap_U8x16 is new SSE2_Binary_128_S0 (U8x16, "paddb %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_U8x16);
   function Add_Wrap (Left, Right : U8x16) return U8x16 is (Native_Add_Wrap_U8x16 (Left, Right));
   function Native_Subtract_Wrap_U8x16 is new SSE2_Binary_128_S0 (U8x16, "psubb %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_U8x16);
   function Subtract_Wrap (Left, Right : U8x16) return U8x16 is (Native_Subtract_Wrap_U8x16 (Left, Right));
   function Native_Multiply_Wrap_U8x16 is new SSE2_Binary_128_S5 (U8x16, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "movdqu %7, %3" & ASCII.LF & ASCII.HT & "movdqu %7, %4" & ASCII.LF & ASCII.HT & "pxor %2, %2" & ASCII.LF & ASCII.HT & "punpcklbw %2, %0" & ASCII.LF & ASCII.HT & "punpckhbw %2, %1" & ASCII.LF & ASCII.HT & "punpcklbw %2, %3" & ASCII.LF & ASCII.HT & "punpckhbw %2, %4" & ASCII.LF & ASCII.HT & "pmullw %3, %0" & ASCII.LF & ASCII.HT & "pmullw %4, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrlw $8, %5" & ASCII.LF & ASCII.HT & "pand %5, %0" & ASCII.LF & ASCII.HT & "pand %5, %1" & ASCII.LF & ASCII.HT & "packuswb %1, %0", "");
   function Multiply_Wrap (Left, Right : U8x16) return U8x16 is (Native_Multiply_Wrap_U8x16 (Left, Right));
   function Native_Bitwise_And_U8x16 is new SSE2_Binary_128_S0 (U8x16, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_U8x16);
   function Bitwise_And (Left, Right : U8x16) return U8x16 is (Native_Bitwise_And_U8x16 (Left, Right));
   function Native_Bitwise_Or_U8x16 is new SSE2_Binary_128_S0 (U8x16, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_U8x16);
   function Bitwise_Or (Left, Right : U8x16) return U8x16 is (Native_Bitwise_Or_U8x16 (Left, Right));
   function Native_Bitwise_Xor_U8x16 is new SSE2_Binary_128_S0 (U8x16, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_U8x16);
   function Bitwise_Xor (Left, Right : U8x16) return U8x16 is (Native_Bitwise_Xor_U8x16 (Left, Right));
   function Native_Interleave_Low_U8x16 is new SSE2_Binary_128_S0 (U8x16, "punpcklbw %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_U8x16);
   function Interleave_Low (Left, Right : U8x16) return U8x16 is (Native_Interleave_Low_U8x16 (Left, Right));
   function Native_Interleave_High_U8x16 is new SSE2_Binary_128_S0 (U8x16, "punpckhbw %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_U8x16);
   function Interleave_High (Left, Right : U8x16) return U8x16 is (Native_Interleave_High_U8x16 (Left, Right));
   function Native_Deinterleave_Even_U8x16 is new SSE2_Binary_128_S2 (U8x16, "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pand %1, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_U8x16);
   function Deinterleave_Even (Left, Right : U8x16) return U8x16 is (Native_Deinterleave_Even_U8x16 (Left, Right));
   function Native_Deinterleave_Odd_U8x16 is new SSE2_Binary_128_S1 (U8x16, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %0" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "packuswb %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_U8x16);
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16 is (Native_Deinterleave_Odd_U8x16 (Left, Right));
   function Native_Add_Saturate_U8x16 is new SSE2_Binary_128_S0 (U8x16, "paddusb %2, %0", "");
   pragma Inline_Always (Native_Add_Saturate_U8x16);
   function Add_Saturate (Left, Right : U8x16) return U8x16 is (Native_Add_Saturate_U8x16 (Left, Right));
   function Native_Subtract_Saturate_U8x16 is new SSE2_Binary_128_S0 (U8x16, "psubusb %2, %0", "");
   pragma Inline_Always (Native_Subtract_Saturate_U8x16);
   function Subtract_Saturate (Left, Right : U8x16) return U8x16 is (Native_Subtract_Saturate_U8x16 (Left, Right));
   function Native_Min_U8x16 is new SSE2_Binary_128_S0 (U8x16, "pminub %2, %0", "");
   pragma Inline_Always (Native_Min_U8x16);
   function Min (Left, Right : U8x16) return U8x16 is (Native_Min_U8x16 (Left, Right));
   function Native_Max_U8x16 is new SSE2_Binary_128_S0 (U8x16, "pmaxub %2, %0", "");
   pragma Inline_Always (Native_Max_U8x16);
   function Max (Left, Right : U8x16) return U8x16 is (Native_Max_U8x16 (Left, Right));
   function Native_Not_U8x16 is new SSE2_Unary_128_S1 (U8x16, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_U8x16);
   function Bitwise_Not (Value : U8x16) return U8x16 is (Native_Not_U8x16 (Value));
   function Native_Reverse_U8x16 is new SSE2_Unary_128_S1 (U8x16, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %0" & ASCII.LF & ASCII.HT & "psllw $8, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_U8x16);
   function Reverse_Lanes (Value : U8x16) return U8x16 is (Native_Reverse_U8x16 (Value));
   function Compare_Equal_U8x16 is new SSE2_Compare_128 (U8x16, 8, "pcmpeqb %2, %1");
   pragma Inline_Always (Compare_Equal_U8x16);
   function Compare_Greater_U8x16 is new SSE2_Compare_128 (U8x16, 8, "pxor %9, %1" & ASCII.LF & ASCII.HT & "pxor %9, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1");
   pragma Inline_Always (Compare_Greater_U8x16);
   function Native_Select_U8x16 is new SSE2_Select_128 (U8x16, 8);
   pragma Inline_Always (Native_Select_U8x16);
   function Native_Zero_U8x16 is new SSE2_Zero_128 (U8x16);
   pragma Inline_Always (Native_Zero_U8x16);
   function Zero return U8x16 is (Native_Zero_U8x16);
   function Native_Splat_U8x16 is new SSE2_Splat_Integer_128 (U8x16, U8, "movzbl %b2, %k1" & ASCII.LF & ASCII.HT & "imull $0x01010101, %k1, %k1" & ASCII.LF & ASCII.HT & "movd %k1, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0");
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
   function Native_Permute_U8x16 is new SSE2_Permute_128 (U8x16, Lane_Map_8x16, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : U8x16; Map : Lane_Map_8x16) return U8x16 is (Native_Permute_U8x16 (Value, Map));
   function Native_Permute_2_U8x16 is new SSE2_Permute_2_128 (U8x16, Two_Source_Lane_Map_8x16, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_U8x16 is new SSE2_Shift_128 (U8x16, "movdqu %0, %2" & ASCII.LF & ASCII.HT & "pxor %3, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %0" & ASCII.LF & ASCII.HT & "punpckhbw %3, %2" & ASCII.LF & ASCII.HT & "psllw %1, %0" & ASCII.LF & ASCII.HT & "psllw %1, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlw $8, %3" & ASCII.LF & ASCII.HT & "pand %3, %0" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0");
   function Native_SHR_U8x16 is new SSE2_Shift_128 (U8x16, "movdqu %0, %2" & ASCII.LF & ASCII.HT & "pxor %3, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %0" & ASCII.LF & ASCII.HT & "punpckhbw %3, %2" & ASCII.LF & ASCII.HT & "psrlw %1, %0" & ASCII.LF & ASCII.HT & "psrlw %1, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0");
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16 is (Native_SHL_U8x16 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 8))));
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16 is (Native_SHR_U8x16 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 8))));
   function Equal (Left, Right : U8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Equal_U8x16 (Left, Right, Sign_Vector_8)));
   function Greater_Than (Left, Right : U8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_U8x16 (Left, Right, Sign_Vector_8)));
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_U8x16 (Left, Right, Sign_Vector_8) or Compare_Equal_U8x16 (Left, Right, Sign_Vector_8)));
   function Less_Than (Left, Right : U8x16) return Mask_8x16 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U8x16) return Mask_8x16 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16 is (Native_Select_U8x16 (To_Bit_Mask (Mask), Weights_X86_Vector_8, If_True, If_False));
   function Native_Reduce_Add_Wrap_U8x16 is new SSE2_Integer_Reduce_128_S2 (U8x16, U8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $2, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $1, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1", "movd %1, %k0" & ASCII.LF & ASCII.HT & "movzbl %b0, %k0");
   function Reduce_Add_Wrap (Value : U8x16) return U8 is (Native_Reduce_Add_Wrap_U8x16 (Value));
   function Native_Reduce_Min_U8x16 is new SSE2_Integer_Reduce_128_S4 (U8x16, U8, "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %4, %2" & ASCII.LF & ASCII.HT & "pminub %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %4, %2" & ASCII.LF & ASCII.HT & "pminub %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pminub %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %3" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "psllw $8, %3" & ASCII.LF & ASCII.HT & "por %3, %2" & ASCII.LF & ASCII.HT & "pminub %2, %1", "movd %1, %k0" & ASCII.LF & ASCII.HT & "movzbl %b0, %k0");
   function Reduce_Min (Value : U8x16) return U8 is (Native_Reduce_Min_U8x16 (Value));
   function Native_Reduce_Max_U8x16 is new SSE2_Integer_Reduce_128_S4 (U8x16, U8, "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %4, %2" & ASCII.LF & ASCII.HT & "pmaxub %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %4, %2" & ASCII.LF & ASCII.HT & "pmaxub %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pmaxub %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %3" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "psllw $8, %3" & ASCII.LF & ASCII.HT & "por %3, %2" & ASCII.LF & ASCII.HT & "pmaxub %2, %1", "movd %1, %k0" & ASCII.LF & ASCII.HT & "movzbl %b0, %k0");
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_8x16'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
      function To_Machine is new Ada.Unchecked_Conversion (U8x16, Machine_Vector);
      Target : Lane_Values_8x16 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_8x16'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U8x16);
      Source : constant Lane_Values_8x16 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_8x16'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
      function To_Machine is new Ada.Unchecked_Conversion (U8x16, Machine_Vector);
      Target : Lane_Values_8x16 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_8x16'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
      Sums : Machine_Vector;
      Upper : Machine_Vector;
   begin
      Asm
        (Template =>
           "movdqa %3, %1" & ASCII.LF & ASCII.HT &
                   "pxor %2, %2" & ASCII.LF & ASCII.HT &
                   "psadbw %2, %1" & ASCII.LF & ASCII.HT &
                   "movhlps %1, %2" & ASCII.LF & ASCII.HT &
                   "paddq %2, %1" & ASCII.LF & ASCII.HT &
                   "movd %1, %0",
         Outputs => [Interfaces.Unsigned_32'Asm_Output ("=r", Result), Machine_Vector'Asm_Output ("=&x", Sums), Machine_Vector'Asm_Output ("=&x", Upper)],
         Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
      return Natural (Result);
   end Horizontal_Sum;
   function Reverse_Bytes (Value : U8x16) return U8x16 is (Reverse_Lanes (Value));
   function Native_Add_Wrap_I8x16 is new SSE2_Binary_128_S0 (I8x16, "paddb %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_I8x16);
   function Add_Wrap (Left, Right : I8x16) return I8x16 is (Native_Add_Wrap_I8x16 (Left, Right));
   function Native_Subtract_Wrap_I8x16 is new SSE2_Binary_128_S0 (I8x16, "psubb %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_I8x16);
   function Subtract_Wrap (Left, Right : I8x16) return I8x16 is (Native_Subtract_Wrap_I8x16 (Left, Right));
   function Native_Multiply_Wrap_I8x16 is new SSE2_Binary_128_S5 (I8x16, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "movdqu %7, %3" & ASCII.LF & ASCII.HT & "movdqu %7, %4" & ASCII.LF & ASCII.HT & "pxor %2, %2" & ASCII.LF & ASCII.HT & "punpcklbw %2, %0" & ASCII.LF & ASCII.HT & "punpckhbw %2, %1" & ASCII.LF & ASCII.HT & "punpcklbw %2, %3" & ASCII.LF & ASCII.HT & "punpckhbw %2, %4" & ASCII.LF & ASCII.HT & "pmullw %3, %0" & ASCII.LF & ASCII.HT & "pmullw %4, %1" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrlw $8, %5" & ASCII.LF & ASCII.HT & "pand %5, %0" & ASCII.LF & ASCII.HT & "pand %5, %1" & ASCII.LF & ASCII.HT & "packuswb %1, %0", "");
   function Multiply_Wrap (Left, Right : I8x16) return I8x16 is (Native_Multiply_Wrap_I8x16 (Left, Right));
   function Native_Bitwise_And_I8x16 is new SSE2_Binary_128_S0 (I8x16, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_I8x16);
   function Bitwise_And (Left, Right : I8x16) return I8x16 is (Native_Bitwise_And_I8x16 (Left, Right));
   function Native_Bitwise_Or_I8x16 is new SSE2_Binary_128_S0 (I8x16, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_I8x16);
   function Bitwise_Or (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Or_I8x16 (Left, Right));
   function Native_Bitwise_Xor_I8x16 is new SSE2_Binary_128_S0 (I8x16, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_I8x16);
   function Bitwise_Xor (Left, Right : I8x16) return I8x16 is (Native_Bitwise_Xor_I8x16 (Left, Right));
   function Native_Interleave_Low_I8x16 is new SSE2_Binary_128_S0 (I8x16, "punpcklbw %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_I8x16);
   function Interleave_Low (Left, Right : I8x16) return I8x16 is (Native_Interleave_Low_I8x16 (Left, Right));
   function Native_Interleave_High_I8x16 is new SSE2_Binary_128_S0 (I8x16, "punpckhbw %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_I8x16);
   function Interleave_High (Left, Right : I8x16) return I8x16 is (Native_Interleave_High_I8x16 (Left, Right));
   function Native_Deinterleave_Even_I8x16 is new SSE2_Binary_128_S2 (I8x16, "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "pand %1, %0" & ASCII.LF & ASCII.HT & "pand %1, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_I8x16);
   function Deinterleave_Even (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Even_I8x16 (Left, Right));
   function Native_Deinterleave_Odd_I8x16 is new SSE2_Binary_128_S1 (I8x16, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %0" & ASCII.LF & ASCII.HT & "psrlw $8, %1" & ASCII.LF & ASCII.HT & "packuswb %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_I8x16);
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16 is (Native_Deinterleave_Odd_I8x16 (Left, Right));
   function Native_Add_Saturate_I8x16 is new SSE2_Binary_128_S0 (I8x16, "paddsb %2, %0", "");
   pragma Inline_Always (Native_Add_Saturate_I8x16);
   function Add_Saturate (Left, Right : I8x16) return I8x16 is (Native_Add_Saturate_I8x16 (Left, Right));
   function Native_Subtract_Saturate_I8x16 is new SSE2_Binary_128_S0 (I8x16, "psubsb %2, %0", "");
   pragma Inline_Always (Native_Subtract_Saturate_I8x16);
   function Subtract_Saturate (Left, Right : I8x16) return I8x16 is (Native_Subtract_Saturate_I8x16 (Left, Right));
   function Native_Not_I8x16 is new SSE2_Unary_128_S1 (I8x16, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_I8x16);
   function Bitwise_Not (Value : I8x16) return I8x16 is (Native_Not_I8x16 (Value));
   function Native_Reverse_I8x16 is new SSE2_Unary_128_S1 (I8x16, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "psrlw $8, %0" & ASCII.LF & ASCII.HT & "psllw $8, %1" & ASCII.LF & ASCII.HT & "por %1, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_I8x16);
   function Reverse_Lanes (Value : I8x16) return I8x16 is (Native_Reverse_I8x16 (Value));
   function Compare_Equal_I8x16 is new SSE2_Compare_128 (I8x16, 8, "pcmpeqb %2, %1");
   pragma Inline_Always (Compare_Equal_I8x16);
   function Compare_Greater_I8x16 is new SSE2_Compare_128 (I8x16, 8, "pcmpgtb %2, %1");
   pragma Inline_Always (Compare_Greater_I8x16);
   function Native_Select_I8x16 is new SSE2_Select_128 (I8x16, 8);
   pragma Inline_Always (Native_Select_I8x16);
   function Native_Zero_I8x16 is new SSE2_Zero_128 (I8x16);
   pragma Inline_Always (Native_Zero_I8x16);
   function Zero return I8x16 is (Native_Zero_I8x16);
   function Native_Splat_I8x16 is new SSE2_Splat_Integer_128 (I8x16, I8, "movzbl %b2, %k1" & ASCII.LF & ASCII.HT & "imull $0x01010101, %k1, %k1" & ASCII.LF & ASCII.HT & "movd %k1, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0");
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
   function Native_Permute_I8x16 is new SSE2_Permute_128 (I8x16, Lane_Map_8x16, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : I8x16; Map : Lane_Map_8x16) return I8x16 is (Native_Permute_I8x16 (Value, Map));
   function Native_Permute_2_I8x16 is new SSE2_Permute_2_128 (I8x16, Two_Source_Lane_Map_8x16, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_I8x16 is new SSE2_Shift_128 (I8x16, "movdqu %0, %2" & ASCII.LF & ASCII.HT & "pxor %3, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %0" & ASCII.LF & ASCII.HT & "punpckhbw %3, %2" & ASCII.LF & ASCII.HT & "psllw %1, %0" & ASCII.LF & ASCII.HT & "psllw %1, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlw $8, %3" & ASCII.LF & ASCII.HT & "pand %3, %0" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0");
   function Native_SHR_I8x16 is new SSE2_Shift_128 (I8x16, "movdqu %0, %2" & ASCII.LF & ASCII.HT & "pxor %3, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %0" & ASCII.LF & ASCII.HT & "punpckhbw %3, %2" & ASCII.LF & ASCII.HT & "psrlw %1, %0" & ASCII.LF & ASCII.HT & "psrlw %1, %2" & ASCII.LF & ASCII.HT & "packuswb %2, %0");
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16 is (Native_SHL_I8x16 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 8))));
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16 is (Native_SHR_I8x16 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 8))));
   function Native_SAR_I8x16 is new SSE2_Shift_128 (I8x16, "movdqu %0, %2" & ASCII.LF & ASCII.HT & "pxor %3, %3" & ASCII.LF & ASCII.HT & "punpcklbw %3, %0" & ASCII.LF & ASCII.HT & "punpckhbw %3, %2" & ASCII.LF & ASCII.HT & "psllw $8, %0" & ASCII.LF & ASCII.HT & "psllw $8, %2" & ASCII.LF & ASCII.HT & "psraw $8, %0" & ASCII.LF & ASCII.HT & "psraw $8, %2" & ASCII.LF & ASCII.HT & "psraw %1, %0" & ASCII.LF & ASCII.HT & "psraw %1, %2" & ASCII.LF & ASCII.HT & "packsswb %2, %0");
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16 is (Native_SAR_I8x16 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 8))));
   function Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Equal_I8x16 (Left, Right, Sign_Vector_8)));
   function Greater_Than (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_I8x16 (Left, Right, Sign_Vector_8)));
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16 is (Mask_From_Bit_Mask (Compare_Greater_I8x16 (Left, Right, Sign_Vector_8) or Compare_Equal_I8x16 (Left, Right, Sign_Vector_8)));
   function Less_Than (Left, Right : I8x16) return Mask_8x16 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I8x16) return Mask_8x16 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16 is (Native_Select_I8x16 (To_Bit_Mask (Mask), Weights_X86_Vector_8, If_True, If_False));
   function Min (Left, Right : I8x16) return I8x16 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : I8x16) return I8x16 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Native_Reduce_Add_Wrap_I8x16 is new SSE2_Integer_Reduce_128_S2 (I8x16, I8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $2, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $1, %2" & ASCII.LF & ASCII.HT & "paddb %2, %1", "movd %1, %k0" & ASCII.LF & ASCII.HT & "movzbl %b0, %k0");
   function Reduce_Add_Wrap (Value : I8x16) return I8 is (Native_Reduce_Add_Wrap_I8x16 (Value));
   function Native_Reduce_Min_I8x16 is new SSE2_Integer_Reduce_128_S6 (I8x16, I8, "movdqa %7, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %6, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %6, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %4" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "psllw $8, %4" & ASCII.LF & ASCII.HT & "por %4, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %4" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "psllw $8, %4" & ASCII.LF & ASCII.HT & "por %4, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movd %1, %k0" & ASCII.LF & ASCII.HT & "movzbl %b0, %k0");
   function Reduce_Min (Value : I8x16) return I8 is (Native_Reduce_Min_I8x16 (Value));
   function Native_Reduce_Max_I8x16 is new SSE2_Integer_Reduce_128_S6 (I8x16, I8, "movdqa %7, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %6, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %6, %2" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %4" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "psllw $8, %4" & ASCII.LF & ASCII.HT & "por %4, %2" & ASCII.LF & ASCII.HT & "pcmpgtb %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %4" & ASCII.LF & ASCII.HT & "psrlw $8, %2" & ASCII.LF & ASCII.HT & "psllw $8, %4" & ASCII.LF & ASCII.HT & "por %4, %2" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movd %1, %k0" & ASCII.LF & ASCII.HT & "movzbl %b0, %k0");
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I8x16'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
      function To_Machine is new Ada.Unchecked_Conversion (I8x16, Machine_Vector);
      Target : Lane_Values_I8x16 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_I8x16'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I8x16);
      Source : constant Lane_Values_I8x16 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I8x16'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) is
      function To_Machine is new Ada.Unchecked_Conversion (I8x16, Machine_Vector);
      Target : Lane_Values_I8x16 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_I8x16'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_Wrap_U16x8 is new SSE2_Binary_128_S0 (U16x8, "paddw %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_U16x8);
   function Add_Wrap (Left, Right : U16x8) return U16x8 is (Native_Add_Wrap_U16x8 (Left, Right));
   function Native_Subtract_Wrap_U16x8 is new SSE2_Binary_128_S0 (U16x8, "psubw %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_U16x8);
   function Subtract_Wrap (Left, Right : U16x8) return U16x8 is (Native_Subtract_Wrap_U16x8 (Left, Right));
   function Native_Multiply_Wrap_U16x8 is new SSE2_Binary_128_S0 (U16x8, "pmullw %2, %0", "");
   pragma Inline_Always (Native_Multiply_Wrap_U16x8);
   function Multiply_Wrap (Left, Right : U16x8) return U16x8 is (Native_Multiply_Wrap_U16x8 (Left, Right));
   function Native_Bitwise_And_U16x8 is new SSE2_Binary_128_S0 (U16x8, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_U16x8);
   function Bitwise_And (Left, Right : U16x8) return U16x8 is (Native_Bitwise_And_U16x8 (Left, Right));
   function Native_Bitwise_Or_U16x8 is new SSE2_Binary_128_S0 (U16x8, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_U16x8);
   function Bitwise_Or (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Or_U16x8 (Left, Right));
   function Native_Bitwise_Xor_U16x8 is new SSE2_Binary_128_S0 (U16x8, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_U16x8);
   function Bitwise_Xor (Left, Right : U16x8) return U16x8 is (Native_Bitwise_Xor_U16x8 (Left, Right));
   function Native_Interleave_Low_U16x8 is new SSE2_Binary_128_S0 (U16x8, "punpcklwd %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_U16x8);
   function Interleave_Low (Left, Right : U16x8) return U16x8 is (Native_Interleave_Low_U16x8 (Left, Right));
   function Native_Interleave_High_U16x8 is new SSE2_Binary_128_S0 (U16x8, "punpckhwd %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_U16x8);
   function Interleave_High (Left, Right : U16x8) return U16x8 is (Native_Interleave_High_U16x8 (Left, Right));
   function Native_Deinterleave_Even_U16x8 is new SSE2_Binary_128_S1 (U16x8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_U16x8);
   function Deinterleave_Even (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Even_U16x8 (Left, Right));
   function Native_Deinterleave_Odd_U16x8 is new SSE2_Binary_128_S1 (U16x8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshuflw $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_U16x8);
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8 is (Native_Deinterleave_Odd_U16x8 (Left, Right));
   function Native_Add_Saturate_U16x8 is new SSE2_Binary_128_S0 (U16x8, "paddusw %2, %0", "");
   pragma Inline_Always (Native_Add_Saturate_U16x8);
   function Add_Saturate (Left, Right : U16x8) return U16x8 is (Native_Add_Saturate_U16x8 (Left, Right));
   function Native_Subtract_Saturate_U16x8 is new SSE2_Binary_128_S0 (U16x8, "psubusw %2, %0", "");
   pragma Inline_Always (Native_Subtract_Saturate_U16x8);
   function Subtract_Saturate (Left, Right : U16x8) return U16x8 is (Native_Subtract_Saturate_U16x8 (Left, Right));
   function Native_Not_U16x8 is new SSE2_Unary_128_S1 (U16x8, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_U16x8);
   function Bitwise_Not (Value : U16x8) return U16x8 is (Native_Not_U16x8 (Value));
   function Native_Reverse_U16x8 is new SSE2_Unary_128_S0 (U16x8, "pshuflw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_U16x8);
   function Reverse_Lanes (Value : U16x8) return U16x8 is (Native_Reverse_U16x8 (Value));
   function Compare_Equal_U16x8 is new SSE2_Compare_128 (U16x8, 16, "pcmpeqw %2, %1");
   pragma Inline_Always (Compare_Equal_U16x8);
   function Compare_Greater_U16x8 is new SSE2_Compare_128 (U16x8, 16, "pxor %9, %1" & ASCII.LF & ASCII.HT & "pxor %9, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1");
   pragma Inline_Always (Compare_Greater_U16x8);
   function Native_Select_U16x8 is new SSE2_Select_128 (U16x8, 16);
   pragma Inline_Always (Native_Select_U16x8);
   function Native_Zero_U16x8 is new SSE2_Zero_128 (U16x8);
   pragma Inline_Always (Native_Zero_U16x8);
   function Zero return U16x8 is (Native_Zero_U16x8);
   function Native_Splat_U16x8 is new SSE2_Splat_Integer_128 (U16x8, U16, "movzwl %w2, %k1" & ASCII.LF & ASCII.HT & "imull $0x00010001, %k1, %k1" & ASCII.LF & ASCII.HT & "movd %k1, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0");
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
   function Native_Permute_U16x8 is new SSE2_Permute_128 (U16x8, Lane_Map_16x8, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : U16x8; Map : Lane_Map_16x8) return U16x8 is (Native_Permute_U16x8 (Value, Map));
   function Native_Permute_2_U16x8 is new SSE2_Permute_2_128 (U16x8, Two_Source_Lane_Map_16x8, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_U16x8 is new SSE2_Shift_128 (U16x8, "psllw %1, %0");
   function Native_SHR_U16x8 is new SSE2_Shift_128 (U16x8, "psrlw %1, %0");
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8 is (Native_SHL_U16x8 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 16))));
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8 is (Native_SHR_U16x8 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 16))));
   function Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_U16x8 (Left, Right, Sign_Vector_16))));
   function Greater_Than (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U16x8 (Left, Right, Sign_Vector_16))));
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U16x8 (Left, Right, Sign_Vector_16) or Compare_Equal_U16x8 (Left, Right, Sign_Vector_16))));
   function Less_Than (Left, Right : U16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8 is (Native_Select_U16x8 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_16, If_True, If_False));
   function Min (Left, Right : U16x8) return U16x8 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : U16x8) return U16x8 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Native_Reduce_Add_Wrap_U16x8 is new SSE2_Integer_Reduce_128_S2 (U16x8, U16, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "paddw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $2, %2" & ASCII.LF & ASCII.HT & "paddw %2, %1", "pextrw $0, %1, %k0");
   function Reduce_Add_Wrap (Value : U16x8) return U16 is (Native_Reduce_Add_Wrap_U16x8 (Value));
   function Native_Reduce_Min_U16x8 is new SSE2_Integer_Reduce_128_S5_Sign (U16x8, U16, "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "pextrw $0, %1, %k0");
   function Reduce_Min (Value : U16x8) return U16 is (Native_Reduce_Min_U16x8 (Value, Sign_Vector_16));
   function Native_Reduce_Max_U16x8 is new SSE2_Integer_Reduce_128_S5_Sign (U16x8, U16, "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "pextrw $0, %1, %k0");
   function Reduce_Max (Value : U16x8) return U16 is (Native_Reduce_Max_U16x8 (Value, Sign_Vector_16));
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_U16x8'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
      function To_Machine is new Ada.Unchecked_Conversion (U16x8, Machine_Vector);
      Target : Lane_Values_U16x8 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_U16x8'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U16x8);
      Source : constant Lane_Values_U16x8 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_U16x8'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) is
      function To_Machine is new Ada.Unchecked_Conversion (U16x8, Machine_Vector);
      Target : Lane_Values_U16x8 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_U16x8'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_Wrap_I16x8 is new SSE2_Binary_128_S0 (I16x8, "paddw %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_I16x8);
   function Add_Wrap (Left, Right : I16x8) return I16x8 is (Native_Add_Wrap_I16x8 (Left, Right));
   function Native_Subtract_Wrap_I16x8 is new SSE2_Binary_128_S0 (I16x8, "psubw %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_I16x8);
   function Subtract_Wrap (Left, Right : I16x8) return I16x8 is (Native_Subtract_Wrap_I16x8 (Left, Right));
   function Native_Multiply_Wrap_I16x8 is new SSE2_Binary_128_S0 (I16x8, "pmullw %2, %0", "");
   pragma Inline_Always (Native_Multiply_Wrap_I16x8);
   function Multiply_Wrap (Left, Right : I16x8) return I16x8 is (Native_Multiply_Wrap_I16x8 (Left, Right));
   function Native_Bitwise_And_I16x8 is new SSE2_Binary_128_S0 (I16x8, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_I16x8);
   function Bitwise_And (Left, Right : I16x8) return I16x8 is (Native_Bitwise_And_I16x8 (Left, Right));
   function Native_Bitwise_Or_I16x8 is new SSE2_Binary_128_S0 (I16x8, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_I16x8);
   function Bitwise_Or (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Or_I16x8 (Left, Right));
   function Native_Bitwise_Xor_I16x8 is new SSE2_Binary_128_S0 (I16x8, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_I16x8);
   function Bitwise_Xor (Left, Right : I16x8) return I16x8 is (Native_Bitwise_Xor_I16x8 (Left, Right));
   function Native_Interleave_Low_I16x8 is new SSE2_Binary_128_S0 (I16x8, "punpcklwd %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_I16x8);
   function Interleave_Low (Left, Right : I16x8) return I16x8 is (Native_Interleave_Low_I16x8 (Left, Right));
   function Native_Interleave_High_I16x8 is new SSE2_Binary_128_S0 (I16x8, "punpckhwd %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_I16x8);
   function Interleave_High (Left, Right : I16x8) return I16x8 is (Native_Interleave_High_I16x8 (Left, Right));
   function Native_Deinterleave_Even_I16x8 is new SSE2_Binary_128_S1 (I16x8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufhw $0x88, %1, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_I16x8);
   function Deinterleave_Even (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Even_I16x8 (Left, Right));
   function Native_Deinterleave_Odd_I16x8 is new SSE2_Binary_128_S1 (I16x8, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshuflw $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshuflw $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "pshufhw $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_I16x8);
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8 is (Native_Deinterleave_Odd_I16x8 (Left, Right));
   function Native_Add_Saturate_I16x8 is new SSE2_Binary_128_S0 (I16x8, "paddsw %2, %0", "");
   pragma Inline_Always (Native_Add_Saturate_I16x8);
   function Add_Saturate (Left, Right : I16x8) return I16x8 is (Native_Add_Saturate_I16x8 (Left, Right));
   function Native_Subtract_Saturate_I16x8 is new SSE2_Binary_128_S0 (I16x8, "psubsw %2, %0", "");
   pragma Inline_Always (Native_Subtract_Saturate_I16x8);
   function Subtract_Saturate (Left, Right : I16x8) return I16x8 is (Native_Subtract_Saturate_I16x8 (Left, Right));
   function Native_Min_I16x8 is new SSE2_Binary_128_S0 (I16x8, "pminsw %2, %0", "");
   pragma Inline_Always (Native_Min_I16x8);
   function Min (Left, Right : I16x8) return I16x8 is (Native_Min_I16x8 (Left, Right));
   function Native_Max_I16x8 is new SSE2_Binary_128_S0 (I16x8, "pmaxsw %2, %0", "");
   pragma Inline_Always (Native_Max_I16x8);
   function Max (Left, Right : I16x8) return I16x8 is (Native_Max_I16x8 (Left, Right));
   function Native_Not_I16x8 is new SSE2_Unary_128_S1 (I16x8, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_I16x8);
   function Bitwise_Not (Value : I16x8) return I16x8 is (Native_Not_I16x8 (Value));
   function Native_Reverse_I16x8 is new SSE2_Unary_128_S0 (I16x8, "pshuflw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufhw $0x1B, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_I16x8);
   function Reverse_Lanes (Value : I16x8) return I16x8 is (Native_Reverse_I16x8 (Value));
   function Compare_Equal_I16x8 is new SSE2_Compare_128 (I16x8, 16, "pcmpeqw %2, %1");
   pragma Inline_Always (Compare_Equal_I16x8);
   function Compare_Greater_I16x8 is new SSE2_Compare_128 (I16x8, 16, "pcmpgtw %2, %1");
   pragma Inline_Always (Compare_Greater_I16x8);
   function Native_Select_I16x8 is new SSE2_Select_128 (I16x8, 16);
   pragma Inline_Always (Native_Select_I16x8);
   function Native_Zero_I16x8 is new SSE2_Zero_128 (I16x8);
   pragma Inline_Always (Native_Zero_I16x8);
   function Zero return I16x8 is (Native_Zero_I16x8);
   function Native_Splat_I16x8 is new SSE2_Splat_Integer_128 (I16x8, I16, "movzwl %w2, %k1" & ASCII.LF & ASCII.HT & "imull $0x00010001, %k1, %k1" & ASCII.LF & ASCII.HT & "movd %k1, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0");
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
   function Native_Permute_I16x8 is new SSE2_Permute_128 (I16x8, Lane_Map_16x8, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : I16x8; Map : Lane_Map_16x8) return I16x8 is (Native_Permute_I16x8 (Value, Map));
   function Native_Permute_2_I16x8 is new SSE2_Permute_2_128 (I16x8, Two_Source_Lane_Map_16x8, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_I16x8 is new SSE2_Shift_128 (I16x8, "psllw %1, %0");
   function Native_SHR_I16x8 is new SSE2_Shift_128 (I16x8, "psrlw %1, %0");
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8 is (Native_SHL_I16x8 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 16))));
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8 is (Native_SHR_I16x8 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 16))));
   function Native_SAR_I16x8 is new SSE2_Shift_128 (I16x8, "psraw %1, %0");
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8 is (Native_SAR_I16x8 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 16))));
   function Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_I16x8 (Left, Right, Sign_Vector_16))));
   function Greater_Than (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I16x8 (Left, Right, Sign_Vector_16))));
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I16x8 (Left, Right, Sign_Vector_16) or Compare_Equal_I16x8 (Left, Right, Sign_Vector_16))));
   function Less_Than (Left, Right : I16x8) return Mask_16x8 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I16x8) return Mask_16x8 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8 is (Native_Select_I16x8 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_16, If_True, If_False));
   function Native_Reduce_Add_Wrap_I16x8 is new SSE2_Integer_Reduce_128_S2 (I16x8, I16, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "paddw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $2, %2" & ASCII.LF & ASCII.HT & "paddw %2, %1", "pextrw $0, %1, %k0");
   function Reduce_Add_Wrap (Value : I16x8) return I16 is (Native_Reduce_Add_Wrap_I16x8 (Value));
   function Native_Reduce_Min_I16x8 is new SSE2_Integer_Reduce_128_S3 (I16x8, I16, "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %3, %2" & ASCII.LF & ASCII.HT & "pminsw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %3, %2" & ASCII.LF & ASCII.HT & "pminsw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pminsw %2, %1", "pextrw $0, %1, %k0");
   function Reduce_Min (Value : I16x8) return I16 is (Native_Reduce_Min_I16x8 (Value));
   function Native_Reduce_Max_I16x8 is new SSE2_Integer_Reduce_128_S3 (I16x8, I16, "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %3, %2" & ASCII.LF & ASCII.HT & "pmaxsw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %3, %2" & ASCII.LF & ASCII.HT & "pmaxsw %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "pshuflw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pshufhw $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "pmaxsw %2, %1", "pextrw $0, %1, %k0");
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I16x8'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
      function To_Machine is new Ada.Unchecked_Conversion (I16x8, Machine_Vector);
      Target : Lane_Values_I16x8 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_I16x8'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I16x8);
      Source : constant Lane_Values_I16x8 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I16x8'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) is
      function To_Machine is new Ada.Unchecked_Conversion (I16x8, Machine_Vector);
      Target : Lane_Values_I16x8 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_I16x8'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_Wrap_U32x4 is new SSE2_Binary_128_S0 (U32x4, "paddd %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_U32x4);
   function Add_Wrap (Left, Right : U32x4) return U32x4 is (Native_Add_Wrap_U32x4 (Left, Right));
   function Native_Subtract_Wrap_U32x4 is new SSE2_Binary_128_S0 (U32x4, "psubd %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_U32x4);
   function Subtract_Wrap (Left, Right : U32x4) return U32x4 is (Native_Subtract_Wrap_U32x4 (Left, Right));
   function Native_Multiply_Wrap_U32x4 is new SSE2_Binary_128_S2 (U32x4, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "movdqu %4, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %1" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "pmuludq %4, %0" & ASCII.LF & ASCII.HT & "pmuludq %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpckldq %1, %0", "");
   function Multiply_Wrap (Left, Right : U32x4) return U32x4 is (Native_Multiply_Wrap_U32x4 (Left, Right));
   function Native_Bitwise_And_U32x4 is new SSE2_Binary_128_S0 (U32x4, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_U32x4);
   function Bitwise_And (Left, Right : U32x4) return U32x4 is (Native_Bitwise_And_U32x4 (Left, Right));
   function Native_Bitwise_Or_U32x4 is new SSE2_Binary_128_S0 (U32x4, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_U32x4);
   function Bitwise_Or (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Or_U32x4 (Left, Right));
   function Native_Bitwise_Xor_U32x4 is new SSE2_Binary_128_S0 (U32x4, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_U32x4);
   function Bitwise_Xor (Left, Right : U32x4) return U32x4 is (Native_Bitwise_Xor_U32x4 (Left, Right));
   function Native_Interleave_Low_U32x4 is new SSE2_Binary_128_S0 (U32x4, "punpckldq %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_U32x4);
   function Interleave_Low (Left, Right : U32x4) return U32x4 is (Native_Interleave_Low_U32x4 (Left, Right));
   function Native_Interleave_High_U32x4 is new SSE2_Binary_128_S0 (U32x4, "punpckhdq %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_U32x4);
   function Interleave_High (Left, Right : U32x4) return U32x4 is (Native_Interleave_High_U32x4 (Left, Right));
   function Native_Deinterleave_Even_U32x4 is new SSE2_Binary_128_S1 (U32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_U32x4);
   function Deinterleave_Even (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Even_U32x4 (Left, Right));
   function Native_Deinterleave_Odd_U32x4 is new SSE2_Binary_128_S1 (U32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_U32x4);
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4 is (Native_Deinterleave_Odd_U32x4 (Left, Right));
   function Native_Add_Saturate_U32x4 is new SSE2_Binary_128_S5 (U32x4, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %2" & ASCII.LF & ASCII.HT & "paddd %7, %0" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %0, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pxor %5, %4" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "por %3, %0", "");
   function Add_Saturate (Left, Right : U32x4) return U32x4 is (Native_Add_Saturate_U32x4 (Left, Right));
   function Native_Subtract_Saturate_U32x4 is new SSE2_Binary_128_S4 (U32x4, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "psubd %6, %0" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "pxor %2, %1" & ASCII.LF & ASCII.HT & "pxor %4, %1" & ASCII.LF & ASCII.HT & "pand %0, %1" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Subtract_Saturate (Left, Right : U32x4) return U32x4 is (Native_Subtract_Saturate_U32x4 (Left, Right));
   function Native_Not_U32x4 is new SSE2_Unary_128_S1 (U32x4, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_U32x4);
   function Bitwise_Not (Value : U32x4) return U32x4 is (Native_Not_U32x4 (Value));
   function Native_Reverse_U32x4 is new SSE2_Unary_128_S0 (U32x4, "pshufd $0x1B, %0, %0", "");
   pragma Inline_Always (Native_Reverse_U32x4);
   function Reverse_Lanes (Value : U32x4) return U32x4 is (Native_Reverse_U32x4 (Value));
   function Compare_Equal_U32x4 is new SSE2_Compare_128 (U32x4, 32, "pcmpeqd %2, %1");
   pragma Inline_Always (Compare_Equal_U32x4);
   function Compare_Greater_U32x4 is new SSE2_Compare_128 (U32x4, 32, "pxor %9, %1" & ASCII.LF & ASCII.HT & "pxor %9, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1");
   pragma Inline_Always (Compare_Greater_U32x4);
   function Native_Select_U32x4 is new SSE2_Select_128 (U32x4, 32);
   pragma Inline_Always (Native_Select_U32x4);
   function Native_Zero_U32x4 is new SSE2_Zero_128 (U32x4);
   pragma Inline_Always (Native_Zero_U32x4);
   function Zero return U32x4 is (Native_Zero_U32x4);
   function Native_Splat_U32x4 is new SSE2_Splat_Integer_128 (U32x4, U32, "movd %k2, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0");
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
   function Native_Permute_U32x4 is new SSE2_Permute_128 (U32x4, Lane_Map_32x4, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : U32x4; Map : Lane_Map_32x4) return U32x4 is (Native_Permute_U32x4 (Value, Map));
   function Native_Permute_2_U32x4 is new SSE2_Permute_2_128 (U32x4, Two_Source_Lane_Map_32x4, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_U32x4 is new SSE2_Shift_128 (U32x4, "pslld %1, %0");
   function Native_SHR_U32x4 is new SSE2_Shift_128 (U32x4, "psrld %1, %0");
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4 is (Native_SHL_U32x4 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 32))));
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4 is (Native_SHR_U32x4 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 32))));
   function Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_U32x4 (Left, Right, Sign_Vector_32))));
   function Greater_Than (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U32x4 (Left, Right, Sign_Vector_32))));
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U32x4 (Left, Right, Sign_Vector_32) or Compare_Equal_U32x4 (Left, Right, Sign_Vector_32))));
   function Less_Than (Left, Right : U32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4 is (Native_Select_U32x4 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_32, If_True, If_False));
   function Min (Left, Right : U32x4) return U32x4 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : U32x4) return U32x4 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Native_Reduce_Add_Wrap_U32x4 is new SSE2_Integer_Reduce_128_S2 (U32x4, U32, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "paddd %2, %1", "movd %1, %k0");
   pragma Inline_Always (Native_Reduce_Add_Wrap_U32x4);
   function Reduce_Add_Wrap (Value : U32x4) return U32 is (Native_Reduce_Add_Wrap_U32x4 (Value));
   function Native_Reduce_Min_U32x4 is new SSE2_Integer_Reduce_128_S5_Sign (U32x4, U32, "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movd %1, %k0");
   function Reduce_Min (Value : U32x4) return U32 is (Native_Reduce_Min_U32x4 (Value, Sign_Vector_32));
   function Native_Reduce_Max_U32x4 is new SSE2_Integer_Reduce_128_S5_Sign (U32x4, U32, "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pxor %7, %1" & ASCII.LF & ASCII.HT & "pxor %7, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movd %1, %k0");
   function Reduce_Max (Value : U32x4) return U32 is (Native_Reduce_Max_U32x4 (Value, Sign_Vector_32));
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_U32x4'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (U32x4, Machine_Vector);
      Target : Lane_Values_U32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_U32x4'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U32x4);
      Source : constant Lane_Values_U32x4 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_U32x4'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (U32x4, Machine_Vector);
      Target : Lane_Values_U32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_U32x4'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_Wrap_I32x4 is new SSE2_Binary_128_S0 (I32x4, "paddd %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_I32x4);
   function Add_Wrap (Left, Right : I32x4) return I32x4 is (Native_Add_Wrap_I32x4 (Left, Right));
   function Native_Subtract_Wrap_I32x4 is new SSE2_Binary_128_S0 (I32x4, "psubd %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_I32x4);
   function Subtract_Wrap (Left, Right : I32x4) return I32x4 is (Native_Subtract_Wrap_I32x4 (Left, Right));
   function Native_Multiply_Wrap_I32x4 is new SSE2_Binary_128_S2 (I32x4, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "movdqu %4, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %1" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "pmuludq %4, %0" & ASCII.LF & ASCII.HT & "pmuludq %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpckldq %1, %0", "");
   function Multiply_Wrap (Left, Right : I32x4) return I32x4 is (Native_Multiply_Wrap_I32x4 (Left, Right));
   function Native_Bitwise_And_I32x4 is new SSE2_Binary_128_S0 (I32x4, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_I32x4);
   function Bitwise_And (Left, Right : I32x4) return I32x4 is (Native_Bitwise_And_I32x4 (Left, Right));
   function Native_Bitwise_Or_I32x4 is new SSE2_Binary_128_S0 (I32x4, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_I32x4);
   function Bitwise_Or (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Or_I32x4 (Left, Right));
   function Native_Bitwise_Xor_I32x4 is new SSE2_Binary_128_S0 (I32x4, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_I32x4);
   function Bitwise_Xor (Left, Right : I32x4) return I32x4 is (Native_Bitwise_Xor_I32x4 (Left, Right));
   function Native_Interleave_Low_I32x4 is new SSE2_Binary_128_S0 (I32x4, "punpckldq %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_I32x4);
   function Interleave_Low (Left, Right : I32x4) return I32x4 is (Native_Interleave_Low_I32x4 (Left, Right));
   function Native_Interleave_High_I32x4 is new SSE2_Binary_128_S0 (I32x4, "punpckhdq %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_I32x4);
   function Interleave_High (Left, Right : I32x4) return I32x4 is (Native_Interleave_High_I32x4 (Left, Right));
   function Native_Deinterleave_Even_I32x4 is new SSE2_Binary_128_S1 (I32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_I32x4);
   function Deinterleave_Even (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Even_I32x4 (Left, Right));
   function Native_Deinterleave_Odd_I32x4 is new SSE2_Binary_128_S1 (I32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_I32x4);
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4 is (Native_Deinterleave_Odd_I32x4 (Left, Right));
   function Native_Add_Saturate_I32x4 is new SSE2_Binary_128_S6 (I32x4, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "paddd %8, %0" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pxor %2, %3" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pxor %5, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pxor %0, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %6" & ASCII.LF & ASCII.HT & "pslld $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "pand %6, %1" & ASCII.LF & ASCII.HT & "pandn %5, %4" & ASCII.LF & ASCII.HT & "por %1, %4" & ASCII.LF & ASCII.HT & "pand %3, %4" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Add_Saturate (Left, Right : I32x4) return I32x4 is (Native_Add_Saturate_I32x4 (Left, Right));
   function Native_Subtract_Saturate_I32x4 is new SSE2_Binary_128_S6 (I32x4, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "psubd %8, %0" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pxor %2, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pxor %0, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %6" & ASCII.LF & ASCII.HT & "pslld $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "pand %6, %1" & ASCII.LF & ASCII.HT & "pandn %5, %4" & ASCII.LF & ASCII.HT & "por %1, %4" & ASCII.LF & ASCII.HT & "pand %3, %4" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Subtract_Saturate (Left, Right : I32x4) return I32x4 is (Native_Subtract_Saturate_I32x4 (Left, Right));
   function Native_Not_I32x4 is new SSE2_Unary_128_S1 (I32x4, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_I32x4);
   function Bitwise_Not (Value : I32x4) return I32x4 is (Native_Not_I32x4 (Value));
   function Native_Reverse_I32x4 is new SSE2_Unary_128_S0 (I32x4, "pshufd $0x1B, %0, %0", "");
   pragma Inline_Always (Native_Reverse_I32x4);
   function Reverse_Lanes (Value : I32x4) return I32x4 is (Native_Reverse_I32x4 (Value));
   function Compare_Equal_I32x4 is new SSE2_Compare_128 (I32x4, 32, "pcmpeqd %2, %1");
   pragma Inline_Always (Compare_Equal_I32x4);
   function Compare_Greater_I32x4 is new SSE2_Compare_128 (I32x4, 32, "pcmpgtd %2, %1");
   pragma Inline_Always (Compare_Greater_I32x4);
   function Native_Select_I32x4 is new SSE2_Select_128 (I32x4, 32);
   pragma Inline_Always (Native_Select_I32x4);
   function Native_Zero_I32x4 is new SSE2_Zero_128 (I32x4);
   pragma Inline_Always (Native_Zero_I32x4);
   function Zero return I32x4 is (Native_Zero_I32x4);
   function Native_Splat_I32x4 is new SSE2_Splat_Integer_128 (I32x4, I32, "movd %k2, %0" & ASCII.LF & ASCII.HT & "pshufd $0, %0, %0");
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
   function Native_Permute_I32x4 is new SSE2_Permute_128 (I32x4, Lane_Map_32x4, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : I32x4; Map : Lane_Map_32x4) return I32x4 is (Native_Permute_I32x4 (Value, Map));
   function Native_Permute_2_I32x4 is new SSE2_Permute_2_128 (I32x4, Two_Source_Lane_Map_32x4, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_I32x4 is new SSE2_Shift_128 (I32x4, "pslld %1, %0");
   function Native_SHR_I32x4 is new SSE2_Shift_128 (I32x4, "psrld %1, %0");
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4 is (Native_SHL_I32x4 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 32))));
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4 is (Native_SHR_I32x4 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 32))));
   function Native_SAR_I32x4 is new SSE2_Shift_128 (I32x4, "psrad %1, %0");
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4 is (Native_SAR_I32x4 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 32))));
   function Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_I32x4 (Left, Right, Sign_Vector_32))));
   function Greater_Than (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I32x4 (Left, Right, Sign_Vector_32))));
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I32x4 (Left, Right, Sign_Vector_32) or Compare_Equal_I32x4 (Left, Right, Sign_Vector_32))));
   function Less_Than (Left, Right : I32x4) return Mask_32x4 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I32x4) return Mask_32x4 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4 is (Native_Select_I32x4 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_32, If_True, If_False));
   function Min (Left, Right : I32x4) return I32x4 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : I32x4) return I32x4 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Native_Reduce_Add_Wrap_I32x4 is new SSE2_Integer_Reduce_128_S2 (I32x4, I32, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "paddd %2, %1", "movd %1, %k0");
   pragma Inline_Always (Native_Reduce_Add_Wrap_I32x4);
   function Reduce_Add_Wrap (Value : I32x4) return I32 is (Native_Reduce_Add_Wrap_I32x4 (Value));
   function Native_Reduce_Min_I32x4 is new SSE2_Integer_Reduce_128_S5 (I32x4, I32, "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %4" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movd %1, %k0");
   function Reduce_Min (Value : I32x4) return I32 is (Native_Reduce_Min_I32x4 (Value));
   function Native_Reduce_Max_I32x4 is new SSE2_Integer_Reduce_128_S5 (I32x4, I32, "movdqa %6, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %5, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %5, %2" & ASCII.LF & ASCII.HT & "pand %1, %4" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movd %1, %k0");
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I32x4'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (I32x4, Machine_Vector);
      Target : Lane_Values_I32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_I32x4'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I32x4);
      Source : constant Lane_Values_I32x4 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I32x4'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (I32x4, Machine_Vector);
      Target : Lane_Values_I32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_I32x4'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_Wrap_U64x2 is new SSE2_Binary_128_S0 (U64x2, "paddq %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_U64x2);
   function Add_Wrap (Left, Right : U64x2) return U64x2 is (Native_Add_Wrap_U64x2 (Left, Right));
   function Native_Subtract_Wrap_U64x2 is new SSE2_Binary_128_S0 (U64x2, "psubq %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_U64x2);
   function Subtract_Wrap (Left, Right : U64x2) return U64x2 is (Native_Subtract_Wrap_U64x2 (Left, Right));
   function Native_Multiply_Wrap_U64x2 is new SSE2_Binary_128_S3 (U64x2, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %1, %1" & ASCII.LF & ASCII.HT & "pmuludq %5, %1" & ASCII.LF & ASCII.HT & "movdqu %5, %2" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "movdqu %0, %3" & ASCII.LF & ASCII.HT & "pmuludq %2, %3" & ASCII.LF & ASCII.HT & "paddq %3, %1" & ASCII.LF & ASCII.HT & "psllq $32, %1" & ASCII.LF & ASCII.HT & "pmuludq %5, %0" & ASCII.LF & ASCII.HT & "paddq %1, %0", "");
   function Multiply_Wrap (Left, Right : U64x2) return U64x2 is (Native_Multiply_Wrap_U64x2 (Left, Right));
   function Native_Bitwise_And_U64x2 is new SSE2_Binary_128_S0 (U64x2, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_U64x2);
   function Bitwise_And (Left, Right : U64x2) return U64x2 is (Native_Bitwise_And_U64x2 (Left, Right));
   function Native_Bitwise_Or_U64x2 is new SSE2_Binary_128_S0 (U64x2, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_U64x2);
   function Bitwise_Or (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Or_U64x2 (Left, Right));
   function Native_Bitwise_Xor_U64x2 is new SSE2_Binary_128_S0 (U64x2, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_U64x2);
   function Bitwise_Xor (Left, Right : U64x2) return U64x2 is (Native_Bitwise_Xor_U64x2 (Left, Right));
   function Native_Interleave_Low_U64x2 is new SSE2_Binary_128_S0 (U64x2, "punpcklqdq %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_U64x2);
   function Interleave_Low (Left, Right : U64x2) return U64x2 is (Native_Interleave_Low_U64x2 (Left, Right));
   function Native_Interleave_High_U64x2 is new SSE2_Binary_128_S0 (U64x2, "punpckhqdq %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_U64x2);
   function Interleave_High (Left, Right : U64x2) return U64x2 is (Native_Interleave_High_U64x2 (Left, Right));
   function Native_Deinterleave_Even_U64x2 is new SSE2_Binary_128_S0 (U64x2, "punpcklqdq %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_U64x2);
   function Deinterleave_Even (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Even_U64x2 (Left, Right));
   function Native_Deinterleave_Odd_U64x2 is new SSE2_Binary_128_S0 (U64x2, "punpckhqdq %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_U64x2);
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2 is (Native_Deinterleave_Odd_U64x2 (Left, Right));
   function Native_Add_Saturate_U64x2 is new SSE2_Binary_128_S5 (U64x2, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %2" & ASCII.LF & ASCII.HT & "paddq %7, %0" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %0, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pxor %5, %4" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "por %3, %0", "");
   function Add_Saturate (Left, Right : U64x2) return U64x2 is (Native_Add_Saturate_U64x2 (Left, Right));
   function Native_Subtract_Saturate_U64x2 is new SSE2_Binary_128_S4 (U64x2, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "psubq %6, %0" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "pxor %2, %1" & ASCII.LF & ASCII.HT & "pxor %4, %1" & ASCII.LF & ASCII.HT & "pand %0, %1" & ASCII.LF & ASCII.HT & "por %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Subtract_Saturate (Left, Right : U64x2) return U64x2 is (Native_Subtract_Saturate_U64x2 (Left, Right));
   function Native_Not_U64x2 is new SSE2_Unary_128_S1 (U64x2, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_U64x2);
   function Bitwise_Not (Value : U64x2) return U64x2 is (Native_Not_U64x2 (Value));
   function Native_Reverse_U64x2 is new SSE2_Unary_128_S0 (U64x2, "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_U64x2);
   function Reverse_Lanes (Value : U64x2) return U64x2 is (Native_Reverse_U64x2 (Value));
   function Compare_Equal_U64x2 is new SSE2_Compare_128 (U64x2, 64, "pcmpeqd %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %1, %3" & ASCII.LF & ASCII.HT & "pand %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1");
   pragma Inline_Always (Compare_Equal_U64x2);
   function Compare_Greater_U64x2 is new SSE2_Compare_128 (U64x2, 64, "movdqu %1, %3" & ASCII.LF & ASCII.HT & "movdqu %2, %4" & ASCII.LF & ASCII.HT & "pxor %9, %3" & ASCII.LF & ASCII.HT & "pxor %9, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqu %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pxor %9, %1" & ASCII.LF & ASCII.HT & "pxor %9, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %3, %1");
   pragma Inline_Always (Compare_Greater_U64x2);
   function Native_Select_U64x2 is new SSE2_Select_128 (U64x2, 64);
   pragma Inline_Always (Native_Select_U64x2);
   function Native_Zero_U64x2 is new SSE2_Zero_128 (U64x2);
   pragma Inline_Always (Native_Zero_U64x2);
   function Zero return U64x2 is (Native_Zero_U64x2);
   function Native_Splat_U64x2 is new SSE2_Splat_Integer_128 (U64x2, U64, "movq %q2, %0" & ASCII.LF & ASCII.HT & "punpcklqdq %0, %0");
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
   function Native_Permute_U64x2 is new SSE2_Permute_128 (U64x2, Lane_Map_64x2, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : U64x2; Map : Lane_Map_64x2) return U64x2 is (Native_Permute_U64x2 (Value, Map));
   function Native_Permute_2_U64x2 is new SSE2_Permute_2_128 (U64x2, Two_Source_Lane_Map_64x2, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_U64x2 is new SSE2_Shift_128 (U64x2, "psllq %1, %0");
   function Native_SHR_U64x2 is new SSE2_Shift_128 (U64x2, "psrlq %1, %0");
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2 is (Native_SHL_U64x2 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 64))));
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2 is (Native_SHR_U64x2 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 64))));
   function Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_U64x2 (Left, Right, Sign_Vector_32))));
   function Greater_Than (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U64x2 (Left, Right, Sign_Vector_32))));
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_U64x2 (Left, Right, Sign_Vector_32) or Compare_Equal_U64x2 (Left, Right, Sign_Vector_32))));
   function Less_Than (Left, Right : U64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : U64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2 is (Native_Select_U64x2 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_64, If_True, If_False));
   function Min (Left, Right : U64x2) return U64x2 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : U64x2) return U64x2 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Native_Reduce_Add_Wrap_U64x2 is new SSE2_Integer_Reduce_128_S2 (U64x2, U64, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddq %2, %1", "movq %1, %q0");
   pragma Inline_Always (Native_Reduce_Add_Wrap_U64x2);
   function Reduce_Add_Wrap (Value : U64x2) return U64 is (Native_Reduce_Add_Wrap_U64x2 (Value));
   function Native_Reduce_Min_U64x2 is new SSE2_Integer_Reduce_128_S6_Sign (U64x2, U64, "movdqa %7, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "movdqu %1, %3" & ASCII.LF & ASCII.HT & "movdqu %2, %4" & ASCII.LF & ASCII.HT & "pxor %8, %3" & ASCII.LF & ASCII.HT & "pxor %8, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqu %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pxor %8, %1" & ASCII.LF & ASCII.HT & "pxor %8, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movq %1, %q0");
   function Reduce_Min (Value : U64x2) return U64 is (Native_Reduce_Min_U64x2 (Value, Sign_Vector_32));
   function Native_Reduce_Max_U64x2 is new SSE2_Integer_Reduce_128_S6_Sign (U64x2, U64, "movdqa %7, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %6" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "movdqu %1, %3" & ASCII.LF & ASCII.HT & "movdqu %2, %4" & ASCII.LF & ASCII.HT & "pxor %8, %3" & ASCII.LF & ASCII.HT & "pxor %8, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqu %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pxor %8, %1" & ASCII.LF & ASCII.HT & "pxor %8, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %6, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %6, %2" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movq %1, %q0");
   function Reduce_Max (Value : U64x2) return U64 is (Native_Reduce_Max_U64x2 (Value, Sign_Vector_32));
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_U64x2'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (U64x2, Machine_Vector);
      Target : Lane_Values_U64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_U64x2'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, U64x2);
      Source : constant Lane_Values_U64x2 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_U64x2'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (U64x2, Machine_Vector);
      Target : Lane_Values_U64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_U64x2'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_Wrap_I64x2 is new SSE2_Binary_128_S0 (I64x2, "paddq %2, %0", "");
   pragma Inline_Always (Native_Add_Wrap_I64x2);
   function Add_Wrap (Left, Right : I64x2) return I64x2 is (Native_Add_Wrap_I64x2 (Left, Right));
   function Native_Subtract_Wrap_I64x2 is new SSE2_Binary_128_S0 (I64x2, "psubq %2, %0", "");
   pragma Inline_Always (Native_Subtract_Wrap_I64x2);
   function Subtract_Wrap (Left, Right : I64x2) return I64x2 is (Native_Subtract_Wrap_I64x2 (Left, Right));
   function Native_Multiply_Wrap_I64x2 is new SSE2_Binary_128_S3 (I64x2, "movdqu %0, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %1, %1" & ASCII.LF & ASCII.HT & "pmuludq %5, %1" & ASCII.LF & ASCII.HT & "movdqu %5, %2" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %2, %2" & ASCII.LF & ASCII.HT & "movdqu %0, %3" & ASCII.LF & ASCII.HT & "pmuludq %2, %3" & ASCII.LF & ASCII.HT & "paddq %3, %1" & ASCII.LF & ASCII.HT & "psllq $32, %1" & ASCII.LF & ASCII.HT & "pmuludq %5, %0" & ASCII.LF & ASCII.HT & "paddq %1, %0", "");
   function Multiply_Wrap (Left, Right : I64x2) return I64x2 is (Native_Multiply_Wrap_I64x2 (Left, Right));
   function Native_Bitwise_And_I64x2 is new SSE2_Binary_128_S0 (I64x2, "pand %2, %0", "");
   pragma Inline_Always (Native_Bitwise_And_I64x2);
   function Bitwise_And (Left, Right : I64x2) return I64x2 is (Native_Bitwise_And_I64x2 (Left, Right));
   function Native_Bitwise_Or_I64x2 is new SSE2_Binary_128_S0 (I64x2, "por %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Or_I64x2);
   function Bitwise_Or (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Or_I64x2 (Left, Right));
   function Native_Bitwise_Xor_I64x2 is new SSE2_Binary_128_S0 (I64x2, "pxor %2, %0", "");
   pragma Inline_Always (Native_Bitwise_Xor_I64x2);
   function Bitwise_Xor (Left, Right : I64x2) return I64x2 is (Native_Bitwise_Xor_I64x2 (Left, Right));
   function Native_Interleave_Low_I64x2 is new SSE2_Binary_128_S0 (I64x2, "punpcklqdq %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_I64x2);
   function Interleave_Low (Left, Right : I64x2) return I64x2 is (Native_Interleave_Low_I64x2 (Left, Right));
   function Native_Interleave_High_I64x2 is new SSE2_Binary_128_S0 (I64x2, "punpckhqdq %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_I64x2);
   function Interleave_High (Left, Right : I64x2) return I64x2 is (Native_Interleave_High_I64x2 (Left, Right));
   function Native_Deinterleave_Even_I64x2 is new SSE2_Binary_128_S0 (I64x2, "punpcklqdq %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_I64x2);
   function Deinterleave_Even (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Even_I64x2 (Left, Right));
   function Native_Deinterleave_Odd_I64x2 is new SSE2_Binary_128_S0 (I64x2, "punpckhqdq %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_I64x2);
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2 is (Native_Deinterleave_Odd_I64x2 (Left, Right));
   function Native_Add_Saturate_I64x2 is new SSE2_Binary_128_S6 (I64x2, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "paddq %8, %0" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pxor %2, %3" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pxor %5, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pxor %0, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %6" & ASCII.LF & ASCII.HT & "psllq $63, %6" & ASCII.LF & ASCII.HT & "psrlq $1, %5" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "pand %6, %1" & ASCII.LF & ASCII.HT & "pandn %5, %4" & ASCII.LF & ASCII.HT & "por %1, %4" & ASCII.LF & ASCII.HT & "pand %3, %4" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Add_Saturate (Left, Right : I64x2) return I64x2 is (Native_Add_Saturate_I64x2 (Left, Right));
   function Native_Subtract_Saturate_I64x2 is new SSE2_Binary_128_S6 (I64x2, "movdqa %0, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "psubq %8, %0" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "pxor %2, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pxor %0, %4" & ASCII.LF & ASCII.HT & "pand %4, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %6" & ASCII.LF & ASCII.HT & "psllq $63, %6" & ASCII.LF & ASCII.HT & "psrlq $1, %5" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "pand %6, %1" & ASCII.LF & ASCII.HT & "pandn %5, %4" & ASCII.LF & ASCII.HT & "por %1, %4" & ASCII.LF & ASCII.HT & "pand %3, %4" & ASCII.LF & ASCII.HT & "pandn %0, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %0", "");
   function Subtract_Saturate (Left, Right : I64x2) return I64x2 is (Native_Subtract_Saturate_I64x2 (Left, Right));
   function Native_Not_I64x2 is new SSE2_Unary_128_S1 (I64x2, "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pxor %1, %0", "");
   pragma Inline_Always (Native_Not_I64x2);
   function Bitwise_Not (Value : I64x2) return I64x2 is (Native_Not_I64x2 (Value));
   function Native_Reverse_I64x2 is new SSE2_Unary_128_S0 (I64x2, "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_I64x2);
   function Reverse_Lanes (Value : I64x2) return I64x2 is (Native_Reverse_I64x2 (Value));
   function Compare_Equal_I64x2 is new SSE2_Compare_128 (I64x2, 64, "pcmpeqd %2, %1" & ASCII.LF & ASCII.HT & "pshufd $0xB1, %1, %3" & ASCII.LF & ASCII.HT & "pand %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1");
   pragma Inline_Always (Compare_Equal_I64x2);
   function Compare_Greater_I64x2 is new SSE2_Compare_128 (I64x2, 64, "movdqu %1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqu %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "movdqu %1, %5" & ASCII.LF & ASCII.HT & "movdqu %2, %6" & ASCII.LF & ASCII.HT & "pxor %9, %5" & ASCII.LF & ASCII.HT & "pxor %9, %6" & ASCII.LF & ASCII.HT & "pcmpgtd %6, %5" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %5, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqu %3, %1");
   pragma Inline_Always (Compare_Greater_I64x2);
   function Native_Select_I64x2 is new SSE2_Select_128 (I64x2, 64);
   pragma Inline_Always (Native_Select_I64x2);
   function Native_Zero_I64x2 is new SSE2_Zero_128 (I64x2);
   pragma Inline_Always (Native_Zero_I64x2);
   function Zero return I64x2 is (Native_Zero_I64x2);
   function Native_Splat_I64x2 is new SSE2_Splat_Integer_128 (I64x2, I64, "movq %q2, %0" & ASCII.LF & ASCII.HT & "punpcklqdq %0, %0");
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
   function Native_Permute_I64x2 is new SSE2_Permute_128 (I64x2, Lane_Map_64x2, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : I64x2; Map : Lane_Map_64x2) return I64x2 is (Native_Permute_I64x2 (Value, Map));
   function Native_Permute_2_I64x2 is new SSE2_Permute_2_128 (I64x2, Two_Source_Lane_Map_64x2, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
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

   function Native_SHL_I64x2 is new SSE2_Shift_128 (I64x2, "psllq %1, %0");
   function Native_SHR_I64x2 is new SSE2_Shift_128 (I64x2, "psrlq %1, %0");
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2 is (Native_SHL_I64x2 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 64))));
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2 is (Native_SHR_I64x2 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 64))));
   function Native_SAR_I64x2 is new SSE2_Shift_128 (I64x2, "movdqa %0, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "psrlq %1, %0" & ASCII.LF & ASCII.HT & "movdqa %2, %3" & ASCII.LF & ASCII.HT & "psrlq %1, %3" & ASCII.LF & ASCII.HT & "pxor %2, %3" & ASCII.LF & ASCII.HT & "por %3, %0");
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2 is (Native_SAR_I64x2 (Value, Interfaces.Unsigned_32 (Natural'Min (Count, 64))));
   function Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_I64x2 (Left, Right, Sign_Vector_32))));
   function Greater_Than (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I64x2 (Left, Right, Sign_Vector_32))));
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Greater_I64x2 (Left, Right, Sign_Vector_32) or Compare_Equal_I64x2 (Left, Right, Sign_Vector_32))));
   function Less_Than (Left, Right : I64x2) return Mask_64x2 is (Greater_Than (Left => Right, Right => Left));
   function Less_Equal (Left, Right : I64x2) return Mask_64x2 is (Greater_Equal (Left => Right, Right => Left));
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2 is (Native_Select_I64x2 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_64, If_True, If_False));
   function Min (Left, Right : I64x2) return I64x2 is (Select_Value (Less_Than (Left, Right), Left, Right));
   function Max (Left, Right : I64x2) return I64x2 is (Select_Value (Greater_Than (Left, Right), Left, Right));
   function Native_Reduce_Add_Wrap_I64x2 is new SSE2_Integer_Reduce_128_S2 (I64x2, I64, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "paddq %2, %1", "movq %1, %q0");
   pragma Inline_Always (Native_Reduce_Add_Wrap_I64x2);
   function Reduce_Add_Wrap (Value : I64x2) return I64 is (Native_Reduce_Add_Wrap_I64x2 (Value));
   function Native_Reduce_Min_I64x2 is new SSE2_Integer_Reduce_128_S7_Sign (I64x2, I64, "movdqa %8, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %7, %2" & ASCII.LF & ASCII.HT & "movdqu %1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqu %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "movdqu %1, %5" & ASCII.LF & ASCII.HT & "movdqu %2, %6" & ASCII.LF & ASCII.HT & "pxor %9, %5" & ASCII.LF & ASCII.HT & "pxor %9, %6" & ASCII.LF & ASCII.HT & "pcmpgtd %6, %5" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %5, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqu %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %7, %2" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "pand %2, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movq %1, %q0");
   function Reduce_Min (Value : I64x2) return I64 is (Native_Reduce_Min_I64x2 (Value, Sign_Vector_32));
   function Native_Reduce_Max_I64x2 is new SSE2_Integer_Reduce_128_S7_Sign (I64x2, I64, "movdqa %8, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %7, %2" & ASCII.LF & ASCII.HT & "movdqu %1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqu %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "movdqu %1, %5" & ASCII.LF & ASCII.HT & "movdqu %2, %6" & ASCII.LF & ASCII.HT & "pxor %9, %5" & ASCII.LF & ASCII.HT & "pxor %9, %6" & ASCII.LF & ASCII.HT & "pcmpgtd %6, %5" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %5, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqu %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %1" & ASCII.LF & ASCII.HT & "pshufd $0x4E, %7, %2" & ASCII.LF & ASCII.HT & "pand %1, %5" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "por %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1", "movq %1, %q0");
   function Reduce_Max (Value : I64x2) return I64 is (Native_Reduce_Max_I64x2 (Value, Sign_Vector_32));
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I64x2'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (I64x2, Machine_Vector);
      Target : Lane_Values_I64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_I64x2'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, I64x2);
      Source : constant Lane_Values_I64x2 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_I64x2'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (I64x2, Machine_Vector);
      Target : Lane_Values_I64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_I64x2'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_F32x4 is new SSE2_Binary_128_S0 (F32x4, "addps %2, %0", "");
   pragma Inline_Always (Native_Add_F32x4);
   function Add (Left, Right : F32x4) return F32x4 is (Native_Add_F32x4 (Left, Right));
   function Native_Subtract_F32x4 is new SSE2_Binary_128_S0 (F32x4, "subps %2, %0", "");
   pragma Inline_Always (Native_Subtract_F32x4);
   function Subtract (Left, Right : F32x4) return F32x4 is (Native_Subtract_F32x4 (Left, Right));
   function Native_Multiply_F32x4 is new SSE2_Binary_128_S0 (F32x4, "mulps %2, %0", "");
   pragma Inline_Always (Native_Multiply_F32x4);
   function Multiply (Left, Right : F32x4) return F32x4 is (Native_Multiply_F32x4 (Left, Right));
   function Native_Divide_F32x4 is new SSE2_Binary_128_S0 (F32x4, "divps %2, %0", "");
   pragma Inline_Always (Native_Divide_F32x4);
   function Divide (Left, Right : F32x4) return F32x4 is (Native_Divide_F32x4 (Left, Right));
   function Native_Interleave_Low_F32x4 is new SSE2_Binary_128_S0 (F32x4, "unpcklps %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_F32x4);
   function Interleave_Low (Left, Right : F32x4) return F32x4 is (Native_Interleave_Low_F32x4 (Left, Right));
   function Native_Interleave_High_F32x4 is new SSE2_Binary_128_S0 (F32x4, "unpckhps %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_F32x4);
   function Interleave_High (Left, Right : F32x4) return F32x4 is (Native_Interleave_High_F32x4 (Left, Right));
   function Native_Deinterleave_Even_F32x4 is new SSE2_Binary_128_S1 (F32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0x88, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0x88, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_F32x4);
   function Deinterleave_Even (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Even_F32x4 (Left, Right));
   function Native_Deinterleave_Odd_F32x4 is new SSE2_Binary_128_S1 (F32x4, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %0, %0" & ASCII.LF & ASCII.HT & "pshufd $0xDD, %1, %1" & ASCII.LF & ASCII.HT & "punpcklqdq %1, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_F32x4);
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4 is (Native_Deinterleave_Odd_F32x4 (Left, Right));
   function Native_Reverse_F32x4 is new SSE2_Unary_128_S0 (F32x4, "pshufd $0x1B, %0, %0", "");
   pragma Inline_Always (Native_Reverse_F32x4);
   function Reverse_Lanes (Value : F32x4) return F32x4 is (Native_Reverse_F32x4 (Value));
   function Compare_Equal_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpeqps %2, %1");
   pragma Inline_Always (Compare_Equal_F32x4);
   function Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_F32x4 (Left, Right, Sign_Vector_32))));
   function Compare_Less_Than_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpltps %2, %1");
   pragma Inline_Always (Compare_Less_Than_F32x4);
   function Less_Than (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Than_F32x4 (Left, Right, Sign_Vector_32))));
   function Compare_Less_Equal_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpleps %2, %1");
   pragma Inline_Always (Compare_Less_Equal_F32x4);
   function Less_Equal (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Equal_F32x4 (Left, Right, Sign_Vector_32))));
   function Compare_Unordered_F32x4 is new SSE2_Compare_128 (F32x4, 32, "cmpunordps %2, %1");
   pragma Inline_Always (Compare_Unordered_F32x4);
   function Unordered (Left, Right : F32x4) return Mask_32x4 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Unordered_F32x4 (Left, Right, Sign_Vector_32))));
   function Greater_Than (Left, Right : F32x4) return Mask_32x4 is (Less_Than (Left => Right, Right => Left));
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4 is (Less_Equal (Left => Right, Right => Left));
   function Native_Select_F32x4 is new SSE2_Select_128 (F32x4, 32);
   pragma Inline_Always (Native_Select_F32x4);
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4 is (Native_Select_F32x4 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_32, If_True, If_False));
   function Native_Zero_F32x4 is new SSE2_Zero_128 (F32x4);
   pragma Inline_Always (Native_Zero_F32x4);
   function Zero return F32x4 is (Native_Zero_F32x4);
   function Native_Splat_F32x4 is new SSE2_Splat_Float_128 (F32x4, F32, "movaps %1, %0" & ASCII.LF & ASCII.HT & "shufps $0, %0, %0");
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
   function Native_Min_Number_F32x4 is new SSE2_Binary_128_S6 (F32x4, "movdqa %0, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "psrld $1, %2" & ASCII.LF & ASCII.HT & "pxor %2, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %1, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pand %5, %2" & ASCII.LF & ASCII.HT & "pandn %6, %1" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "pslld $31, %2" & ASCII.LF & ASCII.HT & "psrld $9, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "pslld $31, %2" & ASCII.LF & ASCII.HT & "psrld $9, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0", "");
   function Min_Number (Left, Right : F32x4) return F32x4 is (Native_Min_Number_F32x4 (Left, Right));
   function Native_Max_Number_F32x4 is new SSE2_Binary_128_S6 (F32x4, "movdqa %0, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "psrld $1, %2" & ASCII.LF & ASCII.HT & "pxor %2, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pand %5, %2" & ASCII.LF & ASCII.HT & "pandn %6, %1" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "pslld $31, %2" & ASCII.LF & ASCII.HT & "psrld $9, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $24, %3" & ASCII.LF & ASCII.HT & "psrld $1, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "pslld $9, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "pslld $31, %2" & ASCII.LF & ASCII.HT & "psrld $9, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0", "");
   function Max_Number (Left, Right : F32x4) return F32x4 is (Native_Max_Number_F32x4 (Left, Right));
   function Native_Reduce_Add_F32x4 is new SSE2_Float_Reduce_128_S2 (F32x4, F32, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pxor %1, %1" & ASCII.LF & ASCII.HT & "addss %2, %1" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "addss %2, %1" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "addss %2, %1" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "addss %2, %1", "movaps %1, %0");
   function Reduce_Add (Value : F32x4) return F32 is (Native_Reduce_Add_F32x4 (Value));
   function Native_Reduce_Min_Number_F32x4 is new SSE2_Float_Reduce_128_S9 (F32x4, F32, "movdqa %10, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %9" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $12, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1", "movaps %1, %0");
   function Reduce_Min_Number (Value : F32x4) return F32 is (Native_Reduce_Min_Number_F32x4 (Value));
   function Native_Reduce_Max_Number_F32x4 is new SSE2_Float_Reduce_128_S9 (F32x4, F32, "movdqa %10, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %9" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $4, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $12, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrld $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrld $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %5" & ASCII.LF & ASCII.HT & "pslld $24, %5" & ASCII.LF & ASCII.HT & "psrld $1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "pslld $9, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "pslld $31, %4" & ASCII.LF & ASCII.HT & "psrld $9, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1", "movaps %1, %0");
   function Reduce_Max_Number (Value : F32x4) return F32 is (Native_Reduce_Max_Number_F32x4 (Value));
   function Native_Permute_F32x4 is new SSE2_Permute_128 (F32x4, Lane_Map_32x4, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : F32x4; Map : Lane_Map_32x4) return F32x4 is (Native_Permute_F32x4 (Value, Map));
   function Native_Permute_2_F32x4 is new SSE2_Permute_2_128 (F32x4, Two_Source_Lane_Map_32x4, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Left, Right : F32x4; Map : Two_Source_Lane_Map_32x4) return F32x4 is (Native_Permute_2_F32x4 (Left, Right, Map));
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_F32x4'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (F32x4, Machine_Vector);
      Target : Lane_Values_F32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_F32x4'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, F32x4);
      Source : constant Lane_Values_F32x4 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_F32x4'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) is
      function To_Machine is new Ada.Unchecked_Conversion (F32x4, Machine_Vector);
      Target : Lane_Values_F32x4 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_F32x4'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Native_Add_F64x2 is new SSE2_Binary_128_S0 (F64x2, "addpd %2, %0", "");
   pragma Inline_Always (Native_Add_F64x2);
   function Add (Left, Right : F64x2) return F64x2 is (Native_Add_F64x2 (Left, Right));
   function Native_Subtract_F64x2 is new SSE2_Binary_128_S0 (F64x2, "subpd %2, %0", "");
   pragma Inline_Always (Native_Subtract_F64x2);
   function Subtract (Left, Right : F64x2) return F64x2 is (Native_Subtract_F64x2 (Left, Right));
   function Native_Multiply_F64x2 is new SSE2_Binary_128_S0 (F64x2, "mulpd %2, %0", "");
   pragma Inline_Always (Native_Multiply_F64x2);
   function Multiply (Left, Right : F64x2) return F64x2 is (Native_Multiply_F64x2 (Left, Right));
   function Native_Divide_F64x2 is new SSE2_Binary_128_S0 (F64x2, "divpd %2, %0", "");
   pragma Inline_Always (Native_Divide_F64x2);
   function Divide (Left, Right : F64x2) return F64x2 is (Native_Divide_F64x2 (Left, Right));
   function Native_Interleave_Low_F64x2 is new SSE2_Binary_128_S0 (F64x2, "unpcklpd %2, %0", "");
   pragma Inline_Always (Native_Interleave_Low_F64x2);
   function Interleave_Low (Left, Right : F64x2) return F64x2 is (Native_Interleave_Low_F64x2 (Left, Right));
   function Native_Interleave_High_F64x2 is new SSE2_Binary_128_S0 (F64x2, "unpckhpd %2, %0", "");
   pragma Inline_Always (Native_Interleave_High_F64x2);
   function Interleave_High (Left, Right : F64x2) return F64x2 is (Native_Interleave_High_F64x2 (Left, Right));
   function Native_Deinterleave_Even_F64x2 is new SSE2_Binary_128_S0 (F64x2, "punpcklqdq %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Even_F64x2);
   function Deinterleave_Even (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Even_F64x2 (Left, Right));
   function Native_Deinterleave_Odd_F64x2 is new SSE2_Binary_128_S0 (F64x2, "punpckhqdq %2, %0", "");
   pragma Inline_Always (Native_Deinterleave_Odd_F64x2);
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2 is (Native_Deinterleave_Odd_F64x2 (Left, Right));
   function Native_Reverse_F64x2 is new SSE2_Unary_128_S0 (F64x2, "pshufd $0x4E, %0, %0", "");
   pragma Inline_Always (Native_Reverse_F64x2);
   function Reverse_Lanes (Value : F64x2) return F64x2 is (Native_Reverse_F64x2 (Value));
   function Compare_Equal_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmpeqpd %2, %1");
   pragma Inline_Always (Compare_Equal_F64x2);
   function Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Equal_F64x2 (Left, Right, Sign_Vector_32))));
   function Compare_Less_Than_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmpltpd %2, %1");
   pragma Inline_Always (Compare_Less_Than_F64x2);
   function Less_Than (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Than_F64x2 (Left, Right, Sign_Vector_32))));
   function Compare_Less_Equal_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmplepd %2, %1");
   pragma Inline_Always (Compare_Less_Equal_F64x2);
   function Less_Equal (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Less_Equal_F64x2 (Left, Right, Sign_Vector_32))));
   function Compare_Unordered_F64x2 is new SSE2_Compare_128 (F64x2, 64, "cmpunordpd %2, %1");
   pragma Inline_Always (Compare_Unordered_F64x2);
   function Unordered (Left, Right : F64x2) return Mask_64x2 is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_Unordered_F64x2 (Left, Right, Sign_Vector_32))));
   function Greater_Than (Left, Right : F64x2) return Mask_64x2 is (Less_Than (Left => Right, Right => Left));
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2 is (Less_Equal (Left => Right, Right => Left));
   function Native_Select_F64x2 is new SSE2_Select_128 (F64x2, 64);
   pragma Inline_Always (Native_Select_F64x2);
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2 is (Native_Select_F64x2 (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), Weights_X86_Vector_64, If_True, If_False));
   function Native_Zero_F64x2 is new SSE2_Zero_128 (F64x2);
   pragma Inline_Always (Native_Zero_F64x2);
   function Zero return F64x2 is (Native_Zero_F64x2);
   function Native_Splat_F64x2 is new SSE2_Splat_Float_128 (F64x2, F64, "movapd %1, %0" & ASCII.LF & ASCII.HT & "unpcklpd %0, %0");
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
   function Native_Min_Number_F64x2 is new SSE2_Binary_128_S7 (F64x2, "movdqa %9, %7" & ASCII.LF & ASCII.HT & "movdqa %0, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "pxor %2, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %1, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %0, %0" & ASCII.LF & ASCII.HT & "pslld $31, %0" & ASCII.LF & ASCII.HT & "pxor %0, %1" & ASCII.LF & ASCII.HT & "pxor %0, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %1, %3" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pand %5, %2" & ASCII.LF & ASCII.HT & "pandn %6, %1" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $63, %2" & ASCII.LF & ASCII.HT & "psrlq $12, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $63, %2" & ASCII.LF & ASCII.HT & "psrlq $12, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0", "");
   function Min_Number (Left, Right : F64x2) return F64x2 is (Native_Min_Number_F64x2 (Left, Right));
   function Native_Max_Number_F64x2 is new SSE2_Binary_128_S7 (F64x2, "movdqa %9, %7" & ASCII.LF & ASCII.HT & "movdqa %0, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "psrad $31, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "pxor %2, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %2" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %2, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %0, %0" & ASCII.LF & ASCII.HT & "pslld $31, %0" & ASCII.LF & ASCII.HT & "pxor %0, %1" & ASCII.LF & ASCII.HT & "pxor %0, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %1" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %1, %1" & ASCII.LF & ASCII.HT & "pand %4, %1" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pand %5, %2" & ASCII.LF & ASCII.HT & "pandn %6, %1" & ASCII.LF & ASCII.HT & "por %2, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %5, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pand %2, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %6, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %6, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %6, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $63, %2" & ASCII.LF & ASCII.HT & "psrlq $12, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0" & ASCII.LF & ASCII.HT & "movdqa %5, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "psrlq $1, %1" & ASCII.LF & ASCII.HT & "pand %1, %7" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $53, %2" & ASCII.LF & ASCII.HT & "psrlq $1, %2" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %7" & ASCII.LF & ASCII.HT & "pxor %1, %2" & ASCII.LF & ASCII.HT & "pcmpgtd %2, %7" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %7, %7" & ASCII.LF & ASCII.HT & "pand %4, %7" & ASCII.LF & ASCII.HT & "por %7, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %2" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "psllq $12, %3" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %3, %3" & ASCII.LF & ASCII.HT & "psrad $31, %3" & ASCII.LF & ASCII.HT & "pandn %2, %3" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "pcmpeqd %2, %2" & ASCII.LF & ASCII.HT & "psllq $63, %2" & ASCII.LF & ASCII.HT & "psrlq $12, %2" & ASCII.LF & ASCII.HT & "por %2, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %4, %2" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pandn %0, %1" & ASCII.LF & ASCII.HT & "por %1, %2" & ASCII.LF & ASCII.HT & "movdqa %2, %0", "");
   function Max_Number (Left, Right : F64x2) return F64x2 is (Native_Max_Number_F64x2 (Left, Right));
   function Native_Reduce_Add_F64x2 is new SSE2_Float_Reduce_128_S2 (F64x2, F64, "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %2" & ASCII.LF & ASCII.HT & "pxor %1, %1" & ASCII.LF & ASCII.HT & "addsd %2, %1" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "addsd %2, %1", "movaps %1, %0");
   pragma Inline_Always (Native_Reduce_Add_F64x2);
   function Reduce_Add (Value : F64x2) return F64 is (Native_Reduce_Add_F64x2 (Value));
   function Native_Reduce_Min_Number_F64x2 is new SSE2_Float_Reduce_128_S9 (F64x2, F64, "movdqa %10, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %9" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrlq $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "movdqa %5, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %3" & ASCII.LF & ASCII.HT & "pxor %1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %3, %5" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "pand %6, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $63, %4" & ASCII.LF & ASCII.HT & "psrlq $12, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $63, %4" & ASCII.LF & ASCII.HT & "psrlq $12, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1", "movaps %1, %0");
   function Reduce_Min_Number (Value : F64x2) return F64 is (Native_Reduce_Min_Number_F64x2 (Value));
   function Native_Reduce_Max_Number_F64x2 is new SSE2_Float_Reduce_128_S9 (F64x2, F64, "movdqa %10, %1" & ASCII.LF & ASCII.HT & "movdqa %1, %9" & ASCII.LF & ASCII.HT & "movdqa %9, %2" & ASCII.LF & ASCII.HT & "psrldq $8, %2" & ASCII.LF & ASCII.HT & "movdqa %1, %7" & ASCII.LF & ASCII.HT & "movdqa %2, %8" & ASCII.LF & ASCII.HT & "movdqa %7, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "psrad $31, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "pxor %4, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "psrad $31, %6" & ASCII.LF & ASCII.HT & "psrlq $1, %6" & ASCII.LF & ASCII.HT & "pxor %6, %5" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %4" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %4, %4" & ASCII.LF & ASCII.HT & "movdqa %3, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %5, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %1, %1" & ASCII.LF & ASCII.HT & "pslld $31, %1" & ASCII.LF & ASCII.HT & "pxor %1, %3" & ASCII.LF & ASCII.HT & "pxor %1, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %5, %3" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %3, %3" & ASCII.LF & ASCII.HT & "pand %6, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %4" & ASCII.LF & ASCII.HT & "pand %7, %4" & ASCII.LF & ASCII.HT & "pandn %8, %3" & ASCII.LF & ASCII.HT & "por %4, %3" & ASCII.LF & ASCII.HT & "movdqa %3, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %7, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pand %4, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %8, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %8, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %8, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %8, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $63, %4" & ASCII.LF & ASCII.HT & "psrlq $12, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1" & ASCII.LF & ASCII.HT & "movdqa %7, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "psrlq $1, %3" & ASCII.LF & ASCII.HT & "pand %3, %2" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $53, %4" & ASCII.LF & ASCII.HT & "psrlq $1, %4" & ASCII.LF & ASCII.HT & "movdqa %2, %5" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "movdqa %2, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %6" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %6, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %3, %3" & ASCII.LF & ASCII.HT & "pslld $31, %3" & ASCII.LF & ASCII.HT & "pxor %3, %2" & ASCII.LF & ASCII.HT & "pxor %3, %4" & ASCII.LF & ASCII.HT & "pcmpgtd %4, %2" & ASCII.LF & ASCII.HT & "pshufd $0xA0, %2, %2" & ASCII.LF & ASCII.HT & "pand %6, %2" & ASCII.LF & ASCII.HT & "por %2, %5" & ASCII.LF & ASCII.HT & "movdqa %5, %4" & ASCII.LF & ASCII.HT & "movdqa %7, %5" & ASCII.LF & ASCII.HT & "psllq $12, %5" & ASCII.LF & ASCII.HT & "pshufd $0xF5, %5, %5" & ASCII.LF & ASCII.HT & "psrad $31, %5" & ASCII.LF & ASCII.HT & "pandn %4, %5" & ASCII.LF & ASCII.HT & "movdqa %7, %6" & ASCII.LF & ASCII.HT & "pcmpeqd %4, %4" & ASCII.LF & ASCII.HT & "psllq $63, %4" & ASCII.LF & ASCII.HT & "psrlq $12, %4" & ASCII.LF & ASCII.HT & "por %4, %6" & ASCII.LF & ASCII.HT & "movdqa %5, %3" & ASCII.LF & ASCII.HT & "movdqa %6, %4" & ASCII.LF & ASCII.HT & "pand %5, %4" & ASCII.LF & ASCII.HT & "pandn %1, %3" & ASCII.LF & ASCII.HT & "por %3, %4" & ASCII.LF & ASCII.HT & "movdqa %4, %1", "movaps %1, %0");
   function Reduce_Max_Number (Value : F64x2) return F64 is (Native_Reduce_Max_Number_F64x2 (Value));
   function Native_Permute_F64x2 is new SSE2_Permute_128 (F64x2, Lane_Map_64x2, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Value : F64x2; Map : Lane_Map_64x2) return F64x2 is (Native_Permute_F64x2 (Value, Map));
   function Native_Permute_2_F64x2 is new SSE2_Permute_2_128 (F64x2, Two_Source_Lane_Map_64x2, "pxor %%xmm3, %%xmm3" & ASCII.LF & ASCII.HT & "pxor %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT & "pcmpeqd %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "psrlw $15, %%xmm7" & ASCII.LF & ASCII.HT & "packuswb %%xmm7, %%xmm7" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm0, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $1, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $2, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $3, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $4, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $6, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $7, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $8, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $9, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $10, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $11, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $12, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $13, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $14, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm1, %%xmm5" & ASCII.LF & ASCII.HT & "psrldq $15, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklbw %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "punpcklwd %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "pshufd $0, %%xmm5, %%xmm5" & ASCII.LF & ASCII.HT & "movdqa %%xmm2, %%xmm6" & ASCII.LF & ASCII.HT & "pcmpeqb %%xmm4, %%xmm6" & ASCII.LF & ASCII.HT & "pand %%xmm6, %%xmm5" & ASCII.LF & ASCII.HT & "por %%xmm5, %%xmm3" & ASCII.LF & ASCII.HT & "paddb %%xmm7, %%xmm4" & ASCII.LF & ASCII.HT & "movdqa %%xmm3, %%xmm0");
   function Permute_Lanes (Left, Right : F64x2; Map : Two_Source_Lane_Map_64x2) return F64x2 is (Native_Permute_2_F64x2 (Left, Right, Map));
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
      Asm (Template => "movdqu %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_F64x2'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Unaligned;
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (F64x2, Machine_Vector);
      Target : Lane_Values_F64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqu %1, %0",
           Outputs => Lane_Values_F64x2'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Unaligned;
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 is
      function To_Vector is new Ada.Unchecked_Conversion (Machine_Vector, F64x2);
      Source : constant Lane_Values_F64x2 with Import, Address => Data (Start)'Address;
      Result : Machine_Vector;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Machine_Vector'Asm_Output ("=x", Result),
           Inputs => Lane_Values_F64x2'Asm_Input ("m", Source));
      return To_Vector (Result);
   end Load_Aligned;
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) is
      function To_Machine is new Ada.Unchecked_Conversion (F64x2, Machine_Vector);
      Target : Lane_Values_F64x2 with Import, Address => Data (Start)'Address;
   begin
      Asm (Template => "movdqa %1, %0",
           Outputs => Lane_Values_F64x2'Asm_Output ("=m", Target),
           Inputs => Machine_Vector'Asm_Input ("x", To_Machine (Value)));
   end Store_Aligned;
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
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16 is (Count_Set_Bits (Interfaces.Unsigned_32 (To_Bit_Mask (Mask))));
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 16));
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 16));
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
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8 is (Count_Set_Bits (Interfaces.Unsigned_32 (To_Bit_Mask (Mask))));
   function First_True (Mask : Mask_16x8) return Lane_Count_16x8 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 8));
   function Last_True (Mask : Mask_16x8) return Lane_Count_16x8 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 8));
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
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4 is (Count_Set_Bits (Interfaces.Unsigned_32 (To_Bit_Mask (Mask))));
   function First_True (Mask : Mask_32x4) return Lane_Count_32x4 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 4));
   function Last_True (Mask : Mask_32x4) return Lane_Count_32x4 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 4));
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
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2 is (Count_Set_Bits (Interfaces.Unsigned_32 (To_Bit_Mask (Mask))));
   function First_True (Mask : Mask_64x2) return Lane_Count_64x2 is (Find_First_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 2));
   function Last_True (Mask : Mask_64x2) return Lane_Count_64x2 is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), 2));
   --  END GENERATED FULL-FAMILY X86 BODIES
end Flyology_SIMD.Backends.Native;
