private package Flyology_SIMD.Wide.Byte_AVX2_Leaf
  with Preelaborate
is
   --  Isolated AVX2 implementations for 256-bit byte-vector operations.

   function Add_Wrap (Left, Right : U8x32) return U8x32;
   --  Add corresponding unsigned byte lanes modulo 256.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding wrapping sums.
   function Add_Wrap (Left, Right : I8x32) return I8x32;
   --  Add corresponding signed byte lanes modulo 256.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding wrapping sums.
   function Subtract_Wrap (Left, Right : U8x32) return U8x32;
   --  Subtract corresponding unsigned byte lanes modulo 256.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding wrapping differences.
   function Subtract_Wrap (Left, Right : I8x32) return I8x32;
   --  Subtract corresponding signed byte lanes modulo 256.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding wrapping differences.
   function Multiply_Wrap (Left, Right : U8x32) return U8x32;
   --  Multiply corresponding unsigned byte lanes modulo 256.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The low byte of each product.
   function Multiply_Wrap (Left, Right : I8x32) return I8x32;
   --  Multiply corresponding signed byte lanes modulo 256.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The low byte of each product.
   function Add_Saturate (Left, Right : U8x32) return U8x32;
   --  Add corresponding unsigned byte lanes and clamp to U8'Last.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding saturated sums.
   function Add_Saturate (Left, Right : I8x32) return I8x32;
   --  Add corresponding signed byte lanes and clamp to the I8 range.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding saturated sums.
   function Subtract_Saturate (Left, Right : U8x32) return U8x32;
   --  Subtract corresponding unsigned byte lanes and clamp to zero.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding saturated differences.
   function Subtract_Saturate (Left, Right : I8x32) return I8x32;
   --  Subtract corresponding signed byte lanes and clamp to the I8 range.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding saturated differences.
   function Bitwise_And (Left, Right : U8x32) return U8x32;
   --  Compute the bitwise conjunction of corresponding unsigned lanes.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding bitwise results.
   function Bitwise_And (Left, Right : I8x32) return I8x32;
   --  Compute the bitwise conjunction of corresponding signed lanes.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding bitwise results.
   function Bitwise_Or (Left, Right : U8x32) return U8x32;
   --  Compute the bitwise disjunction of corresponding unsigned lanes.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding bitwise results.
   function Bitwise_Or (Left, Right : I8x32) return I8x32;
   --  Compute the bitwise disjunction of corresponding signed lanes.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding bitwise results.
   function Bitwise_Xor (Left, Right : U8x32) return U8x32;
   --  Compute the bitwise exclusive disjunction of unsigned lanes.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding bitwise results.
   function Bitwise_Xor (Left, Right : I8x32) return I8x32;
   --  Compute the bitwise exclusive disjunction of signed lanes.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding bitwise results.
   function Bitwise_Not (Value : U8x32) return U8x32;
   --  Complement every bit of every unsigned byte lane.
   --  @param Value The source lanes.
   --  @return The complemented lanes.
   function Bitwise_Not (Value : I8x32) return I8x32;
   --  Complement every bit of every signed byte lane.
   --  @param Value The source lanes.
   --  @return The complemented lanes.
   function Min (Left, Right : U8x32) return U8x32;
   --  Select the smaller corresponding unsigned byte lane.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding minima.
   function Min (Left, Right : I8x32) return I8x32;
   --  Select the smaller corresponding signed byte lane.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding minima.
   function Max (Left, Right : U8x32) return U8x32;
   --  Select the larger corresponding unsigned byte lane.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding maxima.
   function Max (Left, Right : I8x32) return I8x32;
   --  Select the larger corresponding signed byte lane.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return The corresponding maxima.

   function Equal (Left, Right : U8x32) return Mask_Bits_8x32;
   --  Compare unsigned byte lanes for equality and extract compact truths.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return Bit n is set exactly when lane n is equal.
   function Equal (Left, Right : I8x32) return Mask_Bits_8x32;
   --  Compare signed byte lanes for equality and extract compact truths.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return Bit n is set exactly when lane n is equal.
   function Greater_Than (Left, Right : U8x32) return Mask_Bits_8x32;
   --  Compare unsigned byte lanes after the sign-bit ordering transform.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return Bit n is set exactly when Left (n) is greater than Right (n).
   function Greater_Than (Left, Right : I8x32) return Mask_Bits_8x32;
   --  Compare signed byte lanes in their native signed ordering.
   --  @param Left The left operands.
   --  @param Right The right operands.
   --  @return Bit n is set exactly when Left (n) is greater than Right (n).
   function Less_Than (Left, Right : U8x32) return Mask_Bits_8x32;
   function Less_Than (Left, Right : I8x32) return Mask_Bits_8x32;
   function Less_Equal (Left, Right : U8x32) return Mask_Bits_8x32;
   function Less_Equal (Left, Right : I8x32) return Mask_Bits_8x32;
   function Greater_Equal (Left, Right : U8x32) return Mask_Bits_8x32;
   function Greater_Equal (Left, Right : I8x32) return Mask_Bits_8x32;
   --  Derived ordered relations retain distinct isolated entry points so
   --  caller code-generation checks can bind each public relation exactly.

   pragma No_Inline (Less_Than);
   pragma No_Inline (Less_Equal);
   pragma No_Inline (Greater_Equal);

   function Select_Value
     (Bits : Mask_Bits_8x32; If_True, If_False : U8x32) return U8x32;
   --  Expand compact truths and select corresponding unsigned lanes.
   --  @param Bits The compact semantic selection mask.
   --  @param If_True The lanes selected by set bits.
   --  @param If_False The lanes selected by clear bits.
   --  @return The selected lanes.
   function Select_Value
     (Bits : Mask_Bits_8x32; If_True, If_False : I8x32) return I8x32;
   --  Expand compact truths and select corresponding signed lanes.
   --  @param Bits The compact semantic selection mask.
   --  @param If_True The lanes selected by set bits.
   --  @param If_False The lanes selected by clear bits.
   --  @return The selected lanes.
end Flyology_SIMD.Wide.Byte_AVX2_Leaf;
