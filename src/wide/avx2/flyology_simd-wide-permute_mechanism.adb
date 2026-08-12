with System.Machine_Code;

package body Flyology_SIMD.Wide.Permute_Mechanism is
   use System.Machine_Code;
   use type Interfaces.Unsigned_8;

   type Byte_Map is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;
   type Byte_Constants is array (Natural range 0 .. 31) of U8
     with Component_Size => 8, Size => 256;

   Lane_Bias : aliased constant Byte_Constants :=
     [0 .. 15 => 0, 16 .. 31 => 16];
   Sixteen : aliased constant U8 := 16;
   Thirty_Two : aliased constant U8 := 32;

   generic
      type Vector_Type is private;
   function Permute_One_256
     (Value : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_One_256
     (Value : Vector_Type; Map : Byte_Map) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm1, %%ymm0, %%ymm2" & ASCII.LF & ASCII.HT &
           "vperm2i128 $1, %%ymm0, %%ymm0, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm1, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vmovdqu (%3), %%ymm4" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm4, %%ymm1, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%4), %%ymm5" & ASCII.LF & ASCII.HT &
           "vpand %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm5, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpand %%ymm4, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm3, %%ymm4, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpor %%ymm3, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%5), %%ymm6" & ASCII.LF & ASCII.HT &
           "vpand %%ymm1, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm5, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpand %%ymm6, %%ymm2, %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm2, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Value'Address),
            System.Address'Asm_Input ("r", Map'Address),
            System.Address'Asm_Input ("r", Lane_Bias'Address),
            System.Address'Asm_Input ("r", Sixteen'Address),
            System.Address'Asm_Input ("r", Thirty_Two'Address)],
         Clobber => "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,memory",
         Volatile => True);
      return Result;
   end Permute_One_256;

   generic
      type Vector_Type is private;
   function Permute_Two_256
     (Left, Right : Vector_Type; Map : Byte_Map) return Vector_Type;

   function Permute_Two_256
     (Left, Right : Vector_Type; Map : Byte_Map) return Vector_Type
   is
      Result : Vector_Type;
   begin
      Asm
        (Template =>
           "vmovdqu (%1), %%ymm0" & ASCII.LF & ASCII.HT &
           "vmovdqu (%2), %%ymm1" & ASCII.LF & ASCII.HT &
           "vmovdqu (%3), %%ymm2" & ASCII.LF & ASCII.HT &
           "vmovdqu (%4), %%ymm9" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm9, %%ymm2, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%5), %%ymm8" & ASCII.LF & ASCII.HT &
           "vpand %%ymm8, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpxor %%ymm8, %%ymm8, %%ymm8" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm8, %%ymm3, %%ymm3" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm0, %%ymm4" & ASCII.LF & ASCII.HT &
           "vperm2i128 $1, %%ymm0, %%ymm0, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm5, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm5, %%ymm3, %%ymm5" & ASCII.LF & ASCII.HT &
           "vpor %%ymm5, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm1, %%ymm6" & ASCII.LF & ASCII.HT &
           "vperm2i128 $1, %%ymm1, %%ymm1, %%ymm7" & ASCII.LF & ASCII.HT &
           "vpshufb %%ymm2, %%ymm7, %%ymm7" & ASCII.LF & ASCII.HT &
           "vpand %%ymm3, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm7, %%ymm3, %%ymm7" & ASCII.LF & ASCII.HT &
           "vpor %%ymm7, %%ymm6, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpbroadcastb (%6), %%ymm10" & ASCII.LF & ASCII.HT &
           "vpand %%ymm2, %%ymm10, %%ymm10" & ASCII.LF & ASCII.HT &
           "vpcmpeqb %%ymm8, %%ymm10, %%ymm10" & ASCII.LF & ASCII.HT &
           "vpand %%ymm10, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vpandn %%ymm6, %%ymm10, %%ymm6" & ASCII.LF & ASCII.HT &
           "vpor %%ymm6, %%ymm4, %%ymm4" & ASCII.LF & ASCII.HT &
           "vmovdqu %%ymm4, (%0)" & ASCII.LF & ASCII.HT &
           "vzeroupper",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Left'Address),
            System.Address'Asm_Input ("r", Right'Address),
            System.Address'Asm_Input ("r", Map'Address),
            System.Address'Asm_Input ("r", Lane_Bias'Address),
            System.Address'Asm_Input ("r", Sixteen'Address),
            System.Address'Asm_Input ("r", Thirty_Two'Address)],
         Clobber =>
           "ymm0,ymm1,ymm2,ymm3,ymm4,ymm5,ymm6,ymm7,ymm8,ymm9,ymm10,memory",
         Volatile => True);
      return Result;
   end Permute_Two_256;

   function Permute_One_U8x32 is new Permute_One_256 (U8x32);
   pragma Inline_Always (Permute_One_U8x32);
   function Permute_One_I8x32 is new Permute_One_256 (I8x32);
   pragma Inline_Always (Permute_One_I8x32);
   function Permute_One_U16x16 is new Permute_One_256 (U16x16);
   pragma Inline_Always (Permute_One_U16x16);
   function Permute_One_I16x16 is new Permute_One_256 (I16x16);
   pragma Inline_Always (Permute_One_I16x16);
   function Permute_One_U32x8 is new Permute_One_256 (U32x8);
   pragma Inline_Always (Permute_One_U32x8);
   function Permute_One_I32x8 is new Permute_One_256 (I32x8);
   pragma Inline_Always (Permute_One_I32x8);
   function Permute_One_U64x4 is new Permute_One_256 (U64x4);
   pragma Inline_Always (Permute_One_U64x4);
   function Permute_One_I64x4 is new Permute_One_256 (I64x4);
   pragma Inline_Always (Permute_One_I64x4);
   function Permute_One_F32x8 is new Permute_One_256 (F32x8);
   pragma Inline_Always (Permute_One_F32x8);
   function Permute_One_F64x4 is new Permute_One_256 (F64x4);
   pragma Inline_Always (Permute_One_F64x4);
   function Permute_Two_U8x32 is new Permute_Two_256 (U8x32);
   pragma Inline_Always (Permute_Two_U8x32);
   function Permute_Two_I8x32 is new Permute_Two_256 (I8x32);
   pragma Inline_Always (Permute_Two_I8x32);
   function Permute_Two_U16x16 is new Permute_Two_256 (U16x16);
   pragma Inline_Always (Permute_Two_U16x16);
   function Permute_Two_I16x16 is new Permute_Two_256 (I16x16);
   pragma Inline_Always (Permute_Two_I16x16);
   function Permute_Two_U32x8 is new Permute_Two_256 (U32x8);
   pragma Inline_Always (Permute_Two_U32x8);
   function Permute_Two_I32x8 is new Permute_Two_256 (I32x8);
   pragma Inline_Always (Permute_Two_I32x8);
   function Permute_Two_U64x4 is new Permute_Two_256 (U64x4);
   pragma Inline_Always (Permute_Two_U64x4);
   function Permute_Two_I64x4 is new Permute_Two_256 (I64x4);
   pragma Inline_Always (Permute_Two_I64x4);
   function Permute_Two_F32x8 is new Permute_Two_256 (F32x8);
   pragma Inline_Always (Permute_Two_F32x8);
   function Permute_Two_F64x4 is new Permute_Two_256 (F64x4);
   pragma Inline_Always (Permute_Two_F64x4);

   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 1 + Byte);
         end loop;
      end loop;
      return Permute_One_U8x32 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : U8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              U8 ((31 - Result_Lane) * 1 + Byte);
         end loop;
      end loop;
      return Permute_One_U8x32 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_U8x32 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : U8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((16 + Result_Lane / 2) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_U8x32 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane >= 16 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 16)) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_U8x32 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane >= 16 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 16) + 1) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_U8x32 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 32 then
         for Result_Lane in Lane_Index_8x32 loop
            if Result_Lane + Count < 32 then
               for Byte in Natural range 0 .. 0 loop
                  Indexes (Result_Lane * 1 + Byte) :=
                    U8 ((Result_Lane + Count) * 1 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U8x32 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 32 then
         for Result_Lane in Lane_Index_8x32 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 0 loop
                  Indexes (Result_Lane * 1 + Byte) :=
                    U8 ((Result_Lane - Count) * 1 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U8x32 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_U8x32 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 1 + Byte);
         end loop;
      end loop;
      return Permute_One_I8x32 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : I8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              U8 ((31 - Result_Lane) * 1 + Byte);
         end loop;
      end loop;
      return Permute_One_I8x32 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_I8x32 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : I8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((16 + Result_Lane / 2) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_I8x32 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane >= 16 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 16)) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_I8x32 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Result_Lane >= 16 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 16) + 1) * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_I8x32 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 32 then
         for Result_Lane in Lane_Index_8x32 loop
            if Result_Lane + Count < 32 then
               for Byte in Natural range 0 .. 0 loop
                  Indexes (Result_Lane * 1 + Byte) :=
                    U8 ((Result_Lane + Count) * 1 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I8x32 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 32 then
         for Result_Lane in Lane_Index_8x32 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 0 loop
                  Indexes (Result_Lane * 1 + Byte) :=
                    U8 ((Result_Lane - Count) * 1 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I8x32 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_8x32 loop
         for Byte in Natural range 0 .. 0 loop
            Indexes (Result_Lane * 1 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 1 + Byte);
         end loop;
      end loop;
      return Permute_Two_I8x32 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 2 + Byte);
         end loop;
      end loop;
      return Permute_One_U16x16 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : U16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              U8 ((15 - Result_Lane) * 2 + Byte);
         end loop;
      end loop;
      return Permute_One_U16x16 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_U16x16 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : U16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((8 + Result_Lane / 2) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_U16x16 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane >= 8 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 8)) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_U16x16 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane >= 8 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 8) + 1) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_U16x16 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 16 then
         for Result_Lane in Lane_Index_16x16 loop
            if Result_Lane + Count < 16 then
               for Byte in Natural range 0 .. 1 loop
                  Indexes (Result_Lane * 2 + Byte) :=
                    U8 ((Result_Lane + Count) * 2 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U16x16 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 16 then
         for Result_Lane in Lane_Index_16x16 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 1 loop
                  Indexes (Result_Lane * 2 + Byte) :=
                    U8 ((Result_Lane - Count) * 2 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U16x16 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_U16x16 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 2 + Byte);
         end loop;
      end loop;
      return Permute_One_I16x16 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : I16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              U8 ((15 - Result_Lane) * 2 + Byte);
         end loop;
      end loop;
      return Permute_One_I16x16 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_I16x16 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : I16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((8 + Result_Lane / 2) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_I16x16 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane >= 8 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 8)) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_I16x16 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Result_Lane >= 8 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 8) + 1) * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_I16x16 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 16 then
         for Result_Lane in Lane_Index_16x16 loop
            if Result_Lane + Count < 16 then
               for Byte in Natural range 0 .. 1 loop
                  Indexes (Result_Lane * 2 + Byte) :=
                    U8 ((Result_Lane + Count) * 2 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I16x16 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 16 then
         for Result_Lane in Lane_Index_16x16 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 1 loop
                  Indexes (Result_Lane * 2 + Byte) :=
                    U8 ((Result_Lane - Count) * 2 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I16x16 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_16x16 loop
         for Byte in Natural range 0 .. 1 loop
            Indexes (Result_Lane * 2 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 2 + Byte);
         end loop;
      end loop;
      return Permute_Two_I16x16 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 4 + Byte);
         end loop;
      end loop;
      return Permute_One_U32x8 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : U32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              U8 ((7 - Result_Lane) * 4 + Byte);
         end loop;
      end loop;
      return Permute_One_U32x8 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_U32x8 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : U32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((4 + Result_Lane / 2) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_U32x8 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane >= 4 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 4)) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_U32x8 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane >= 4 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 4) + 1) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_U32x8 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 8 then
         for Result_Lane in Lane_Index_32x8 loop
            if Result_Lane + Count < 8 then
               for Byte in Natural range 0 .. 3 loop
                  Indexes (Result_Lane * 4 + Byte) :=
                    U8 ((Result_Lane + Count) * 4 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U32x8 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 8 then
         for Result_Lane in Lane_Index_32x8 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 3 loop
                  Indexes (Result_Lane * 4 + Byte) :=
                    U8 ((Result_Lane - Count) * 4 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U32x8 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_U32x8 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 4 + Byte);
         end loop;
      end loop;
      return Permute_One_I32x8 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : I32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              U8 ((7 - Result_Lane) * 4 + Byte);
         end loop;
      end loop;
      return Permute_One_I32x8 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_I32x8 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : I32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((4 + Result_Lane / 2) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_I32x8 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane >= 4 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 4)) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_I32x8 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane >= 4 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 4) + 1) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_I32x8 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 8 then
         for Result_Lane in Lane_Index_32x8 loop
            if Result_Lane + Count < 8 then
               for Byte in Natural range 0 .. 3 loop
                  Indexes (Result_Lane * 4 + Byte) :=
                    U8 ((Result_Lane + Count) * 4 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I32x8 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 8 then
         for Result_Lane in Lane_Index_32x8 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 3 loop
                  Indexes (Result_Lane * 4 + Byte) :=
                    U8 ((Result_Lane - Count) * 4 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I32x8 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_I32x8 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 8 + Byte);
         end loop;
      end loop;
      return Permute_One_U64x4 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : U64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              U8 ((3 - Result_Lane) * 8 + Byte);
         end loop;
      end loop;
      return Permute_One_U64x4 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : U64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_U64x4 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : U64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((2 + Result_Lane / 2) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_U64x4 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : U64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane >= 2 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 2)) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_U64x4 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : U64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane >= 2 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 2) + 1) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_U64x4 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 4 then
         for Result_Lane in Lane_Index_64x4 loop
            if Result_Lane + Count < 4 then
               for Byte in Natural range 0 .. 7 loop
                  Indexes (Result_Lane * 8 + Byte) :=
                    U8 ((Result_Lane + Count) * 8 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U64x4 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 4 then
         for Result_Lane in Lane_Index_64x4 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 7 loop
                  Indexes (Result_Lane * 8 + Byte) :=
                    U8 ((Result_Lane - Count) * 8 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_U64x4 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_U64x4 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 8 + Byte);
         end loop;
      end loop;
      return Permute_One_I64x4 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : I64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              U8 ((3 - Result_Lane) * 8 + Byte);
         end loop;
      end loop;
      return Permute_One_I64x4 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : I64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_I64x4 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : I64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((2 + Result_Lane / 2) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_I64x4 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : I64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane >= 2 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 2)) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_I64x4 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : I64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane >= 2 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 2) + 1) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_I64x4 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 4 then
         for Result_Lane in Lane_Index_64x4 loop
            if Result_Lane + Count < 4 then
               for Byte in Natural range 0 .. 7 loop
                  Indexes (Result_Lane * 8 + Byte) :=
                    U8 ((Result_Lane + Count) * 8 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I64x4 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 4 then
         for Result_Lane in Lane_Index_64x4 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 7 loop
                  Indexes (Result_Lane * 8 + Byte) :=
                    U8 ((Result_Lane - Count) * 8 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_I64x4 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_I64x4 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 4 + Byte);
         end loop;
      end loop;
      return Permute_One_F32x8 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : F32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              U8 ((7 - Result_Lane) * 4 + Byte);
         end loop;
      end loop;
      return Permute_One_F32x8 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : F32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_F32x8 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : F32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((4 + Result_Lane / 2) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_F32x8 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : F32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane >= 4 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 4)) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_F32x8 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : F32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Result_Lane >= 4 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 4) + 1) * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_F32x8 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 8 then
         for Result_Lane in Lane_Index_32x8 loop
            if Result_Lane + Count < 8 then
               for Byte in Natural range 0 .. 3 loop
                  Indexes (Result_Lane * 4 + Byte) :=
                    U8 ((Result_Lane + Count) * 4 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_F32x8 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 8 then
         for Result_Lane in Lane_Index_32x8 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 3 loop
                  Indexes (Result_Lane * 4 + Byte) :=
                    U8 ((Result_Lane - Count) * 4 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_F32x8 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_32x8 loop
         for Byte in Natural range 0 .. 3 loop
            Indexes (Result_Lane * 4 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 4 + Byte);
         end loop;
      end loop;
      return Permute_Two_F32x8 (Left, Right, Indexes);
   end Permute_Lanes;
   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              U8 (Map.Selectors (Result_Lane) * 8 + Byte);
         end loop;
      end loop;
      return Permute_One_F64x4 (Value, Indexes);
   end Permute_Lanes;
   function Reverse_Lanes (Value : F64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              U8 ((3 - Result_Lane) * 8 + Byte);
         end loop;
      end loop;
      return Permute_One_F64x4 (Value, Indexes);
   end Reverse_Lanes;
   function Interleave_Low (Left, Right : F64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((Result_Lane / 2) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_F64x4 (Left, Right, Indexes);
   end Interleave_Low;
   function Interleave_High (Left, Right : F64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane mod 2 = 1 then U8 (32) else U8 (0))
              + U8 ((2 + Result_Lane / 2) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_F64x4 (Left, Right, Indexes);
   end Interleave_High;
   function Deinterleave_Even (Left, Right : F64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane >= 2 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 2)) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_F64x4 (Left, Right, Indexes);
   end Deinterleave_Even;
   function Deinterleave_Odd (Left, Right : F64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Result_Lane >= 2 then U8 (32) else U8 (0))
              + U8 ((2 * (Result_Lane mod 2) + 1) * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_F64x4 (Left, Right, Indexes);
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 4 then
         for Result_Lane in Lane_Index_64x4 loop
            if Result_Lane + Count < 4 then
               for Byte in Natural range 0 .. 7 loop
                  Indexes (Result_Lane * 8 + Byte) :=
                    U8 ((Result_Lane + Count) * 8 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_F64x4 (Value, Indexes);
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4 is
      Indexes : Byte_Map := [others => 32];
   begin
      if Count < 4 then
         for Result_Lane in Lane_Index_64x4 loop
            if Result_Lane >= Count then
               for Byte in Natural range 0 .. 7 loop
                  Indexes (Result_Lane * 8 + Byte) :=
                    U8 ((Result_Lane - Count) * 8 + Byte);
               end loop;
            end if;
         end loop;
      end if;
      return Permute_One_F64x4 (Value, Indexes);
   end Slide_Lanes_Toward_High;
   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4 is
      Indexes : Byte_Map;
   begin
      for Result_Lane in Lane_Index_64x4 loop
         for Byte in Natural range 0 .. 7 loop
            Indexes (Result_Lane * 8 + Byte) :=
              (if Map.Selectors (Result_Lane).From_Right
               then U8 (32)
               else U8 (0))
              + U8 (Map.Selectors (Result_Lane).Lane * 8 + Byte);
         end loop;
      end loop;
      return Permute_Two_F64x4 (Left, Right, Indexes);
   end Permute_Lanes;
end Flyology_SIMD.Wide.Permute_Mechanism;
