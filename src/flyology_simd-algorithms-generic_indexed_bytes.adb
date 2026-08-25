with System;
with System.Storage_Elements;
with Flyology_SIMD.Index_Arithmetic;

package body Flyology_SIMD.Algorithms.Generic_Indexed_Bytes is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use System.Storage_Elements;

   pragma
     Compile_Time_Error
       (Byte_Type'Modulus /= 2**U8'Size,
        "Generic_Indexed_Bytes requires an eight-bit modular component type");
   pragma
     Compile_Time_Error
       (Byte_Array_Type'Component_Size /= U8'Size,
        "Generic_Indexed_Bytes requires contiguous eight-bit array components");

   package Index_Arithmetic is new Flyology_SIMD.Index_Arithmetic (Index_Type, Byte_Type, Byte_Array_Type);

   function Index_At (Data : Byte_Array_Type; Offset : Natural) return Index_Type
   renames Index_Arithmetic.Index_At;
   pragma Inline_Always (Index_At);

   function Load_Unaligned (Address : System.Address) return U8x16 is
      Source : constant Lane_Values_8x16
      with Import, Address => Address;
   begin
      return (Lanes => Source);
   end Load_Unaligned;
   pragma Inline_Always (Load_Unaligned);

   function Find_First_Of (Data : Byte_Array_Type; Needles : Byte_Array_Type) return Search_Result is
      function Find_Small (Needle_0, Needle_1, Needle_2, Needle_3 : U8; Count : Natural) return Search_Result
      is
         Offset   : Natural := 0;
         Bits     : Interfaces.Unsigned_16;
         Value    : U8x16;
         Wanted_0 : constant U8x16 := Backend_Splat (Needle_0);
         Wanted_1 : constant U8x16 := Backend_Splat (Needle_1);
         Wanted_2 : constant U8x16 := Backend_Splat (Needle_2);
         Wanted_3 : constant U8x16 := Backend_Splat (Needle_3);
         Base     : System.Address := System.Null_Address;
      begin
         if Data'Length = 0 then
            return (Found => False, Index => Index_Type'First);
         end if;
         Base := Data (Data'First)'Address;

         while Data'Length - Offset >= 16 loop
            Value := Load_Unaligned (Base + Storage_Offset (Offset));
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
                     return (Found => True, Index => Index_At (Data, Offset + Lane));
                  end if;
               end loop;
            end if;
            Offset := Offset + 16;
         end loop;

         while Offset < Data'Length loop
            declare
               Item : constant U8 := U8 (Data (Index_At (Data, Offset)));
            begin
               if Item = Needle_0
                 or else (Count >= 2 and then Item = Needle_1)
                 or else (Count >= 3 and then Item = Needle_2)
                 or else (Count >= 4 and then Item = Needle_3)
               then
                  return (Found => True, Index => Index_At (Data, Offset));
               end if;
            end;
            Offset := Offset + 1;
         end loop;
         return (Found => False, Index => Index_Type'First);
      end Find_Small;
      pragma Inline_Always (Find_Small);
   begin
      case Needles'Length is
         when 0      =>
            return (Found => False, Index => Index_Type'First);

         when 1      =>
            return Find_Small (U8 (Needles (Needles'First)), 0, 0, 0, 1);

         when 2      =>
            return Find_Small (U8 (Needles (Needles'First)), U8 (Needles (Index_At (Needles, 1))), 0, 0, 2);

         when 3      =>
            return
              Find_Small
                (U8 (Needles (Needles'First)),
                 U8 (Needles (Index_At (Needles, 1))),
                 U8 (Needles (Index_At (Needles, 2))),
                 0,
                 3);

         when 4      =>
            return
              Find_Small
                (U8 (Needles (Needles'First)),
                 U8 (Needles (Index_At (Needles, 1))),
                 U8 (Needles (Index_At (Needles, 2))),
                 U8 (Needles (Index_At (Needles, 3))),
                 4);

         when others =>
            for Index in Data'Range loop
               for Needle of Needles loop
                  if Data (Index) = Needle then
                     return (Found => True, Index => Index);
                  end if;
               end loop;
            end loop;
            return (Found => False, Index => Index_Type'First);
      end case;
   end Find_First_Of;
end Flyology_SIMD.Algorithms.Generic_Indexed_Bytes;
