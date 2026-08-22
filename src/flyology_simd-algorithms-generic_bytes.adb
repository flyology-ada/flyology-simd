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

   function Find_First_Difference (Left, Right : Byte_Array) return Search_Result is
      Offset : Natural := 0;
      Bits   : Interfaces.Unsigned_16;
   begin
      while Left'Length - Offset >= 16 loop
         Bits :=
           not Backend_To_Bit_Mask
                 (Backend_Equal
                    (Backend_Load_Unaligned (Left, Left'First + Offset),
                     Backend_Load_Unaligned (Right, Right'First + Offset)));
         if Bits /= 0 then
            for Lane in Lane_Index_8x16 loop
               if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane)) /= 0 then
                  return (Found => True, Index => Left'First + Offset + Lane);
               end if;
            end loop;
         end if;
         Offset := Offset + 16;
      end loop;

      while Offset < Left'Length loop
         if Left (Left'First + Offset) /= Right (Right'First + Offset) then
            return (Found => True, Index => Left'First + Offset);
         end if;
         Offset := Offset + 1;
      end loop;
      return (Found => False, Index => 0);
   end Find_First_Difference;

   function Equal (Left, Right : Byte_Array) return Boolean
   is (not Find_First_Difference (Left, Right).Found);

   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result is
      Offset : Natural := 0;
      Bits   : Interfaces.Unsigned_16;
      Wanted : constant U8x16 := Backend_Splat (Needle);
   begin
      while Data'Length - Offset >= 16 loop
         Bits :=
           Backend_To_Bit_Mask (Backend_Equal (Backend_Load_Unaligned (Data, Data'First + Offset), Wanted));
         if Bits /= 0 then
            for Lane in Lane_Index_8x16 loop
               if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane)) /= 0 then
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

   function Find_First_Of (Data : Byte_Array; Needles : Byte_Array) return Search_Result is
      function Find_Small (Needle_0, Needle_1, Needle_2, Needle_3 : U8; Count : Natural) return Search_Result
      is
         Offset   : Natural := 0;
         Bits     : Interfaces.Unsigned_16;
         Value    : U8x16;
         Wanted_0 : constant U8x16 := Backend_Splat (Needle_0);
         Wanted_1 : constant U8x16 := Backend_Splat (Needle_1);
         Wanted_2 : constant U8x16 := Backend_Splat (Needle_2);
         Wanted_3 : constant U8x16 := Backend_Splat (Needle_3);
      begin
         while Data'Length - Offset >= 16 loop
            Value := Backend_Load_Unaligned (Data, Data'First + Offset);
            Bits := Backend_To_Bit_Mask (Backend_Equal (Value, Wanted_0));
            if Count >= 2 then
               Bits := Bits or Backend_To_Bit_Mask (Backend_Equal (Value, Wanted_1));
            end if;
            if Count >= 3 then
               Bits := Bits or Backend_To_Bit_Mask (Backend_Equal (Value, Wanted_2));
            end if;
            if Count >= 4 then
               Bits := Bits or Backend_To_Bit_Mask (Backend_Equal (Value, Wanted_3));
            end if;
            if Bits /= 0 then
               for Lane in Lane_Index_8x16 loop
                  if (Bits and Interfaces.Shift_Left (Interfaces.Unsigned_16'(1), Lane)) /= 0 then
                     return (Found => True, Index => Data'First + Offset + Lane);
                  end if;
               end loop;
            end if;
            Offset := Offset + 16;
         end loop;

         while Offset < Data'Length loop
            declare
               Item : constant U8 := Data (Data'First + Offset);
            begin
               if Item = Needle_0
                 or else (Count >= 2 and then Item = Needle_1)
                 or else (Count >= 3 and then Item = Needle_2)
                 or else (Count >= 4 and then Item = Needle_3)
               then
                  return (Found => True, Index => Data'First + Offset);
               end if;
            end;
            Offset := Offset + 1;
         end loop;
         return (Found => False, Index => 0);
      end Find_Small;
      pragma Inline_Always (Find_Small);
   begin
      case Needles'Length is
         when 0      =>
            return (Found => False, Index => 0);

         when 1      =>
            return Find_First (Data, Needles (Needles'First));

         when 2      =>
            return Find_Small (Needles (Needles'First), Needles (Needles'First + 1), 0, 0, 2);

         when 3      =>
            return
              Find_Small
                (Needles (Needles'First), Needles (Needles'First + 1), Needles (Needles'First + 2), 0, 3);

         when 4      =>
            return
              Find_Small
                (Needles (Needles'First),
                 Needles (Needles'First + 1),
                 Needles (Needles'First + 2),
                 Needles (Needles'First + 3),
                 4);

         when others =>
            for Index in Data'Range loop
               for Needle of Needles loop
                  if Data (Index) = Needle then
                     return (Found => True, Index => Index);
                  end if;
               end loop;
            end loop;
            return (Found => False, Index => 0);
      end case;
   end Find_First_Of;

   function Count (Data : Byte_Array; Needle : U8) return Natural is
      Offset : Natural := 0;
      Result : Natural := 0;
      Wanted : constant U8x16 := Backend_Splat (Needle);
   begin
      while Data'Length - Offset >= 16 loop
         Result :=
           Result
           + Popcount
               (Backend_To_Bit_Mask
                  (Backend_Equal (Backend_Load_Unaligned (Data, Data'First + Offset), Wanted)));
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

   function Count_In_Range (Data : Byte_Array; Low, High : U8) return Natural is
      Offset : Natural := 0;
      Result : Natural := 0;
      Lower  : constant U8x16 := Backend_Splat (Low);
      Upper  : constant U8x16 := Backend_Splat (High);
   begin
      while Data'Length - Offset >= 16 loop
         declare
            Value : constant U8x16 := Backend_Load_Unaligned (Data, Data'First + Offset);
         begin
            Result :=
              Result
              + Popcount
                  (Backend_To_Bit_Mask
                     (Backend_Mask_And
                        (Backend_Greater_Equal (Value, Lower), Backend_Less_Equal (Value, Upper))));
         end;
         Offset := Offset + 16;
      end loop;
      while Offset < Data'Length loop
         if Data (Data'First + Offset) >= Low and then Data (Data'First + Offset) <= High then
            Result := Result + 1;
         end if;
         Offset := Offset + 1;
      end loop;
      return Result;
   end Count_In_Range;

   procedure Add_Saturate (Data : in out Byte_Array; Value : U8) is
      Offset : Natural := 0;
      Addend : constant U8x16 := Backend_Splat (Value);
   begin
      while Data'Length - Offset >= 16 loop
         Backend_Store_Unaligned
           (Data,
            Data'First + Offset,
            Backend_Add_Saturate (Backend_Load_Unaligned (Data, Data'First + Offset), Addend));
         Offset := Offset + 16;
      end loop;
      while Offset < Data'Length loop
         declare
            Index : constant Natural := Data'First + Offset;
         begin
            if Data (Index) > U8'Last - Value then
               Data (Index) := U8'Last;
            else
               Data (Index) := Data (Index) + Value;
            end if;
         end;
         Offset := Offset + 1;
      end loop;
   end Add_Saturate;

   function Is_ASCII (Data : Byte_Array) return Boolean is
      Offset    : Natural := 0;
      High_Bit  : constant U8x16 := Backend_Splat (16#80#);
      Zero_Bits : constant U8x16 := Backend_Splat (0);
   begin
      while Data'Length - Offset >= 16 loop
         if Backend_To_Bit_Mask
              (Backend_Equal
                 (Backend_Bitwise_And (Backend_Load_Unaligned (Data, Data'First + Offset), High_Bit),
                  Zero_Bits))
           /= Interfaces.Unsigned_16'Last
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
