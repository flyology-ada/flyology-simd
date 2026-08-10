with Interfaces;

package Flyology_SIMD
  with Preelaborate
is
   subtype U8 is Interfaces.Unsigned_8;

   subtype Lane_Index_8x16 is Natural range 0 .. 15;
   subtype Lane_Count_8x16 is Natural range 0 .. 16;
   type Lane_Values_8x16 is array (Lane_Index_8x16) of U8;
   type Byte_Array is array (Natural range <>) of aliased U8;

   type U8x16 is private;
   type Mask_8x16 is private;

   function Zero return U8x16;
   function Splat (Value : U8) return U8x16;
   function From_Lanes (Values : Lane_Values_8x16) return U8x16;
   function To_Lanes (Value : U8x16) return Lane_Values_8x16;
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8;
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16;

   function Add_Wrap (Left, Right : U8x16) return U8x16;
   function Subtract_Wrap (Left, Right : U8x16) return U8x16;
   function Add_Saturate (Left, Right : U8x16) return U8x16;
   function Subtract_Saturate (Left, Right : U8x16) return U8x16;

   function Bitwise_And (Left, Right : U8x16) return U8x16;
   function Bitwise_Or (Left, Right : U8x16) return U8x16;
   function Bitwise_Xor (Left, Right : U8x16) return U8x16;
   function Bitwise_Not (Value : U8x16) return U8x16;

   --  Counts of eight or more produce zero in every lane.
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16;
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16;

   function Equal (Left, Right : U8x16) return Mask_8x16;
   function Less_Than (Left, Right : U8x16) return Mask_8x16;
   function Less_Equal (Left, Right : U8x16) return Mask_8x16;
   function Greater_Than (Left, Right : U8x16) return Mask_8x16;
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16;

   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16;
   function Min (Left, Right : U8x16) return U8x16;
   function Max (Left, Right : U8x16) return U8x16;
   function Horizontal_Sum (Value : U8x16) return Natural
     with Post => Horizontal_Sum'Result <= 16 * 255;

   function Reverse_Bytes (Value : U8x16) return U8x16;
   function Interleave_Low (Left, Right : U8x16) return U8x16;
   function Interleave_High (Left, Right : U8x16) return U8x16;

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16) return Mask_8x16;
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean;
   function Any_True (Mask : Mask_8x16) return Boolean;
   function All_True (Mask : Mask_8x16) return Boolean;
   function None_True (Mask : Mask_8x16) return Boolean;
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16;

   function Has_Extent
     (Data : Byte_Array; Start : Natural; Count : Natural) return Boolean;
   function Is_Aligned_16 (Data : Byte_Array; Start : Natural) return Boolean;

   --  Full typed operations require sixteen logical elements.  Load and Store
   --  make no alignment assertion; the Unaligned names make that fact explicit.
   function Load (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);

   --  Count zero touches no element.  Load zero-fills lanes Count .. 15.
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16)
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);

private
   type U8x16 is record
      Lanes : Lane_Values_8x16;
   end record;
   for U8x16'Size use 128;

   type Mask_8x16 is record
      Bits : Interfaces.Unsigned_16;
   end record;
   for Mask_8x16'Size use 16;
end Flyology_SIMD;
