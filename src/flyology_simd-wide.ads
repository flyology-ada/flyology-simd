with Interfaces;

--  Portable 256-bit values. Representations stay private and are not an ABI.
package Flyology_SIMD.Wide
  with Preelaborate
is
   type U8x32 is private;
   --  A private 256-bit vector containing 32 U8 lanes.
   type I8x32 is private;
   --  A private 256-bit vector containing 32 I8 lanes.
   type U16x16 is private;
   --  A private 256-bit vector containing 16 U16 lanes.
   type I16x16 is private;
   --  A private 256-bit vector containing 16 I16 lanes.
   type U32x8 is private;
   --  A private 256-bit vector containing 8 U32 lanes.
   type I32x8 is private;
   --  A private 256-bit vector containing 8 I32 lanes.
   type U64x4 is private;
   --  A private 256-bit vector containing 4 U64 lanes.
   type I64x4 is private;
   --  A private 256-bit vector containing 4 I64 lanes.
   type F32x8 is private;
   --  A private 256-bit vector containing 8 F32 lanes.
   type F64x4 is private;
   --  A private 256-bit vector containing 4 F64 lanes.

   subtype Lane_Index_8x32 is Natural range 0 .. 31;
   --  Logical lane indexes for 32-lane vectors.
   subtype Lane_Count_8x32 is Natural range 0 .. 32;
   --  Counts from zero through the complete 32-lane width.
   type Lane_Selectors_8x32 is array (Lane_Index_8x32) of Lane_Index_8x32;
   --  One source-lane selector for each result lane.
   type Lane_Map_8x32 is private;
   --  A reusable, validated mapping from result lanes to source lanes.
   function Make_Lane_Map (Selectors : Lane_Selectors_8x32) return Lane_Map_8x32;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Two_Source_Lane_Selector_8x32 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   type Two_Source_Lane_Selectors_8x32 is array (Lane_Index_8x32) of Two_Source_Lane_Selector_8x32;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_8x32 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_8x32) return Two_Source_Lane_Map_8x32;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Mask_8x32 is private;
   --  One semantic Boolean truth for each of 32 lanes.
   subtype Mask_Bits_8x32 is Interfaces.Unsigned_32 range 0 .. 4294967295;
   --  Compact bits for exactly 32 mask lanes.
   type Lane_Values_U8x32 is array (Lane_Index_8x32) of U8;
   --  U8 lane values in logical lane order.
   function Zero return U8x32;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : U8) return U8x32;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U8x32) return U8x32;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U8x32) return Lane_Values_U8x32;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U8x32; Lane : Lane_Index_8x32) return U8;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U8x32; Lane : Lane_Index_8x32; With_Value : U8) return U8x32;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Table_Lookup (Table, Indices : U8x32) return U8x32;
   --  Select each result byte from the corresponding unsigned index. Indexes from 0 through 31 select that table lane; larger indexes produce zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, AArch64 uses two-register NEON tbl for each result half; the x86-64 composed selection calls the Wide scalar implementation, and the optional AVX2 selection uses a dedicated U8x32 implementation. A scalar build uses the portable Wide implementation.
   --  @param Table The table input.
   --  @param Indices The indices input.
   --  @return The operation result.
   function Bit_Cast (Value : U8x32) return I8x32;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U8x32) return U8x32;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x32) return U8x32;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x32) return U8x32;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x32) return U8x32;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x32) return U8x32;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U8x32) return U8x32;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x32) return U8x32;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x32) return U8x32;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U8x32) return U8x32;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x32) return U8x32;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x32) return U8x32;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U8x32; Count : Natural) return U8x32;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x32; Count : Natural) return U8x32;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U8x32) return Mask_8x32;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x32) return Mask_8x32;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x32) return Mask_8x32;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x32) return Mask_8x32;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x32) return Mask_8x32;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x32; If_True, If_False : U8x32) return U8x32;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Horizontal_Sum (Value : U8x32) return Natural with Post => Horizontal_Sum'Result <= 32 * 255;
   --  Return the exact sum of all 32 unsigned byte lanes as Natural.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x32) return U8;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U8x32) return U8;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U8x32) return U8;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x32) return U8x32;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x32) return U8x32;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x32) return U8x32;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x32) return U8x32;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x32) return U8x32;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_8x32) return Mask_8x32;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x32) return Mask_Bits_8x32;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x32) return Mask_8x32;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x32) return Mask_8x32;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x32) return Mask_8x32;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x32) return Mask_8x32;
   --  Complement every mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_8x32; Lane : Lane_Index_8x32) return Boolean;
   --  Return one mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x32) return Boolean;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_8x32) return Boolean;
   --  Return the All_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_8x32) return Boolean;
   --  Return the None_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x32) return Lane_Count_8x32;
   --  Return the number of true lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_8x32) return Lane_Count_8x32;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x32) return Lane_Count_8x32;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : Byte_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x32) return U8x32 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out Byte_Array; Start : Natural; Count : Lane_Count_8x32; Value : U8x32) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   type Lane_Values_I8x32 is array (Lane_Index_8x32) of I8;
   --  I8 lane values in logical lane order.
   function Zero return I8x32;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : I8) return I8x32;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I8x32) return I8x32;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I8x32) return Lane_Values_I8x32;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I8x32; Lane : Lane_Index_8x32) return I8;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I8x32; Lane : Lane_Index_8x32; With_Value : I8) return I8x32;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I8x32) return U8x32;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I8x32) return I8x32;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I8x32) return I8x32;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I8x32) return I8x32;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I8x32) return I8x32;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I8x32) return I8x32;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I8x32) return I8x32;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I8x32) return I8x32;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I8x32) return I8x32;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I8x32) return I8x32;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I8x32) return I8x32;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I8x32) return I8x32;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I8x32; Count : Natural) return I8x32;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I8x32; Count : Natural) return I8x32;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I8x32; Count : Natural) return I8x32;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I8x32) return Mask_8x32;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I8x32) return Mask_8x32;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I8x32) return Mask_8x32;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I8x32) return Mask_8x32;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I8x32) return Mask_8x32;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x32; If_True, If_False : I8x32) return I8x32;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I8x32) return I8;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I8x32) return I8;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I8x32) return I8;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I8x32) return I8x32;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I8x32) return I8x32;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I8x32) return I8x32;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I8x32) return I8x32;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I8x32) return I8x32;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I8_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x32) return I8x32 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x32; Value : I8x32) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   subtype Lane_Index_16x16 is Natural range 0 .. 15;
   --  Logical lane indexes for 16-lane vectors.
   subtype Lane_Count_16x16 is Natural range 0 .. 16;
   --  Counts from zero through the complete 16-lane width.
   type Lane_Selectors_16x16 is array (Lane_Index_16x16) of Lane_Index_16x16;
   --  One source-lane selector for each result lane.
   type Lane_Map_16x16 is private;
   --  A reusable, validated mapping from result lanes to source lanes.
   function Make_Lane_Map (Selectors : Lane_Selectors_16x16) return Lane_Map_16x16;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Two_Source_Lane_Selector_16x16 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   type Two_Source_Lane_Selectors_16x16 is array (Lane_Index_16x16) of Two_Source_Lane_Selector_16x16;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_16x16 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_16x16) return Two_Source_Lane_Map_16x16;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Mask_16x16 is private;
   --  One semantic Boolean truth for each of 16 lanes.
   subtype Mask_Bits_16x16 is Interfaces.Unsigned_16 range 0 .. 65535;
   --  Compact bits for exactly 16 mask lanes.
   type Lane_Values_U16x16 is array (Lane_Index_16x16) of U16;
   --  U16 lane values in logical lane order.
   function Zero return U16x16;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : U16) return U16x16;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U16x16) return U16x16;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U16x16) return Lane_Values_U16x16;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U16x16; Lane : Lane_Index_16x16) return U16;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U16x16; Lane : Lane_Index_16x16; With_Value : U16) return U16x16;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U16x16) return I16x16;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U16x16) return U16x16;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U16x16) return U16x16;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U16x16) return U16x16;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U16x16) return U16x16;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U16x16) return U16x16;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U16x16) return U16x16;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U16x16) return U16x16;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U16x16) return U16x16;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U16x16) return U16x16;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U16x16) return U16x16;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U16x16) return U16x16;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U16x16; Count : Natural) return U16x16;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U16x16; Count : Natural) return U16x16;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U16x16) return Mask_16x16;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U16x16) return Mask_16x16;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U16x16) return Mask_16x16;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U16x16) return Mask_16x16;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U16x16) return Mask_16x16;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x16; If_True, If_False : U16x16) return U16x16;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U16x16) return U16;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U16x16) return U16;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U16x16) return U16;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U16x16) return U16x16;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U16x16) return U16x16;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U16x16) return U16x16;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U16x16) return U16x16;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U16x16) return U16x16;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_16x16) return Mask_16x16;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_16x16) return Mask_Bits_16x16;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_16x16) return Mask_16x16;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_16x16) return Mask_16x16;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_16x16) return Mask_16x16;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_16x16) return Mask_16x16;
   --  Complement every mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_16x16; Lane : Lane_Index_16x16) return Boolean;
   --  Return one mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_16x16) return Boolean;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_16x16) return Boolean;
   --  Return the All_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_16x16) return Boolean;
   --  Return the None_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_16x16) return Lane_Count_16x16;
   --  Return the number of true lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_16x16) return Lane_Count_16x16;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_16x16) return Lane_Count_16x16;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U16_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x16) return U16x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x16; Value : U16x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   type Lane_Values_I16x16 is array (Lane_Index_16x16) of I16;
   --  I16 lane values in logical lane order.
   function Zero return I16x16;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : I16) return I16x16;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I16x16) return I16x16;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I16x16) return Lane_Values_I16x16;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I16x16; Lane : Lane_Index_16x16) return I16;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I16x16; Lane : Lane_Index_16x16; With_Value : I16) return I16x16;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I16x16) return U16x16;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I16x16) return I16x16;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I16x16) return I16x16;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I16x16) return I16x16;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I16x16) return I16x16;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I16x16) return I16x16;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I16x16) return I16x16;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I16x16) return I16x16;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I16x16) return I16x16;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I16x16) return I16x16;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I16x16) return I16x16;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I16x16) return I16x16;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I16x16; Count : Natural) return I16x16;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I16x16; Count : Natural) return I16x16;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I16x16; Count : Natural) return I16x16;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I16x16) return Mask_16x16;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I16x16) return Mask_16x16;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I16x16) return Mask_16x16;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I16x16) return Mask_16x16;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I16x16) return Mask_16x16;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x16; If_True, If_False : I16x16) return I16x16;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I16x16) return I16;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I16x16) return I16;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I16x16) return I16;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I16x16) return I16x16;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I16x16) return I16x16;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I16x16) return I16x16;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I16x16) return I16x16;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I16x16) return I16x16;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I16_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x16) return I16x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x16; Value : I16x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   subtype Lane_Index_32x8 is Natural range 0 .. 7;
   --  Logical lane indexes for 8-lane vectors.
   subtype Lane_Count_32x8 is Natural range 0 .. 8;
   --  Counts from zero through the complete 8-lane width.
   type Lane_Selectors_32x8 is array (Lane_Index_32x8) of Lane_Index_32x8;
   --  One source-lane selector for each result lane.
   type Lane_Map_32x8 is private;
   --  A reusable, validated mapping from result lanes to source lanes.
   function Make_Lane_Map (Selectors : Lane_Selectors_32x8) return Lane_Map_32x8;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Two_Source_Lane_Selector_32x8 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   type Two_Source_Lane_Selectors_32x8 is array (Lane_Index_32x8) of Two_Source_Lane_Selector_32x8;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_32x8 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_32x8) return Two_Source_Lane_Map_32x8;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Mask_32x8 is private;
   --  One semantic Boolean truth for each of 8 lanes.
   subtype Mask_Bits_32x8 is Interfaces.Unsigned_8 range 0 .. 255;
   --  Compact bits for exactly 8 mask lanes.
   type Lane_Values_U32x8 is array (Lane_Index_32x8) of U32;
   --  U32 lane values in logical lane order.
   function Zero return U32x8;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : U32) return U32x8;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U32x8) return U32x8;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U32x8) return Lane_Values_U32x8;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U32x8; Lane : Lane_Index_32x8) return U32;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U32x8; Lane : Lane_Index_32x8; With_Value : U32) return U32x8;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U32x8) return I32x8;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : U32x8) return F32x8;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U32x8) return U32x8;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U32x8) return U32x8;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U32x8) return U32x8;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U32x8) return U32x8;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U32x8) return U32x8;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U32x8) return U32x8;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U32x8) return U32x8;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U32x8) return U32x8;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U32x8) return U32x8;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U32x8) return U32x8;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U32x8) return U32x8;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U32x8; Count : Natural) return U32x8;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U32x8; Count : Natural) return U32x8;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U32x8) return Mask_32x8;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U32x8) return Mask_32x8;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U32x8) return Mask_32x8;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U32x8) return Mask_32x8;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U32x8) return Mask_32x8;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : U32x8) return U32x8;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U32x8) return U32;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U32x8) return U32;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U32x8) return U32;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U32x8) return U32x8;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U32x8) return U32x8;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U32x8) return U32x8;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U32x8) return U32x8;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U32x8) return U32x8;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_32x8) return Mask_32x8;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_32x8) return Mask_Bits_32x8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_32x8) return Mask_32x8;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_32x8) return Mask_32x8;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_32x8) return Mask_32x8;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_32x8) return Mask_32x8;
   --  Complement every mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_32x8; Lane : Lane_Index_32x8) return Boolean;
   --  Return one mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_32x8) return Boolean;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_32x8) return Boolean;
   --  Return the All_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_32x8) return Boolean;
   --  Return the None_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_32x8) return Lane_Count_32x8;
   --  Return the number of true lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_32x8) return Lane_Count_32x8;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_32x8) return Lane_Count_32x8;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x8) return U32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x8; Value : U32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   type Lane_Values_I32x8 is array (Lane_Index_32x8) of I32;
   --  I32 lane values in logical lane order.
   function Zero return I32x8;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : I32) return I32x8;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I32x8) return I32x8;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I32x8) return Lane_Values_I32x8;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I32x8; Lane : Lane_Index_32x8) return I32;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I32x8; Lane : Lane_Index_32x8; With_Value : I32) return I32x8;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I32x8) return U32x8;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : I32x8) return F32x8;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I32x8) return I32x8;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I32x8) return I32x8;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I32x8) return I32x8;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I32x8) return I32x8;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I32x8) return I32x8;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I32x8) return I32x8;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I32x8) return I32x8;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I32x8) return I32x8;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I32x8) return I32x8;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I32x8) return I32x8;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I32x8) return I32x8;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I32x8; Count : Natural) return I32x8;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I32x8; Count : Natural) return I32x8;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I32x8; Count : Natural) return I32x8;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I32x8) return Mask_32x8;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I32x8) return Mask_32x8;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I32x8) return Mask_32x8;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I32x8) return Mask_32x8;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I32x8) return Mask_32x8;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : I32x8) return I32x8;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I32x8) return I32;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I32x8) return I32;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I32x8) return I32;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I32x8) return I32x8;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I32x8) return I32x8;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I32x8) return I32x8;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I32x8) return I32x8;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I32x8) return I32x8;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x8) return I32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x8; Value : I32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   subtype Lane_Index_64x4 is Natural range 0 .. 3;
   --  Logical lane indexes for 4-lane vectors.
   subtype Lane_Count_64x4 is Natural range 0 .. 4;
   --  Counts from zero through the complete 4-lane width.
   type Lane_Selectors_64x4 is array (Lane_Index_64x4) of Lane_Index_64x4;
   --  One source-lane selector for each result lane.
   type Lane_Map_64x4 is private;
   --  A reusable, validated mapping from result lanes to source lanes.
   function Make_Lane_Map (Selectors : Lane_Selectors_64x4) return Lane_Map_64x4;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Two_Source_Lane_Selector_64x4 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   type Two_Source_Lane_Selectors_64x4 is array (Lane_Index_64x4) of Two_Source_Lane_Selector_64x4;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_64x4 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_64x4) return Two_Source_Lane_Map_64x4;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   type Mask_64x4 is private;
   --  One semantic Boolean truth for each of 4 lanes.
   subtype Mask_Bits_64x4 is Interfaces.Unsigned_8 range 0 .. 15;
   --  Compact bits for exactly 4 mask lanes.
   type Lane_Values_U64x4 is array (Lane_Index_64x4) of U64;
   --  U64 lane values in logical lane order.
   function Zero return U64x4;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : U64) return U64x4;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U64x4) return U64x4;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U64x4) return Lane_Values_U64x4;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U64x4; Lane : Lane_Index_64x4) return U64;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U64x4; Lane : Lane_Index_64x4; With_Value : U64) return U64x4;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U64x4) return I64x4;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : U64x4) return F64x4;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U64x4) return U64x4;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U64x4) return U64x4;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U64x4) return U64x4;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U64x4) return U64x4;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U64x4) return U64x4;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U64x4) return U64x4;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U64x4) return U64x4;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U64x4) return U64x4;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U64x4) return U64x4;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U64x4) return U64x4;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U64x4) return U64x4;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U64x4; Count : Natural) return U64x4;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U64x4; Count : Natural) return U64x4;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U64x4) return Mask_64x4;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U64x4) return Mask_64x4;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U64x4) return Mask_64x4;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U64x4) return Mask_64x4;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U64x4) return Mask_64x4;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : U64x4) return U64x4;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U64x4) return U64;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U64x4) return U64;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U64x4) return U64;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U64x4) return U64x4;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U64x4) return U64x4;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U64x4) return U64x4;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U64x4) return U64x4;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U64x4) return U64x4;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_64x4) return Mask_64x4;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_64x4) return Mask_Bits_64x4;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_64x4) return Mask_64x4;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_64x4) return Mask_64x4;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_64x4) return Mask_64x4;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_64x4) return Mask_64x4;
   --  Complement every mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_64x4; Lane : Lane_Index_64x4) return Boolean;
   --  Return one mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_64x4) return Boolean;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_64x4) return Boolean;
   --  Return the All_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_64x4) return Boolean;
   --  Return the None_True mask reduction.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_64x4) return Lane_Count_64x4;
   --  Return the number of true lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_64x4) return Lane_Count_64x4;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_64x4) return Lane_Count_64x4;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x4) return U64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x4; Value : U64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   type Lane_Values_I64x4 is array (Lane_Index_64x4) of I64;
   --  I64 lane values in logical lane order.
   function Zero return I64x4;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : I64) return I64x4;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I64x4) return I64x4;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I64x4) return Lane_Values_I64x4;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I64x4; Lane : Lane_Index_64x4) return I64;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I64x4; Lane : Lane_Index_64x4; With_Value : I64) return I64x4;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I64x4) return U64x4;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : I64x4) return F64x4;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I64x4) return I64x4;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I64x4) return I64x4;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I64x4) return I64x4;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I64x4) return I64x4;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I64x4) return I64x4;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I64x4) return I64x4;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I64x4) return I64x4;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I64x4) return I64x4;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I64x4) return I64x4;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I64x4) return I64x4;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I64x4) return I64x4;
   --  Complement every bit in every lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I64x4; Count : Natural) return I64x4;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I64x4; Count : Natural) return I64x4;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I64x4; Count : Natural) return I64x4;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I64x4) return Mask_64x4;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I64x4) return Mask_64x4;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I64x4) return Mask_64x4;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I64x4) return Mask_64x4;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I64x4) return Mask_64x4;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : I64x4) return I64x4;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I64x4) return I64;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I64x4) return I64;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I64x4) return I64;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I64x4) return I64x4;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I64x4) return I64x4;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I64x4) return I64x4;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I64x4) return I64x4;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I64x4) return I64x4;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x4) return I64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x4; Value : I64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   type Lane_Values_F32x8 is array (Lane_Index_32x8) of F32;
   --  F32 lane values in logical lane order.
   function Zero return F32x8;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : F32) return F32x8;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F32x8) return F32x8;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : F32x8) return Lane_Values_F32x8;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : F32x8; Lane : Lane_Index_32x8) return F32;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : F32x8; Lane : Lane_Index_32x8; With_Value : F32) return F32x8;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : F32x8) return U32x8;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : F32x8) return I32x8;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add (Left, Right : F32x8) return F32x8;
   --  Apply Add independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vaddps operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F32x8) return F32x8;
   --  Apply Subtract independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vsubps operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F32x8) return F32x8;
   --  Apply Multiply independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vmulps operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F32x8) return F32x8;
   --  Apply Divide independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vdivps operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min_Number (Left, Right : F32x8) return F32x8;
   --  Apply Min_Number independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F32x8) return F32x8;
   --  Apply Max_Number independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F32x8) return Mask_32x8;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F32x8) return Mask_32x8;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F32x8) return Mask_32x8;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F32x8) return Mask_32x8;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F32x8) return Mask_32x8;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F32x8) return Mask_32x8;
   --  Apply Unordered independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : F32x8) return F32x8;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add (Value : F32x8) return F32;
   --  Apply Reduce_Add in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend uses a dedicated ordered Advanced SIMD sequence that starts from positive zero and visits lanes in ascending order. The x86-64 backend uses portable Ada composition. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F32x8) return F32;
   --  Apply Reduce_Min_Number in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend uses a dedicated ordered Advanced SIMD sequence with scalar fminnm operations that visits lanes in ascending order. The x86-64 backend uses portable Ada composition. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F32x8) return F32;
   --  Apply Reduce_Max_Number in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend uses a dedicated ordered Advanced SIMD sequence with scalar fmaxnm operations that visits lanes in ascending order. The x86-64 backend uses portable Ada composition. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : F32x8) return F32x8;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F32x8) return F32x8;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F32x8) return F32x8;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F32x8) return F32x8;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F32x8) return F32x8;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : F32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x8) return F32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x8; Value : F32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   type Lane_Values_F64x4 is array (Lane_Index_64x4) of F64;
   --  F64 lane values in logical lane order.
   function Zero return F64x4;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @return The operation result.
   function Splat (Value : F64) return F64x4;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F64x4) return F64x4;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : F64x4) return Lane_Values_F64x4;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : F64x4; Lane : Lane_Index_64x4) return F64;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : F64x4; Lane : Lane_Index_64x4; With_Value : F64) return F64x4;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : F64x4) return U64x4;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : F64x4) return I64x4;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add (Left, Right : F64x4) return F64x4;
   --  Apply Add independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vaddpd operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F64x4) return F64x4;
   --  Apply Subtract independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vsubpd operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F64x4) return F64x4;
   --  Apply Multiply independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vmulpd operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F64x4) return F64x4;
   --  Apply Divide independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vdivpd operation and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min_Number (Left, Right : F64x4) return F64x4;
   --  Apply Min_Number independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F64x4) return F64x4;
   --  Apply Max_Number independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F64x4) return Mask_64x4;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F64x4) return Mask_64x4;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F64x4) return Mask_64x4;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F64x4) return Mask_64x4;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F64x4) return Mask_64x4;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F64x4) return Mask_64x4;
   --  Apply Unordered independently to corresponding lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : F64x4) return F64x4;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a byte map and uses two-register NEON tbl for each result half. The x86-64 backend uses the Wide scalar implementation. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add (Value : F64x4) return F64;
   --  Apply Reduce_Add in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend uses a dedicated ordered Advanced SIMD sequence that starts from positive zero and visits lanes in ascending order. The x86-64 backend uses portable Ada composition. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F64x4) return F64;
   --  Apply Reduce_Min_Number in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend uses a dedicated ordered Advanced SIMD sequence with scalar fminnm operations that visits lanes in ascending order. The x86-64 backend uses portable Ada composition. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F64x4) return F64;
   --  Apply Reduce_Max_Number in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend uses a dedicated ordered Advanced SIMD sequence with scalar fmaxnm operations that visits lanes in ascending order. The x86-64 backend uses portable Ada composition. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : F64x4) return F64x4;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F64x4) return F64x4;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F64x4) return F64x4;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F64x4) return F64x4;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F64x4) return F64x4;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend calls the Wide scalar implementation. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, the matching Wide.Native overload calls the portable Wide implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : F64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends use the same portable Ada implementation. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start);
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x4) return F64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x4; Value : F64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends conditionally compose selected 128-bit full and partial memory operations. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   function Widen_Low (Value : U8x32) return U16x16;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U8x32) return U16x16;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I8x32) return I16x16;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I8x32) return I16x16;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : U16x16) return U32x8;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U16x16) return U32x8;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I16x16) return I32x8;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I16x16) return I32x8;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : U32x8) return U64x4;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U32x8) return U64x4;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I32x8) return I64x4;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I32x8) return I64x4;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : F32x8) return F64x4;
   --  With the platform's default gradual-underflow environment, widen the low binary32 source half exactly to binary64 and preserve lane order. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : F32x8) return F64x4;
   --  With the platform's default gradual-underflow environment, widen the high binary32 source half exactly to binary64 and preserve lane order. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U16x16) return U8x32;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U16x16) return U8x32;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I16x16) return I8x32;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x16) return I8x32;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U32x8) return U16x16;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U32x8) return U16x16;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I32x8) return I16x16;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x8) return I16x16;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U64x4) return U32x8;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U64x4) return U32x8;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I64x4) return I32x8;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x4) return I32x8;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x16) return U8x32;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x8) return U16x16;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x4) return U32x8;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Round (Low, High : F64x4) return F32x8;
   --  With the default round-to-nearest, ties-to-even and gradual-underflow environment, round binary64 lanes to binary32 and concatenate Low before High. Preserve signed zero and infinity. Use gradual underflow and signed overflow to infinity. A NaN remains a NaN with unspecified payload and signaling state. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Convert_Round (Value : I32x8) return F32x8;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : U32x8) return F32x8;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : I64x4) return F64x4;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : U64x4) return F64x4;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x8) return I32x8;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x8) return U32x8;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x4) return I64x4;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x4) return U64x4;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I8x32) return U8x32;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U8x32) return I8x32;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I16x16) return U16x16;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U16x16) return I16x16;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I32x8) return U32x8;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U32x8) return I32x8;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I64x4) return U64x4;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U64x4) return I64x4;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: This overload uses the portable scalar Wide implementation on every supported GNAT target. For the matching Wide.Native overload, the AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.

private
   type U8x32 is record
      Low, High : U8x16;
   end record;
   for U8x32'Size use 256;
   type Lane_Map_8x32 is record
      Selectors : Lane_Selectors_8x32 := [others => 0];
   end record;
   type Two_Source_Lane_Selector_8x32 is record
      From_Right : Boolean := False;
      Lane : Lane_Index_8x32 := 0;
   end record;
   type Two_Source_Lane_Map_8x32 is record
      Selectors : Two_Source_Lane_Selectors_8x32 := [others => (From_Right => False, Lane => 0)];
   end record;
   type Mask_8x32 is record
      Low, High : Mask_8x16;
   end record;
   type I8x32 is record
      Low, High : I8x16;
   end record;
   for I8x32'Size use 256;
   type U16x16 is record
      Low, High : U16x8;
   end record;
   for U16x16'Size use 256;
   type Lane_Map_16x16 is record
      Selectors : Lane_Selectors_16x16 := [others => 0];
   end record;
   type Two_Source_Lane_Selector_16x16 is record
      From_Right : Boolean := False;
      Lane : Lane_Index_16x16 := 0;
   end record;
   type Two_Source_Lane_Map_16x16 is record
      Selectors : Two_Source_Lane_Selectors_16x16 := [others => (From_Right => False, Lane => 0)];
   end record;
   type Mask_16x16 is record
      Low, High : Mask_16x8;
   end record;
   type I16x16 is record
      Low, High : I16x8;
   end record;
   for I16x16'Size use 256;
   type U32x8 is record
      Low, High : U32x4;
   end record;
   for U32x8'Size use 256;
   type Lane_Map_32x8 is record
      Selectors : Lane_Selectors_32x8 := [others => 0];
   end record;
   type Two_Source_Lane_Selector_32x8 is record
      From_Right : Boolean := False;
      Lane : Lane_Index_32x8 := 0;
   end record;
   type Two_Source_Lane_Map_32x8 is record
      Selectors : Two_Source_Lane_Selectors_32x8 := [others => (From_Right => False, Lane => 0)];
   end record;
   type Mask_32x8 is record
      Low, High : Mask_32x4;
   end record;
   type I32x8 is record
      Low, High : I32x4;
   end record;
   for I32x8'Size use 256;
   type U64x4 is record
      Low, High : U64x2;
   end record;
   for U64x4'Size use 256;
   type Lane_Map_64x4 is record
      Selectors : Lane_Selectors_64x4 := [others => 0];
   end record;
   type Two_Source_Lane_Selector_64x4 is record
      From_Right : Boolean := False;
      Lane : Lane_Index_64x4 := 0;
   end record;
   type Two_Source_Lane_Map_64x4 is record
      Selectors : Two_Source_Lane_Selectors_64x4 := [others => (From_Right => False, Lane => 0)];
   end record;
   type Mask_64x4 is record
      Low, High : Mask_64x2;
   end record;
   type I64x4 is record
      Low, High : I64x2;
   end record;
   for I64x4'Size use 256;
   type F32x8 is record
      Low, High : F32x4;
   end record;
   for F32x8'Size use 256;
   type F64x4 is record
      Low, High : F64x2;
   end record;
   for F64x4'Size use 256;
end Flyology_SIMD.Wide;
