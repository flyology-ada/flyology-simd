with Flyology_SIMD.Backends.Native;
with System.Machine_Code;

package body Flyology_SIMD.Wide.Compact_Mechanism is
   use System.Machine_Code;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   type Byte_Map is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;

   generic
      type Vector_Type is private;
   function Permute_256 (Value : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_256 (Value : Vector_Type; Map : Byte_Map) return Vector_Type is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%1, #16]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2]" & ASCII.LF & ASCII.HT &
           "tbl v3.16b, {v0.16b, v1.16b}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%2, #16]" & ASCII.LF & ASCII.HT &
           "tbl v3.16b, {v0.16b, v1.16b}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q3, [%0, #16]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Map'Address)],
         Clobber => "v0,v1,v2,v3,memory",
         Volatile => True);
      return Result;
   end Permute_256;

   function Permute_U8x32 is new Permute_256 (U8x32);
   pragma Inline_Always (Permute_U8x32);
   function Permute_I8x32 is new Permute_256 (I8x32);
   pragma Inline_Always (Permute_I8x32);
   function Permute_U16x16 is new Permute_256 (U16x16);
   pragma Inline_Always (Permute_U16x16);
   function Permute_I16x16 is new Permute_256 (I16x16);
   pragma Inline_Always (Permute_I16x16);
   function Permute_U32x8 is new Permute_256 (U32x8);
   pragma Inline_Always (Permute_U32x8);
   function Permute_I32x8 is new Permute_256 (I32x8);
   pragma Inline_Always (Permute_I32x8);
   function Permute_U64x4 is new Permute_256 (U64x4);
   pragma Inline_Always (Permute_U64x4);
   function Permute_I64x4 is new Permute_256 (I64x4);
   pragma Inline_Always (Permute_I64x4);
   function Permute_F32x8 is new Permute_256 (F32x8);
   pragma Inline_Always (Permute_F32x8);
   function Permute_F64x4 is new Permute_256 (F64x4);
   pragma Inline_Always (Permute_F64x4);

   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 0 loop
               Map (Result_Lane * 1 + Byte) :=
                 U8 (Lane * 1 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_U8x32 (Value, Map);
   end Compress;
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 0 loop
               Map (Lane * 1 + Byte) :=
                 U8 (Source_Lane * 1 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_U8x32 (Value, Map);
   end Expand;
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 0 loop
               Map (Result_Lane * 1 + Byte) :=
                 U8 (Lane * 1 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_I8x32 (Value, Map);
   end Compress;
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 0 loop
               Map (Lane * 1 + Byte) :=
                 U8 (Source_Lane * 1 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_I8x32 (Value, Map);
   end Expand;
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 1 loop
               Map (Result_Lane * 2 + Byte) :=
                 U8 (Lane * 2 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_U16x16 (Value, Map);
   end Compress;
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 1 loop
               Map (Lane * 2 + Byte) :=
                 U8 (Source_Lane * 2 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_U16x16 (Value, Map);
   end Expand;
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 1 loop
               Map (Result_Lane * 2 + Byte) :=
                 U8 (Lane * 2 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_I16x16 (Value, Map);
   end Compress;
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 1 loop
               Map (Lane * 2 + Byte) :=
                 U8 (Source_Lane * 2 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_I16x16 (Value, Map);
   end Expand;
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map (Result_Lane * 4 + Byte) :=
                 U8 (Lane * 4 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_U32x8 (Value, Map);
   end Compress;
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map (Lane * 4 + Byte) :=
                 U8 (Source_Lane * 4 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_U32x8 (Value, Map);
   end Expand;
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map (Result_Lane * 4 + Byte) :=
                 U8 (Lane * 4 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_I32x8 (Value, Map);
   end Compress;
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map (Lane * 4 + Byte) :=
                 U8 (Source_Lane * 4 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_I32x8 (Value, Map);
   end Expand;
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map (Result_Lane * 8 + Byte) :=
                 U8 (Lane * 8 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_U64x4 (Value, Map);
   end Compress;
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map (Lane * 8 + Byte) :=
                 U8 (Source_Lane * 8 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_U64x4 (Value, Map);
   end Expand;
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map (Result_Lane * 8 + Byte) :=
                 U8 (Lane * 8 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_I64x4 (Value, Map);
   end Compress;
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map (Lane * 8 + Byte) :=
                 U8 (Source_Lane * 8 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_I64x4 (Value, Map);
   end Expand;
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map (Result_Lane * 4 + Byte) :=
                 U8 (Lane * 4 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_F32x8 (Value, Map);
   end Compress;
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 3 loop
               Map (Lane * 4 + Byte) :=
                 U8 (Source_Lane * 4 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_F32x8 (Value, Map);
   end Expand;
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map (Result_Lane * 8 + Byte) :=
                 U8 (Lane * 8 + Byte);
            end loop;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      return Permute_F64x4 (Value, Map);
   end Compress;
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4 is
      Map : Byte_Map := [others => 32];
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            for Byte in Natural range 0 .. 7 loop
               Map (Lane * 8 + Byte) :=
                 U8 (Source_Lane * 8 + Byte);
            end loop;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      return Permute_F64x4 (Value, Map);
   end Expand;
end Flyology_SIMD.Wide.Compact_Mechanism;
