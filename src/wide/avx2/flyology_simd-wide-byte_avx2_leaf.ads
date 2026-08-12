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
end Flyology_SIMD.Wide.Byte_AVX2_Leaf;
