with Interfaces;
with System.Machine_Code;

package body Flyology_SIMD.Algorithms.AVX2_Implementation is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;
   use System.Machine_Code;

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
