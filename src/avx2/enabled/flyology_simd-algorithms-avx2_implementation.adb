with Interfaces;
with System.Machine_Code;
with Flyology_SIMD.Algorithms.Scalar;

package body Flyology_SIMD.Algorithms.AVX2_Implementation is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;
   use System.Machine_Code;

   function Sum (Data : F32_Array) return F32 is
      Accumulator  : aliased Lane_Values_F32x4 := [others => 0.0];
      Result       : F32 := 0.0;
      Offset       : Natural := 0;
      Vector_Count : Natural := Data'Length / 8;
      Cursor       : System.Address;
   begin
      if Vector_Count > 0 then
         Cursor := Data (Data'First)'Address;
         Asm
           (Template =>
              "vxorps %%xmm4, %%xmm4, %%xmm4" & ASCII.LF &
              "0:" & ASCII.LF & ASCII.HT &
              "vmovups (%0), %%ymm0" & ASCII.LF & ASCII.HT &
              "vaddps %%xmm0, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "vextractf128 $1, %%ymm0, %%xmm1" & ASCII.LF & ASCII.HT &
              "vaddps %%xmm1, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "addq $32, %0" & ASCII.LF & ASCII.HT &
              "subl $1, %1" & ASCII.LF & ASCII.HT &
              "jnz 0b" & ASCII.LF & ASCII.HT &
              "vmovups %%xmm4, (%2)" & ASCII.LF & ASCII.HT &
              "vzeroupper",
            Outputs =>
              [System.Address'Asm_Output ("+&r", Cursor),
               Natural'Asm_Output ("+&r", Vector_Count)],
            Inputs =>
              System.Address'Asm_Input ("r", Accumulator'Address),
            Clobber => "ymm0,ymm1,ymm4,cc,memory",
            Volatile => True);
         Offset := (Data'Length / 8) * 8;
      end if;

      while Offset < Data'Length loop
         declare
            Lane : constant Lane_Index_32x4 :=
              Lane_Index_32x4 (Offset mod 4);
         begin
            Accumulator (Lane) :=
              Accumulator (Lane) + Data (Data'First + Offset);
         end;
         Offset := Offset + 1;
      end loop;
      for Lane in Accumulator'Range loop
         Result := Result + Accumulator (Lane);
      end loop;
      return Result;
   end Sum;

   function Sum (Data : F64_Array) return F64 is
      Accumulator  : aliased Lane_Values_F64x2 := [others => 0.0];
      Result       : F64 := 0.0;
      Offset       : Natural := 0;
      Vector_Count : Natural := Data'Length / 4;
      Cursor       : System.Address;
   begin
      if Vector_Count > 0 then
         Cursor := Data (Data'First)'Address;
         Asm
           (Template =>
              "vxorpd %%xmm4, %%xmm4, %%xmm4" & ASCII.LF &
              "0:" & ASCII.LF & ASCII.HT &
              "vmovupd (%0), %%ymm0" & ASCII.LF & ASCII.HT &
              "vaddpd %%xmm0, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "vextractf128 $1, %%ymm0, %%xmm1" & ASCII.LF & ASCII.HT &
              "vaddpd %%xmm1, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "addq $32, %0" & ASCII.LF & ASCII.HT &
              "subl $1, %1" & ASCII.LF & ASCII.HT &
              "jnz 0b" & ASCII.LF & ASCII.HT &
              "vmovupd %%xmm4, (%2)" & ASCII.LF & ASCII.HT &
              "vzeroupper",
            Outputs =>
              [System.Address'Asm_Output ("+&r", Cursor),
               Natural'Asm_Output ("+&r", Vector_Count)],
            Inputs =>
              System.Address'Asm_Input ("r", Accumulator'Address),
            Clobber => "ymm0,ymm1,ymm4,cc,memory",
            Volatile => True);
         Offset := (Data'Length / 4) * 4;
      end if;

      while Offset < Data'Length loop
         declare
            Lane : constant Lane_Index_64x2 :=
              Lane_Index_64x2 (Offset mod 2);
         begin
            Accumulator (Lane) :=
              Accumulator (Lane) + Data (Data'First + Offset);
         end;
         Offset := Offset + 1;
      end loop;
      for Lane in Accumulator'Range loop
         Result := Result + Accumulator (Lane);
      end loop;
      return Result;
   end Sum;

   function Dot_Product (Left, Right : F32_Array) return F32 is
      Accumulator  : aliased Lane_Values_F32x4 := [others => 0.0];
      Result       : F32 := 0.0;
      Offset       : Natural := 0;
      Vector_Count : Natural := Left'Length / 8;
      Left_Cursor  : System.Address;
      Right_Cursor : System.Address;
   begin
      if Vector_Count > 0 then
         Left_Cursor := Left (Left'First)'Address;
         Right_Cursor := Right (Right'First)'Address;
         Asm
           (Template =>
              "vxorps %%xmm4, %%xmm4, %%xmm4" & ASCII.LF &
              "0:" & ASCII.LF & ASCII.HT &
              "vmovups (%0), %%ymm0" & ASCII.LF & ASCII.HT &
              "vmovups (%1), %%ymm1" & ASCII.LF & ASCII.HT &
              "vmulps %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
              "vaddps %%xmm0, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "vextractf128 $1, %%ymm0, %%xmm1" & ASCII.LF & ASCII.HT &
              "vaddps %%xmm1, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "addq $32, %0" & ASCII.LF & ASCII.HT &
              "addq $32, %1" & ASCII.LF & ASCII.HT &
              "subl $1, %2" & ASCII.LF & ASCII.HT &
              "jnz 0b" & ASCII.LF & ASCII.HT &
              "vmovups %%xmm4, (%3)" & ASCII.LF & ASCII.HT &
              "vzeroupper",
            Outputs =>
              [System.Address'Asm_Output ("+&r", Left_Cursor),
               System.Address'Asm_Output ("+&r", Right_Cursor),
               Natural'Asm_Output ("+&r", Vector_Count)],
            Inputs =>
              System.Address'Asm_Input ("r", Accumulator'Address),
            Clobber => "ymm0,ymm1,ymm4,cc,memory",
            Volatile => True);
         Offset := (Left'Length / 8) * 8;
      end if;

      while Offset < Left'Length loop
         declare
            Lane : constant Lane_Index_32x4 :=
              Lane_Index_32x4 (Offset mod 4);
            Index : constant Natural := Left'First + Offset;
         begin
            Accumulator (Lane) :=
              Accumulator (Lane) + Left (Index) * Right (Index);
         end;
         Offset := Offset + 1;
      end loop;
      for Lane in Accumulator'Range loop
         Result := Result + Accumulator (Lane);
      end loop;
      return Result;
   end Dot_Product;

   function Dot_Product (Left, Right : F64_Array) return F64 is
      Accumulator  : aliased Lane_Values_F64x2 := [others => 0.0];
      Result       : F64 := 0.0;
      Offset       : Natural := 0;
      Vector_Count : Natural := Left'Length / 4;
      Left_Cursor  : System.Address;
      Right_Cursor : System.Address;
   begin
      if Vector_Count > 0 then
         Left_Cursor := Left (Left'First)'Address;
         Right_Cursor := Right (Right'First)'Address;
         Asm
           (Template =>
              "vxorpd %%xmm4, %%xmm4, %%xmm4" & ASCII.LF &
              "0:" & ASCII.LF & ASCII.HT &
              "vmovupd (%0), %%ymm0" & ASCII.LF & ASCII.HT &
              "vmovupd (%1), %%ymm1" & ASCII.LF & ASCII.HT &
              "vmulpd %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
              "vaddpd %%xmm0, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "vextractf128 $1, %%ymm0, %%xmm1" & ASCII.LF & ASCII.HT &
              "vaddpd %%xmm1, %%xmm4, %%xmm4" & ASCII.LF & ASCII.HT &
              "addq $32, %0" & ASCII.LF & ASCII.HT &
              "addq $32, %1" & ASCII.LF & ASCII.HT &
              "subl $1, %2" & ASCII.LF & ASCII.HT &
              "jnz 0b" & ASCII.LF & ASCII.HT &
              "vmovupd %%xmm4, (%3)" & ASCII.LF & ASCII.HT &
              "vzeroupper",
            Outputs =>
              [System.Address'Asm_Output ("+&r", Left_Cursor),
               System.Address'Asm_Output ("+&r", Right_Cursor),
               Natural'Asm_Output ("+&r", Vector_Count)],
            Inputs =>
              System.Address'Asm_Input ("r", Accumulator'Address),
            Clobber => "ymm0,ymm1,ymm4,cc,memory",
            Volatile => True);
         Offset := (Left'Length / 4) * 4;
      end if;

      while Offset < Left'Length loop
         declare
            Lane : constant Lane_Index_64x2 :=
              Lane_Index_64x2 (Offset mod 2);
            Index : constant Natural := Left'First + Offset;
         begin
            Accumulator (Lane) :=
              Accumulator (Lane) + Left (Index) * Right (Index);
         end;
         Offset := Offset + 1;
      end loop;
      for Lane in Accumulator'Range loop
         Result := Result + Accumulator (Lane);
      end loop;
      return Result;
   end Dot_Product;

   function Difference_Mask_32
     (Left, Right : Byte_Array; Start : Natural)
      return Interfaces.Unsigned_32
   is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vpmovmskb %%ymm0, %0" & ASCII.LF & ASCII.HT &
           "notl %0" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs =>
           [System.Address'Asm_Input ("r", Left (Start)'Address),
            System.Address'Asm_Input ("r", Right (Start)'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Difference_Mask_32;
   pragma Inline_Always (Difference_Mask_32);

   function Equal_Mask_32
     (Data : Byte_Array; Start : Natural; Needle : U8)
      return Interfaces.Unsigned_32
   is
      Result : Interfaces.Unsigned_32;
      Local_Needle : aliased U8 := Needle;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm1, %%ymm0, %%ymm0" & ASCII.LF & ASCII.HT &
           "vpmovmskb %%ymm0, %0" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs =>
           [System.Address'Asm_Input ("r", Data (Start)'Address),
            System.Address'Asm_Input ("r", Local_Needle'Address)],
         Clobber => "ymm0,ymm1,memory",
         Volatile => True);
      return Result;
   end Equal_Mask_32;
   pragma Inline_Always (Equal_Mask_32);

   function High_Bit_Mask_32
     (Data : Byte_Array; Start : Natural) return Interfaces.Unsigned_32
   is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vpmovmskb %%ymm0, %0" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => System.Address'Asm_Input ("r", Data (Start)'Address),
         Clobber => "ymm0,memory",
         Volatile => True);
      return Result;
   end High_Bit_Mask_32;
   pragma Inline_Always (High_Bit_Mask_32);

   function Equal_Any_Offset_32
     (Data : Byte_Array;
      Start : Natural;
      Length : Natural;
      Needle_0, Needle_1, Needle_2, Needle_3 : U8)
      return Interfaces.Unsigned_32
   is
      Cursor : System.Address := Data (Start)'Address;
      Offset : Interfaces.Unsigned_32;
      Bits : Interfaces.Unsigned_32;
      Local_0 : aliased U8 := Needle_0;
      Local_1 : aliased U8 := Needle_1;
      Local_2 : aliased U8 := Needle_2;
      Local_3 : aliased U8 := Needle_3;
   begin
      Asm
        (Template =>
           "xorl %1, %1" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%3), %%ymm4" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%4), %%ymm5" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%5), %%ymm6" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%6), %%ymm7" & ASCII.LF &
           "0:" & ASCII.LF & ASCII.HT &
           "vmovdqu (%0), %%ymm0" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm4, %%ymm0, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm5, %%ymm0, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm6, %%ymm0, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm7, %%ymm0, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpor %%ymm2, %%ymm1, %%ymm1" & ASCII.LF & ASCII.HT &
           "vpmovmskb %%ymm1, %2" & ASCII.LF & ASCII.HT &
           "testl %2, %2" & ASCII.LF & ASCII.HT &
           "jne 1f" & ASCII.LF & ASCII.HT &
           "addq $32, %0" & ASCII.LF & ASCII.HT &
           "addl $32, %1" & ASCII.LF & ASCII.HT &
           "cmpl %7, %1" & ASCII.LF & ASCII.HT &
           "jb 0b" & ASCII.LF & ASCII.HT &
           "movl $-1, %1" & ASCII.LF & ASCII.HT &
           "jmp 2f" & ASCII.LF &
           "1:" & ASCII.LF & ASCII.HT &
           "bsfl %2, %2" & ASCII.LF & ASCII.HT &
           "addl %2, %1" & ASCII.LF &
           "2:" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Outputs =>
           [System.Address'Asm_Output ("+&r", Cursor),
            Interfaces.Unsigned_32'Asm_Output ("=&r", Offset),
            Interfaces.Unsigned_32'Asm_Output ("=&r", Bits)],
         Inputs =>
           [System.Address'Asm_Input ("r", Local_0'Address),
            System.Address'Asm_Input ("r", Local_1'Address),
            System.Address'Asm_Input ("r", Local_2'Address),
            System.Address'Asm_Input ("r", Local_3'Address),
            Natural'Asm_Input ("r", Length)],
         Clobber => "ymm0,ymm1,ymm2,ymm4,ymm5,ymm6,ymm7,cc,memory",
         Volatile => True);
      return Offset;
   end Equal_Any_Offset_32;
   pragma Inline_Always (Equal_Any_Offset_32);

   function Equal_Any_Mask_16
     (Data : Byte_Array;
      Start : Natural;
      Needle_0, Needle_1, Needle_2, Needle_3 : U8)
      return Interfaces.Unsigned_32
   is
      Result : Interfaces.Unsigned_32;
      Local_0 : aliased U8 := Needle_0;
      Local_1 : aliased U8 := Needle_1;
      Local_2 : aliased U8 := Needle_2;
      Local_3 : aliased U8 := Needle_3;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%xmm0" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%2), %%xmm4" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%3), %%xmm5" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%4), %%xmm6" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%5), %%xmm7" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%xmm4, %%xmm0, %%xmm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%xmm5, %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT &
           "vpor %%xmm2, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%xmm6, %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT &
           "vpor %%xmm2, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%xmm7, %%xmm0, %%xmm2" & ASCII.LF & ASCII.HT &
           "vpor %%xmm2, %%xmm1, %%xmm1" & ASCII.LF & ASCII.HT &
           "vpmovmskb %%xmm1, %0" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs =>
           [System.Address'Asm_Input ("r", Data (Start)'Address),
            System.Address'Asm_Input ("r", Local_0'Address),
            System.Address'Asm_Input ("r", Local_1'Address),
            System.Address'Asm_Input ("r", Local_2'Address),
            System.Address'Asm_Input ("r", Local_3'Address)],
         Clobber => "xmm0,xmm1,xmm2,xmm4,xmm5,xmm6,xmm7,memory",
         Volatile => True);
      return Result;
   end Equal_Any_Mask_16;
   pragma Inline_Always (Equal_Any_Mask_16);

   function First_Set_Bit (Bits : Interfaces.Unsigned_32) return Natural is
      Result : Interfaces.Unsigned_32;
   begin
      Asm
        (Template => "bsfl %1, %0",
         Outputs => Interfaces.Unsigned_32'Asm_Output ("=r", Result),
         Inputs => Interfaces.Unsigned_32'Asm_Input ("r", Bits),
         Volatile => True);
      return Natural (Result);
   end First_Set_Bit;
   pragma Inline_Always (First_Set_Bit);

   function Find_First_Difference
     (Left, Right : Byte_Array) return Search_Result
   is
      Offset : Natural := 0;
      Bits   : Interfaces.Unsigned_32;
   begin
      while Left'Length - Offset >= 32 loop
         Bits := Difference_Mask_32 (Left, Right, Left'First + Offset);
         if Bits /= 0 then
            return
              (Found => True,
               Index => Left'First + Offset + First_Set_Bit (Bits));
         end if;
         Offset := Offset + 32;
      end loop;
      while Offset < Left'Length loop
         if Left (Left'First + Offset) /= Right (Right'First + Offset) then
            return (Found => True, Index => Left'First + Offset);
         end if;
         Offset := Offset + 1;
      end loop;
      return (Found => False, Index => 0);
   end Find_First_Difference;

   function Equal (Left, Right : Byte_Array) return Boolean is
     (not Find_First_Difference (Left, Right).Found);

   function Popcount (Value : Interfaces.Unsigned_32) return Natural is
      Bits : Interfaces.Unsigned_32 := Value;
      Result : Natural := 0;
   begin
      while Bits /= 0 loop
         Result := Result + 1;
         Bits := Bits and (Bits - 1);
      end loop;
      return Result;
   end Popcount;

   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result is
      Offset : Natural := 0;
      Bits : Interfaces.Unsigned_32;
   begin
      while Data'Length - Offset >= 32 loop
         Bits := Equal_Mask_32 (Data, Data'First + Offset, Needle);
         if Bits /= 0 then
            return
              (Found => True,
               Index => Data'First + Offset + First_Set_Bit (Bits));
         end if;
         Offset := Offset + 32;
      end loop;
      while Offset < Data'Length loop
         if Data (Data'First + Offset) = Needle then
            return (Found => True, Index => Data'First + Offset);
         end if;
         Offset := Offset + 1;
      end loop;
      return (Found => False, Index => 0);
   end Find_First;

   function Find_First_Of
     (Data : Byte_Array; Needles : Byte_Array) return Search_Result
   is
      Offset : Natural := 0;
      Full_Bytes : Natural;
      Match_Offset : Interfaces.Unsigned_32;
      Bits : Interfaces.Unsigned_32;
      Needle_0, Needle_1, Needle_2, Needle_3 : U8;
   begin
      case Needles'Length is
         when 0 =>
            return (Found => False, Index => 0);
         when 1 =>
            return Find_First (Data, Needles (Needles'First));
         when 2 .. 4 =>
            Needle_0 := Needles (Needles'First);
            Needle_1 := Needles (Needles'First + 1);
            Needle_2 :=
              (if Needles'Length >= 3
               then Needles (Needles'First + 2) else Needle_0);
            Needle_3 :=
              (if Needles'Length >= 4
               then Needles (Needles'First + 3) else Needle_0);
         when others =>
            return Algorithms.Scalar.Find_First_Of (Data, Needles);
      end case;

      Full_Bytes := Data'Length - (Data'Length mod 32);
      if Full_Bytes > 0 then
         Match_Offset := Equal_Any_Offset_32
           (Data, Data'First, Full_Bytes,
            Needle_0, Needle_1, Needle_2, Needle_3);
         if Match_Offset /= Interfaces.Unsigned_32'Last then
            return
              (Found => True,
               Index => Data'First + Natural (Match_Offset));
         end if;
         Offset := Full_Bytes;
      end if;

      if Data'Length - Offset >= 16 then
         Bits := Equal_Any_Mask_16
           (Data, Data'First + Offset,
            Needle_0, Needle_1, Needle_2, Needle_3);
         if Bits /= 0 then
            return
              (Found => True,
               Index => Data'First + Offset + First_Set_Bit (Bits));
         end if;
         Offset := Offset + 16;
      end if;

      while Offset < Data'Length loop
         declare
            Item : constant U8 := Data (Data'First + Offset);
         begin
            if Item = Needle_0
              or else Item = Needle_1
              or else Item = Needle_2
              or else Item = Needle_3
            then
               return (Found => True, Index => Data'First + Offset);
            end if;
         end;
         Offset := Offset + 1;
      end loop;
      return (Found => False, Index => 0);
   end Find_First_Of;

   function Count (Data : Byte_Array; Needle : U8) return Natural is
      Offset : Natural := 0;
      Result : Natural := 0;
   begin
      while Data'Length - Offset >= 32 loop
         Result := Result +
           Popcount (Equal_Mask_32 (Data, Data'First + Offset, Needle));
         Offset := Offset + 32;
      end loop;
      while Offset < Data'Length loop
         if Data (Data'First + Offset) = Needle then
            Result := Result + 1;
         end if;
         Offset := Offset + 1;
      end loop;
      return Result;
   end Count;

   function Is_ASCII (Data : Byte_Array) return Boolean is
      Offset : Natural := 0;
   begin
      while Data'Length - Offset >= 32 loop
         if High_Bit_Mask_32 (Data, Data'First + Offset) /= 0 then
            return False;
         end if;
         Offset := Offset + 32;
      end loop;
      while Offset < Data'Length loop
         if (Data (Data'First + Offset) and 16#80#) /= 0 then
            return False;
         end if;
         Offset := Offset + 1;
      end loop;
      return True;
   end Is_ASCII;
end Flyology_SIMD.Algorithms.AVX2_Implementation;
