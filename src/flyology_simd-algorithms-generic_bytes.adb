package body Flyology_SIMD.Algorithms.Generic_Bytes is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;

   function Popcount (Value : Interfaces.Unsigned_16) return Natural is
      Bits   : Interfaces.Unsigned_16 := Value;
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
      Bits   : Interfaces.Unsigned_16;
      Wanted : constant U8x16 := Backend_Splat (Needle);
   begin
      while Data'Length - Offset >= 16 loop
         Bits := Backend_To_Bit_Mask
           (Backend_Equal
              (Backend_Load_Unaligned (Data, Data'First + Offset), Wanted));
         if Bits /= 0 then
            for Lane in Lane_Index_8x16 loop
               if (Bits and Interfaces.Shift_Left
                     (Interfaces.Unsigned_16'(1), Lane)) /= 0
               then
                  return (Found => True, Index => Data'First + Offset + Lane);
               end if;
            end loop;
         end if;
         Offset := Offset + 16;
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
      Wanted : constant U8x16 := Backend_Splat (Needle);
   begin
      while Data'Length - Offset >= 16 loop
         Result := Result + Popcount
           (Backend_To_Bit_Mask
              (Backend_Equal
                 (Backend_Load_Unaligned (Data, Data'First + Offset), Wanted)));
         Offset := Offset + 16;
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
      Offset    : Natural := 0;
      High_Bit  : constant U8x16 := Backend_Splat (16#80#);
      Zero_Bits : constant U8x16 := Backend_Splat (0);
   begin
      while Data'Length - Offset >= 16 loop
         if Backend_To_Bit_Mask
              (Backend_Equal
                 (Backend_Bitwise_And
                    (Backend_Load_Unaligned (Data, Data'First + Offset), High_Bit),
                  Zero_Bits)) /= Interfaces.Unsigned_16'Last
         then
            return False;
         end if;
         Offset := Offset + 16;
      end loop;
      while Offset < Data'Length loop
         if (Data (Data'First + Offset) and 16#80#) /= 0 then
            return False;
         end if;
         Offset := Offset + 1;
      end loop;
      return True;
   end Is_ASCII;
end Flyology_SIMD.Algorithms.Generic_Bytes;
