with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Conversions is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type F32;
   use type F64;
   use type I16;
   package Native renames Flyology_SIMD.Backends.Native;

   Input : constant Byte_Array :=
     [0, 17, 34, 51, 68, 85, 102, 119,
      136, 153, 170, 187, 204, 221, 238, 255];
   Bytes : constant U8x16 := Native.Load_Unaligned (Input, Input'First);

   Low_Words  : constant U16x8 := Native.Widen_Low (Bytes);
   High_Words : constant U16x8 := Native.Widen_High (Bytes);
   Round_Trip : constant U8x16 :=
     Native.Narrow_Saturate (Low_Words, High_Words);

   Wide_Low : constant U16x8 :=
     Native.From_Lanes ([254, 255, 256, 300, 0, 1, 2, 3]);
   Wide_High : constant U16x8 := Native.Zero;
   Truncated : constant U8x16 :=
     Native.Narrow_Truncate (Wide_Low, Wide_High);
   Saturated : constant U8x16 :=
     Native.Narrow_Saturate (Wide_Low, Wide_High);

   Signed_Low : constant I16x8 :=
     Native.From_Lanes ([-1, 0, 255, 256, 0, 1, 2, 3]);
   Signed_High : constant I16x8 := Native.Zero;
   Unsigned_Saturated : constant U8x16 :=
     Native.Narrow_Saturate (Signed_Low, Signed_High);

   Samples : constant F32x4 :=
     Native.From_Lanes ([1.0, -2.0, 0.5, 4.0]);
   Encodings : constant U32x4 := Native.Bit_Cast (Samples);

   Wide_Float_Low : constant F64x2 :=
     Native.From_Lanes
       ([1.000_000_059_604_644_775_390_625,
         1.000_000_178_813_934_326_171_875]);
   Wide_Float_High : constant F64x2 := Native.From_Lanes ([-0.0, 4.0]);
   Narrowed_Floats : constant F32x4 :=
     Native.Narrow_Round (Wide_Float_Low, Wide_Float_High);
   Narrowed_Encodings : constant U32x4 := Native.Bit_Cast (Narrowed_Floats);
begin
   Put_Line
     ("round trip:" &
      Boolean'Image (Native.All_True (Native.Equal (Bytes, Round_Trip))));
   Put ("truncate:");
   for Lane in Lane_Index_8x16 range 0 .. 3 loop
      Put (U8'Image (Native.Extract (Truncated, Lane)));
   end loop;
   New_Line;
   Put ("saturate:");
   for Lane in Lane_Index_8x16 range 0 .. 3 loop
      Put (U8'Image (Native.Extract (Saturated, Lane)));
   end loop;
   New_Line;
   Put ("signed to unsigned:");
   for Lane in Lane_Index_8x16 range 0 .. 3 loop
      Put (U8'Image (Native.Extract (Unsigned_Saturated, Lane)));
   end loop;
   New_Line;
   Put ("F32 bits:");
   for Lane in Lane_Index_32x4 loop
      Put (U32'Image (Native.Extract (Encodings, Lane)));
   end loop;
   New_Line;
   Put ("F64 narrowed bits:");
   for Lane in Lane_Index_32x4 loop
      Put (U32'Image (Native.Extract (Narrowed_Encodings, Lane)));
   end loop;
   New_Line;
end Conversions;
