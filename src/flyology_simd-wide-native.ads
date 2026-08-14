--  Statically selected 256-bit composition through the native 128-bit backend.
package Flyology_SIMD.Wide.Native
  with Preelaborate
is
   function Make_Lane_Map (Selectors : Lane_Selectors_8x32) return Lane_Map_8x32 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_8x32) return Two_Source_Lane_Map_8x32 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U8x32 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : U8) return U8x32 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U8x32) return U8x32 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U8x32) return Lane_Values_U8x32 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U8x32; Lane : Lane_Index_8x32) return U8 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U8x32; Lane : Lane_Index_8x32; With_Value : U8) return U8x32 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Table_Lookup (Table, Indices : U8x32) return U8x32 with Inline_Always;
   --  Select each result byte from the corresponding unsigned index. Indexes from 0 through 31 select that table lane; larger indexes produce zero.
   --  Cross-platform support: The AArch64 backend uses one two-register NEON tbl operation for each result half. The composed x86-64 backend constructs one 16-filled vector with selected Splat. It uses four selected 128-bit Table_Lookup operations, two selected Subtract_Wrap operations, and two selected Bitwise_Or operations. The optional AVX2 backend uses a dedicated U8x32 implementation. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Table The table input.
   --  @param Indices The indices input.
   --  @return The operation result.
   function Bit_Cast (Value : U8x32) return I8x32 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Add_Wrap operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpaddb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Subtract_Wrap operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpsubb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Multiply_Wrap operation for both private parts. The optional AVX2 backend calls an isolated 256-bit byte-multiplication leaf that uses vpmullw, vpand, vpsrlw, vpsllw, and vpor and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Add_Saturate operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpaddusb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Subtract_Saturate operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpsubusb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_And operation to both private parts. The optional AVX2 backend calls an isolated 256-bit vpand leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_Or operation to both private parts. The optional AVX2 backend calls an isolated 256-bit vpor leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. The optional AVX2 backend calls an isolated 256-bit vpxor leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x32) return U8x32 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_Not operation to both private parts. The optional AVX2 backend calls an isolated 256-bit leaf that constructs an all-one mask with vpcmpeqd and complements with vpxor and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Equal operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Equal leaf. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Less_Than operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Less_Than leaf. The leaf reverses the operands within its Greater_Than comparison. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Less_Equal operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Less_Equal leaf. The leaf complements the result of Greater_Than (Left, Right). A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Greater_Than operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Greater_Than leaf. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Greater_Equal operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Greater_Equal leaf. The leaf complements the result of Greater_Than (Right, Left). A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x32; If_True, If_False : U8x32) return U8x32 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Select_Value operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Select_Value leaf. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Horizontal_Sum (Value : U8x32) return Natural with Post => Horizontal_Sum'Result <= 32 * 255, Inline_Always;
   --  Return the exact sum of all 32 unsigned byte lanes as Natural.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x32) return U8 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U8x32) return U8 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U8x32) return U8 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x32) return U8x32 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_8x32) return Mask_8x32 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x32) return Mask_Bits_8x32 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Complement every mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_8x32; Lane : Lane_Index_8x32) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x32) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_8x32) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_8x32) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x32) return Lane_Count_8x32 with Inline_Always;
   --  Return the number of true lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit population-count operation on both private parts and add the two counts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_8x32) return Lane_Count_8x32 with Inline_Always;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x32) return Lane_Count_8x32 with Inline_Always;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : Byte_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x32) return U8x32 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out Byte_Array; Start : Natural; Count : Lane_Count_8x32; Value : U8x32) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I8x32 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : I8) return I8x32 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I8x32) return I8x32 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I8x32) return Lane_Values_I8x32 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I8x32; Lane : Lane_Index_8x32) return I8 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I8x32; Lane : Lane_Index_8x32; With_Value : I8) return I8x32 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I8x32) return U8x32 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Add_Wrap operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpaddb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Subtract_Wrap operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpsubb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Multiply_Wrap operation for both private parts. The optional AVX2 backend calls an isolated 256-bit byte-multiplication leaf that uses vpmullw, vpand, vpsrlw, vpsllw, and vpor and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Add_Saturate operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpaddsb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends call the selected 128-bit Subtract_Saturate operation for both private parts. The optional AVX2 backend calls an isolated 256-bit vpsubsb leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_And operation to both private parts. The optional AVX2 backend calls an isolated 256-bit vpand leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_Or operation to both private parts. The optional AVX2 backend calls an isolated 256-bit vpor leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. The optional AVX2 backend calls an isolated 256-bit vpxor leaf and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses a dedicated 256-bit implementation. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I8x32) return I8x32 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64 and composed x86-64 backends apply the selected 128-bit Bitwise_Not operation to both private parts. The optional AVX2 backend calls an isolated 256-bit leaf that constructs an all-one mask with vpcmpeqd and complements with vpxor and then runs vzeroupper. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Arithmetic operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Equal operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Equal leaf. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Less_Than operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Less_Than leaf. The leaf reverses the operands within its Greater_Than comparison. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Less_Equal operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Less_Equal leaf. The leaf complements the result of Greater_Than (Left, Right). A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Greater_Than operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Greater_Than leaf. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Greater_Equal operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Greater_Equal leaf. The leaf complements the result of Greater_Than (Right, Left). A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x32; If_True, If_False : I8x32) return I8x32 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 backend runs the selected 128-bit Select_Value operation on both private parts. The x86-64 backend does the same by default, and the optional AVX2 build uses an isolated relation-specific 256-bit Select_Value leaf. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I8x32) return I8 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I8x32) return I8 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I8x32) return I8 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I8x32) return I8x32 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I8_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x32) return I8x32 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x32; Value : I8x32) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Make_Lane_Map (Selectors : Lane_Selectors_16x16) return Lane_Map_16x16 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_16x16) return Two_Source_Lane_Map_16x16 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U16x16 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : U16) return U16x16 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U16x16) return U16x16 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U16x16) return Lane_Values_U16x16 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U16x16; Lane : Lane_Index_16x16) return U16 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U16x16; Lane : Lane_Index_16x16; With_Value : U16) return U16x16 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U16x16) return I16x16 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Multiply_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_And operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Or operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U16x16) return U16x16 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Not operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x16; If_True, If_False : U16x16) return U16x16 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U16x16) return U16 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U16x16) return U16 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U16x16) return U16 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U16x16) return U16x16 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_16x16) return Mask_16x16 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_16x16) return Mask_Bits_16x16 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Complement every mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_16x16; Lane : Lane_Index_16x16) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_16x16) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_16x16) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_16x16) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_16x16) return Lane_Count_16x16 with Inline_Always;
   --  Return the number of true lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit population-count operation on both private parts and add the two counts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_16x16) return Lane_Count_16x16 with Inline_Always;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_16x16) return Lane_Count_16x16 with Inline_Always;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U16_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x16) return U16x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x16; Value : U16x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I16x16 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : I16) return I16x16 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I16x16) return I16x16 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I16x16) return Lane_Values_I16x16 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I16x16; Lane : Lane_Index_16x16) return I16 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I16x16; Lane : Lane_Index_16x16; With_Value : I16) return I16x16 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I16x16) return U16x16 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Multiply_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_And operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Or operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I16x16) return I16x16 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Not operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Arithmetic operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x16; If_True, If_False : I16x16) return I16x16 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I16x16) return I16 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I16x16) return I16 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I16x16) return I16 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I16x16) return I16x16 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I16_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x16) return I16x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x16; Value : I16x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Make_Lane_Map (Selectors : Lane_Selectors_32x8) return Lane_Map_32x8 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_32x8) return Two_Source_Lane_Map_32x8 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U32x8 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : U32) return U32x8 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U32x8) return U32x8 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U32x8) return Lane_Values_U32x8 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U32x8; Lane : Lane_Index_32x8) return U32 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U32x8; Lane : Lane_Index_32x8; With_Value : U32) return U32x8 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U32x8) return I32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : U32x8) return F32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Multiply_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_And operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Or operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U32x8) return U32x8 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Not operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : U32x8) return U32x8 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U32x8) return U32 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U32x8) return U32 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U32x8) return U32 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U32x8) return U32x8 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_32x8) return Mask_32x8 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_32x8) return Mask_Bits_32x8 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Complement every mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_32x8; Lane : Lane_Index_32x8) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_32x8) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_32x8) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_32x8) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_32x8) return Lane_Count_32x8 with Inline_Always;
   --  Return the number of true lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit population-count operation on both private parts and add the two counts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_32x8) return Lane_Count_32x8 with Inline_Always;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_32x8) return Lane_Count_32x8 with Inline_Always;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U32_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x8) return U32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x8; Value : U32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I32x8 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : I32) return I32x8 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I32x8) return I32x8 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I32x8) return Lane_Values_I32x8 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I32x8; Lane : Lane_Index_32x8) return I32 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I32x8; Lane : Lane_Index_32x8; With_Value : I32) return I32x8 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I32x8) return U32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : I32x8) return F32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Multiply_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_And operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Or operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I32x8) return I32x8 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Not operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Arithmetic operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : I32x8) return I32x8 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I32x8) return I32 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I32x8) return I32 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I32x8) return I32 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I32x8) return I32x8 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I32_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x8) return I32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x8; Value : I32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Make_Lane_Map (Selectors : Lane_Selectors_64x4) return Lane_Map_64x4 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_64x4) return Two_Source_Lane_Map_64x4 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  Cross-platform support: The AArch64 and x86-64 backends use portable Ada code. A scalar build uses the portable Wide implementation.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U64x4 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : U64) return U64x4 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U64x4) return U64x4 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U64x4) return Lane_Values_U64x4 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U64x4; Lane : Lane_Index_64x4) return U64 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U64x4; Lane : Lane_Index_64x4; With_Value : U64) return U64x4 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U64x4) return I64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : U64x4) return F64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Multiply_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_And operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Or operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U64x4) return U64x4 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Not operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : U64x4) return U64x4 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U64x4) return U64 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U64x4) return U64 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U64x4) return U64 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U64x4) return U64x4 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_64x4) return Mask_64x4 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_64x4) return Mask_Bits_64x4 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Complement every mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_64x4; Lane : Lane_Index_64x4) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation only on the private part that contains the requested lane. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_64x4) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_64x4) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_64x4) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit operation on each private part and combine the results in Ada. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_64x4) return Lane_Count_64x4 with Inline_Always;
   --  Return the number of true lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit population-count operation on both private parts and add the two counts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_64x4) return Lane_Count_64x4 with Inline_Always;
   --  Return the lowest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid low-part result first. Otherwise, they return a valid high-part result plus the private lane count. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_64x4) return Lane_Count_64x4 with Inline_Always;
   --  Return the highest true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: The AArch64 and x86-64 backends query both private parts with the selected 128-bit mask-position operation. They return a valid high-part result plus the private lane count first. Otherwise, they return a valid low-part result. If neither part contains a true lane, they return the Wide lane-count value. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U64_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x4) return U64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x4; Value : U64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I64x4 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : I64) return I64x4 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I64x4) return I64x4 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I64x4) return Lane_Values_I64x4 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I64x4; Lane : Lane_Index_64x4) return I64 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I64x4; Lane : Lane_Index_64x4; With_Value : I64) return I64x4 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I64x4) return U64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : I64x4) return F64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Multiply_Wrap operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Add_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends call the selected 128-bit Subtract_Saturate operation for both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_And operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Or operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Xor operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I64x4) return I64x4 with Inline_Always;
   --  Complement every bit in every lane.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Bitwise_Not operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Left_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Logical operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  Cross-platform support: The AArch64, composed x86-64, and optional AVX2 backends apply the selected 128-bit Shift_Right_Arithmetic operation to both private parts. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : I64x4) return I64x4 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I64x4) return I64 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Add_Wrap operation, combine the two results with the selected 128-bit Add_Wrap operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I64x4) return I64 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Min operation, combine the two results with the selected 128-bit Min operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I64x4) return I64 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends reduce each private part with the selected 128-bit Reduce_Max operation, combine the two results with the selected 128-bit Max operation, and extract lane zero. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I64x4) return I64x4 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I64_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x4) return I64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x4; Value : I64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return F32x8 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : F32) return F32x8 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F32x8) return F32x8 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : F32x8) return Lane_Values_F32x8 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : F32x8; Lane : Lane_Index_32x8) return F32 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : F32x8; Lane : Lane_Index_32x8; With_Value : F32) return F32x8 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : F32x8) return U32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : F32x8) return I32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Add independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vaddps operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Subtract independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vsubps operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Multiply independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vmulps operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Divide independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vdivps operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min_Number (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Min_Number independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Max_Number independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Unordered independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Unordered operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : F32x8) return F32x8 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add (Value : F32x8) return F32 with Inline_Always;
   --  Apply Reduce_Add in ascending lane order.
   --  Cross-platform support: The AArch64 backend uses a dedicated Advanced SIMD sequence that starts from positive zero and adds one lane at a time in ascending order. The x86-64 backend uses a dedicated SSE2 sequence with the same start value and lane order. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F32x8) return F32 with Inline_Always;
   --  Apply Reduce_Min_Number in ascending lane order.
   --  Cross-platform support: The AArch64 backend uses a dedicated Advanced SIMD sequence that applies fminnm to one lane at a time in ascending order. The x86-64 backend uses a dedicated integer-only SSE2 classification and bit-selection sequence that applies minimum-number in the same order. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F32x8) return F32 with Inline_Always;
   --  Apply Reduce_Max_Number in ascending lane order.
   --  Cross-platform support: The AArch64 backend uses a dedicated Advanced SIMD sequence that applies fmaxnm to one lane at a time in ascending order. The x86-64 backend uses a dedicated integer-only SSE2 classification and bit-selection sequence that applies maximum-number in the same order. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : F32x8) return F32x8 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : F32_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x8) return F32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x8; Value : F32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return F64x4 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Zero operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @return The operation result.
   function Splat (Value : F64) return F64x4 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Splat operation for both private parts and return the two-part result. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F64x4) return F64x4 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends split the logical lane array into low and high private parts. They call the matching selected 128-bit From_Lanes operation for each part. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : F64x4) return Lane_Values_F64x4 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit To_Lanes operation for both private parts. They concatenate the low-part lanes followed by the high-part lanes in logical order. In a scalar build, this overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : F64x4; Lane : Lane_Index_64x4) return F64 with Inline_Always;
   --  Return one logical lane.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Extract operation only on the private part that contains the requested lane. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : F64x4; Lane : Lane_Index_64x4; With_Value : F64) return F64x4 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  Cross-platform support: The AArch64 and x86-64 backends call the matching selected 128-bit Replace operation only on the private part that contains the requested lane and preserve the other part. In a scalar build, this overload uses the same selected-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : F64x4) return U64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : F64x4) return I64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Add (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Add independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vaddpd operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Subtract independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vsubpd operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Multiply independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vmulpd operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Divide independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit vdivpd operation and vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min_Number (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Min_Number independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Max_Number independently to corresponding lanes.
   --  Cross-platform support: The AArch64 backend and the composed x86-64 backend run the selected 128-bit operation on both private parts. The optional AVX2 backend uses one isolated 256-bit integer-classification and bit-selection sequence. The sequence preserves the documented NaN and signed-zero rules. Each leaf ends with vzeroupper. In a scalar build, this overload calls the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Less_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Than operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Greater_Equal operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Unordered independently to corresponding lanes.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Unordered operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : F64x4) return F64x4 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit Select_Value operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte compression map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit compression maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  Cross-platform support: The AArch64 backend applies the selected 128-bit To_Bit_Mask operation to each private mask part. It combines the two results and derives one 32-byte expansion map. An isolated assembly subprogram runs one two-register NEON tbl operation for each result half. The x86-64 composed and optional AVX2 backends derive two selected-128-bit expansion maps. They run one SSE2 two-source permutation for each result half and apply the selected 128-bit mask and zero operations for defined zero fill. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add (Value : F64x4) return F64 with Inline_Always;
   --  Apply Reduce_Add in ascending lane order.
   --  Cross-platform support: The AArch64 backend uses a dedicated Advanced SIMD sequence that starts from positive zero and adds one lane at a time in ascending order. The x86-64 backend uses a dedicated SSE2 sequence with the same start value and lane order. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F64x4) return F64 with Inline_Always;
   --  Apply Reduce_Min_Number in ascending lane order.
   --  Cross-platform support: The AArch64 backend uses a dedicated Advanced SIMD sequence that applies fminnm to one lane at a time in ascending order. The x86-64 backend uses a dedicated integer-only SSE2 classification and bit-selection sequence that applies minimum-number in the same order. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F64x4) return F64 with Inline_Always;
   --  Apply Reduce_Max_Number in ascending lane order.
   --  Cross-platform support: The AArch64 backend uses a dedicated Advanced SIMD sequence that applies fmaxnm to one lane at a time in ascending order. The x86-64 backend uses a dedicated integer-only SSE2 classification and bit-selection sequence that applies maximum-number in the same order. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : F64x4) return F64x4 with Inline_Always;
   --  Reverse logical lane order.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses the same two Permute_Lanes operations through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Alternate lanes from the low half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Alternate lanes from the high half of Left and Right, starting with Left.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Return the even-index lanes of Left followed by the even-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Return the odd-index lanes of Left followed by the odd-index lanes of Right.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one four-register NEON tbl operation for each result half. The composed x86-64 backend uses four selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations. The optional AVX2 backend derives a 32-byte index map and uses four vpshufb instructions, two vperm2i128 instructions, mask selection, and vzeroupper. In a scalar build, this overload uses the same four permutations and two selections through the portable 128-bit implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  Cross-platform support: The AArch64 backend derives a 32-byte index map and runs one two-register NEON tbl operation for each result half. The composed x86-64 backend uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero. The optional AVX2 backend derives a 32-byte index map and uses two vpshufb instructions, one vperm2i128 instruction, mask selection, and vzeroupper. In a scalar build, this overload uses two selected 128-bit two-source Permute_Lanes operations and two selected Select_Value operations against Zero through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : F64_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends first check that Start is in the array range. For a valid Start, they test the selected element address modulo 32 directly with fixed-width Ada code. A scalar build uses the portable Wide implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Unaligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Load_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  Cross-platform support: The AArch64 and x86-64 backends call the selected 128-bit Store_Aligned operation at Start and Start plus the private lane count. In a scalar build, this overload uses the same two-part composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x4) return F64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Load_Partial operation for the low result part and the selected Zero operation for the high result part. When Count exceeds the private lane count, they call the selected Load operation for the low result part and the selected Load_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x4; Value : F64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  Cross-platform support: When Count does not exceed the private lane count, the AArch64 and x86-64 backends call the selected 128-bit Store_Partial operation for the low value part. When Count exceeds the private lane count, they call the selected Store operation for the low value part and the selected Store_Partial operation for the remaining high lanes. A zero count does not evaluate an element address. In a scalar build, this overload uses the same conditional composition through the portable 128-bit implementation.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   function Widen_Low (Value : U8x32) return U16x16 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U8x32) return U16x16 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I8x32) return I16x16 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I8x32) return I16x16 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : U16x16) return U32x8 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U16x16) return U32x8 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I16x16) return I32x8 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I16x16) return I32x8 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : U32x8) return U64x4 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U32x8) return U64x4 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I32x8) return I64x4 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I32x8) return I64x4 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : F32x8) return F64x4 with Inline_Always;
   --  With the platform's default gradual-underflow environment, widen the low binary32 source half exactly to binary64 and preserve lane order. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: The AArch64 and x86-64 backends select the low private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : F32x8) return F64x4 with Inline_Always;
   --  With the platform's default gradual-underflow environment, widen the high binary32 source half exactly to binary64 and preserve lane order. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: The AArch64 and x86-64 backends select the high private source part. The selected 128-bit Widen_Low operation forms the low result part, and the selected 128-bit Widen_High operation forms the high result part. In a scalar build, the overload uses the same composition through the portable 128-bit implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U16x16) return U8x32 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U16x16) return U8x32 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I16x16) return I8x32 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x16) return I8x32 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U32x8) return U16x16 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U32x8) return U16x16 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I32x8) return I16x16 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x8) return I16x16 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U64x4) return U32x8 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U64x4) return U32x8 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I64x4) return I32x8 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x4) return I32x8 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x16) return U8x32 with Inline_Always;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x8) return U16x16 with Inline_Always;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x4) return U32x8 with Inline_Always;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Round (Low, High : F64x4) return F32x8 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even and gradual-underflow environment, round binary64 lanes to binary32 and concatenate Low before High. Preserve signed zero and infinity. Use gradual underflow and signed overflow to infinity. A NaN remains a NaN with unspecified payload and signaling state. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Convert_Round (Value : I32x8) return F32x8 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : U32x8) return F32x8 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : I64x4) return F64x4 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : U64x4) return F64x4 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not change the rounding mode or exception-control settings. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x8) return I32x8 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x8) return U32x8 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x4) return I64x4 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x4) return U64x4 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode. Floating-point exception-status flags can change.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I8x32) return U8x32 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U8x32) return I8x32 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I16x16) return U16x16 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U16x16) return I16x16 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I32x8) return U32x8 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U32x8) return I32x8 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I64x4) return U64x4 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U64x4) return I64x4 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  Cross-platform support: The AArch64 and x86-64 backends run the selected 128-bit operation on both private parts. A scalar build uses the portable Wide implementation.
   --  @param Value The value input.
   --  @return The operation result.
end Flyology_SIMD.Wide.Native;
