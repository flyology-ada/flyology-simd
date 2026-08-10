package body Flyology_SIMD.Backends.Native is
   function Zero return U8x16 is (Flyology_SIMD.Zero);
   function Splat (Value : U8) return U8x16 is (Flyology_SIMD.Splat (Value));
   function Add_Wrap (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Add_Wrap (Left, Right));
   function Add_Saturate (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Add_Saturate (Left, Right));
   function Bitwise_And (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Bitwise_And (Left, Right));
   function Equal (Left, Right : U8x16) return Mask_8x16 is
     (Flyology_SIMD.Equal (Left, Right));
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16 is
     (Flyology_SIMD.Select_Value (Mask, If_True, If_False));
   function Min (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Min (Left, Right));
   function Max (Left, Right : U8x16) return U8x16 is
     (Flyology_SIMD.Max (Left, Right));
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16 is
     (Flyology_SIMD.To_Bit_Mask (Mask));
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16 is
     (Flyology_SIMD.Load_Unaligned (Data, Start));
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16) is
   begin
      Flyology_SIMD.Store_Unaligned (Data, Start, Value);
   end Store_Unaligned;
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16 is
     (Flyology_SIMD.Load_Partial (Data, Start, Count));
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16) is
   begin
      Flyology_SIMD.Store_Partial (Data, Start, Count, Value);
   end Store_Partial;
end Flyology_SIMD.Backends.Native;
